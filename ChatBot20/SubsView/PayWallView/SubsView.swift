import UIKit
import SnapKit
import OneSignalFramework

class SubsView: UIView {
    
    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let headerView = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let featuresStackView = UIStackView()
    private let descriptionLabel = UILabel()
    private let cancelAnyTimeLabel = UILabel()
    private let plansStackView = UIStackView()
    private let weeklyPlanView = SubscriptionPlanView()
    private let monthlyPlanView = SubscriptionPlanView()
    private let yearlyPlanView = SubscriptionPlanView()
    private let continueButton = UIButton()
    private let bestValueBadge = UIView()
    private let bestValueLabel = UILabel()
    let closeButton = UIButton()
    private let bottomGradientView = UIView()
    private let backgroundImageView = UIImageView()
    private let termsPrivacyButton = UIButton()
    
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
        
        if isCurrentDeviceiPad() {
            setupForIpad()
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // MARK: - Setup Views
    private func setupViews() {
        backgroundColor = UIColor(red: 255/255, green: 251/255, blue: 249/255, alpha: 1) // Warmer, more nurturing background
        layer.cornerRadius = 24
        clipsToBounds = true
        
        // Background pattern image (subtle baby-themed pattern)
        backgroundImageView.image = UIImage(named: "background_pattern")
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.alpha = 0.07 // Very subtle
        addSubview(backgroundImageView)
        
        // ScrollView
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        addSubview(scrollView)
        
        // ContentView
        contentView.backgroundColor = .clear
        scrollView.addSubview(contentView)
        
        // Header View - Soft gradient background
        headerView.backgroundColor = UIColor(red: 255/255, green: 224/255, blue: 228/255, alpha: 0.5)
        let headerGradient = CAGradientLayer()
        headerGradient.colors = [
            UIColor(red: 255/255, green: 224/255, blue: 228/255, alpha: 0.7).cgColor,
            UIColor(red: 255/255, green: 245/255, blue: 245/255, alpha: 0.4).cgColor
        ]
        headerGradient.locations = [0.0, 1.0]
        headerGradient.startPoint = CGPoint(x: 0.5, y: 0)
        headerGradient.endPoint = CGPoint(x: 0.5, y: 1)
        headerView.layer.insertSublayer(headerGradient, at: 0)
        contentView.addSubview(headerView)
        
        // Icon Image - Enhanced with better shadows and border
        iconImageView.image = UIImage(named: "main")
        iconImageView.contentMode = .scaleAspectFill
        iconImageView.clipsToBounds = true
        iconImageView.layer.cornerRadius = 28
        iconImageView.layer.borderWidth = 5
        iconImageView.layer.borderColor = UIColor.white.cgColor
        iconImageView.layer.shadowColor = UIColor.black.cgColor
        iconImageView.layer.shadowOffset = CGSize(width: 0, height: 6)
        iconImageView.layer.shadowRadius = 12
        iconImageView.layer.shadowOpacity = 0.15
        contentView.addSubview(iconImageView)
        
        // Close Button - Improved design
        closeButton.setImage(UIImage(systemName: "xmark.circle"), for: .normal)
        closeButton.tintColor = UIColor(red: 142/255, green: 142/255, blue: 147/255, alpha: 0.8)
        closeButton.layer.shadowColor = UIColor.black.cgColor
        closeButton.layer.shadowOffset = CGSize(width: 0, height: 1)
        closeButton.layer.shadowRadius = 3
        closeButton.layer.shadowOpacity = 0.15
        closeButton.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        contentView.addSubview(closeButton)
        
        // Title Label - Enhanced typography
        titleLabel.text = "Subs.Title".localize()
        titleLabel.textColor = UIColor(red: 50/255, green: 50/255, blue: 50/255, alpha: 1)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.font = UIFont(name: "AvenirNext-Bold", size: 24) ?? UIFont.systemFont(ofSize: 24, weight: .bold)
        contentView.addSubview(titleLabel)
        
        // Split the subtitle into title and feature list
        subtitleLabel.text = "Subs.SubTitle".localize()
        subtitleLabel.textColor = UIColor(red: 50/255, green: 50/255, blue: 50/255, alpha: 1)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        subtitleLabel.font = UIFont(name: "AvenirNext-Medium", size: 17) ?? UIFont.systemFont(ofSize: 17, weight: .medium)
        contentView.addSubview(subtitleLabel)
        
        // Features Stack View - Organize features better
        setupFeaturesStackView()
        contentView.addSubview(featuresStackView)
        
        // Description Label
        descriptionLabel.textColor = UIColor(red: 50/255, green: 50/255, blue: 50/255, alpha: 1)
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
        descriptionLabel.font = UIFont(name: "AvenirNext-DemiBold", size: 18) ?? UIFont.systemFont(ofSize: 18, weight: .semibold)
        contentView.addSubview(descriptionLabel)
        
        // Cancel Anytime Label
        let attributedText = NSMutableAttributedString(string: "Subs.CancelAnytime".localize() + "Subs.CancelAnytimeYouWontBeCharged".localize())
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineSpacing = 4
        attributedText.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributedText.length))
        cancelAnyTimeLabel.attributedText = attributedText
        cancelAnyTimeLabel.numberOfLines = 3
        cancelAnyTimeLabel.textColor = UIColor(red: 100/255, green: 100/255, blue: 100/255, alpha: 1)
        cancelAnyTimeLabel.font = UIFont(name: "AvenirNext-Medium", size: 15) ?? UIFont.systemFont(ofSize: 15)
        contentView.addSubview(cancelAnyTimeLabel)
        
