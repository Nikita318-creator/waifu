import UIKit
import AVFoundation
import AVKit
import SafariServices
import StoreKit
import SnapKit

class ChatCell: UITableViewCell {
    static let identifier = "ChatCell"

    let reactions = [
        (emoji: "❤️", id: "heart"),
        (emoji: "👍", id: "up"),
        (emoji: "👎", id: "down"),
        (emoji: "😂", id: "laugh"),
        (emoji: "😭", id: "cry"),
        (emoji: "😡", id: "angry")
    ]
    
    private let reactionContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.2, alpha: 1.0) // Темный фон реакции
        view.layer.cornerRadius = 10
        view.isHidden = true
        return view
    }()

    private let reactionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        return label
    }()
    
    private var overlayView: UIView?

    private var loopingPlayerManager: LoopingPlayerManager?

    // MARK: - UI Elements
    
    private let messageContainerView = UIView()
    private lazy var messageLabel: UITextView = {
        let messageTextView = UITextView()
        messageTextView.isEditable = false
        messageTextView.isSelectable = false  // <-- вот эта строка вырубает выделение по long press
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
        
//        let interaction = UIContextMenuInteraction(delegate: self)
//        messageContainerView.addInteraction(interaction)
        setupLongPressForReactions()
        
        messageImageView.addSubview(blurryOverlayView)
        
        blurryOverlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        setupAudioUI()
        
        contentView.addSubview(reactionContainer)
        reactionContainer.addSubview(reactionLabel)
        reactionLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4))
        }
    }

    func configure(message: String, isUserMessage: Bool, photoID: String, needHideActionButtons: Bool, isVoiceMessage: Bool, reaction: String?, id: String) {
        messageID = id
        isVideoCell = message.contains("[video]")
        loadingIndicator.stopAnimating()
        loadingIndicator.isHidden = true
        avatarView.isHidden = isUserMessage
        
        if let reactionId = reaction,
           let emoji = reactions.first(where: { $0.id == reactionId })?.emoji {
            
            reactionContainer.isHidden = false
            reactionLabel.text = emoji
            
            if isUserMessage {
                reactionContainer.backgroundColor = TelegramColors.userMessageBackground
            } else {
                reactionContainer.backgroundColor = TelegramColors.assistantMessageBackground
            }
            
            reactionContainer.snp.remakeConstraints { make in
                make.bottom.equalTo(messageContainerView.snp.bottom).offset(6)
                if isUserMessage {
                    make.trailing.equalTo(messageContainerView.snp.trailing).offset(-8)
                } else {
                    make.leading.equalTo(messageContainerView.snp.leading).offset(8)
                }
                make.height.equalTo(22)
            }
        } else {
            reactionContainer.isHidden = true
        }
        
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
        reactionContainer.isHidden = true
        reactionLabel.text = nil
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
extension ChatCell {
    
    func setupLongPressForReactions() {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.5
        messageContainerView.isUserInteractionEnabled = true
        messageContainerView.addGestureRecognizer(longPress)
    }
        
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began,
              let window = window,
              let snapshot = messageContainerView.snapshotView(afterScreenUpdates: true)
        else { return }
        
        let overlay = UIView(frame: window.bounds)
        overlay.backgroundColor = .clear
        
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = overlay.bounds
        blurView.alpha = 0
        overlay.addSubview(blurView)
        
        let tapToDismiss = UITapGestureRecognizer(target: self, action: #selector(dismissOverlay(_:)))
        overlay.addGestureRecognizer(tapToDismiss)
        
        let cellFrameInWindow = messageContainerView.convert(messageContainerView.bounds, to: window)
        
        snapshot.frame = cellFrameInWindow
        snapshot.layer.cornerRadius = messageContainerView.layer.cornerRadius
        snapshot.clipsToBounds = true
        snapshot.layer.shadowColor = UIColor.black.cgColor
        snapshot.layer.shadowOpacity = 0.2
        snapshot.layer.shadowOffset = CGSize(width: 0, height: 2)
        snapshot.layer.shadowRadius = 6
        overlay.addSubview(snapshot)
        
        // --- РАСЧЕТ ПОЗИЦИИ И ШИРИНЫ ---
        let screenWidth = window.bounds.width
        let screenHeight = window.bounds.height
        let sidePadding: CGFloat = 24
        let bottomPadding: CGFloat = 40 // Отступ от низа экрана
        let topPadding: CGFloat = 60    // Отступ от верха экрана
        let menuWidth: CGFloat = screenWidth * 0.52
        
        var targetCenterX = cellFrameInWindow.midX
        if targetCenterX - (menuWidth / 2) < sidePadding {
            targetCenterX = sidePadding + (menuWidth / 2)
        }
        if targetCenterX + (menuWidth / 2) > screenWidth - sidePadding {
            targetCenterX = screenWidth - sidePadding - (menuWidth / 2)
        }
        
        let reactionsWidthEstimate = CGFloat(reactions.count) * 40 + 80
        var reactionsWidth = max(reactionsWidthEstimate, menuWidth * 0.9)
        reactionsWidth = min(reactionsWidth, screenWidth - sidePadding * 2)
        
        // --- РЕАКЦИИ ---
        let reactionsContainer = UIView()
        reactionsContainer.backgroundColor = UIColor(white: 0.15, alpha: 0.95)
        reactionsContainer.layer.cornerRadius = 28
        overlay.addSubview(reactionsContainer)
        
        let reactionsStack = UIStackView()
        reactionsStack.axis = .horizontal
        reactionsStack.spacing = 20
        reactionsStack.distribution = .fillProportionally
        reactionsStack.alignment = .center
        
        for (index, item) in reactions.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(item.emoji, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 20) // Оставил как в твоем коде
            button.titleLabel?.adjustsFontSizeToFitWidth = true
            button.titleLabel?.minimumScaleFactor = 0.7
            button.tag = index
            button.addTarget(self, action: #selector(selectReaction(_:)), for: .touchUpInside)
            reactionsStack.addArrangedSubview(button)
        }
        
        reactionsContainer.addSubview(reactionsStack)
        reactionsStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 24, bottom: 10, right: 24))
        }
        
        // --- МЕНЮ ДЕЙСТВИЙ ---
        let actionsContainer = UIView()
        actionsContainer.backgroundColor = UIColor(white: 0.15, alpha: 0.95)
        actionsContainer.layer.cornerRadius = 18
        actionsContainer.clipsToBounds = true
        overlay.addSubview(actionsContainer)
        
        let actionsStack = UIStackView()
        actionsStack.axis = .vertical
        actionsStack.spacing = 0
        
        let actionsData: [(title: String, image: String, destructive: Bool, handler: () -> Void)] = [
            ("Copy".localize(), "doc.on.doc", false, { [weak self] in
                guard let self = self else { return }
                AnalyticService.shared.logEvent(name: "UIContext Copy", properties: ["":""])
                if !self.messageLabel.isHidden {
                    UIPasteboard.general.string = self.messageLabel.text ?? " "
                }
                self.dismissOverlay()
            }),
            ("SelectText".localize(), "text.cursor", false, { [weak self] in
                guard let self = self else { return }
                AnalyticService.shared.logEvent(name: "UIContext SelectText", properties: ["":""])
                guard !self.messageLabel.isHidden else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.messageLabel.isSelectable = true
                    self.messageLabel.becomeFirstResponder()
                    if let textRange = self.messageLabel.textRange(from: self.messageLabel.beginningOfDocument, to: self.messageLabel.endOfDocument) {
                        self.messageLabel.selectedTextRange = textRange
                    }
                }
                self.dismissOverlay()
            }),
            ("Share".localize(), "square.and.arrow.up", false, { [weak self] in
                guard let self = self else { return }
                AnalyticService.shared.logEvent(name: "UIContext Share", properties: ["":""])
                var activityItems: [Any] = []
                if let image = self.messageImageView.image, !self.messageImageView.isHidden {
                    guard IAPService.shared.hasActiveSubscription else {
                        self.showSubsHandler?()
                        self.dismissOverlay()
                        return
                    }
                    activityItems.append(image)
                    activityItems.append("\("ResourceImage".localize()) \(SubsView.Constants.appStoreUrl)")
                } else if let textToShare = self.messageLabel.text, !self.messageLabel.isHidden {
                    activityItems.append(textToShare)
                    activityItems.append("\("ResourceText".localize()) \(SubsView.Constants.appStoreUrl)")
                }
                if !activityItems.isEmpty, let vc = self.vc {
                    let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
                    activityViewController.popoverPresentationController?.sourceView = self.messageContainerView
                    vc.present(activityViewController, animated: true, completion: nil)
                }
                self.dismissOverlay()
            }),
            ("Delete".localize(), "trash", true, { [weak self] in
                guard let self = self else { return }
                AnalyticService.shared.logEvent(name: "UIContext delete", properties: ["":""])
                MessageHistoryService().deleteMessage(id: self.messageID)
                self.reloadDataHandler?()
                self.dismissOverlay()
            })
        ]
        
        for (index, data) in actionsData.enumerated() {
            let button = createActionButton(title: data.title, imageName: data.image, destructive: data.destructive) { data.handler() }
            actionsStack.addArrangedSubview(button)
            if index < actionsData.count - 1 {
                let separator = UIView()
                separator.backgroundColor = UIColor(white: 0.3, alpha: 0.5)
                separator.snp.makeConstraints { $0.height.equalTo(0.5) }
                actionsStack.addArrangedSubview(separator)
            }
        }
        
        actionsContainer.addSubview(actionsStack)
        actionsStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16))
        }
        
        // --- УМНЫЕ КОНСТРЕЙНТЫ (ЧТОБЫ НЕ ВЫЛЕТАЛО ЗА ЭКРАН) ---
        
        reactionsContainer.snp.makeConstraints { make in
            make.centerX.equalTo(overlay.snp.leading).offset(targetCenterX)
            make.width.equalTo(reactionsWidth)
            make.height.equalTo(60)
            
            // Пытаемся быть сверху сообщения
            make.bottom.equalTo(snapshot.snp.top).offset(-16).priority(.high)
            // Но не выше верхнего края экрана
            make.top.greaterThanOrEqualTo(overlay.snp.top).offset(topPadding).priority(.required)
        }
        
        actionsContainer.snp.makeConstraints { make in
            make.centerX.equalTo(overlay.snp.leading).offset(targetCenterX)
            make.width.equalTo(menuWidth)
            
            // Пытаемся быть снизу сообщения
            make.top.equalTo(snapshot.snp.bottom).offset(16).priority(.high)
            // НО: нижний край меню НЕ ДОЛЖЕН уходить за нижний край экрана (priority .required)
            make.bottom.lessThanOrEqualTo(overlay.snp.bottom).offset(-bottomPadding).priority(.required)
        }
        
        window.addSubview(overlay)
        self.overlayView = overlay
        
        // --- АНИМАЦИЯ ---
        let startTransform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        reactionsContainer.transform = startTransform
        actionsContainer.transform = startTransform
        reactionsContainer.alpha = 0
        actionsContainer.alpha = 0
        
        UIView.animate(withDuration: 0.25) {
            blurView.alpha = 1.0
        }
        
        UIView.animate(withDuration: 0.45, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 1.0, options: .curveEaseOut) {
            reactionsContainer.transform = .identity
            actionsContainer.transform = .identity
            reactionsContainer.alpha = 1.0
            actionsContainer.alpha = 1.0
            snapshot.transform = CGAffineTransform(scaleX: 1.03, y: 1.03)
        }
    }
    
    @objc private func dismissOverlay(_ gesture: UITapGestureRecognizer? = nil) {
        overlayView?.removeFromSuperview()
        overlayView = nil
        messageLabel.isSelectable = false  // <-- СБРОС ЗДЕСЬ, чтоб после любого закрытия текст не был selectable
    }
    
    @objc private func selectReaction(_ sender: UIButton) {
        let index = sender.tag
        guard index >= 0 && index < reactions.count else { return }
        let selected = reactions[index]
        
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        AnalyticService.shared.logEvent(name: "UIContext Reaction Tap", properties: ["emoji_id": selected.id])
        MessageHistoryService().updateReaction(id: messageID, reaction: selected.id)
        reloadDataHandler?()
        dismissOverlay()
    }
    
    private func createActionButton(title: String, imageName: String, destructive: Bool = false, handler: @escaping () -> Void) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setImage(UIImage(systemName: imageName), for: .normal)
        button.tintColor = destructive ? .systemRed : .white
        button.setTitleColor(destructive ? .systemRed : .white, for: .normal)
        button.contentHorizontalAlignment = .left
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 8)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 0)
        button.addAction(UIAction { _ in handler() }, for: .touchUpInside)
        button.heightAnchor.constraint(equalToConstant: 48).isActive = true
        return button
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
