import UIKit
import SnapKit

// MARK: - GiftItem Model
struct GiftItem {
    let imageName: String
    let price: Int
}

// MARK: - GiftCell
class GiftCell: UICollectionViewCell {
    static let reuseIdentifier = "GiftCell"

    private let imageView = UIImageView()
    private let priceLabel = UILabel()
    private let coinIcon = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupCell() {
        layer.cornerRadius = 20
        layer.masksToBounds = true
        backgroundColor = .secondarySystemBackground

        // Image View
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)
        
        // Price Label
        priceLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        priceLabel.textColor = .label
        
        // Coin Icon
        coinIcon.image = UIImage(systemName: "circle.fill")
        coinIcon.tintColor = .systemYellow

        let priceStackView = UIStackView(arrangedSubviews: [priceLabel, coinIcon])
        priceStackView.axis = .horizontal
        priceStackView.alignment = .center
        priceStackView.spacing = 10
        contentView.addSubview(priceStackView)

        // Constraints
        imageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(8)
            make.bottom.equalTo(priceStackView.snp.top).offset(-8)
        }

        priceStackView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(8)
            make.height.equalTo(30)
        }
        
        coinIcon.snp.makeConstraints { make in
            make.width.height.equalTo(24)
        }
    }

    func configure(with gift: GiftItem, isProfile: Bool = false) {
        imageView.image = UIImage(named: gift.imageName)
        priceLabel.text = "\(gift.price)"
        priceLabel.isHidden = isProfile
        coinIcon.isHidden = isProfile
    }
}
