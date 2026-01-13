import UIKit
import SnapKit

class SubsView: UIView {
    
    // MARK: - UI Elements
    private let backgroundImageView = UIImageView()
    private let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let gradientOverlay = CAGradientLayer()
    private let contentView = UIView()
    private let subtitleLabel = UILabel()
    private let benefitsLabel = UILabel()
    private let plansStackView = UIStackView()
    private let weeklyPlanView = SubscriptionPlanView()
    private let yearlyPlanView = SubscriptionPlanView()
    private let continueButton = UIButton()
    private let bestValueBadge = UIView()
    private let bestValueLabel = UILabel()
    let closeButton = UIButton()
    private let bottomButtonsStack = UIStackView()
    private let termsOfUseButton = UIButton()
    private let privacyPolicyButton = UIButton()
    private let restorePurchaseButton = UIButton()
    private let trialInfoLabel = UILabel()
    private let cancelAnyTimeLabel = UILabel()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let blurMaskLayer = CAGradientLayer()
    
    private var selectedPlanType: PlanType = .yearly
    
    enum PlanType {
        case weekly
        case yearly
    }
    
    enum Constants {
        static let termsOfUseUrl = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
        static let privacyUrl = "https://sites.google.com/view/animewaifu729"
        static let appStoreUrl = "https://apps.apple.com/app/id6757756558"
    }
    
    weak var vc: UIViewController?
    let isOnboarding: Bool
    var purchasedHandler: (() -> Void)?
    var onPaywallClosedHandler: (() -> Void)?
    
