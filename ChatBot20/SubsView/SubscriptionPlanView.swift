import UIKit
import SnapKit

class SubscriptionPlanView: UIView {
    // MARK: - UI Elements
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let priceLabel = UILabel()
    private let weeklyPriceLabel = UILabel()
    private let oldPriceLabel = UILabel()
    private let checkmarkImageView = UIImageView()
    private let selectionBorder = CALayer()
    private let contentStack = UIStackView()
        
    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        updateTextForIPadIfNeeded()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupView() {
        // Container View
        containerView.backgroundColor = UIColor(hex: "#1A1A1A")
        containerView.layer.cornerRadius = 14
        containerView.layer.masksToBounds = true
        addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // Content Stack - горизонтальное расположение для вертикальных карточек
        contentStack.axis = .horizontal
        contentStack.distribution = .fill
        contentStack.alignment = .center
        contentStack.spacing = 12
        containerView.addSubview(contentStack)
        
        // Left Side - Title
        titleLabel.textAlignment = .left
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = UIColor(hex: "#E0E0E0")
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        contentStack.addArrangedSubview(titleLabel)
        
        // Right Side Stack - Price Info
        let priceStack = UIStackView()
        priceStack.axis = .vertical
        priceStack.alignment = .trailing
        priceStack.spacing = 2
        priceStack.setContentHuggingPriority(.required, for: .horizontal)
        
        oldPriceLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        oldPriceLabel.textColor = UIColor(hex: "#FF4D4D")
        oldPriceLabel.isHidden = true
        priceStack.addArrangedSubview(oldPriceLabel)
        
        // Price Label
        priceLabel.textAlignment = .right
        priceLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        priceLabel.textColor = UIColor(hex: "#1A73E8")
        priceStack.addArrangedSubview(priceLabel)
        
        // Weekly Price Label
        weeklyPriceLabel.textAlignment = .right
        weeklyPriceLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        weeklyPriceLabel.textColor = UIColor(hex: "#808080")
        weeklyPriceLabel.isHidden = true
        priceStack.addArrangedSubview(weeklyPriceLabel)
        
        contentStack.addArrangedSubview(priceStack)
        
        // Checkmark Image View
        checkmarkImageView.image = UIImage(systemName: "checkmark.circle.fill")
        checkmarkImageView.tintColor = UIColor(hex: "#34C759")
        checkmarkImageView.contentMode = .scaleAspectFit
        checkmarkImageView.isHidden = true
        checkmarkImageView.alpha = 0
        containerView.addSubview(checkmarkImageView)
        
        // Selection Border
        selectionBorder.borderWidth = 2
        selectionBorder.borderColor = UIColor(hex: "#34C759").cgColor
        selectionBorder.cornerRadius = 14
        layer.insertSublayer(selectionBorder, at: 0)
        selectionBorder.opacity = 0
        
        checkmarkImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-12)
            make.width.height.equalTo(24)
        }
        
        contentStack.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.trailing.equalTo(checkmarkImageView.snp.leading).offset(-12)
            make.centerY.equalToSuperview()
        }
    }
    
    func updateTextForIPadIfNeeded() {
        guard isCurrentDeviceiPad() else { return }

        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        priceLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        weeklyPriceLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        
        checkmarkImageView.snp.updateConstraints { make in
            make.width.height.equalTo(32)
        }
    }
    
    // MARK: - Public Methods
    func setTitle(_ title: String, isTrial: Bool = false) {
        titleLabel.text = title
        let isDiscount = MainHelper.shared.isDiscountOffer
        
        // Логика определения ID
        var currentId: String = ""
        var oldId: String? = nil
        
        if title == "Subs.week".localize() {
            // Если скидка - берем дешевый, а старый - дорогой
            if isDiscount {
                currentId = SubsIDs.weeklySubsId
                oldId = SubsIDs.weeklyPROSubsId
            } else {
                currentId = ConfigService.shared.isProPrice ? SubsIDs.weeklyPROSubsId : SubsIDs.weeklySubsId
            }
        } else if title == "Subs.month".localize() {
            if isDiscount {
                currentId = SubsIDs.monthlySubsId
                oldId = SubsIDs.monthlyPROSubsId
            } else {
                currentId = ConfigService.shared.isProPrice ? SubsIDs.monthlyPROSubsId : SubsIDs.monthlySubsId
            }
        }
        
        // 1. Ставим основную цену
        if let product = IAPService.shared.products.first(where: { $0.productId == currentId }) {
            priceLabel.text = product.skProduct?.localizedPrice() ?? ""
            
            // Расчет недельной цены для месяца (как у тебя было)
            if title == "Subs.month".localize(),
               let priceString = product.skProduct?.localizedPrice(),
               let (price, currencySymbol) = extractPrice(from: priceString) {
                let weeklyPrice = price / 4.33
                weeklyPriceLabel.text = String(format: "%@%.2f \("Subs.perWeek".localize())", currencySymbol, weeklyPrice)
                weeklyPriceLabel.isHidden = false
            }
        }
        
        // 2. Ставим зачеркнутую цену, если есть оффер
        if isDiscount, let oid = oldId,
           let oldProduct = IAPService.shared.products.first(where: { $0.productId == oid }),
           let oldPrice = oldProduct.skProduct?.localizedPrice() {
            
            let attributeString = NSMutableAttributedString(string: oldPrice)
            attributeString.addAttribute(.strikethroughStyle, value: 2, range: NSMakeRange(0, attributeString.length))
            oldPriceLabel.attributedText = attributeString
            oldPriceLabel.isHidden = false
        } else {
            oldPriceLabel.isHidden = true
        }
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
    
    func setSelected(_ selected: Bool) {
        if selected {
            UIView.animate(withDuration: 0.2) {
                self.selectionBorder.opacity = 1.0
                self.containerView.backgroundColor = UIColor(hex: "#222222")
                self.checkmarkImageView.alpha = 1.0
                self.checkmarkImageView.isHidden = false
            }
            
            priceLabel.textColor = UIColor(hex: "#34C759")
            titleLabel.textColor = UIColor(hex: "#FFFFFF")
            
        } else {
            UIView.animate(withDuration: 0.2) {
                self.selectionBorder.opacity = 0.0
                self.containerView.backgroundColor = UIColor(hex: "#1A1A1A")
                self.checkmarkImageView.alpha = 0.0
            } completion: { _ in
                self.checkmarkImageView.isHidden = true
            }
            
            priceLabel.textColor = UIColor(hex: "#1A73E8")
            titleLabel.textColor = UIColor(hex: "#E0E0E0")
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        selectionBorder.frame = bounds
    }
}
