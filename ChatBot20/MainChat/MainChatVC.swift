import UIKit
import SnapKit

class MainChatVC: UIViewController {
    
    private let chatView: AIChatView

    init(isWardrobeChat: Bool = false) {
        chatView = AIChatView(isWardrobeChat: isWardrobeChat)
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(chatView)
        chatView.vc = self
        chatView.setup()
        chatView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        chatView.setMessagesFromDB()
        chatView.setupNavTitleAndAvatar()
        
        if !NetworkMonitor.shared.isConnected {
            showInternetErrorAlert()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        chatView.updateForRLTIfNeeded()
    }
    
    func showInternetErrorAlert() {
        let alertController = UIAlertController(
            title: "InternetError.title".localize(),
            message: "InternetError.message".localize(),
            preferredStyle: .alert
        )
        
        let okAction = UIAlertAction(title: "OK".localize(), style: .default)
        alertController.addAction(okAction)
        
        present(alertController, animated: true)
    }
}
