import UIKit
import SnapKit

struct ChatModel {
    let id: String
    let assistantName: String
    let lastMessage: String
    let lastMessageTime: String
    let assistantAvatar: String
    let isPremium: Bool
}

class ChatListItemCell: UITableViewCell {

    private struct TelegramColors {
        static let primary = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0) // #3390DC
        static let background = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0) // #1C1C1E
        static let cardBackground = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1.0) // #2C2C2E
        static let messageBackground = UIColor(red: 0.22, green: 0.22, blue: 0.24, alpha: 1.0) // #38383A
        static let userMessageBackground = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0) // #3390DC
        static let textPrimary = UIColor.white
        static let textSecondary = UIColor(red: 0.64, green: 0.64, blue: 0.66, alpha: 1.0) // #A4A4A8
        static let separator = UIColor(red: 0.28, green: 0.28, blue: 0.29, alpha: 1.0) // #48484A
        static let unreadBadge = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0)
    }

    static let identifier = "ChatListItemCell"
    
    private let containerView = UIView()
    private let avatarContainer = UIView() // Для эффекта свечения вокруг аватара
    private let avatarImageView = UIImageView()
    private let titleLabel = UILabel()
    private let lastMessageLabel = UILabel()
    private let timeLabel = UILabel()
    private let unreadIndicator = UIView() // Точка вместо тяжелого баджа

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupNewStyle()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupNewStyle() {
        backgroundColor = .clear
        selectionStyle = .none

        // Контейнер с легким бордером
        containerView.backgroundColor = TelegramColors.cardBackground
        containerView.layer.cornerRadius = 20 // Более скругленные углы
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = TelegramColors.separator.withAlphaComponent(0.5).cgColor
        contentView.addSubview(containerView)

        containerView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(6)
            make.leading.trailing.equalToSuperview().inset(12)
        }

        // Аватар с подложкой
        avatarContainer.backgroundColor = TelegramColors.messageBackground
        avatarContainer.layer.cornerRadius = 28
        containerView.addSubview(avatarContainer)
        
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 24
        avatarImageView.clipsToBounds = true
        avatarContainer.addSubview(avatarImageView)

        // Текстовый блок
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = TelegramColors.textPrimary
        containerView.addSubview(titleLabel)

        lastMessageLabel.font = .systemFont(ofSize: 14, weight: .medium)
        lastMessageLabel.textColor = TelegramColors.textSecondary
        lastMessageLabel.numberOfLines = 2 // Даем больше контекста
        containerView.addSubview(lastMessageLabel)

        timeLabel.font = .systemFont(ofSize: 12, weight: .regular)
        timeLabel.textColor = TelegramColors.primary.withAlphaComponent(0.8)
        containerView.addSubview(timeLabel)

        // Индикатор непрочитанного (стильная точка)
        unreadIndicator.backgroundColor = TelegramColors.primary
        unreadIndicator.layer.cornerRadius = 5
        unreadIndicator.isHidden = true
        containerView.addSubview(unreadIndicator)

        // Constraints
        avatarContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(56)
        }

        avatarImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(48)
        }

        timeLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(14)
            make.trailing.equalToSuperview().inset(16)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(12)
            make.leading.equalTo(avatarContainer.snp.trailing).offset(14)
            make.trailing.equalTo(timeLabel.snp.leading).offset(-8)
        }

        lastMessageLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalTo(titleLabel)
            make.trailing.equalToSuperview().inset(16)
            make.bottom.lessThanOrEqualToSuperview().inset(12)
        }
        
        unreadIndicator.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(8)
            make.centerY.equalTo(titleLabel)
            make.width.height.equalTo(10)
        }
    }

    func configure(with chat: ChatModel) {
        titleLabel.text = chat.assistantName
        lastMessageLabel.text = chat.lastMessage
        timeLabel.text = chat.lastMessageTime
        avatarImageView.image = UIImage(named: chat.assistantAvatar) ?? UIImage.loadCustomAvatar(for: chat.assistantAvatar)
        
        // Если премиум — добавляем золотистую рамку аватару
        avatarContainer.layer.borderWidth = chat.isPremium ? 2 : 0
        avatarContainer.layer.borderColor = UIColor.systemOrange.cgColor
    }
    
    func setUnread() {
        unreadIndicator.isHidden = false
        containerView.layer.borderColor = TelegramColors.primary.withAlphaComponent(0.4).cgColor
    }
}
