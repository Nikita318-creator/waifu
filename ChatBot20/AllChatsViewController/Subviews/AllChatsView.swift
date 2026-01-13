import UIKit
import SnapKit

class AllChatsView: UIView {

    private struct TelegramColors {
        static let primary = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0) // #3390DC
        static let background = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0) // #1C1C1E
        static let cardBackground = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1.0) // #2C2C2E
        static let messageBackground = UIColor(red: 0.22, green: 0.22, blue: 0.24, alpha: 1.0) // #38383A
        static let userMessageBackground = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0) // #3390DC
        static let textPrimary = UIColor.white
        static let textSecondary = UIColor(red: 0.64, green: 0.64, blue: 0.66, alpha: 1.0) // #A4A4A8
        static let separator = UIColor(red: 0.28, green: 0.28, blue: 0.29, alpha: 1.0) // #48484A
    }
    
    let tableView = UITableView(frame: .zero, style: .grouped) 
    private let headerTitle = UILabel()

    private var needScrollTotTheEnd: Bool = true
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup() {
        backgroundColor = TelegramColors.background
        
        headerTitle.text = "Messages".localize() 
        headerTitle.font = .systemFont(ofSize: 34, weight: .bold)
        headerTitle.textColor = TelegramColors.textPrimary
        addSubview(headerTitle)
        
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 100, right: 0)
        tableView.register(ChatListItemCell.self, forCellReuseIdentifier: ChatListItemCell.identifier)
        addSubview(tableView)

        headerTitle.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide)
            make.leading.equalToSuperview().inset(20)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(headerTitle.snp.bottom).offset(15)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
}