        // Plans Stack View - Enhanced spacing and layout
        plansStackView.axis = .horizontal
        plansStackView.distribution = .fillEqually
        plansStackView.spacing = 12
        contentView.addSubview(plansStackView)
        
        // Setup Subscription Plan Views - Enhanced design
        setupPlanView(weeklyPlanView, title: "Subs.week".localize(), action: #selector(weeklyButtonTapped))
        setupPlanView(monthlyPlanView, title: "Subs.month".localize(), action: #selector(monthlyButtonTapped))
        setupPlanView(yearlyPlanView, title: "Subs.year".localize(), action: #selector(yearlyButtonTapped))
        
        plansStackView.addArrangedSubview(weeklyPlanView)
        plansStackView.addArrangedSubview(monthlyPlanView)
        plansStackView.addArrangedSubview(yearlyPlanView)
        
        // Add "Best Value" badge to yearly plan
        setupBestValueBadge()
        plansStackView.addSubview(bestValueBadge)
        monthlyButtonTapped() // This will set the initial text

        // Bottom Gradient View
        bottomGradientView.backgroundColor = .clear
        contentView.addSubview(bottomGradientView)

        // Continue Button - Enhanced with gradient and better shadow
        continueButton.setTitle("ContinueForFree".localize(), for: .normal)
        setupContinueButtonGradient()
        continueButton.setTitleColor(.white, for: .normal)
        continueButton.layer.cornerRadius = 28
        continueButton.titleLabel?.font = UIFont(name: "AvenirNext-Bold", size: 18) ?? UIFont.systemFont(ofSize: 18, weight: .bold)
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
        
        // Add shadow to continue button
        continueButton.layer.shadowColor = UIColor(red: 255/255, green: 130/255, blue: 140/255, alpha: 0.8).cgColor
        continueButton.layer.shadowOffset = CGSize(width: 0, height: 5)
        continueButton.layer.shadowRadius = 10
        continueButton.layer.shadowOpacity = 0.7
        
        addSubview(continueButton)
        
        // Terms and Privacy Button
        termsPrivacyButton.setTitle("Subs.Terms".localize(), for: .normal)
        termsPrivacyButton.setTitleColor(UIColor(red: 100/255, green: 100/255, blue: 100/255, alpha: 1), for: .normal)
        termsPrivacyButton.titleLabel?.font = UIFont(name: "AvenirNext-Medium", size: 12) ?? UIFont.systemFont(ofSize: 12)
        termsPrivacyButton.addTarget(self, action: #selector(termsPrivacyTapped), for: .touchUpInside)
        addSubview(termsPrivacyButton)
    }
    
    private func setupFeaturesStackView() {
        featuresStackView.axis = .vertical
        featuresStackView.distribution = .equalSpacing
        featuresStackView.spacing = 12
        featuresStackView.alignment = .leading
        
        // Feature items from your subtitle string
        let features = [
            "Subs.features1".localize(),
            "Subs.features2".localize(),
            "Subs.features3".localize(),
            "Subs.features4".localize(),
            "Subs.features5".localize(),
            "Subs.features6".localize(),
            "Subs.features7".localize(),
        ]
        
        for feature in features {
            let featureView = UIView()
            
            let featureLabel = UILabel()
            featureLabel.text = feature
            featureLabel.textColor = UIColor(red: 50/255, green: 50/255, blue: 50/255, alpha: 1)
            featureLabel.font = UIFont(name: "AvenirNext-Medium", size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .medium)
            featureLabel.numberOfLines = 0
            
            featureView.addSubview(featureLabel)
            featureLabel.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 0, bottom: 2, right: 0))
            }
            
            featuresStackView.addArrangedSubview(featureView)
        }
    }
    
