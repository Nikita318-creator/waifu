import UIKit
import SnapKit
import OneSignalFramework

class CustomPayWallV1View: UIView {
    
    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let headerView = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private var featuresStackView = UIStackView()
    private let descriptionLabel = UILabel()
    private let cancelAnyTimeLabel = UILabel()
    private let plansStackView = UIStackView()
    private let monthlyPlanView = CustomPayWallSubscriptionPlanView()
    private let continueButton = UIButton()
    let closeButton = UIButton()
    private let bottomGradientView = UIView()
    private let decorativeElements = UIView()
    
    private var selectedPlanType: PlanType = .monthly
    
    enum PlanType {
        case weekly
        case monthly
        case yearly
    }
    
    var isOnbording: Bool = false
    weak var vc: UIViewController?

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
        updatePlanSelection(.monthly)
        setupGradients()
        addDecorations()
        
        if isCurrentDeviceiPad() {
            setupForIpad()
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // MARK: - Setup Views
    private func setupViews() {
        // Soft, warm background color that feels gentle and nurturing
        backgroundColor = UIColor(red: 252/255, green: 250/255, blue: 247/255, alpha: 1)
        layer.cornerRadius = 24
        clipsToBounds = true
        let isRTL = UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft

        // ScrollView
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        addSubview(scrollView)
        
        // ContentView
        contentView.backgroundColor = .clear
        scrollView.addSubview(contentView)
        
        // Header View - Soft pastel gradient that feels warm and inviting
        headerView.backgroundColor = .clear
        let headerGradient = CAGradientLayer()
        headerGradient.colors = [
            UIColor(red: 255/255, green: 222/255, blue: 227/255, alpha: 1).cgColor,
            UIColor(red: 255/255, green: 235/255, blue: 238/255, alpha: 1).cgColor
        ]
        headerGradient.locations = [0.0, 1.0]
        headerGradient.startPoint = CGPoint(x: 0.0, y: 0.0)
        headerGradient.endPoint = CGPoint(x: 1.0, y: 1.0)
        headerView.layer.insertSublayer(headerGradient, at: 0)
        contentView.addSubview(headerView)
        
        // Icon Image
        iconImageView.image = UIImage(named: "main")
        iconImageView.contentMode = .scaleAspectFill
        iconImageView.clipsToBounds = true
        iconImageView.layer.cornerRadius = 28
        iconImageView.layer.borderWidth = 4
        iconImageView.layer.borderColor = UIColor.white.cgColor
        iconImageView.layer.shadowColor = UIColor.black.cgColor
        iconImageView.layer.shadowOffset = CGSize(width: 0, height: 4)
        iconImageView.layer.shadowRadius = 8
        iconImageView.layer.shadowOpacity = 0.1
        contentView.addSubview(iconImageView)
        
        // Close Button
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = UIColor(red: 70/255, green: 70/255, blue: 70/255, alpha: 0.8)
        closeButton.layer.shadowColor = UIColor.black.cgColor
        closeButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        closeButton.layer.shadowRadius = 4
        closeButton.layer.shadowOpacity = 0.1
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        contentView.addSubview(closeButton)
        
        // Title Label - Warm, friendly typography
        titleLabel.text = "CustomPaywall.Title".localize()
        titleLabel.textColor = UIColor(red: 79/255, green: 45/255, blue: 69/255, alpha: 1) // Deeper, rich purple
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.font = UIFont(name: "AvenirNext-Bold", size: 24) ?? UIFont.systemFont(ofSize: 24, weight: .bold)
        contentView.addSubview(titleLabel)
        
        // Features Stack View for organized feature listing
        featuresStackView = createFeaturesStackView()
        contentView.addSubview(featuresStackView)
        
        // Monthly Plan View - make it look more like a special offer card
        setupPlanView(monthlyPlanView, title: "CustomPaywall.month".localize(), action: #selector(monthlyButtonTapped))
        monthlyPlanView.layer.cornerRadius = 16
        monthlyPlanView.layer.borderWidth = 2
        monthlyPlanView.layer.borderColor = UIColor(red: 252/255, green: 187/255, blue: 197/255, alpha: 1).cgColor
        monthlyPlanView.backgroundColor = UIColor(red: 255/255, green: 245/255, blue: 247/255, alpha: 1)
        monthlyPlanView.clipsToBounds = true
        
        // Description Label - Clear price information
        monthlyButtonTapped() // Set up initial text
        descriptionLabel.textColor = UIColor(red: 79/255, green: 45/255, blue: 69/255, alpha: 1)
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
        descriptionLabel.font = UIFont(name: "AvenirNext-Medium", size: 17) ?? UIFont.systemFont(ofSize: 17, weight: .medium)
        contentView.addSubview(descriptionLabel)
        
        // Cancel Anytime Label - Reassuring message with better styling
        let attributedText = NSMutableAttributedString(string: "CustomPaywall.CancelAnytime".localize() + " " + "CustomPaywall.CancelAnytimeYouWontBeCharged".localize())
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineSpacing = 4
        attributedText.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributedText.length))
        
        // Add checkmark icon for reassurance
        let attachment = NSTextAttachment()
        attachment.image = UIImage(systemName: "checkmark.circle.fill")?.withTintColor(UIColor(red: 120/255, green: 195/255, blue: 162/255, alpha: 1))
        let checkmarkString = NSAttributedString(attachment: attachment)
        let finalString = NSMutableAttributedString(attributedString: checkmarkString)
        finalString.append(NSAttributedString(string: " "))
        finalString.append(attributedText)
        
        cancelAnyTimeLabel.attributedText = finalString
        cancelAnyTimeLabel.numberOfLines = 3
        cancelAnyTimeLabel.textColor = UIColor(red: 79/255, green: 79/255, blue: 79/255, alpha: 1)
        cancelAnyTimeLabel.font = UIFont(name: "AvenirNext-Medium", size: 15) ?? UIFont.systemFont(ofSize: 15)
        contentView.addSubview(cancelAnyTimeLabel)
        
        // Plans Stack View
        plansStackView.axis = .horizontal
        plansStackView.distribution = .fillEqually
        plansStackView.spacing = 12
        contentView.addSubview(plansStackView)
        plansStackView.addArrangedSubview(monthlyPlanView)
        
        // Bottom Gradient View
        bottomGradientView.backgroundColor = .clear
        contentView.addSubview(bottomGradientView)

        // Continue Button - More appealing with animation
        continueButton.setTitle("CustomPaywall.ContinueForFree".localize(), for: .normal)
        continueButton.backgroundColor = UIColor(red: 255/255, green: 105/255, blue: 140/255, alpha: 1) // Warmer pink
        continueButton.setTitleColor(.white, for: .normal)
        continueButton.layer.cornerRadius = 28 // More rounded
        continueButton.titleLabel?.font = UIFont(name: "AvenirNext-Bold", size: 18) ?? UIFont.systemFont(ofSize: 18, weight: .bold)
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
        
        // Add glow effect to continue button
        continueButton.layer.shadowColor = UIColor(red: 255/255, green: 105/255, blue: 140/255, alpha: 0.6).cgColor
        continueButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        continueButton.layer.shadowRadius = 12
        continueButton.layer.shadowOpacity = 0.8
        
        // Add subtle pulsing animation to draw attention
        let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
        pulseAnimation.duration = 1.5
        pulseAnimation.fromValue = 1.0
        pulseAnimation.toValue = 1.03
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .infinity
        continueButton.layer.add(pulseAnimation, forKey: "pulse")

        addSubview(continueButton)
        
        // Add decorative elements
        decorativeElements.backgroundColor = .clear
        contentView.addSubview(decorativeElements)
    }
    
