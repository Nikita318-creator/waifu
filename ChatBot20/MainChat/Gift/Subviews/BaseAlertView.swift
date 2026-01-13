
import UIKit
import SnapKit

// MARK: - Custom Alert Views

class BaseAlertView: UIView {
    let alertView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupBase()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupBase() {
        backgroundColor = UIColor.black.withAlphaComponent(0.4)
        
        alertView.layer.cornerRadius = 20
        alertView.backgroundColor = .systemBackground
        addSubview(alertView)
        
        alertView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(40)
        }
    }
    
    func show(on viewController: UIViewController) {
        self.frame = viewController.view.bounds
        viewController.view.addSubview(self)
        
        alertView.alpha = 0
        alertView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        UIView.animate(withDuration: 0.3) {
            self.alertView.alpha = 1
            self.alertView.transform = .identity
        }
    }
    
    @objc func dismissAlert() {
        UIView.animate(withDuration: 0.3) {
            self.alpha = 0
        } completion: { _ in
            self.removeFromSuperview()
        }
    }
}

// MARK: - GiftConfirmAlert
class GiftConfirmAlert: BaseAlertView {
    
    private let closeButton = UIButton(type: .system)
    private let giftImageView = UIImageView()
    private let sendButton = UIButton(type: .system)
    
    private var completion: (() -> Void)?
    
    init(gift: GiftItem, completion: @escaping () -> Void) {
        super.init(frame: .zero)
        self.completion = completion
        setupAlert(gift: gift)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupAlert(gift: GiftItem) {
        // Close Button
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .secondaryLabel
        closeButton.addTarget(self, action: #selector(dismissAlert), for: .touchUpInside)
        alertView.addSubview(closeButton)
        
        // Gift Image
        giftImageView.image = UIImage(named: gift.imageName)
        giftImageView.contentMode = .scaleAspectFit
        giftImageView.clipsToBounds = true
        giftImageView.layer.cornerRadius = 10
        giftImageView.backgroundColor = .clear
        alertView.addSubview(giftImageView)
        
        // Send Button
        
        sendButton.setTitle("".localize(attribut: "SendTheGift", arguments: "\(gift.price)"), for: .normal)
        sendButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        sendButton.setTitleColor(.white, for: .normal)
        sendButton.layer.cornerRadius = 15
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        alertView.addSubview(sendButton)
        
        sendButton.backgroundColor = UIColor(red: 0.2, green: 0.5, blue: 0.8, alpha: 1.0)
        // Вы можете также добавить тень для согласованности, если хотите
        sendButton.layer.shadowColor = UIColor(red: 0.2, green: 0.5, blue: 0.8, alpha: 0.5).cgColor
        sendButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        sendButton.layer.shadowRadius = 12
        sendButton.layer.shadowOpacity = 0.4
        
        // Constraints
        closeButton.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(10)
            make.width.height.equalTo(30)
        }
        
        giftImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(40)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(200)
        }
        
        sendButton.snp.makeConstraints { make in
            make.top.equalTo(giftImageView.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(50)
            make.bottom.equalToSuperview().inset(20)
        }
    }
    
    @objc private func sendButtonTapped() {
        completion?()
        dismissAlert()
    }
}

// MARK: - NotEnoughCoinsAlert
class NotEnoughCoinsAlert: BaseAlertView {
    private let titleLabel = UILabel()
    private let okButton = UIButton(type: .system)
    
    var okButtonTappedHandler: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupAlert()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupAlert() {
        titleLabel.text = "NotEnoughCoins".localize()
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        alertView.addSubview(titleLabel)
        
        okButton.setTitle("OK".localize(), for: .normal)
        okButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        okButton.setTitleColor(.white, for: .normal)
        okButton.layer.cornerRadius = 15
        okButton.addTarget(self, action: #selector(okButtonTapped), for: .touchUpInside)
        alertView.addSubview(okButton)
        
        okButton.backgroundColor = UIColor(red: 0.2, green: 0.5, blue: 0.8, alpha: 1.0)
        okButton.layer.shadowColor = UIColor(red: 0.2, green: 0.5, blue: 0.8, alpha: 0.5).cgColor
        okButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        okButton.layer.shadowRadius = 12
        okButton.layer.shadowOpacity = 0.4
        
        // Constraints
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(30)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        okButton.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(50)
            make.bottom.equalToSuperview().inset(20)
        }
    }
    
    @objc func okButtonTapped() {
        okButtonTappedHandler?()
    }
}