    // MARK: - Initializer
    init(isOnboarding: Bool = false) {
        self.isOnboarding = isOnboarding
        super.init(frame: .zero)
        
        setupViews()
        setupConstraints()
        updatePlanSelection(.yearly)
        updateTextForIPadIfNeeded()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Views
    private func setupViews() {
        backgroundColor = UIColor(hex: "#0A0A0A")
        
        // Background Image - на пол-экрана
        backgroundImageView.image = UIImage(named: ConfigService.shared.isTestB ? "paywallB" : "roleplay10")
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        addSubview(backgroundImageView)
        
        // Blur Effect теперь на весь экран, но с маской
        addSubview(blurEffectView)
        
        // Настраиваем маску для блюра
        // Там где opaque (1.0) - будет блюр, где clear - четко
        blurMaskLayer.colors = [
            UIColor.clear.cgColor,        // Сверху картинка четкая
            UIColor.black.cgColor         // К середине и низу плавно размывается
        ]
        // Настрой точки начала и конца размытия под свою картинку (от 0.0 до 1.0)
        blurMaskLayer.locations = [0.0, 0.8]
        blurEffectView.layer.mask = blurMaskLayer
        
        // Gradient Overlay для плавного перехода
        gradientOverlay.colors = [
            UIColor.clear.cgColor,
            UIColor(hex: "#0A0A0A").withAlphaComponent(0.4).cgColor,
            UIColor(hex: "#0A0A0A").withAlphaComponent(0.9).cgColor,
            UIColor(hex: "#0A0A0A").cgColor
        ]
        gradientOverlay.locations = [0.0, 0.3, 0.7, 1.0]
        layer.addSublayer(gradientOverlay)
        
        // Content View
        contentView.backgroundColor = .clear
        addSubview(contentView)
        
        // Close Button
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .white
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        closeButton.layer.cornerRadius = 18
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        contentView.addSubview(closeButton)

        // Subtitle Label
        subtitleLabel.text = MainHelper.shared.isDiscountOffer ? "Subs.UnlockPremiumFeatures.DiscountOffer".localize() : "Subs.UnlockPremiumFeatures".localize()
        subtitleLabel.textColor = UIColor(hex: "#B0B0B0")
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        subtitleLabel.font = MainHelper.shared.isDiscountOffer ? UIFont.systemFont(ofSize: 14, weight: .medium) : UIFont.systemFont(ofSize: 20, weight: .medium)
        contentView.addSubview(subtitleLabel)
        
        // Benefits - компактно
        setupBenefitsLabel()
        contentView.addSubview(benefitsLabel)
        
        // Plans Stack View - ВЕРТИКАЛЬНО
        plansStackView.axis = .vertical
        plansStackView.distribution = .fillEqually
        plansStackView.spacing = 12
        contentView.addSubview(plansStackView)
        
        // Setup Subscription Plan Views
        setupPlanView(weeklyPlanView, title: "Subs.week".localize(), action: #selector(weeklyButtonTapped))
        setupPlanView(yearlyPlanView, title: "Subs.month".localize(), action: #selector(yearlyButtonTapped))
        
        plansStackView.addArrangedSubview(yearlyPlanView)
        plansStackView.addArrangedSubview(weeklyPlanView)
        
        // Best Value Badge
        setupBestValueBadge()
        contentView.addSubview(bestValueBadge)
        
        // Trial Info Label
        trialInfoLabel.textColor = UIColor(hex: "#E0E0E0")
        trialInfoLabel.textAlignment = .center
        trialInfoLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        trialInfoLabel.numberOfLines = 0
        contentView.addSubview(trialInfoLabel)
        
        // Cancel Label
        cancelAnyTimeLabel.numberOfLines = 0
        cancelAnyTimeLabel.textColor = UIColor(hex: "#808080")
        cancelAnyTimeLabel.textAlignment = .center
        cancelAnyTimeLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        contentView.addSubview(cancelAnyTimeLabel)
        
        // Continue Button
        setupContinueButton()
        contentView.addSubview(continueButton)
        
        // Bottom buttons
        setupBottomButtons()
        
        yearlyButtonTapped()
        
        addSubview(loadingIndicator)
    }
    
    private func setupBenefitsLabel() {
        let benefits = [
            "Subs.features1".localize(),
            "Subs.features2".localize(),
            "Subs.features3".localize(),
            "Subs.features4".localize()
        ]
        
        let attributedText = NSMutableAttributedString()
        let fontSize: CGFloat = isCurrentDeviceiPad() ? 24 : 16
        
        for benefit in benefits {
            let benefitText = NSAttributedString(
                string: "  •  " + benefit + "\n",
                attributes: [
                    .foregroundColor: UIColor(hex: "#C0C0C0"),
                    .font: UIFont.systemFont(ofSize: fontSize, weight: .medium)
                ]
            )
            attributedText.append(benefitText)
        }
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        paragraphStyle.lineSpacing = 2
        attributedText.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributedText.length))
        
        benefitsLabel.attributedText = attributedText
        benefitsLabel.numberOfLines = 0
        benefitsLabel.textAlignment = .left
    }
    
    private func setupBestValueBadge() {
        bestValueBadge.backgroundColor = UIColor(hex: "#FF4D4D")
        bestValueBadge.layer.cornerRadius = 10
        bestValueBadge.layer.shadowColor = UIColor(hex: "#FF4D4D").cgColor
        bestValueBadge.layer.shadowOffset = CGSize(width: 0, height: 0)
        bestValueBadge.layer.shadowRadius = 6
        bestValueBadge.layer.shadowOpacity = 0.5
        
        bestValueLabel.text = "Subs.BESTVALUE".localize()
        bestValueLabel.textColor = .white
        bestValueLabel.font = UIFont.systemFont(ofSize: 10, weight: .black)
        bestValueLabel.textAlignment = .center
        
        bestValueBadge.addSubview(bestValueLabel)
        bestValueLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10))
        }
    }
    
    private func setupContinueButton() {
        continueButton.backgroundColor = UIColor(hex: "#1A73E8")
        continueButton.setTitleColor(.white, for: .normal)
        continueButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        continueButton.layer.cornerRadius = 14
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
        
        continueButton.layer.shadowColor = UIColor(hex: "#1A73E8").cgColor
        continueButton.layer.shadowOffset = CGSize(width: 0, height: 3)
        continueButton.layer.shadowRadius = 8
        continueButton.layer.shadowOpacity = 0.3
    }
    
    private func setupPlanView(_ planView: SubscriptionPlanView, title: String, action: Selector) {
        planView.setTitle(title)
        planView.layer.cornerRadius = 14
        planView.layer.borderWidth = 1
        planView.layer.borderColor = UIColor(hex: "#2A2A2A").cgColor
        planView.backgroundColor = UIColor(hex: "#1A1A1A")
        
        planView.isUserInteractionEnabled = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: action)
        planView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    private func setupBottomButtons() {
        bottomButtonsStack.axis = .horizontal
        bottomButtonsStack.distribution = .equalSpacing
        bottomButtonsStack.alignment = .center
        contentView.addSubview(bottomButtonsStack)
        
        termsOfUseButton.setTitle("Subs.TermsOfUse".localize(), for: .normal)
        termsOfUseButton.setTitleColor(UIColor(hex: "#707070"), for: .normal)
        termsOfUseButton.titleLabel?.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        termsOfUseButton.addTarget(self, action: #selector(termsOfUseTapped), for: .touchUpInside)
        
        privacyPolicyButton.setTitle("Subs.PrivacyPolicy".localize(), for: .normal)
        privacyPolicyButton.setTitleColor(UIColor(hex: "#707070"), for: .normal)
        privacyPolicyButton.titleLabel?.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        privacyPolicyButton.addTarget(self, action: #selector(privacyPolicyTapped), for: .touchUpInside)
        
        restorePurchaseButton.setTitle("Subs.Restore".localize(), for: .normal)
        restorePurchaseButton.setTitleColor(UIColor(hex: "#707070"), for: .normal)
        restorePurchaseButton.titleLabel?.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        restorePurchaseButton.addTarget(self, action: #selector(restorePurchaseTapped), for: .touchUpInside)
        
        bottomButtonsStack.addArrangedSubview(termsOfUseButton)
        bottomButtonsStack.addArrangedSubview(privacyPolicyButton)
        bottomButtonsStack.addArrangedSubview(restorePurchaseButton)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        blurEffectView.frame = bounds
        blurMaskLayer.frame = blurEffectView.bounds
        gradientOverlay.frame = bounds
    }
    
    // MARK: - Setup Constraints
    private func setupConstraints() {
        loadingIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        // Background Image - верхняя половина экрана
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // Blur Effect
        blurEffectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // Content View
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(safeAreaLayoutGuide)
        }
        
        // Close Button
        closeButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-16)
            make.width.height.equalTo(36)
        }
        
        // Subtitle Label
        subtitleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }
        
        // Benefits Label
        benefitsLabel.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }
        
        // Plans Stack View - вертикально, более компактно
        plansStackView.snp.makeConstraints { make in
            make.top.equalTo(benefitsLabel.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.height.equalTo(150)
        }
        
        // Best Value Badge
        bestValueBadge.snp.makeConstraints { make in
            make.top.equalTo(plansStackView).offset(-8)
            make.trailing.equalTo(yearlyPlanView).offset(-8)
        }
        
        // Trial Info Label
        trialInfoLabel.snp.makeConstraints { make in
            make.top.equalTo(plansStackView.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }
        
        // Cancel Label
        cancelAnyTimeLabel.snp.makeConstraints { make in
            make.top.equalTo(trialInfoLabel.snp.bottom).offset(6)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }
        
        // Continue Button
        continueButton.snp.makeConstraints { make in
            make.top.equalTo(cancelAnyTimeLabel.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.height.equalTo(52)
        }
        
        // Bottom Buttons Stack
        bottomButtonsStack.snp.makeConstraints { make in
            make.top.equalTo(continueButton.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview().offset(-12)
        }
    }
    
    // MARK: - Button Actions
        
    private func onPaywallClosed() {
        onPaywallClosedHandler?()
        removeFromSuperview()
    }
    
    @objc private func closeButtonTapped() {
        onPaywallClosed()
    }
    
    @objc private func weeklyButtonTapped() {
        let currentProductId: String
        if MainHelper.shared.isDiscountOffer {
            currentProductId = SubsIDs.weeklySubsId
        } else {
            currentProductId = ConfigService.shared.isProPrice ? SubsIDs.weeklyPROSubsId : SubsIDs.weeklySubsId
        }

        if let product = IAPService.shared.products.first(where: { $0.productId == currentProductId }) {
            let priceString = product.skProduct?.localizedPrice() ?? ""
            weeklyPlanView.setTitle("Subs.week".localize())
            yearlyPlanView.setTitle("Subs.month".localize())
            trialInfoLabel.text = "Subs.Price.week".localize(attribut: "Subs.Price.week", arguments: priceString)
            continueButton.setTitle("Continue".localize(), for: .normal)
            
            let attributedText = NSMutableAttributedString(string: "Subs.CancelAnytime".localize())
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            paragraphStyle.lineSpacing = 2
            attributedText.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributedText.length))
            cancelAnyTimeLabel.attributedText = attributedText
            
            updatePlanSelection(.weekly)
        }
    }
    
    @objc func yearlyButtonTapped() { // test111 проверить ценники правильно ли расчитывают месячную цену в неделю + проверить логику и UI DiscountOffer
        let currentProductId: String
        if MainHelper.shared.isDiscountOffer {
            currentProductId = SubsIDs.monthlySubsId
        } else {
            currentProductId = ConfigService.shared.isProPrice ? SubsIDs.monthlyPROSubsId : SubsIDs.monthlySubsId
        }

        if let product = IAPService.shared.products.first(where: { $0.productId == currentProductId }) {
            let priceString = product.skProduct?.localizedPrice() ?? ""
            weeklyPlanView.setTitle("Subs.week".localize())
            yearlyPlanView.setTitle("Subs.month".localize())

            if let (price, currency) = extractPrice(from: priceString) {
                let weekly = price / 4.33
                let weeklyFormatted = String(format: "%@%.2f", currency, weekly)
                trialInfoLabel.text = "Subs.Price.week".localize(attribut: "Subs.Price.week", arguments: weeklyFormatted) // todo
            } else {
                trialInfoLabel.text = "" // "Subs.Price.week".localize(attribut: "Subs.Price.week", arguments: priceString) // todo
            }

            // Твоя визуальная часть
            let attributedText = NSMutableAttributedString(string: "Subs.CancelAnytime".localize())
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            paragraphStyle.lineSpacing = 2
            attributedText.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributedText.length))
            cancelAnyTimeLabel.attributedText = attributedText
            continueButton.setTitle("Continue".localize(), for: .normal)
            
            updatePlanSelection(.yearly)
        }
    }
    
    @objc private func continueTapped() {
        let productIdentifier: String
        let isDiscount = MainHelper.shared.isDiscountOffer
        
        switch selectedPlanType {
        case .weekly:
            if isDiscount {
                productIdentifier = SubsIDs.weeklySubsId // Всегда дешевый при скидке
            } else {
                productIdentifier = ConfigService.shared.isProPrice ? SubsIDs.weeklyPROSubsId : SubsIDs.weeklySubsId
            }
        case .yearly:
            if isDiscount {
                productIdentifier = SubsIDs.monthlySubsId // Всегда дешевый при скидке
            } else {
                productIdentifier = ConfigService.shared.isProPrice ? SubsIDs.monthlyPROSubsId : SubsIDs.monthlySubsId
            }
        }
        
        continueButton.alpha = 0.8
        UIView.animate(withDuration: 0.15) {
            self.continueButton.alpha = 1.0
        }
        
        purchaseSubsInAppStore(productIdentifier: productIdentifier)
    }
    
    @objc private func termsOfUseTapped() {
        if let url = URL(string: Constants.termsOfUseUrl), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    @objc private func privacyPolicyTapped() {
        if let url = URL(string: Constants.privacyUrl), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    @objc private func restorePurchaseTapped() {
        IAPService.shared.restorePurchases() { [self] result in
            DispatchQueue.main.async {
                switch result {
                case .failed: break
                case .purchased, .restored:
                    AnalyticService.shared.logEvent(name: "Purchase Restored", properties: ["":""])
                    WebHookAnalyticsService.shared.sendAnalyticsReport(messageText: "Purchase Restored")
                    self.onPaywallClosed()
                }
            }
        }
    }
    
    private func updatePlanSelection(_ planType: PlanType) {
        selectedPlanType = planType
        weeklyPlanView.setSelected(planType == .weekly)
        yearlyPlanView.setSelected(planType == .yearly)
        
        bestValueBadge.isHidden = planType != .yearly
        
        let buttonColor = planType == .yearly ? UIColor(hex: "#34C759") : UIColor(hex: "#1A73E8")
        continueButton.backgroundColor = buttonColor
        continueButton.layer.shadowColor = buttonColor.cgColor
    }
    
    private func extractPrice(from priceString: String) -> (price: Double, currencySymbol: String)? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = NSLocale.current
        if let number = formatter.number(from: priceString) {
            let currencySymbol = formatter.currencySymbol ?? ""
            return (number.doubleValue, currencySymbol)
        }
        
        let cleanedStringPrice = priceString
            .components(separatedBy: CharacterSet(charactersIn: "0123456789,.").inverted)
            .joined()
            .replacingOccurrences(of: ",", with: ".")
        
        guard let price = Double(cleanedStringPrice) else {
            return nil
        }
        
        let currencySymbol = priceString
            .trimmingCharacters(in: CharacterSet(charactersIn: "0123456789,."))
            .trimmingCharacters(in: .whitespaces)
        
        return (price, currencySymbol.isEmpty ? "" : currencySymbol)
    }
}