    private func createFeaturesStackView() -> UIStackView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.distribution = .fillEqually
        
        // Parse subtitleLabel.text to extract features
        let features = [
            (icon: "moon.stars.fill", text: "CustomPaywall.features1".localize()),
            (icon: "heart.fill", text: "CustomPaywall.features2".localize()),
            (icon: "gift.fill", text: "CustomPaywall.features3".localize()),
            (icon: "music.note", text: "CustomPaywall.features4".localize())
        ]
        
        for feature in features {
            let featureView = createFeatureRow(icon: feature.icon, text: feature.text)
            stack.addArrangedSubview(featureView)
        }
        
        return stack
    }
    
    private func createFeatureRow(icon: String, text: String) -> UIView {
        let container = UIView()
        
        let iconImage = UIImageView()
        iconImage.image = UIImage(systemName: icon)
        iconImage.contentMode = .scaleAspectFit
        iconImage.tintColor = UIColor(red: 255/255, green: 105/255, blue: 140/255, alpha: 1)
        
        let label = UILabel()
        label.text = text
        label.textColor = UIColor(red: 79/255, green: 45/255, blue: 69/255, alpha: 1)
        label.font = UIFont(name: "AvenirNext-Medium", size: 16) ?? UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 0
        
        container.addSubview(iconImage)
        container.addSubview(label)
        
        iconImage.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(5)
            make.top.equalToSuperview().offset(5) // Привязываем к верху
            make.width.height.equalTo(28)
        }
        
        label.snp.makeConstraints { make in
            make.leading.equalTo(iconImage.snp.trailing).offset(12)
            make.trailing.equalToSuperview().offset(-5)
            make.top.equalToSuperview().offset(5) // Привязываем к верху
            make.bottom.equalToSuperview().offset(-5) // Привязываем к низу для адаптации высоты
        }
        
        // Убедимся, что иконка не сжимается ниже label
        iconImage.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        
        return container
    }
    
    private func addDecorations() {
        // Add decorative elements that appeal to mothers (subtle baby-themed elements)
        let decorations = [
            createDecoration(systemName: "heart.fill", color: UIColor(red: 255/255, green: 182/255, blue: 193/255, alpha: 0.3), size: 24, position: CGPoint(x: 30, y: 180)),
            createDecoration(systemName: "star.fill", color: UIColor(red: 255/255, green: 215/255, blue: 0/255, alpha: 0.3), size: 18, position: CGPoint(x: UIScreen.main.bounds.width - 50, y: 220)),
            createDecoration(systemName: "cloud.fill", color: UIColor(red: 173/255, green: 216/255, blue: 230/255, alpha: 0.3), size: 28, position: CGPoint(x: 40, y: 350))
        ]
        
        for decoration in decorations {
            decorativeElements.addSubview(decoration)
        }
    }
    
    private func createDecoration(systemName: String, color: UIColor, size: CGFloat, position: CGPoint) -> UIImageView {
        let imageView = UIImageView(image: UIImage(systemName: systemName))
        imageView.tintColor = color
        imageView.contentMode = .scaleAspectFit
        imageView.frame = CGRect(x: position.x, y: position.y, width: size, height: size)
        return imageView
    }
    
    private func setupPlanView(_ planView: CustomPayWallSubscriptionPlanView, title: String, action: Selector) {
        planView.setTitle(title)
        
        // Enhance plan view styling
        planView.layer.shadowColor = UIColor.black.cgColor
        planView.layer.shadowOffset = CGSize(width: 0, height: 3)
        planView.layer.shadowOpacity = 0.1
        planView.layer.shadowRadius = 6
        
        planView.isUserInteractionEnabled = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: action)
        planView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    private func setupGradients() {
        // Update header gradient frame
        if let gradientLayer = headerView.layer.sublayers?.first as? CAGradientLayer {
            gradientLayer.frame = headerView.bounds
        }
        
        // Add gradient to bottom for better visibility of content
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(white: 1, alpha: 0).cgColor,
            UIColor(white: 1, alpha: 1).cgColor
        ]
        gradientLayer.locations = [0.0, 0.5]
        gradientLayer.frame = bottomGradientView.bounds
        bottomGradientView.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update gradients frame
        if let headerGradient = headerView.layer.sublayers?.first as? CAGradientLayer {
            headerGradient.frame = headerView.bounds
        }
        
        if let gradientLayer = bottomGradientView.layer.sublayers?.first as? CAGradientLayer {
            gradientLayer.frame = bottomGradientView.bounds
        }
    }
    
    // MARK: - Setup Constraints
    private func setupConstraints() {
        let screenWidth = UIScreen.main.bounds.width
        let iconSize = screenWidth / 3.5
        
        // ScrollView
        scrollView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(continueButton.snp.top).offset(-16)
        }
        
        // ContentView
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
            make.height.greaterThanOrEqualTo(scrollView)
        }
        
        // Header View - Make it more prominent
        headerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(-UIScreen.main.bounds.height)
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(iconImageView).inset(20)
        }
        
        // Close Button
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(contentView.safeAreaLayoutGuide).offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.width.height.equalTo(36)
        }
        closeButton.isHidden = true
        
        // Icon Image - Slightly larger
        iconImageView.snp.makeConstraints { make in
            make.top.equalTo(contentView.safeAreaLayoutGuide).offset(24)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(iconSize + 10)
        }
        
        // Title Label
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconImageView.snp.bottom).offset(24)
            make.leading.equalToSuperview().offset(24)
            make.trailing.equalToSuperview().offset(-24)
        }
        
        // Features Stack View (replacing subtitle)
        featuresStackView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(24)
            make.leading.equalToSuperview().offset(32)
            make.trailing.equalToSuperview().offset(-24)
        }
        
        // Plans Stack View - move up before description
        plansStackView.snp.makeConstraints { make in
            make.top.equalTo(featuresStackView.snp.bottom).offset(24)
            make.leading.equalToSuperview().offset(24)
            make.trailing.equalToSuperview().offset(-24)
            make.height.equalTo(isCurrentDeviceiPad() ? 110 : 90)
        }
        
        // Description Label - after plans
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(plansStackView.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(24)
            make.trailing.equalToSuperview().offset(-24)
        }
        
        // Cancel Anytime Label
        cancelAnyTimeLabel.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(24)
            make.trailing.equalToSuperview().offset(-24)
        }
        
        // Bottom Gradient View
        bottomGradientView.snp.makeConstraints { make in
            make.top.equalTo(cancelAnyTimeLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(100)
            make.bottom.equalToSuperview().offset(-16)
        }
        
        // Continue Button - larger and more prominent
        continueButton.snp.makeConstraints { make in
            make.bottom.equalTo(safeAreaLayoutGuide).offset(-28)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.height.equalTo(60)
        }
        
        // Decorative elements container
        decorativeElements.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    // MARK: - Button Actions
    @objc private func closeButtonTapped() {
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 0
        }) { _ in
            self.removeFromSuperview()
        }
    }

    @objc func monthlyButtonTapped() {
        AnaliticsManager.shared.logEvent(key: AppEvent.customPaywallV1.rawValue, eventProperty: "monthlyButtonTapped")

        if let product = InAppPurchaseManager.shared.products.first(where: { $0.storeProduct.productIdentifier == StoreData.monthlyProProductIdentifier }) {
            let priceString = product.storeProduct.localizedPriceString
            
            descriptionLabel.text = "CustomPaywall.Price.month".localize(attribut: "CustomPaywall.Price.month", arguments: priceString)
            continueButton.setTitle("CustomPaywall.ContinueForFree".localize(), for: .normal)
            
            // Add fun emoji and better formatting
            let attributedText = NSMutableAttributedString()
            
            // Add checkmark and first part
            let attachment = NSTextAttachment()
            attachment.image = UIImage(systemName: "checkmark.circle.fill")?.withTintColor(UIColor(red: 120/255, green: 195/255, blue: 162/255, alpha: 1))
            attributedText.append(NSAttributedString(attachment: attachment))
            attributedText.append(NSAttributedString(string: " " + "CustomPaywall.CancelAnytime".localize()))
            
            // Add second part with slightly lighter color
            let secondPartAttr = NSAttributedString(
                string: " " + "CustomPaywall.CancelAnytimeYouWontBeCharged".localize(),
                attributes: [NSAttributedString.Key.foregroundColor: UIColor(red: 100/255, green: 100/255, blue: 100/255, alpha: 0.8)]
            )
            attributedText.append(secondPartAttr)
            
            // Apply paragraph style
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            paragraphStyle.lineSpacing = 4
            attributedText.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributedText.length))
            
            cancelAnyTimeLabel.attributedText = attributedText
            
            updatePlanSelection(.monthly)
        } else {
            AnaliticsManager.shared.logEvent(key: AppEvent.customPaywallV1.rawValue, eventProperty: "monthly Product not found")
        }
    }
    
    @objc private func continueTapped() {
        AnaliticsManager.shared.logEvent(key: AppEvent.customPaywallV1.rawValue, eventProperty: "continueTapped with \(selectedPlanType)")

        // Enhanced animation for better feedback
//        UIView.animate(withDuration: 0.15, animations: {
//            self.continueButton.transform = CGAffineTransform(scaleX: 0.93, y: 0.93)
//        }) { _ in
            UIView.animate(withDuration: 0.15, animations: {
                self.continueButton.transform = CGAffineTransform.identity
            }) { _ in
                // Add subtle haptic feedback if available
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.prepare()
                generator.impactOccurred()
                
                self.purchaseSubsInAppStore(productIdentifier: StoreData.monthlyProProductIdentifier)
            }
//        }
    }
    
    private func updatePlanSelection(_ planType: PlanType) {
        selectedPlanType = planType
        monthlyPlanView.setSelected(planType == .monthly)
        
        // Highlight selected plan with animation
        UIView.animate(withDuration: 0.3) {
            if planType == .monthly {
                self.monthlyPlanView.layer.borderWidth = 3
                self.monthlyPlanView.layer.borderColor = UIColor(red: 255/255, green: 105/255, blue: 140/255, alpha: 1).cgColor
                self.monthlyPlanView.transform = CGAffineTransform(scaleX: 1.03, y: 1.03)
            } else {
                self.monthlyPlanView.layer.borderWidth = 1
                self.monthlyPlanView.layer.borderColor = UIColor(red: 200/255, green: 200/255, blue: 200/255, alpha: 0.5).cgColor
                self.monthlyPlanView.transform = CGAffineTransform.identity
            }
        }
    }
}

