import UIKit
import SnapKit

class StoryCell: UICollectionViewCell {
    static let identifier = "StoryCell"

    private let avatarImageView = UIImageView()
    private let titleLabel = UILabel()
    private let seenBorderView = UIView() // Кружок для непросмотренных сторис

    // Telegram цвета (можно вынести в общий файл, если их нет в этом scope)
    private struct TelegramColors {
        static let primary = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0) // #3390DC
        static let textPrimary = UIColor.white
        static let textSecondary = UIColor(red: 0.64, green: 0.64, blue: 0.66, alpha: 1.0) // #A4A4A8
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        updateTextForIPadIfNeeded()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        contentView.backgroundColor = .clear // Прозрачный фон ячейки
        
        // Кружок для непросмотренных сторис
        seenBorderView.layer.cornerRadius = 32 // Размер круга (аватар 60px + border 2px * 2) / 2
        seenBorderView.layer.borderWidth = 2
        seenBorderView.layer.borderColor = TelegramColors.primary.cgColor
        seenBorderView.clipsToBounds = true // Обрезаем по границам
        contentView.addSubview(seenBorderView)

        // Аватарка сторис
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 30 // Половина ширины/высоты для круга (60px / 2)
        avatarImageView.clipsToBounds = true
        contentView.addSubview(avatarImageView)

        // Заголовок/имя под сторис
        titleLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        titleLabel.textColor = TelegramColors.textSecondary
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1 // Одна строка для имени
        contentView.addSubview(titleLabel)

        // Constraints
        avatarImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(5)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(60) // Размер аватарки
        }
        
        seenBorderView.snp.makeConstraints { make in
            make.center.equalTo(avatarImageView)
            make.width.height.equalTo(64) // 60 + 2*2 = 64 (аватарка + 2px с каждой стороны)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarImageView.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview()
            make.bottom.lessThanOrEqualToSuperview() // Заголовок может быть обрезается, если не помещается
        }
    }

    func configure(with story: StoryModel) {
        avatarImageView.image = UIImage(named: story.imageName)
        titleLabel.text = story.title
        seenBorderView.layer.borderColor = story.isViewed ? TelegramColors.textSecondary.cgColor : TelegramColors.primary.cgColor
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        avatarImageView.image = nil
        titleLabel.text = nil
        seenBorderView.layer.borderColor = TelegramColors.primary.cgColor // Сброс бордера при переиспользовании
    }
}

extension StoryCell {
    func updateTextForIPadIfNeeded() {
        guard isCurrentDeviceiPad() else { return }
        
        titleLabel.font = UIFont.systemFont(ofSize: 23, weight: .regular)
        avatarImageView.layer.cornerRadius = 45
        seenBorderView.layer.cornerRadius = 49
        
        avatarImageView.snp.updateConstraints { make in
            make.width.height.equalTo(90) // Размер аватарки
        }
        
        seenBorderView.snp.updateConstraints { make in
            make.width.height.equalTo(98)
        }
    }
}
