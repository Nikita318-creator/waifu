import UIKit
import AVFoundation
import AVKit
import SafariServices
import StoreKit
import SnapKit

class ChatCell: UITableViewCell {
    static let identifier = "ChatCell"

    private var loopingPlayerManager: LoopingPlayerManager?

    // MARK: - UI Elements
    
    private let messageContainerView = UIView()
    private lazy var messageLabel: UITextView = {
        let messageTextView = UITextView()
        messageTextView.isEditable = false
        messageTextView.isScrollEnabled = false
        messageTextView.dataDetectorTypes = .link
        messageTextView.backgroundColor = .clear
        messageTextView.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        messageTextView.textColor = TelegramColors.textPrimary
        messageTextView.linkTextAttributes = [
            .foregroundColor: TelegramColors.link,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        messageTextView.delegate = self
        return messageTextView
    }()

    private let messageImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.isHidden = true
        imageView.isUserInteractionEnabled = true
        return imageView
    }()

    private let avatarView = UIImageView()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = TelegramColors.textSecondary // Используем вторичный цвет для статуса
        label.isHidden = true
        return label
    }()

    private let blurryOverlayView: BlurryOverlayView = {
        let view = BlurryOverlayView()
        view.isHidden = true
        view.isUserInteractionEnabled = true
        return view
    }()
    
    // MARK: - Voice Message Elements
    private let voiceContainerView = UIView()
    private let playPauseButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
        button.setImage(UIImage(systemName: "play.fill", withConfiguration: config), for: .normal)
        button.tintColor = .white
        return button
    }()
    
    private let waveStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fillEqually
        stack.spacing = 3
        return stack
    }()
    
    private let playIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .semibold, scale: .large)
        imageView.image = UIImage(systemName: "play.circle.fill")?.withConfiguration(config)
        imageView.isHidden = true
        return imageView
    }()
    
    private var displayLink: CADisplayLink?
    private let activeWaveColor = UIColor.white
    private let inactiveWaveColor = UIColor.white.withAlphaComponent(0.4)
    
    private var currentMessageText: String = ""
    
    weak var vc: UIViewController?
    var hideKeyboardHandler: (() -> Void)?
    var showSubsHandler: (() -> Void)?
    var reloadDataHandler: (() -> Void)?
    var avatarTappedHandler: (() -> Void)?

    private var messageID = ""
    private var isVideoCell = false
    private var videoID: String?
    private var isVoiceMessage = false
    private let service = GoogleTTSManager.shared

    var isSpeak = false {
        didSet {
            let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
            let imageName = isSpeak ? "pause.fill" : "play.fill"
            playPauseButton.setImage(UIImage(systemName: imageName, withConfiguration: config), for: .normal)
            
            if isSpeak {
                startDisplayLink()
            } else {
                stopDisplayLink()
            }
        }
    }
    
    private struct TelegramColors {
        static let userMessageBackground = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0)
        static let assistantMessageBackground = UIColor(red: 0.22, green: 0.22, blue: 0.24, alpha: 1.0)
        static let textPrimary = UIColor.white
        static let textSecondary = UIColor(red: 0.64, green: 0.64, blue: 0.66, alpha: 1.0)
        static let avatarBackground = UIColor(red: 0.30, green: 0.69, blue: 0.31, alpha: 1.0)
        static let link = UIColor(red: 0.25, green: 0.77, blue: 1.0, alpha: 1.0)
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
        updateTextForIPadIfNeeded()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCell() {
        backgroundColor = .clear
        selectionStyle = .none

        messageContainerView.layer.cornerRadius = 18
        messageContainerView.layer.masksToBounds = false
        messageContainerView.layer.shadowColor = UIColor.black.cgColor
        messageContainerView.layer.shadowOpacity = 0.1
        messageContainerView.layer.shadowOffset = CGSize(width: 0, height: 1)
        messageContainerView.layer.shadowRadius = 2
        contentView.addSubview(messageContainerView)

        avatarView.backgroundColor = TelegramColors.avatarBackground
        avatarView.layer.cornerRadius = 18
        avatarView.clipsToBounds = true
        avatarView.isUserInteractionEnabled = true
        avatarView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(avatarTapped)))

        contentView.addSubview(avatarView)

        if MainHelper.shared.currentAssistant?.avatarImageName.isEmpty ?? true {
            avatarView.image = UIImage(named: "1")
        } else {
            avatarView.image = UIImage(named: MainHelper.shared.currentAssistant?.avatarImageName ?? "") ?? UIImage.loadCustomAvatar(for: MainHelper.shared.currentAssistant?.avatarImageName ?? "")
        }

        messageContainerView.addSubview(messageLabel)
        messageContainerView.addSubview(messageImageView)
        messageImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(messageImageTapped)))

        loadingIndicator.color = TelegramColors.textSecondary
        loadingIndicator.isHidden = true
        messageContainerView.addSubview(loadingIndicator)
        messageContainerView.addSubview(statusLabel)

        messageImageView.addSubview(playIconImageView)
        messageImageView.bringSubviewToFront(playIconImageView)

        playIconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            let iconSize: CGFloat = isCurrentDeviceiPad() ? 80 : 60
            make.width.height.equalTo(iconSize)
        }
        
        let interaction = UIContextMenuInteraction(delegate: self)
        messageContainerView.addInteraction(interaction)
        
        messageImageView.addSubview(blurryOverlayView)
        
        blurryOverlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        setupAudioUI()
    }

    func configure(message: String, isUserMessage: Bool, photoID: String, needHideActionButtons: Bool, isVoiceMessage: Bool, id: String) {
        messageID = id
        isVideoCell = message.contains("[video]")
        loadingIndicator.stopAnimating()
        loadingIndicator.isHidden = true
        avatarView.isHidden = isUserMessage
        
        if !isUserMessage {
            avatarView.image = UIImage(named: MainHelper.shared.currentAssistant?.avatarImageName ?? "") ?? UIImage.loadCustomAvatar(for: MainHelper.shared.currentAssistant?.avatarImageName ?? "")
        }
        
        self.isVoiceMessage = isVoiceMessage
        self.currentMessageText = message
        
        if isVoiceMessage && !isUserMessage {
            messageLabel.isHidden = true
            messageImageView.isHidden = true
            voiceContainerView.isHidden = false
            messageContainerView.backgroundColor = TelegramColors.assistantMessageBackground
            configureAssistantVoiceMessage()
            
            // Проверяем: играет ли СЕЙЧАС именно это сообщение?
            self.isSpeak = service.isSpeaking && (service.currentSpeakinID == id)
            
            return
        } else {
            voiceContainerView.isHidden = true
        }
        
        if !photoID.isEmpty { // Если сообщение - картинка/видео
            messageLabel.isHidden = true
            messageImageView.isHidden = false
            
            // Логика подписки
            let isSubscribed = IAPService.shared.hasActiveSubscription
            if !isUserMessage && !isSubscribed {
                blurryOverlayView.isHidden = false
            } else {
                blurryOverlayView.isHidden = true
            }
            
            if message.contains("[new pic]") {
                messageImageView.image = RemoteRealmPhotoService.shared.getImage(by: photoID)
            } else if message.contains("[video]") {
                videoID = photoID
                playIconImageView.isHidden = false
                if let thumbnailData = RemoteRealmVideoService.shared.getThumbnailData(name: photoID) {
                    self.messageImageView.image = UIImage(data: thumbnailData)
                }
            } else {
                messageImageView.image = UIImage(named: photoID)
            }
            
            messageContainerView.backgroundColor = TelegramColors.assistantMessageBackground
            
            if isUserMessage {
                configureUserMessageForImage()
            } else {
                configureAssistantMessageForImage()
            }

        } else { // Если сообщение - текст
            messageLabel.isHidden = false
            messageImageView.isHidden = true
            messageLabel.text = message.trimmingCharacters(in: .whitespacesAndNewlines)
                        
            if isUserMessage {
                messageContainerView.backgroundColor = TelegramColors.userMessageBackground
                configureUserMessageForText()
            } else {
                messageContainerView.backgroundColor = TelegramColors.assistantMessageBackground
                configureAssistantMessageForText()
            }
        }
    }

    private func setupAudioUI() {
        messageContainerView.addSubview(voiceContainerView)
        voiceContainerView.addSubview(playPauseButton)
        voiceContainerView.addSubview(waveStackView)
        
        voiceContainerView.isHidden = true
        
        playPauseButton.addTarget(self, action: #selector(playPauseTapped), for: .touchUpInside)
        
        // Генерируем статичную рандомную волну
        for _ in 0..<20 {
            let bar = UIView()
            bar.backgroundColor = .white.withAlphaComponent(0.5)
            bar.layer.cornerRadius = 1.5
            waveStackView.addArrangedSubview(bar)
            bar.snp.makeConstraints { make in
                make.height.equalTo(CGFloat.random(in: 10...30))
                make.width.equalTo(3)
            }
        }
        
        // Подписываемся на события сервиса
        NotificationCenter.default.addObserver(self, selector: #selector(handleSpeechStarted), name: NSNotification.Name("updateAllAudioCellsOnStart"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleSpeechFinished), name: NSNotification.Name("updateAllAudioCellsOnFinish"), object: nil)
    }
    
    func configureLoader() {
        loadingIndicator.stopAnimating()
        loadingIndicator.isHidden = false
        loadingIndicator.startAnimating()
        
        statusLabel.text = MainHelper.shared.currentAIMessageType.rawValue.localize()
        statusLabel.isHidden = false
        statusLabel.textColor = TelegramColors.textSecondary
        
        messageLabel.isHidden = true
        messageImageView.isHidden = true
        voiceContainerView.isHidden = true

        avatarView.isHidden = false
        avatarView.image = UIImage(named: MainHelper.shared.currentAssistant?.avatarImageName ?? "") ?? UIImage.loadCustomAvatar(for: MainHelper.shared.currentAssistant?.avatarImageName ?? "")
        
        messageContainerView.backgroundColor = TelegramColors.assistantMessageBackground
        
        configureAssistantMessageForLoader()
    }

    private func configureAssistantMessageForLoader() {
        avatarView.isHidden = false
        
        let avatarViewSize: CGFloat = isCurrentDeviceiPad() ? 52 : 36
        
        avatarView.snp.remakeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(4)
            make.width.height.equalTo(avatarViewSize)
        }
        
        // Контейнер: фиксированная минимальная ширина для размещения индикатора и текста
        messageContainerView.snp.remakeConstraints { make in
            make.top.equalToSuperview().inset(4)
            make.bottom.equalToSuperview().inset(4)
            make.leading.equalTo(avatarView.snp.trailing).offset(8)
            make.trailing.lessThanOrEqualToSuperview().inset(80)
            make.width.greaterThanOrEqualTo(150) // Достаточно места для текста + индикатора
            make.height.equalTo(44) // Фиксированная высота для чистого лоадера
        }
        
        let padding: CGFloat = isCurrentDeviceiPad() ? 12 : 8
        let indicatorSize: CGFloat = isCurrentDeviceiPad() ? 24 : 20
        
        // Индикатор: слева
        loadingIndicator.snp.remakeConstraints { make in
            make.leading.equalToSuperview().inset(padding)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(indicatorSize)
        }
        
        statusLabel.snp.remakeConstraints { make in
            make.leading.equalTo(loadingIndicator.snp.trailing).offset(padding / 2)
            make.trailing.equalToSuperview().inset(padding)
            make.centerY.equalToSuperview()
        }
        
        messageLabel.snp.remakeConstraints { make in make.height.equalTo(0) }
        messageImageView.snp.remakeConstraints { make in make.height.equalTo(0) }
    }
    
    @objc private func avatarTapped() {
        avatarTappedHandler?()
    }
    
    private func makePlayer(from videoName: String) -> AVPlayer? {
        guard let data = RemoteRealmVideoService.shared.getVideoData(name: videoName) else {
            return nil
        }

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(videoName).mp4")

        try? data.write(to: tempURL, options: .atomic)

        return AVPlayer(url: tempURL)
    }
    
    // MARK: - Обработка нажатия на видео (Ключевой метод с лупом и аудио - Обновлено)
    @objc private func messageImageTapped() {
        guard let vc = vc else { return }
        
        hideKeyboardHandler?()
        
        guard IAPService.shared.hasActiveSubscription else {
            showSubsHandler?()
            return
        }
        
        if isVideoCell {
            AnalyticService.shared.logEvent(name: "messageImageTapped", properties: ["isVideo":"\(true)"])

            guard let player = makePlayer(from: videoID ?? "") else { return }
            
            let audioManager = LoopingAudioManager()
            self.loopingPlayerManager = LoopingPlayerManager(player: player, audioManager: audioManager)

            let playerVC = HardcorePlayerViewController()
            playerVC.player = player
            playerVC.modalPresentationStyle = .fullScreen
            playerVC.delegate = self
            
            vc.present(playerVC, animated: true) {
                player.play()
            }
        } else if let messageImage = messageImageView.image {
            AnalyticService.shared.logEvent(name: "messageImageTapped", properties: ["isVideo":"\(false)"])

            let fullScreenView = FullScreenImageView(image: messageImage)
            fullScreenView.vc = vc
            fullScreenView.show(in: vc.view)
        }
    }
    
    private func configureUserMessageForText() {
        avatarView.isHidden = true
        messageContainerView.snp.remakeConstraints { make in
            make.top.equalToSuperview().inset(4)
            make.bottom.equalToSuperview().inset(4)
            make.trailing.equalToSuperview().inset(16)
            make.leading.greaterThanOrEqualToSuperview().inset(80)
        }

        messageLabel.snp.remakeConstraints { make in
            make.top.leading.trailing.bottom.equalToSuperview().inset(12)
        }

        loadingIndicator.snp.remakeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    private func configureUserMessageForImage() {
        avatarView.isHidden = true
        
        let smallerSide = UIScreen.main.bounds.height < UIScreen.main.bounds.width ? UIScreen.main.bounds.height : UIScreen.main.bounds.width
        let photoSize: CGFloat = isCurrentDeviceiPad() ? smallerSide / 2 : 200
        
        messageContainerView.snp.remakeConstraints { make in
            make.top.equalToSuperview().inset(4)
            make.bottom.equalToSuperview().inset(4)
            make.trailing.equalToSuperview().inset(16)
            make.leading.greaterThanOrEqualToSuperview().inset(80)
            make.width.equalTo(photoSize)
            make.height.equalTo(photoSize)
        }
        
        messageImageView.snp.remakeConstraints { make in
            make.edges.equalToSuperview().inset(4)
        }
        
        messageLabel.snp.remakeConstraints { make in
            make.height.equalTo(0)
        }
        loadingIndicator.snp.remakeConstraints { make in
            make.height.equalTo(0)
        }
    }

    private func configureAssistantMessageForText() {
        avatarView.isHidden = false
        
        let avatarViewSize: CGFloat = isCurrentDeviceiPad() ? 52 : 36
        avatarView.snp.remakeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(4)
            make.width.height.equalTo(avatarViewSize)
        }

        messageContainerView.backgroundColor = TelegramColors.assistantMessageBackground
        messageContainerView.snp.remakeConstraints { make in
            make.top.equalToSuperview().inset(4)
            make.bottom.equalToSuperview().inset(4)
            make.leading.equalTo(avatarView.snp.trailing).offset(8)
            make.trailing.lessThanOrEqualToSuperview().inset(80)
        }

        messageLabel.snp.remakeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(12)
            make.bottom.equalToSuperview().inset(8)
        }

        if !loadingIndicator.isHidden {
            messageContainerView.snp.remakeConstraints { make in
                make.top.equalToSuperview().inset(4)
                make.bottom.equalToSuperview().inset(4)
                make.leading.equalTo(avatarView.snp.trailing).offset(8)
                make.trailing.lessThanOrEqualToSuperview().inset(80)
                make.width.greaterThanOrEqualTo(200)
            }
            
            messageLabel.snp.remakeConstraints { make in
                make.top.leading.trailing.equalToSuperview().inset(12)
                make.bottom.equalToSuperview().inset(12)
                make.height.equalTo(20)
            }

            loadingIndicator.snp.remakeConstraints { make in
                make.center.equalToSuperview()
                make.width.height.equalTo(20)
            }
        }
    }
    
    private func configureAssistantMessageForImage() {
        avatarView.isHidden = false

        let smallerSide = UIScreen.main.bounds.height < UIScreen.main.bounds.width ? UIScreen.main.bounds.height : UIScreen.main.bounds.width
        let photoSize: CGFloat = isCurrentDeviceiPad() ? smallerSide / 2 : 200
        let avatarViewSize: CGFloat = isCurrentDeviceiPad() ? 52 : 36
        
        avatarView.snp.remakeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(4)
            make.width.height.equalTo(avatarViewSize)
        }

        messageContainerView.backgroundColor = TelegramColors.assistantMessageBackground
        messageContainerView.snp.remakeConstraints { make in
            make.top.equalToSuperview().inset(4)
            make.bottom.equalToSuperview().inset(4)
            make.leading.equalTo(avatarView.snp.trailing).offset(8)
            make.trailing.lessThanOrEqualToSuperview().inset(80)
            make.width.equalTo(photoSize)
            make.height.equalTo(photoSize)
        }
        
        messageImageView.snp.remakeConstraints { make in
            make.edges.equalToSuperview().inset(4)
        }
        
        messageLabel.snp.remakeConstraints { make in
            make.height.equalTo(0)
        }
        loadingIndicator.snp.remakeConstraints { make in
            make.height.equalTo(0)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        
        if let manager = self.loopingPlayerManager {
            manager.player.pause()
        }
        self.loopingPlayerManager = nil
        
        // СБРАСЫВАЕМ АУДИО СТАТУС (Важно!)
        isSpeak = false
        voiceContainerView.isHidden = true
        
        // Сброс остальных элементов
        loadingIndicator.stopAnimating()
        loadingIndicator.isHidden = true
        messageLabel.isHidden = false
        messageImageView.isHidden = true
        messageImageView.image = nil
        statusLabel.isHidden = true
        statusLabel.text = nil
        playIconImageView.isHidden = true
        blurryOverlayView.isHidden = true
    }
    
    private func configureAssistantVoiceMessage() {
        avatarView.isHidden = false
        
        let avatarViewSize: CGFloat = isCurrentDeviceiPad() ? 52 : 36
        avatarView.snp.remakeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(4)
            make.width.height.equalTo(avatarViewSize)
        }
        
        messageContainerView.snp.remakeConstraints { make in
            make.top.bottom.equalToSuperview().inset(4)
            make.leading.equalTo(avatarView.snp.trailing).offset(8)
            make.width.equalTo(220)
            make.height.equalTo(50)
        }
        
        voiceContainerView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        playPauseButton.snp.remakeConstraints { make in
            make.leading.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(32)
        }
        
        waveStackView.snp.remakeConstraints { make in
            make.leading.equalTo(playPauseButton.snp.trailing).offset(12)
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.height.equalTo(30)
        }
    }
    
    @objc private func playPauseTapped() {
        AnalyticService.shared.logEvent(name: "audio message playPause button Tapped", properties: ["isSpeak":"\(isSpeak)"])

        if isSpeak {
            service.stopSpeaking()
            isSpeak = false
        } else {
            service.stopSpeaking(needNotifyOthers: false)
            service.currentSpeakinID = messageID
            service.speak(text: currentMessageText)
            isSpeak = true
        }
    }
    
    @objc private func handleSpeechStarted() {
        DispatchQueue.main.async {
            self.isSpeak = (self.service.currentSpeakinID == self.messageID)
        }
    }

    @objc private func handleSpeechFinished() {
        DispatchQueue.main.async { [weak self] in
            self?.isSpeak = false
        }
    }
    
    @objc private func updateWaveProgress() {
        guard isSpeak,
              let player = service.audioPlayer,
              let currentItem = player.currentItem else {
            stopDisplayLink()
            return
        }
        
        let duration = CMTimeGetSeconds(currentItem.duration)
        let currentTime = CMTimeGetSeconds(player.currentTime())
        
        guard duration > 0 else { return }
        
        // Вычисляем процент прогресса (0.0 - 1.0)
        let progress = CGFloat(currentTime / duration)
        let totalBars = waveStackView.arrangedSubviews.count
        let activeBarsCount = Int(progress * CGFloat(totalBars))
        
        // Красим бары
        for (index, bar) in waveStackView.arrangedSubviews.enumerated() {
            bar.backgroundColor = index <= activeBarsCount ? activeWaveColor : inactiveWaveColor
        }
    }
    
    private func startDisplayLink() {
        displayLink?.invalidate()
        displayLink = CADisplayLink(target: self, selector: #selector(updateWaveProgress))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
        
        // Сбрасываем цвета к неактивным
        waveStackView.arrangedSubviews.forEach { $0.backgroundColor = inactiveWaveColor }
    }
    
    deinit {
        service.currentSpeakinID = nil
        service.stopSpeaking()
    }
}