extension SubsView {
    func updateTextForIPadIfNeeded() {
        guard isCurrentDeviceiPad() else { return }
        
        subtitleLabel.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        trialInfoLabel.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        cancelAnyTimeLabel.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        bestValueLabel.font = UIFont.systemFont(ofSize: 16, weight: .black)
        continueButton.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        termsOfUseButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        privacyPolicyButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        restorePurchaseButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        
        closeButton.snp.updateConstraints { make in
            make.width.height.equalTo(48)
        }
        
        continueButton.snp.updateConstraints { make in
            make.height.equalTo(68)
        }
        
        plansStackView.snp.updateConstraints { make in
            make.height.equalTo(200)
        }
        
        layoutIfNeeded()
    }
    
    func showLoadingIndicator() {
        loadingIndicator.startAnimating()
    }
    
    func hideLoadingIndicator() {
        loadingIndicator.stopAnimating()
    }
    
    private func purchaseSubsInAppStore(productIdentifier: String) {
        showLoadingIndicator()
        
        IAPService.shared.purchase(productId: productIdentifier) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .failed:
                    self?.hideLoadingIndicator()
                case .purchased, .restored:
                    let productPlanID: String
                    switch productIdentifier {
                    case SubsIDs.weeklyPROSubsId:
                        productPlanID = "weeklyPRO"
                    case SubsIDs.monthlyPROSubsId:
                        productPlanID = "monthlyPRO"
                    case SubsIDs.weeklySubsId:
                        productPlanID = "weeklySubsId"
                    case SubsIDs.monthlySubsId:
                        productPlanID = "monthlySubsId"
                    default:
                        productPlanID = "unknown ???"
                    }
                                        
                    WebHookAnalyticsService.shared.sendAnalyticsReport(messageText: "PURCHASED!!! \(productPlanID) \((self?.isOnboarding ?? false) ? "from Onboarding" : "from limits")")
                    AnalyticService.shared.logEvent(name: "PURCHASED!!!", properties: ["productPlanID":"\(productPlanID)", "isOnboarding":"\(self?.isOnboarding ?? false)"])

                    self?.purchasedHandler?()
                    self?.hideLoadingIndicator()
                    self?.onPaywallClosed()
                }
            }
        }
    }
}
