import UIKit
import SnapKit

class OutfitCell: UICollectionViewCell {
    private let imageView = UIImageView()
    private let priceLabel = UILabel()
    private let coinIcon = UIImageView()
    private let priceStack = UIStackView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupCell() {
        contentView.backgroundColor = DressUpVC.TelegramColors.cardBackground
        contentView.layer.cornerRadius = 15
        contentView.clipsToBounds = true
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)
        
        priceLabel.font = .systemFont(ofSize: 14, weight: .bold)
        priceLabel.textColor = .white
        
        coinIcon.image = UIImage(systemName: "circle.fill")
        coinIcon.tintColor = .systemYellow
        
        priceStack.axis = .horizontal
        priceStack.spacing = 4
        priceStack.alignment = .center
        priceStack.addArrangedSubview(priceLabel)
        priceStack.addArrangedSubview(coinIcon)
        contentView.addSubview(priceStack)
        
        imageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().inset(25)
        }
        
        priceStack.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(4)
        }
        
        coinIcon.snp.makeConstraints { make in
            make.width.height.equalTo(12)
        }
    }
    
    func configure(imageName: String, price: Int, isPurchased: Bool) {
        imageView.image = UIImage(named: imageName)
        priceLabel.text = "\(price)"
        priceStack.isHidden = isPurchased
    }
}
