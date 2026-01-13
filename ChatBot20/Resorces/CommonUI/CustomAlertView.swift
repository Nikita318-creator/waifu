
import UIKit
import SnapKit

class CustomAlertView: UIView {
    
    enum CustomAlertType {
        case needPremiumForAudio
        case dailyLimitReached
        case giftFromUs
    }
    
    // MARK: - UI Elements
    private let backgroundView = UIView()
    private let containerView = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let buttonsStackView = UIStackView()
    private let rateButton = UIButton(type: .system)
    private let laterButton = UIButton(type: .system)
    
    // MARK: - Callbacks
    var onRateButtonTapped: (() -> Void)?
    var onLaterButtonTapped: (() -> Void)?
    
    // MARK: - Colors (Telegram Dark Theme)
    private struct Colors {
        static let background = UIColor.black.withAlphaComponent(0.6)
        static let container = UIColor(red: 0.11, green: 0.11, blue: 0.11, alpha: 1.0) // #1C1C1C
        static let primaryText = UIColor.white
        static let secondaryText = UIColor(red: 0.67, green: 0.67, blue: 0.67, alpha: 1.0) // #ABABAB
        static let accentBlue = UIColor(red: 0.33, green: 0.61, blue: 0.93, alpha: 1.0) // #549CED (Telegram blue)
        static let buttonBackground = UIColor(red: 0.16, green: 0.16, blue: 0.16, alpha: 1.0) // #292929
        static let separator = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0) // #333333
    }
    
    let type: CustomAlertType
    
    // MARK: - Initialization
    init(type: CustomAlertType) {
        self.type = type
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
        setupActions()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        // Background
        backgroundView.backgroundColor = Colors.background
        addSubview(backgroundView)
        
        // Container
        containerView.backgroundColor = Colors.container
        containerView.layer.cornerRadius = 16
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowRadius = 16
        containerView.layer.shadowOpacity = 0.3
        addSubview(containerView)
        
        // Icon
        iconImageView.image = UIImage(systemName: "star.fill")
        iconImageView.tintColor = UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0) // Gold color
        iconImageView.contentMode = .scaleAspectFit
        containerView.addSubview(iconImageView)
        
        // Title
        let title: String
        let message: String
        let okButtonText: String
        let later: String
        switch type {
        case .needPremiumForAudio:
            title = "needPremiumForAudio.Title".localize()
            message = "needPremiumForAudio.Message".localize()
            okButtonText = "DailyLimitReached.GoPremium".localize()
            later = "OK".localize()
        case .dailyLimitReached:
            title = "DailyLimitReached.Title".localize()
            message = "DailyLimitReached.Message".localize()
            okButtonText = "DailyLimitReached.GoPremium".localize()
            later = "OK".localize()
        case .giftFromUs:
            title = "giftFromUs.title".localize()
            message = "giftFromUs.message".localize()
            okButtonText = "giftFromUs.thanks".localize()
            later = "OK".localize()
        }
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = Colors.primaryText
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        containerView.addSubview(titleLabel)
        
        // Message
        messageLabel.text = message
        messageLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        messageLabel.textColor = Colors.secondaryText
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.lineBreakMode = .byWordWrapping
        containerView.addSubview(messageLabel)
        
        // Buttons Stack View
        buttonsStackView.axis = .horizontal
        buttonsStackView.distribution = .fillEqually
        buttonsStackView.spacing = 12
        containerView.addSubview(buttonsStackView)
        
        // Rate Button
        rateButton.setTitle(okButtonText, for: .normal)
        rateButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        rateButton.setTitleColor(.white, for: .normal)
        rateButton.backgroundColor = Colors.accentBlue
        rateButton.layer.cornerRadius = 12
        rateButton.layer.shadowColor = Colors.accentBlue.cgColor
        rateButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        rateButton.layer.shadowRadius = 8
        rateButton.layer.shadowOpacity = 0.3
        rateButton.titleLabel?.adjustsFontSizeToFitWidth = true
        rateButton.titleLabel?.minimumScaleFactor = 0.5
        
        // Later Button
        laterButton.setTitle(later, for: .normal)
        laterButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        laterButton.setTitleColor(Colors.secondaryText, for: .normal)
        laterButton.backgroundColor = Colors.buttonBackground
        laterButton.layer.cornerRadius = 12
        laterButton.layer.borderWidth = 1
        laterButton.layer.borderColor = Colors.separator.cgColor
        
        buttonsStackView.addArrangedSubview(laterButton)
        buttonsStackView.addArrangedSubview(rateButton)
    }
    
    private func setupConstraints() {
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        containerView.snp.makeConstraints { make in
            make.centerX.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(32)
            make.trailing.lessThanOrEqualToSuperview().offset(-32)
            make.width.lessThanOrEqualTo(340)
        }
        
        iconImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(40)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconImageView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(24)
        }
        
        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(24)
        }
        
        buttonsStackView.snp.makeConstraints { make in
            make.top.equalTo(messageLabel.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(24)
            make.bottom.equalToSuperview().offset(-24)
            make.height.equalTo(48)
        }
    }
    
    private func setupActions() {
        rateButton.addTarget(self, action: #selector(rateButtonTapped), for: .touchUpInside)
        laterButton.addTarget(self, action: #selector(laterButtonTapped), for: .touchUpInside)
        
        // Add tap gesture to background to dismiss
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        backgroundView.addGestureRecognizer(tapGesture)
        
        // Button animations
        addButtonAnimations()
    }
    
    private func addButtonAnimations() {
        [rateButton, laterButton].forEach { button in
            button.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
            button.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        }
    }
    
    // MARK: - Actions
    @objc private func rateButtonTapped() {
        dismiss()
        animateButtonTap(rateButton) { [weak self] in
            self?.onRateButtonTapped?()
        }
    }
    
    @objc private func laterButtonTapped() {
        dismiss()
        animateButtonTap(laterButton) { [weak self] in
            self?.onLaterButtonTapped?()
        }
    }
    
    @objc private func backgroundTapped() {
//        onLaterButtonTapped?()
    }
    
    @objc private func buttonTouchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }
    
    @objc private func buttonTouchUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.transform = .identity
        }
    }
    
    private func animateButtonTap(_ button: UIButton, completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.1, animations: {
            button.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            UIView.animate(withDuration: 0.1, animations: {
                button.transform = .identity
            }) { _ in
                completion()
            }
        }
    }
    
    // MARK: - Public Methods
    func show(in parentView: UIView) {
        parentView.addSubview(self)
        self.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // Initial state
        self.alpha = 0
        containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        // Animate in
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseOut) {
            self.alpha = 1
            self.containerView.transform = .identity
        }
    }
    
    func dismiss(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn) {
            self.alpha = 0
            self.containerView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        } completion: { _ in
            self.removeFromSuperview()
            completion?()
        }
    }
}
