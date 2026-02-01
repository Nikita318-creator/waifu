import UIKit
import SnapKit

class CreateWaifuHeader: UICollectionReusableView {
    static let identifier = "CreateWaifuHeader"
    
    // MARK: - UI Components
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let iconImageView = UIImageView()
    private let actionButton = UIButton(type: .system)
    
    var onButtonTap: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        // Контейнер (сама карточка)
        containerView.backgroundColor = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1.0)
        containerView.layer.cornerRadius = 20
        containerView.layer.masksToBounds = true
        // Добавим небольшую обводку, чтобы карточка "звенела"
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.white.withAlphaComponent(0.1).cgColor
        
        addSubview(containerView)
        
        // Иконка (Magic Wand или плюс)
        iconImageView.image = UIImage(systemName: "sparkles") // Анимешный эффект сияния
        iconImageView.tintColor = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0)
        iconImageView.contentMode = .scaleAspectFit
        containerView.addSubview(iconImageView)
        
        // Заголовок
        titleLabel.text = "CreateDreamWaifu".localize()
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        containerView.addSubview(titleLabel)
        
        // Подзаголовок (объясняет, что делать)
        subtitleLabel.text = "CreateDreamWaifu.subtitle".localize() 
        subtitleLabel.textColor = .lightGray
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        containerView.addSubview(subtitleLabel)
        
        // Скрытая кнопка на всю область для тапа
        actionButton.addTarget(self, action: #selector(tapped), for: .touchUpInside)
        containerView.addSubview(actionButton)
        
        // Layout
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }
        
        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.size.equalTo(40)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(16)
            make.top.equalToSuperview().inset(16)
            make.trailing.equalToSuperview().inset(16)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.trailing.equalToSuperview().inset(16)
        }
        
        actionButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    @objc private func tapped() {
        // Эффект нажатия (мигание)
        UIView.animate(withDuration: 0.1, animations: {
            self.containerView.alpha = 0.7
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.containerView.alpha = 1.0
            }
            self.onButtonTap?()
        }
    }
}
