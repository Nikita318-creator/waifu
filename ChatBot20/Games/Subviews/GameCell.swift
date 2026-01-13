import UIKit
import SnapKit

struct GameModel {
    let id: String
    let title: String
    let imageName: String
}

class GameCell: UICollectionViewCell {
    static let identifier = "GameCell"
    
    private let containerView = UIView()
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let labelBackgroundView = UIView()
    private let gradientLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupViews() {
        // Карточка
        containerView.backgroundColor = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1.0)
        containerView.layer.cornerRadius = 16
        
        // --- Добавляем рамку здесь ---
        containerView.layer.borderWidth = 1.0
        containerView.layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor
        // -----------------------------
        
        containerView.clipsToBounds = true
        contentView.addSubview(containerView)
        
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // Картинка
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .darkGray
        containerView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // Градиент
        gradientLayer.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.5).cgColor]
        gradientLayer.locations = [0.6, 1.0]
        imageView.layer.addSublayer(gradientLayer)

        // Подложка лейбла
        labelBackgroundView.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
        labelBackgroundView.layer.cornerRadius = 10
        labelBackgroundView.layer.borderWidth = 1.0
        labelBackgroundView.layer.borderColor = UIColor.white.withAlphaComponent(0.1).cgColor
        labelBackgroundView.alpha = 0.95
        containerView.addSubview(labelBackgroundView)

        // Название игры
        titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 1
        titleLabel.textAlignment = .center
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.5
        labelBackgroundView.addSubview(titleLabel)
        
        titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10))
        }

        labelBackgroundView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(12)
            make.leading.trailing.lessThanOrEqualToSuperview().inset(12)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = imageView.bounds
    }

    func configure(with model: GameModel) {
        titleLabel.text = model.title
        imageView.image = UIImage(named: model.imageName)
    }
}