extension CustomPayWallV1View {
    func setupForIpad() {
        titleLabel.font = UIFont(name: "AvenirNext-Bold", size: 30) ?? UIFont.systemFont(ofSize: 20, weight: .bold)
        descriptionLabel.font = UIFont(name: "AvenirNext-Medium", size: 27) ?? UIFont.systemFont(ofSize: 17, weight: .medium)
        cancelAnyTimeLabel.font = UIFont(name: "AvenirNext-Medium", size: 25) ?? UIFont.systemFont(ofSize: 15)
        continueButton.titleLabel?.font = UIFont(name: "AvenirNext-Bold", size: 28) ?? UIFont.systemFont(ofSize: 18, weight: .bold)

        continueButton.snp.makeConstraints { make in
            make.bottom.equalTo(safeAreaLayoutGuide).offset(-24)
            make.leading.equalToSuperview().offset(24)
            make.trailing.equalToSuperview().offset(-24)
            make.height.equalTo(76)
        }
    }
    
    func scrollToBottom(animated: Bool = true) {
        let bottomOffset = CGPoint(x: 0, y: scrollView.contentSize.height - scrollView.bounds.height + scrollView.contentInset.bottom)
        scrollView.setContentOffset(bottomOffset, animated: animated)
    }
    
    private func purchaseSubsInAppStore(productIdentifier: String) {
        if let productIdentifier = InAppPurchaseManager.shared.products.first(
            where: { $0.storeProduct.productIdentifier == productIdentifier }
        )?.storeProduct.productIdentifier {
            InAppPurchaseManager.shared.purchase(productId: productIdentifier) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .failed:
                        OneSignal.User.addTag(key: "is_finish_onbording", value: "false")
                        OneSignal.User.addTag(key: "is_finish_purchase", value: "false")
                        AnaliticsManager.shared.logEvent(key: AppEvent.customPaywallV1.rawValue, eventProperty: "purchase failed")
                    case .purchased, .restored:
                        SubsManager.shared.saveSubscriptionStatus(isSubscribed: true)
                        AnaliticsManager.shared.logEvent(key: AppEvent.customPaywallV1.rawValue, eventProperty: "purchased !!!")

                        let isFirstLounchKey = "isFirstLounchKey"
                        UserDefaults.standard.set(true, forKey: isFirstLounchKey)
                        
                        DispatchQueue.main.async {
                            let mainVC = ViewController()
                            mainVC.modalPresentationStyle = .fullScreen
                            self?.vc?.present(mainVC, animated: true, completion: nil)
                        }
                        
                        OneSignal.User.addTag(key: "is_finish_onbording", value: "true")
                        OneSignal.User.addTag(key: "is_finish_purchase", value: "true")
                    }
                }
            }
        }
    }
}