// MARK: - AVPlayerViewControllerDelegate для очистки менеджера после закрытия (Обновлено: Важно для KVO)
extension ChatCell: AVPlayerViewControllerDelegate {
    
    func playerViewControllerWillDisappear(_ playerViewController: AVPlayerViewController) {
        playerViewController.player?.pause()
        
        if let manager = self.loopingPlayerManager {
            manager.player.removeObserver(manager, forKeyPath: "rate")
        }
        
        self.loopingPlayerManager = nil
    }
}

// MARK: - UIContextMenuInteractionDelegate
extension ChatCell: UIContextMenuInteractionDelegate {
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        
        let snapshot = messageContainerView.snapshotView(afterScreenUpdates: true)
        let originalSize = messageContainerView.bounds.size
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: { [weak self] in
            guard let self = self else { return nil }
            
            let controller = UIViewController()
            
            // 1. ОБЩАЯ ПАНЕЛЬ С БЛЮРОМ (Как была)
            let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
            let reactionsContainer = UIVisualEffectView(effect: blurEffect)
            reactionsContainer.layer.cornerRadius = 25
            reactionsContainer.clipsToBounds = true
            
            // 2. ОТДЕЛЬНЫЙ ФОН ЧИСТО ПОД СМАЙЛЫ (Внутри блюра)
            let innerDarkBackground = UIView()
            innerDarkBackground.backgroundColor = UIColor(white: 0, alpha: 0.9)
            innerDarkBackground.layer.cornerRadius = 20
            
            let stackView = UIStackView()
            stackView.axis = .horizontal
            stackView.spacing = 10
            stackView.distribution = .fillEqually
            
            let reactions = [
                (emoji: "❤️", id: "heart"),
                (emoji: "👍", id: "up"),
                (emoji: "👎", id: "down"),
                (emoji: "😂", id: "laugh"),
                (emoji: "😭", id: "cry"),
                (emoji: "😡", id: "angry")
            ]
            
            reactions.forEach { item in
                let btn = UIButton(type: .system)
                btn.setTitle(item.emoji, for: .normal)
                btn.titleLabel?.font = .systemFont(ofSize: 28)
                btn.addAction(UIAction { [weak self] _ in
                    guard let self = self else { return }
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    AnalyticService.shared.logEvent(name: "UIContext Reaction Tap", properties: ["emoji_id": item.id])
                    interaction.dismissMenu()
                    self.reloadDataHandler?()
                }, for: .touchUpInside)
                stackView.addArrangedSubview(btn)
            }
            
            controller.view.addSubview(reactionsContainer)
            reactionsContainer.contentView.addSubview(innerDarkBackground) // Кладем фон на блюр
            innerDarkBackground.addSubview(stackView) // Смайлы на фон
            
            if let snap = snapshot {
                controller.view.addSubview(snap)
                
                snap.snp.makeConstraints { make in
                    make.bottom.equalToSuperview()
                    make.centerX.equalToSuperview()
                    make.size.equalTo(originalSize)
                }
                
                reactionsContainer.snp.makeConstraints { make in
                    make.bottom.equalTo(snap.snp.top).offset(-15)
                    make.centerX.equalToSuperview()
                    make.width.equalTo(300)
                    make.height.equalTo(60)
                }
            }
            
            // Констрейнты для темного фона внутри блюра
            innerDarkBackground.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(5) // Небольшой отступ, чтобы блюр был виден по краям
            }
            
