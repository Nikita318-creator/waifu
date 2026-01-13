import UIKit
import SnapKit
import OneSignalFramework

class SubscriptionPlanView: UIView {
    // MARK: - UI Elements
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let priceLabel = UILabel()
    private let saveLabel = UILabel()
    private let checkmarkImageView = UIImageView()
    
    // Selection indicator
    private let selectionBorder = CALayer()
    
    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Setup
    private func setupView() {
        // Container View
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 16
        containerView.layer.masksToBounds = true
        addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // Title Label
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont(name: "AvenirNext-DemiBold", size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = UIColor(red: 80/255, green: 80/255, blue: 80/255, alpha: 1)
        containerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(8)
        }
        
        // Price Label
        priceLabel.textAlignment = .center
        priceLabel.font = UIFont(name: "AvenirNext-Bold", size: 18) ?? UIFont.systemFont(ofSize: 18, weight: .bold)
        priceLabel.textColor = UIColor(red: 255/255, green: 86/255, blue: 110/255, alpha: 1)
        containerView.addSubview(priceLabel)
        priceLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(8)
        }
        
        // Save Label (for discounts)
        saveLabel.textAlignment = .center
        saveLabel.font = UIFont(name: "AvenirNext-Medium", size: 12) ?? UIFont.systemFont(ofSize: 12, weight: .medium)
        saveLabel.textColor = UIColor(red: 70/255, green: 195/255, blue: 120/255, alpha: 1)
        saveLabel.isHidden = true
        containerView.addSubview(saveLabel)
        saveLabel.snp.makeConstraints { make in
            make.top.equalTo(priceLabel.snp.bottom).offset(4)
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(8)
        }
        
        // Checkmark Image View
        checkmarkImageView.image = UIImage(systemName: "checkmark.circle.fill")
        checkmarkImageView.tintColor = UIColor(red: 255/255, green: 86/255, blue: 110/255, alpha: 1)
        checkmarkImageView.contentMode = .scaleAspectFit
        checkmarkImageView.isHidden = true
        checkmarkImageView.alpha = 0
        containerView.addSubview(checkmarkImageView)
        checkmarkImageView.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(8)
            make.width.height.equalTo(24)
        }
        
        // Selection Border (initially hidden)
        selectionBorder.borderWidth = 3
        selectionBorder.borderColor = UIColor(red: 255/255, green: 86/255, blue: 110/255, alpha: 1).cgColor
        selectionBorder.cornerRadius = 16
        layer.insertSublayer(selectionBorder, at: 0)
        selectionBorder.opacity = 0
    }
    
    // MARK: - Public Methods
    
    func setTitle(_ title: String) {
        titleLabel.text = title
        
        // Set the price based on subscription type
        switch title {
        case "Subs.week".localize():
            if let product = InAppPurchaseManager.shared.products.first(where: { $0.storeProduct.productIdentifier == StoreData.weeklyProductIdentifier }) {
                priceLabel.text = product.storeProduct.localizedPriceString
            }
            saveLabel.text = ""
            saveLabel.isHidden = false
        case "Subs.month".localize():
            if let product = InAppPurchaseManager.shared.products.first(where: { $0.storeProduct.productIdentifier == StoreData.monthlyProProductIdentifier }) {
                priceLabel.text = product.storeProduct.localizedPriceString
            }
            saveLabel.text = "Subs.14dFree".localize()
            saveLabel.isHidden = false
        case "Subs.year".localize():
            if let product = InAppPurchaseManager.shared.products.first(where: { $0.storeProduct.productIdentifier == StoreData.yearlyProProductIdentifier }) {
                priceLabel.text = product.storeProduct.localizedPriceString
            }
            saveLabel.text = "Subs.Save33".localize()
            saveLabel.isHidden = false
        default:
            priceLabel.text = ""
        }
    }
    
    func setSelected(_ selected: Bool) {
        // Update the visual appearance to reflect selection state
        if selected {
            // Show pulsing animation for selection
            let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
            pulseAnimation.duration = 0.2
            pulseAnimation.fromValue = 1.0
            pulseAnimation.toValue = 1.05
            pulseAnimation.autoreverses = true
            pulseAnimation.repeatCount = 1
            layer.add(pulseAnimation, forKey: "pulseAnimation")
            
            // Show selection border with animation
            let borderAnimation = CABasicAnimation(keyPath: "opacity")
            borderAnimation.duration = 0.2
            borderAnimation.fromValue = 0.0
            borderAnimation.toValue = 1.0
            selectionBorder.add(borderAnimation, forKey: "opacityAnimation")
            selectionBorder.opacity = 1.0
            
            // Update the container view background
            containerView.backgroundColor = UIColor(red: 255/255, green: 248/255, blue: 248/255, alpha: 1)
            
            // Show checkmark with animation
            checkmarkImageView.isHidden = false
            UIView.animate(withDuration: 0.2) {
                self.checkmarkImageView.alpha = 1.0
            }
            
            // Make price more vibrant
            priceLabel.textColor = UIColor(red: 255/255, green: 68/255, blue: 92/255, alpha: 1)
            titleLabel.textColor = UIColor(red: 50/255, green: 50/255, blue: 50/255, alpha: 1)
        } else {
            // Hide selection elements
            selectionBorder.opacity = 0.0
            containerView.backgroundColor = .white
            
            // Hide checkmark with animation
            UIView.animate(withDuration: 0.2) {
                self.checkmarkImageView.alpha = 0.0
            } completion: { _ in
                self.checkmarkImageView.isHidden = true
            }
            
            // Reset colors
            priceLabel.textColor = UIColor(red: 255/255, green: 86/255, blue: 110/255, alpha: 1)
            titleLabel.textColor = UIColor(red: 80/255, green: 80/255, blue: 80/255, alpha: 1)
        }
    }
    
    // Handle layout changes
    override func layoutSubviews() {
        super.layoutSubviews()
        selectionBorder.frame = bounds
    }
}
