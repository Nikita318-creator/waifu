import UIKit
import SnapKit

// MARK: - CoinPackage Model
struct CoinPackage {
    let id: String
    let amount: Int
    var price: String
    let imageName: String
}

// MARK: - CoinsPackageCell
class CoinsPackageCell: UICollectionViewCell {
    static let reuseIdentifier = "CoinsPackageCell"

    private let imageView = UIImageView()
    private let amountLabel = UILabel()
    private let priceButton = UIButton()
    
    private var coinID = ""
    private var amount: Int = 0
    
    var loadingIAPHandler: ((Bool) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupCell() {
        layer.cornerRadius = 15
        layer.borderWidth = 1
        layer.borderColor = UIColor.systemGray4.cgColor
        backgroundColor = .secondarySystemBackground
        
        // Image View
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 15
        contentView.addSubview(imageView)
        
        // Amount Label
        amountLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        amountLabel.textColor = .label
        amountLabel.textAlignment = .center
        
        amountLabel.layer.shadowColor = UIColor.black.cgColor
        amountLabel.layer.shadowOpacity = 0.8
        amountLabel.layer.shadowRadius = 2.0
        amountLabel.layer.shadowOffset = CGSize(width: 1.0, height: 1.0)
        amountLabel.layer.masksToBounds = false
        
        contentView.addSubview(amountLabel)

        // Price Button
        priceButton.layer.cornerRadius = 10
        priceButton.backgroundColor = .systemGreen
        priceButton.setTitleColor(.white, for: .normal)
        priceButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        
        // Add visual tap effect
        priceButton.addTarget(self, action: #selector(priceButtonDown), for: .touchDown)
        priceButton.addTarget(self, action: #selector(priceButtonUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        
        contentView.addSubview(priceButton)
        
        // Constraints
        imageView.snp.makeConstraints { make in
            make.top.equalTo(amountLabel.snp.bottom)
            make.bottom.equalTo(priceButton.snp.top)
            make.centerX.equalToSuperview()
        }
        
        amountLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(10)
            make.centerX.equalToSuperview()
            make.height.equalTo(20)
        }
        
        priceButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.height.equalTo(40)
            make.bottom.equalToSuperview().inset(10)
        }
    }

    func configure(with package: CoinPackage) {
        coinID = package.id
        amount = package.amount
        imageView.image = UIImage(named: package.imageName)
        amountLabel.text = "\(package.amount) \("Coins".localize())"
        priceButton.setTitle("\("Buy.for".localize()) \(package.price)", for: .normal)
    }
    
    // MARK: - Button Animations
    
    @objc private func priceButtonDown() {
        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseOut) {
            self.priceButton.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        }
    }
    
    @objc private func priceButtonUp() {
        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseOut) {
            self.priceButton.transform = .identity
        } completion: { [weak self] _ in
            self?.priceButtonTapped()
        }
    }
    
    func priceButtonTapped() {
        AnalyticService.shared.logEvent(name: "CoinsPackageCell priceButtonTapped", properties: ["":""])

        loadingIAPHandler?(true)
        
        IAPService.shared.purchase(productId: coinID) { [self] result in
            DispatchQueue.main.async {
                switch result {
                case .failed:
                    self.loadingIAPHandler?(false)
                case .purchased, .restored:
                    WebHookAnalyticsService.shared.sendAnalyticsReport(messageText: "COINS PURCHASED!!! \(self.coinID)")
                    AnalyticService.shared.logEvent(name: "Coins purchased!!!", properties: ["":"with id: \(self.coinID)"])
                    CoinsService.shared.addCoins(self.amount)
                    self.loadingIAPHandler?(false)
                }
            }
        }
    }
}
