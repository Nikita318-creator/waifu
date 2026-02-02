import UIKit
import SnapKit

class BaseGameViewController: UIViewController {
    
    // MARK: - UI Colors
    struct TelegramColors {
        static let primary = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0)
        static let background = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
        static let cardBackground = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1.0)
        static let textPrimary = UIColor.white
        static let textSecondary = UIColor(red: 0.64, green: 0.64, blue: 0.66, alpha: 1.0)
        static let bubbleBackground = UIColor(red: 0.22, green: 0.22, blue: 0.24, alpha: 1.0)
    }
    
    // MARK: - Properties
    var waifuScore = 0
    var userScore = 0
    
    private var gameSaveKey: String {
        return String(describing: type(of: self)) + "_progress"
    }
    
    // Custom Navigation Elements
    private let customNavBar = UIView()
    private let scoreLabel = UILabel()
    private let backButton = UIButton(type: .system)
    private let infoButton = UIButton(type: .system)
    
    let waifuImageView = UIImageView()
    private let chatBubbleView = UIView()
    private let bubbleLabel = UILabel()
    
    let gameContainerView = UIView()
    var gameRules: String { "Rules for this game will be added soon." }

    func didResetProgress() {
        // Будет переопределено в дочерних классах (Reversi, Checkers и т.д.)
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.isModalInPresentation = true
        
        setupBaseUI()
        setupCustomNavigationBar()
        
        setWaifuMessage(ConfigService.shared.isGameText ? "ReadyForChallenge1".localize() : "ReadyForChallenge2".localize())
        
        print("\(self)")
        AnalyticService.shared.logEvent(name: "game opened", properties: ["type":"\(self)"])
    }
    
    func loadProgress() {
        if let stats = UserDefaults.standard.dictionary(forKey: gameSaveKey) as? [String: Int] {
            self.waifuScore = stats["waifu"] ?? 0
            self.userScore = stats["user"] ?? 0
            updateScore(waifu: waifuScore, user: userScore)
        } else {
            self.waifuScore = 0
            self.userScore = 0
            updateScore(waifu: waifuScore, user: userScore)
        }
    }
        
    func updateScore(waifu: Int, user: Int) {
        AnalyticService.shared.logEvent(name: "game updatedScore", properties: ["type":"\(self)", "waifu":"\(waifu)", "user":"\(user)"])

        self.waifuScore = waifu
        self.userScore = user
        scoreLabel.text = "\("Roleplay".localize()) \(waifuScore) : \(userScore) \("you".localize())"
        
        saveProgress()
    }
    
    func setWaifuMessage(_ text: String) {
        bubbleLabel.text = text
    }

    // MARK: - Private Setup
    
    private func saveProgress() {
        let stats = ["waifu": waifuScore, "user": userScore]
        UserDefaults.standard.set(stats, forKey: gameSaveKey)
    }
    
    private func setupCustomNavigationBar() {
        view.addSubview(customNavBar)
        customNavBar.backgroundColor = .clear
        
        customNavBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(60) // Увеличили высоту для более крупного контента
        }
        
        // Кнопка Назад (Современная: шеврон в круге)
        let backConfig = UIImage.SymbolConfiguration(pointSize: 28, weight: .semibold)
        let backImage = UIImage(systemName: "chevron.left.circle.fill", withConfiguration: backConfig)
        
        backButton.setImage(backImage, for: .normal)
        backButton.tintColor = .white // Или TelegramColors.primary, но серый в круге сейчас в тренде
        backButton.addTarget(self, action: #selector(dismissGame), for: .touchUpInside)
        customNavBar.addSubview(backButton)
        
        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(44) // Увеличенная область нажатия
        }
        
        // Счёт (Текст покрупнее)
        scoreLabel.text = "\("Roleplay".localize()) \(waifuScore) : \(userScore) \("you".localize())"
        scoreLabel.font = .systemFont(ofSize: 20, weight: .black) // Жирный и крупный
        scoreLabel.textColor = .white
        scoreLabel.textAlignment = .center
        
        scoreLabel.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(scoreLabelTapped))
        scoreLabel.addGestureRecognizer(tap)
        
        customNavBar.addSubview(scoreLabel)
        
        scoreLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        // Кнопка Инфо (Тоже в круге, покрупнее)
        let infoConfig = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        let infoImage = UIImage(systemName: "info.circle.fill", withConfiguration: infoConfig)
        
        infoButton.setImage(infoImage, for: .normal)
        infoButton.tintColor = TelegramColors.primary
        infoButton.addTarget(self, action: #selector(showRules), for: .touchUpInside)
        customNavBar.addSubview(infoButton)
        
        infoButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(44)
        }
    }
    
    private func setupBaseUI() {
        view.backgroundColor = TelegramColors.background
        
        waifuImageView.contentMode = .scaleAspectFill
        waifuImageView.layer.cornerRadius = 40
        waifuImageView.clipsToBounds = true
        waifuImageView.backgroundColor = TelegramColors.cardBackground
        waifuImageView.isUserInteractionEnabled = true
        let imageTap = UITapGestureRecognizer(target: self, action: #selector(waifuImageTapped))
        waifuImageView.addGestureRecognizer(imageTap)
        view.addSubview(waifuImageView)
        
        chatBubbleView.backgroundColor = TelegramColors.bubbleBackground
        chatBubbleView.layer.cornerRadius = 15
        chatBubbleView.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner, .layerMinXMinYCorner]
        view.addSubview(chatBubbleView)
        
        bubbleLabel.textColor = .white
        bubbleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        bubbleLabel.numberOfLines = 0
        chatBubbleView.addSubview(bubbleLabel)
        
        gameContainerView.backgroundColor = .clear
        view.addSubview(gameContainerView)
        
        // MARK: - Constraints
        waifuImageView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(64) // Под кастомным баром
            make.leading.equalToSuperview().offset(16)
            make.width.equalTo(UIScreen.main.bounds.width / 2)
            make.height.equalTo(UIScreen.main.bounds.height / 3)
        }
        
        chatBubbleView.snp.makeConstraints { make in
            make.top.equalTo(waifuImageView.snp.top)
            make.leading.equalTo(waifuImageView.snp.trailing).offset(-25)
            make.trailing.equalToSuperview().inset(8)
            make.bottom.lessThanOrEqualTo(waifuImageView.snp.bottom).offset(10)
        }
        
        bubbleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }
        
        gameContainerView.snp.makeConstraints { make in
            make.top.equalTo(waifuImageView.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(10)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    private func resetGameProgress() {
        UserDefaults.standard.removeObject(forKey: gameSaveKey)
        
        waifuScore = 0
        userScore = 0
        updateScore(waifu: 0, user: 0)
        
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
        
        didResetProgress()
    }
    
    @objc private func scoreLabelTapped() {
        let haptic = UISelectionFeedbackGenerator()
        haptic.selectionChanged()
        
        let alert = UIAlertController(
            title: "ResetProgress".localize(),
            message: "ResetProgress.message".localize(),
            preferredStyle: .alert
        )
        
        let resetAction = UIAlertAction(title: "Reset".localize(), style: .destructive) { [weak self] _ in
            self?.resetGameProgress()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel".localize(), style: .cancel)
        
        alert.addAction(resetAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    @objc private func dismissGame() {
        dismiss(animated: true)
    }
    
    @objc private func showRules() {
        let alert = UIAlertController(title: "HowPlay".localize(), message: gameRules, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "GotIt".localize(), style: .default))
        present(alert, animated: true)
    }
    
    @objc private func waifuImageTapped() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        let fullScreenView = FullScreenImageView(image: waifuImageView.image)
        fullScreenView.vc = self
        fullScreenView.show(in: view)
    }
}