    private func setupBestValueBadge() {
        bestValueBadge.backgroundColor = UIColor(red: 255/255, green: 86/255, blue: 110/255, alpha: 1)
        bestValueBadge.layer.cornerRadius = 10
        
        bestValueLabel.text = "Subs.BESTVALUE".localize()
        bestValueLabel.textColor = .white
        bestValueLabel.font = UIFont(name: "AvenirNext-Bold", size: 9) ?? UIFont.systemFont(ofSize: 9, weight: .bold)
        bestValueLabel.textAlignment = .center
        
        bestValueBadge.addSubview(bestValueLabel)
        bestValueLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6))
        }
    }
    
    private func setupContinueButtonGradient() {
        // Create gradient layer for button
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 255/255, green: 144/255, blue: 154/255, alpha: 1).cgColor,
            UIColor(red: 255/255, green: 86/255, blue: 110/255, alpha: 1).cgColor
        ]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.cornerRadius = 28
        gradientLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 48, height: 56)
        
        // Set gradient as button background
        continueButton.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    private func setupPlanView(_ planView: SubscriptionPlanView, title: String, action: Selector) {
        planView.setTitle(title)
        planView.layer.cornerRadius = 16
        planView.layer.borderWidth = 1.5
        planView.layer.borderColor = UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1).cgColor
        planView.backgroundColor = UIColor(red: 252/255, green: 252/255, blue: 252/255, alpha: 1)
        planView.layer.shadowColor = UIColor.black.cgColor
        planView.layer.shadowOffset = CGSize(width: 0, height: 3)
        planView.layer.shadowRadius = 8
        planView.layer.shadowOpacity = 0.05
        
        planView.isUserInteractionEnabled = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: action)
        planView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    private func setupGradients() {
        // Update header gradient frame
        if let headerGradient = headerView.layer.sublayers?.first as? CAGradientLayer {
            headerGradient.frame = headerView.bounds
        }
        
        // Add gradient to bottom
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
        
        // Update background image frame
        backgroundImageView.frame = bounds
        
        // Update gradient frames
        if let headerGradient = headerView.layer.sublayers?.first as? CAGradientLayer {
            headerGradient.frame = headerView.bounds
        }
        
        if let gradientLayer = bottomGradientView.layer.sublayers?.first as? CAGradientLayer {
            gradientLayer.frame = bottomGradientView.bounds
        }
        
        // Update button gradient
        if let buttonGradient = continueButton.layer.sublayers?.first as? CAGradientLayer {
            buttonGradient.frame = continueButton.bounds
        }
    }
    
    // MARK: - Setup Constraints
    private func setupConstraints() {
        let screenWidth = UIScreen.main.bounds.width
        let iconSize = min(screenWidth / 4, 100) // Cap the size for larger screens
        
        // Background Image
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
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
        
        // Header View
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
        
        // Icon Image
        iconImageView.snp.makeConstraints { make in
            make.top.equalTo(contentView.safeAreaLayoutGuide).offset(20)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(iconSize)
        }
        
        // Title Label
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconImageView.snp.bottom).offset(24)
            make.leading.equalToSuperview().offset(24)
            make.trailing.equalToSuperview().offset(-24)
        }
        
        // Subtitle Label
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(24)
            make.trailing.equalToSuperview().offset(-24)
        }
        
        // Features Stack View
        featuresStackView.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(36)
            make.trailing.equalToSuperview().offset(-24)
        }
        
        // Description Label
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(featuresStackView.snp.bottom).offset(24)
            make.leading.equalToSuperview().offset(24)
            make.trailing.equalToSuperview().offset(-24)
        }
        
        // Cancel Anytime Label
        cancelAnyTimeLabel.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(10)
            make.leading.equalToSuperview().offset(24)
            make.trailing.equalToSuperview().offset(-24)
        }
        
        // Plans Stack View
        plansStackView.snp.makeConstraints { make in
            make.top.equalTo(cancelAnyTimeLabel.snp.bottom).offset(24)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(isCurrentDeviceiPad() ? 110 : 100)
        }
        
        // Bottom Gradient View
        bottomGradientView.snp.makeConstraints { make in
            make.top.equalTo(plansStackView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(100)
            make.bottom.equalToSuperview().offset(-16)
        }
        
        // Continue Button
        continueButton.snp.makeConstraints { make in
            make.bottom.equalTo(termsPrivacyButton.snp.top).offset(-12)
            make.leading.equalToSuperview().offset(24)
            make.trailing.equalToSuperview().offset(-24)
            make.height.equalTo(56)
        }
        
        // Terms and Privacy Button
        termsPrivacyButton.snp.makeConstraints { make in
            make.bottom.equalTo(safeAreaLayoutGuide).offset(-12)
            make.centerX.equalToSuperview()
            make.height.equalTo(20)
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
    
    @objc private func weeklyButtonTapped() {
        AnaliticsManager.shared.logEvent(key: AppEvent.subsViewAction.rawValue, eventProperty: "weeklyButtonTapped")
        
        if let product = InAppPurchaseManager.shared.products.first(where: { $0.storeProduct.productIdentifier == StoreData.weeklyProductIdentifier }) {
            let priceString = product.storeProduct.localizedPriceString
            
            weeklyPlanView.setTitle("Subs.week".localize())
            monthlyPlanView.setTitle("Subs.month".localize())
            yearlyPlanView.setTitle("Subs.year".localize())

            descriptionLabel.text = "Subs.Price.week".localize(attribut: "Subs.Price.week", arguments: priceString)
            continueButton.setTitle("Continue".localize(), for: .normal)
            
            let attributedText = NSMutableAttributedString(string: "Subs.CancelAnytime".localize())
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            paragraphStyle.lineSpacing = 4
            attributedText.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributedText.length))
            cancelAnyTimeLabel.attributedText = attributedText
            
            updatePlanSelection(.weekly)
        } else {
            AnaliticsManager.shared.logEvent(key: AppEvent.subsViewAction.rawValue, eventProperty: "weekly Product not found")
        }
    }

    @objc private func monthlyButtonTapped() {
        AnaliticsManager.shared.logEvent(key: AppEvent.subsViewAction.rawValue, eventProperty: "monthlyButtonTapped")

        if let product = InAppPurchaseManager.shared.products.first(where: { $0.storeProduct.productIdentifier == StoreData.monthlyProProductIdentifier }) {
            let priceString = product.storeProduct.localizedPriceString
            
            weeklyPlanView.setTitle("Subs.week".localize())
            monthlyPlanView.setTitle("Subs.month".localize())
            yearlyPlanView.setTitle("Subs.year".localize())

            descriptionLabel.text = "Subs.Price.month".localize(attribut: "Subs.Price.month", arguments: priceString)
            continueButton.setTitle("ContinueForFree".localize(), for: .normal)
            
            let attributedText = NSMutableAttributedString(string: "Subs.CancelAnytime".localize() + "Subs.CancelAnytimeYouWontBeCharged".localize())
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            paragraphStyle.lineSpacing = 4
            attributedText.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributedText.length))
            cancelAnyTimeLabel.attributedText = attributedText
            
            updatePlanSelection(.monthly)
        } else {
            AnaliticsManager.shared.logEvent(key: AppEvent.subsViewAction.rawValue, eventProperty: "monthly Product not found")
        }
    }

    @objc private func yearlyButtonTapped() {
        AnaliticsManager.shared.logEvent(key: AppEvent.subsViewAction.rawValue, eventProperty: "yearlyButtonTapped")

        if let product = InAppPurchaseManager.shared.products.first(where: { $0.storeProduct.productIdentifier == StoreData.yearlyProProductIdentifier }) {
            let priceString = product.storeProduct.localizedPriceString
            
            weeklyPlanView.setTitle("Subs.week".localize())
            monthlyPlanView.setTitle("Subs.month".localize())
            yearlyPlanView.setTitle("Subs.year".localize())

            descriptionLabel.text = "Subs.Price.year".localize(attribut: "Subs.Price.year", arguments: priceString)
            continueButton.setTitle("Continue".localize(), for: .normal)
            
            let attributedText = NSMutableAttributedString(string: "Subs.CancelAnytime".localize())
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            paragraphStyle.lineSpacing = 4
            attributedText.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributedText.length))
            cancelAnyTimeLabel.attributedText = attributedText
            
            updatePlanSelection(.yearly)
        } else {
            AnaliticsManager.shared.logEvent(key: AppEvent.subsViewAction.rawValue, eventProperty: "yearly Product not found")
        }
    }
    
    @objc private func continueTapped() {
        AnaliticsManager.shared.logEvent(key: AppEvent.subsViewAction.rawValue, eventProperty: "continueTapped with \(selectedPlanType)")

        let productIdentifier: String
        
        switch selectedPlanType {
        case .weekly:
            productIdentifier = StoreData.weeklyProductIdentifier
        case .monthly:
            productIdentifier = StoreData.monthlyProProductIdentifier
        case .yearly:
            productIdentifier = StoreData.yearlyProProductIdentifier
        }
        
        // More polished button animation
        UIView.animate(withDuration: 0.1, animations: {
            self.continueButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            self.continueButton.alpha = 0.9
        }) { _ in
            UIView.animate(withDuration: 0.15, animations: {
                self.continueButton.transform = CGAffineTransform.identity
                self.continueButton.alpha = 1.0
            }) { _ in
                self.purchaseSubsInAppStore(productIdentifier: productIdentifier)
            }
        }
    }
    
    @objc private func termsPrivacyTapped() {
        if let url = URL(string: MenuView.Constants.termsOfUseUrl), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
        
        AnaliticsManager.shared.logEvent(key: AppEvent.subsViewAction.rawValue, eventProperty: "termsPrivacyTapped")
    }
    
    private func updatePlanSelection(_ planType: PlanType) {
        selectedPlanType = planType
        
        // Update visual selection state
        weeklyPlanView.setSelected(planType == .weekly)
        monthlyPlanView.setSelected(planType == .monthly)
        yearlyPlanView.setSelected(planType == .yearly)
        
        // Show/hide best value badge
            if planType == .monthly {
                self.bestValueBadge.snp.remakeConstraints { make in
                    make.top.equalTo(self.monthlyPlanView).offset(-10)
                    make.centerX.equalTo(self.monthlyPlanView)
                    make.height.equalTo(20)
                }
                self.bestValueLabel.text = "Subs.POPULAR".localize()
                self.bestValueBadge.alpha = 1
            } else if planType == .yearly {
                self.bestValueBadge.snp.remakeConstraints { make in
                    make.top.equalTo(self.yearlyPlanView).offset(-10)
                    make.centerX.equalTo(self.yearlyPlanView)
                    make.height.equalTo(20)
                }
                self.bestValueLabel.text = "Subs.BESTVALUE".localize()
                self.bestValueBadge.alpha = 1
            } else {
                self.bestValueBadge.alpha = 0
            }
        
        // Update subscription manager
        SubsManager.shared.isYearlyPlan = (planType == .yearly)
        
        // Animate description update
        UIView.transition(with: descriptionLabel, duration: 0.3, options: .transitionCrossDissolve, animations: {
            // Text is set in the button tapped methods
        }, completion: nil)
        
        // Button style update for selection
        if let buttonGradient = continueButton.layer.sublayers?.first as? CAGradientLayer {
            let newGradientColors: [CGColor]
            
            switch planType {
            case .weekly:
                newGradientColors = [
                    UIColor(red: 255/255, green: 144/255, blue: 154/255, alpha: 1).cgColor,
                    UIColor(red: 255/255, green: 86/255, blue: 110/255, alpha: 1).cgColor
                ]
            case .monthly:
                newGradientColors = [
                    UIColor(red: 255/255, green: 144/255, blue: 154/255, alpha: 1).cgColor,
                    UIColor(red: 255/255, green: 86/255, blue: 110/255, alpha: 1).cgColor
                ]
            case .yearly:
                // Slightly different gradient for yearly to highlight it more
                newGradientColors = [
                    UIColor(red: 255/255, green: 110/255, blue: 130/255, alpha: 1).cgColor,
                    UIColor(red: 255/255, green: 70/255, blue: 90/255, alpha: 1).cgColor
                ]
            }
            
            // Animate gradient change
            let animation = CABasicAnimation(keyPath: "colors")
            animation.fromValue = buttonGradient.colors
            animation.toValue = newGradientColors
            animation.duration = 0.3
            animation.fillMode = .forwards
            animation.isRemovedOnCompletion = false
            buttonGradient.add(animation, forKey: "colorsChange")
            
            buttonGradient.colors = newGradientColors
        }
    }
}

extension SubsView {
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
                    case .purchased, .restored:
                        SubsManager.shared.saveSubscriptionStatus(isSubscribed: true)
                        
                        if self?.isOnbording == true {
                            let isFirstLounchKey = "isFirstLounchKey"
                            UserDefaults.standard.set(true, forKey: isFirstLounchKey)
                            
                            DispatchQueue.main.async {
                                let mainVC = ViewController()
                                mainVC.modalPresentationStyle = .fullScreen
                                self?.vc?.present(mainVC, animated: true, completion: nil)
                            }
                        } else {
                            self?.removeFromSuperview()
                        }
                        
                        OneSignal.User.addTag(key: "is_finish_onbording", value: "true")
                        OneSignal.User.addTag(key: "is_finish_purchase", value: "true")
                    }
                }
            }
        }
    }
}