            stackView.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10))
            }
            
            controller.preferredContentSize = CGSize(width: max(300, originalSize.width),
                                                     height: originalSize.height + 85)
            return controller
            
        }) { [weak self] _ in
            
            // --- ТВОЙ ОРИГИНАЛЬНЫЙ КОД БЕЗ ИЗМЕНЕНИЙ ---
            let deleteAction = UIAction(
                title: "Delete".localize(),
                image: UIImage(systemName: "trash"),
                attributes: .destructive
            ) { _ in
                guard let self = self else { return }
                AnalyticService.shared.logEvent(name: "UIContext delete", properties: ["":""])
                MessageHistoryService().deleteMessage(id: self.messageID)
                self.reloadDataHandler?()
            }
            
            return UIMenu(title: "", children: [
                UIAction(title: "Copy".localize(), image: UIImage(systemName: "doc.on.doc")) { _ in
                    AnalyticService.shared.logEvent(name: "UIContext Copy", properties: ["":""])
                    if !(self?.messageLabel.isHidden ?? true) {
                        UIPasteboard.general.string = self?.messageLabel.text ?? " "
                    }
                },
                UIAction(title: "SelectText".localize(), image: UIImage(systemName: "text.cursor"), handler: { _ in
                    AnalyticService.shared.logEvent(name: "UIContext SelectText", properties: ["":""])
                    guard !(self?.messageLabel.isHidden ?? true) else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                        guard let self = self else { return }
                        self.messageLabel.isSelectable = true
                        self.messageLabel.becomeFirstResponder()

                        if let textRange = self.messageLabel.textRange(
                            from: self.messageLabel.beginningOfDocument,
                            to: self.messageLabel.endOfDocument
                        ) {
                            self.messageLabel.selectedTextRange = textRange
                        }
                    }
                }),
                UIAction(title: "Share".localize(), image: UIImage(systemName: "square.and.arrow.up")) { _ in
                    AnalyticService.shared.logEvent(name: "UIContext Share", properties: ["":""])
                    
                    var activityItems: [Any] = []
                    if let image = self?.messageImageView.image, !(self?.messageImageView.isHidden ?? true) {
                        guard IAPService.shared.hasActiveSubscription else {
                            self?.showSubsHandler?()
                            return
                        }
                        activityItems.append(image)
                        activityItems.append("\("ResourceImage".localize()) \(SubsView.Constants.appStoreUrl)")
                    } else if let textToShare = self?.messageLabel.text, !(self?.messageLabel.isHidden ?? true) {
                        activityItems.append(textToShare)
                        activityItems.append("\("ResourceText".localize()) \(SubsView.Constants.appStoreUrl)")
                    }
                    
                    if !activityItems.isEmpty, let vc = self?.vc {
                        let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
                        activityViewController.popoverPresentationController?.sourceView = self?.messageContainerView
                        vc.present(activityViewController, animated: true, completion: nil)
                    }
                },
                deleteAction
            ])
        }
    }
}

// MARK: - UITextViewDelegate
extension ChatCell: UITextViewDelegate {
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if interaction == .invokeDefaultAction {
            AnalyticService.shared.logEvent(name: "Link tapped", properties: ["url": URL.absoluteString])
            if URL.scheme == "mailto" || URL.scheme == "tel" {
                UIApplication.shared.open(URL)
            } else {
                let safariVC = SFSafariViewController(url: URL)
                safariVC.modalPresentationStyle = .pageSheet
                self.vc?.present(safariVC, animated: true)
            }
        }
        return false
    }
    
    // Добавляем обработку для сброса isSelectable
    func textViewDidEndEditing(_ textView: UITextView) {
        textView.isSelectable = false
    }
}

// MARK: - Device check
extension ChatCell {    
    private func updateTextForIPadIfNeeded() {
        if isCurrentDeviceiPad() {
            messageLabel.font = UIFont.systemFont(ofSize: 20, weight: .regular)
            statusLabel.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        }
    }
}
