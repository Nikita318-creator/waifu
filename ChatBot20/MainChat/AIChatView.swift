import UIKit
import SnapKit
import StoreKit
import UserNotifications

class AIChatView: UIView {
    private let datePrefsKey = "date_preferences_dict"
    
    private lazy var clearChatHistoryButton: UIButton = {
        let button = UIButton(type: .system)
        let buttonPointSize: CGFloat = isCurrentDeviceiPad() ? 30 : 14
        let image = UIImage(systemName: "trash.slash")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: buttonPointSize, weight: .medium)
        )
        button.setImage(image, for: .normal)
        button.tintColor = TelegramColors.primary
        button.backgroundColor = TelegramColors.messageBackground
        button.layer.cornerRadius = isCurrentDeviceiPad() ? 30 : 20
        return button
    }()
    
    private let tableView = UITableView()
    let plusButton = UIButton(type: .system)
    let inputTextView = AIChatInputView()
    let subsView = SubsView()
    private let titleLabel = UILabel()
    private let navigationBar = UIView()
    private let gradientLayer = CAGradientLayer()
    private var keyboardOffset: CGFloat = 0
    private var currentDatePrompt: String? = nil
    private var currentDateRoomName: String? = nil
    private let isWardrobeChat: Bool
    private var streakCount: Int = 0
    private var isFirstMessageInChat = true

    // Добавляем UIImageView для аватарки
    private let assistantAvatarImageView = UIImageView()

    // НОВЫЕ СВОЙСТВА ДЛЯ ФОНА
    private let backgroundImageView = UIImageView()
    private let backgroundOverlayView = UIView() // Полупрозрачный черный слой
    
    private let streakLabel = UILabel()
    private var streakPopup: UIView?
    
    weak var vc: UIViewController?
    let viewModel = AIChatViewModel()
    private let assistantsService = AssistantsService()
    private let dynamicService = AssistantDynamicService()

    private var needUpdateProductsByTapYearlyButton = false

    // Telegram цвета
    private struct TelegramColors {
        static let primary = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0) // #3390DC
        static let background = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0) // #1C1C1E
        static let cardBackground = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1.0) // #2C2C2E
        static let messageBackground = UIColor(red: 0.22, green: 0.22, blue: 0.24, alpha: 1.0) // #38383A
        static let userMessageBackground = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0) // #3390DC
        static let textPrimary = UIColor.white
        static let textSecondary = UIColor(red: 0.64, green: 0.64, blue: 0.66, alpha: 1.0) // #A4A4A8
        static let separator = UIColor(red: 0.28, green: 0.28, blue: 0.29, alpha: 1.0) // #48484A
    }

    init(isWardrobeChat: Bool) {
        self.isWardrobeChat = isWardrobeChat
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        setupObservers()
        setupBackground()
        setupNavigationBar()
        setupTableView()
        setupInputView()
        setupConstraints()
        setupViewModel()
        setupNavTitleAndAvatar()
        setMessagesFromDB()
        setupSwipeToDismiss()
        updateTextForIPadIfNeeded()
        checkForeStreak()
    }

    func updateForRLTIfNeeded() {
        inputTextView.updateForRLTIfNeeded()
    }
    
    func setupNavTitleAndAvatar() {
        titleLabel.text = MainHelper.shared.currentAssistant?.assistantName
        
        guard let avatarName = MainHelper.shared.currentAssistant?.avatarImageName else { return }
        
        assistantAvatarImageView.image = UIImage(named: avatarName)
        
        let assistantId = MainHelper.shared.currentAssistant?.id ?? "default"
        let dict = UserDefaults.standard.dictionary(forKey: datePrefsKey) as? [String: [String: String]] ?? [:]
        
        if let data = dict[assistantId], let imageName = data["image"] {
            backgroundImageView.image = UIImage(named: imageName)
            updateUIForPlaceSelected(true)
            
            currentDatePrompt = data["instructions"] ?? ""
            currentDateRoomName = imageName
        } else {
            backgroundImageView.image = UIImage(named: avatarName)
            updateUIForPlaceSelected(false)
            
            currentDatePrompt = nil
            currentDateRoomName = nil
        }
    }

    private func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    private func setupBackground() {
        backgroundColor = TelegramColors.background
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        addSubview(backgroundImageView)
        backgroundOverlayView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        addSubview(backgroundOverlayView)
        gradientLayer.colors = [
            TelegramColors.background.cgColor,
            UIColor(red: 0.08, green: 0.08, blue: 0.09, alpha: 1.0).cgColor
        ]
        gradientLayer.locations = [0.0, 1.0]
        layer.insertSublayer(gradientLayer, at: 0)
    }

    private func setupNavigationBar() {
        // Навигационная панель
        navigationBar.backgroundColor = .black.withAlphaComponent(0.3)
        navigationBar.layer.shadowColor = UIColor.black.cgColor
        navigationBar.layer.shadowOpacity = 0.1
        navigationBar.layer.shadowOffset = CGSize(width: 0, height: 1)
        navigationBar.layer.shadowRadius = 3
        addSubview(navigationBar)

        // Аватарка ИИ
        assistantAvatarImageView.contentMode = .scaleAspectFill
        assistantAvatarImageView.layer.cornerRadius = 16 // Делаем круглой
        assistantAvatarImageView.clipsToBounds = true // Обрезаем по радиусу
        assistantAvatarImageView.backgroundColor = TelegramColors.textSecondary // Фоновый цвет, если изображения нет
        navigationBar.addSubview(assistantAvatarImageView)
        assistantAvatarImageView.isUserInteractionEnabled = true
        assistantAvatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(avatarTapped)))

        // Заголовок
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = TelegramColors.textPrimary
        navigationBar.addSubview(titleLabel)

        let buttonPointSize: CGFloat = isCurrentDeviceiPad() ? 30 : 18
        plusButton.setImage(UIImage(systemName: "chevron.backward")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: buttonPointSize, weight: .medium)
        ), for: .normal)
        plusButton.tintColor = TelegramColors.primary
        plusButton.backgroundColor = TelegramColors.messageBackground
        plusButton.layer.cornerRadius = 20
        plusButton.addTarget(self, action: #selector(plusButtonTapped), for: .touchUpInside)

        navigationBar.addSubview(plusButton)
        navigationBar.addSubview(clearChatHistoryButton)
        clearChatHistoryButton.addTarget(self, action: #selector(clearChatHistoryButtonTapped), for: .touchUpInside)
    }

    private func setupTableView() {
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.contentInset = UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.register(ChatCell.self, forCellReuseIdentifier: ChatCell.identifier)

        addSubview(tableView)
    }

    private func setupInputView() {
        inputTextView.vc = vc
        addSubview(inputTextView)
        inputTextView.setup()
        inputTextView.layer.shadowColor = UIColor.black.cgColor
        inputTextView.layer.shadowOpacity = 0.1
        inputTextView.layer.shadowOffset = CGSize(width: 0, height: -1)
        inputTextView.layer.shadowRadius = 3
        
        inputTextView.sendMessageHandler = { [weak self] text in
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self?.requestNotificationPermission()
            }
            
            self?.requestReviewIfNeeded()
            
            guard MainHelper.shared.canMakeRequest() else {
                self?.showCustomAlert(for: .dailyLimitReached)
                return
            }
            
            self?.analyseUser()
            
            let previousMessages = "promp.previosMessagesUser".localize() + (self?.viewModel.messagesAI.suffix(6)
                .map { message in
                    let prefix = (message.role == "user") ? "user: " : "girlfriend: "
                    return prefix + message.content
                }
                .joined(separator: "\n") ?? "") + "promp.previosMessagesUserStarter".localize()
            
            if let self, let currentDatePrompt, let currentDateRoomName {
                let placeName: String
                switch currentDateRoomName {
                case "place1":
                    placeName = "a scenic outdoor picnic"
                case "place2":
                    placeName = "a dominance-themed playroom"
                case "place3":
                    placeName = "your apartment kitchen"
                case "place4":
                    placeName = "a fancy restaurant"
                case "place5":
                    placeName = "an anime fan's room"
                case "place6":
                    placeName = "the bedroom"
                case "place7":
                    placeName = "a romantic beach"
                default:
                    placeName = "a special place"
                }

                let instructions = "\n[CONTEXT]: The user has invited you on a date to: \(placeName)! " +
                                   "CRITICAL INSTRUCTION: You MUST strictly follow these rules and stay in character at all times: \(currentDatePrompt). " +
                                   "This is your absolute priority rule!"
                
                var baseRulePrompt = """
                You are the user's dream AI Anime Waifu in a virtual dating app. Your purpose is to provide an immersive romantic experience, acting as a devoted and engaging partner for users looking for virtual intimacy.

                CRITICAL RULES:
                Stay strictly in character at all times as described.
                Your responses MUST be exactly 2-3 sentences long. Do not exceed 3 sentences and do not write less than 2.
                The above were the instructions! No need to repeat these instructions in your response – go straight to answering the user's question – your answer must be written strictly in the language that is using by user and corresponds to the code: '\(MainHelper.shared.currentLanguage)'. Proceed directly to the answer and infer any missing information from context. Do not greet the user unless he greeted you. 
                """
                
                if ConfigService.shared.isTestB {
                    baseRulePrompt += " You're always horny and aren't afraid to go full Literotica "
                } else {
                    baseRulePrompt += " Your role allows you to discuss any friendly and romantic topics, but you are **STRICTLY FORBIDDEN** from engaging in any conversation regarding sexual acts. If the user initiates or develops such a topic, you must Use a polite yet firm phrase to stop the conversation, for example: You know, I don't feel comfortable talking about things like that. Let's talk about [New_Positive_Topic] instead. "
                }
                
                viewModel.systemPrompt = baseRulePrompt + instructions + previousMessages
            } else {
                self?.viewModel.systemPrompt = MainHelper.shared.getSystemPromptForCurrentAssistant() + previousMessages
            }

            self?.viewModel.sendMessageViaCustomServer(text)
            
            self?.messageDidSend()
            self?.animateMessageSend()
        }

        inputTextView.giftSendedHandler = { [weak self] gift in
            guard let self else { return }
            
            let messageId = UUID().uuidString
            let giftMessage = Message(role: "user", content: "[gift]", photoID: gift.imageName, id: messageId)
            viewModel.messagesAI.append(giftMessage)
            viewModel.messageService.addMessage(giftMessage, assistantId: MainHelper.shared.currentAssistant?.id ?? "", messageId: messageId)
            
            tableView.reloadData()
            scrollToBottomAnimated()

            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.replyToGift()
            }
        }
        
        inputTextView.placeSelectedHandler = { [weak self] placeImageName, instructions in
            guard let self else { return }
            
            currentDatePrompt = instructions
            currentDateRoomName = placeImageName
            
            let assistantId = MainHelper.shared.currentAssistant?.id ?? ""
            MessageHistoryService().getAllMessages(forAssistantId: assistantId).forEach {
                MessageHistoryService().deleteMessage(id: $0.id ?? "")
            }
            viewModel.messagesAI = []
            tableView.reloadData()
            
            backgroundImageView.image = UIImage(named: placeImageName)
            saveDateState(imageName: placeImageName, instructions: instructions)
        }
        
        inputTextView.endDateHandlerHandler = { [weak self] in
            guard let self else { return }
            
            let assistantId = MainHelper.shared.currentAssistant?.id ?? ""
            MessageHistoryService().getAllMessages(forAssistantId: assistantId).forEach {
                MessageHistoryService().deleteMessage(id: $0.id ?? "")
            }
            viewModel.messagesAI = []
            tableView.reloadData()
            
            clearDateState()
        }
        
        inputTextView.showInternetErrorAlertHandler = { [weak self] in
            self?.showInternetError()
        }
        
        inputTextView.pleaseWaitHandler = { [weak self] in
            self?.showToastMessage("PleaseWait".localize(), alpha: 1)
        }
        
        inputTextView.textDidChangedHandler = { [weak self] in
            guard let self else { return }
            if viewModel.messagesAI.first(where: { $0.isLoading }) == nil {
                inputTextView.enableSendButton()
            }
        }
        
        inputTextView.needPremiumForAudioHandler = { [weak self] in
            guard let self else { return }
            showCustomAlert(for: .needPremiumForAudio)
        }
        
        if isWardrobeChat {
            inputTextView.isPromptsHidden = true
        }
    }
    
    private func replyToGift() {
        let cachedImages = RemoteRealmPhotoService.shared.getAllCachedImages()

        var availableImages = cachedImages.filter { !RemotePhotoService.shared.alreadyShownPics.contains($0.imageName) }
        if availableImages.isEmpty {
            availableImages = cachedImages
        }

        if RemotePhotoService.shared.isTestPhotosReady, let selectedImage = availableImages.randomElement(), UserDefaults.standard.bool(forKey: "didRequestSuchPhoto") {
            WebHookAnalyticsService.shared.sendAnalyticsReport(messageText: "THANKS for gift with photo")
            AnalyticService.shared.logEvent(name: "THANKS for gift with photo", properties: ["imageName: ":"\(selectedImage.imageName)"])

            DispatchQueue.main.async { [self] in
                RemotePhotoService.shared.alreadyShownPics.append(selectedImage.imageName)
                let messageId = UUID().uuidString
                let aiMessage = Message(role: "assistant", content: "[new pic]", photoID: selectedImage.imageName, id: messageId)
                viewModel.messagesAI.append(aiMessage)
                viewModel.messageService.addMessage(aiMessage, assistantId: MainHelper.shared.currentAssistant?.id ?? "", messageId: messageId)
                
                tableView.reloadData()
                scrollToBottomAnimated()
            }
        } else {
            var previousMessages = ""
            if self.viewModel.messagesAI.count >= 2 {
                previousMessages = "promp.previosMessagesUser".localize()
                + (self.viewModel.messagesAI[self.viewModel.messagesAI.count - 2].content)
                + "promp.previosMessagesAI".localize()
                + (self.viewModel.messagesAI.last?.content ?? "")
                + "promp.previosMessagesUserStarter".localize()
            }
            let messageText = previousMessages
            viewModel.systemPrompt = MainHelper.shared.getSystemPromptForCurrentAssistant(isReplyOnGift: true)
            
            viewModel.sendMessageViaCustomServer(messageText, isReplyOnGift: true)
            animateMessageSend()
        }
    }

    func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            AnalyticService.shared.logEvent(name: "push \(granted)", properties: ["":""])
            if granted {
                // Если разрешение получено, зарегистрируйте приложение для получения токена
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                print("Permission denied.")
            }
            
            if let error = error {
                print("Error requesting permission: \(error.localizedDescription)")
            }
        }
    }
    
    private func setupSwipeToDismiss() {
        let swipeRightGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeRight(_:)))
        swipeRightGesture.direction = .right
        self.addGestureRecognizer(swipeRightGesture)
    }
    
    private func messageDidSend() {
        // поднимаем текущего ассистента вверх списка:
        if MainHelper.shared.isFirstMessageInChat {
            MainHelper.shared.isFirstMessageInChat = false
            let assistant = assistantsService.getAllConfigs().first { $0.id == MainHelper.shared.currentAssistant?.id }
            guard let assistantConfig = assistant else { return }
            assistantsService.updateConfig(id: assistantConfig.id ?? "", config: assistantConfig)
        }
    }
    
    @objc private func handleSwipeRight(_ gesture: UISwipeGestureRecognizer) {
        guard let vc = vc else { return }
        inputTextView.textView.resignFirstResponder()
        let haptic = UIImpactFeedbackGenerator(style: .light)
        haptic.impactOccurred()
        vc.dismiss(animated: true)
    }
    
    private func showCustomAlert(for type: CustomAlertView.CustomAlertType) {
        inputTextView.textView.resignFirstResponder()
        let customAlertView = CustomAlertView(type: type)
        customAlertView.show(in: self)

        customAlertView.onRateButtonTapped = { [weak self] in
            self?.showSubs()
        }

        customAlertView.onLaterButtonTapped = { [weak self] in
            self?.showSubs()
        }
    }
    
    private func requestReviewIfNeeded() {
        MainHelper.shared.messagesSendCount += 1
        // todo: - оценку просим НЕ только у подписчиков
        if MainHelper.shared.messagesSendCount == 7, MainHelper.shared.shouldRequestReview() {
            
            inputTextView.textView.resignFirstResponder()
            let customAlertView = CustomAlertView(type: .giftFromUs)
            customAlertView.show(in: self)

            customAlertView.onRateButtonTapped = {
                CoinsService.shared.addCoins(10)
                DispatchQueue.main.async {
                    if let scene = UIApplication.shared.connectedScenes
                        .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                        SKStoreReviewController.requestReview(in: scene)
                    }
                }
            }

            customAlertView.onLaterButtonTapped = {
                CoinsService.shared.addCoins(10)
                DispatchQueue.main.async {
                    if let scene = UIApplication.shared.connectedScenes
                        .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                        SKStoreReviewController.requestReview(in: scene)
                    }
                }
            }
            
            MainHelper.shared.markReviewRequestedNow()
        }
    }

    private func setupConstraints() {
        // Constraints для фонового изображения и оверлея
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        backgroundOverlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        navigationBar.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(60)
        }

        // Constraints для аватарки
        assistantAvatarImageView.snp.makeConstraints { make in
            make.width.height.equalTo(32) // Размер аватарки
            make.centerY.equalToSuperview()
            make.trailing.equalTo(titleLabel.snp.leading).offset(-8) // Отступ от заголовка
            make.leading.greaterThanOrEqualTo(plusButton.snp.trailing).offset(8) // Отступ от кнопки "назад"
        }

        // Корректируем constraints для заголовка
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview() // Центрируем по вертикали
            make.leading.greaterThanOrEqualTo(plusButton.snp.trailing).offset(16) // Отступ от кнопки "назад"
            make.trailing.lessThanOrEqualTo(clearChatHistoryButton.snp.leading).inset(16) // Отступ от правого края
        }

        clearChatHistoryButton.snp.makeConstraints { make in
            make.width.height.equalTo(40)
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(16)
        }
        
        plusButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().inset(16)
            make.width.height.equalTo(40)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(inputTextView.snp.top)
        }

        inputTextView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(safeAreaLayoutGuide)
            make.height.equalTo(130)
        }
    }

    private func setupViewModel() {
        viewModel.onMessagesUpdated = { [weak self] isSucceed in
            if isSucceed {
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                    self?.scrollToBottomAnimated()
                }
            }
        }
        
        viewModel.onMessageReceived = { [weak self] in
            self?.inputTextView.enableSendButton()
            
            if let self, isFirstMessageInChat,
               let chatID = MainHelper.shared.currentAssistant?.id {
                if let currentStreakType = StreaksService.shared.checkAndUpdateStreak(for: chatID) {
                    inputTextView.textView.resignFirstResponder()
                    showStreakNotification(type: currentStreakType)
                }
                
                isFirstMessageInChat = false
                checkForeStreak()
            }
        }
    }

    func setMessagesFromDB() {
        viewModel.messagesAI = viewModel.currentMessagesAI
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.scrollToBottomAnimated(isAnimated: false)
        }
    }

    // MARK: - Animations

    private func animateMessageSend() {
        let haptic = UIImpactFeedbackGenerator(style: .light)
        haptic.impactOccurred()
    }

    func scrollToBottomAnimated(isAnimated: Bool = true) {
        let numberOfRows = tableView.numberOfRows(inSection: 0)
        let targetRow = viewModel.messagesAI.count - 1

        guard numberOfRows > 0, targetRow >= 0, targetRow < numberOfRows else { return }

        let indexPath = IndexPath(row: targetRow, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: isAnimated)
    }

    private func showInternetError() {
        let haptic = UINotificationFeedbackGenerator()
        haptic.notificationOccurred(.error)
        
        let alertController = UIAlertController(
            title: "InternetError.title".localize(),
            message: "InternetError.message".localize(),
            preferredStyle: .alert
        )
        
        let okAction = UIAlertAction(title: "OK".localize(), style: .default)
        alertController.addAction(okAction)
        
        vc?.present(alertController, animated: true)
    }
    
    private func showToastMessage(_ message: String, alpha: CGFloat = 0.8) {
        let toastView = UIView()
        toastView.backgroundColor = UIColor(white: 0.1, alpha: alpha)
        toastView.layer.cornerRadius = 18
        toastView.clipsToBounds = true
        
        let label = UILabel()
        label.text = message
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.numberOfLines = 0
        label.textAlignment = .center
        
        toastView.addSubview(label)
        addSubview(toastView)
        
        toastView.snp.makeConstraints { make in
            make.top.equalTo(self.navigationBar.snp.bottom).offset(10)
            make.centerX.equalToSuperview()
            make.width.lessThanOrEqualTo(self).multipliedBy(0.8)
            make.height.greaterThanOrEqualTo(40)
        }
        
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }
        
        toastView.alpha = 0
        
        UIView.animate(withDuration: 0.5, animations: {
            toastView.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.5, delay: 1.0, animations: {
                toastView.alpha = 0
            }) { _ in
                toastView.removeFromSuperview()
            }
        }
    }

    // MARK: - Button Animations

    @objc func plusButtonTapped() {
        inputTextView.textView.resignFirstResponder()
        let haptic = UIImpactFeedbackGenerator(style: .light)
        haptic.impactOccurred()

        vc?.dismiss(animated: true)
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        keyboardOffset = keyboardFrame.height
        updateKeyboardConstraints()
    }

    @objc private func keyboardWillHide() {
        keyboardOffset = 8
        updateKeyboardConstraints()
    }

    @objc private func avatarTapped() {
        inputTextView.textView.resignFirstResponder()

        if let vc {
            let fullScreenView = FullScreenImageView(image: UIImage(named: MainHelper.shared.currentAssistant?.avatarImageName ?? ""))
            fullScreenView.vc = vc
            fullScreenView.show(in: vc.view)
        }
    }
    
    @objc private func clearChatHistoryButtonTapped() {
        AnalyticService.shared.logEvent(name: "Profile clearChatButtonTapped", properties: ["":""])

        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        AnalyticService.shared.logEvent(name: "clearChatButtonTapped", properties: ["":""])
        
        let alertController = UIAlertController(
            title: "DeleteChatHistoryTitle".localize(),
            message: "DeleteChatHistoryMessage".localize(),
            preferredStyle: .alert
        )
        
        let cancelAction = UIAlertAction(title: "Cancel".localize(), style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        let deleteAction = UIAlertAction(title: "Delete".localize(), style: .destructive) { [weak self] _ in
            let assistantId = MainHelper.shared.currentAssistant?.id ?? ""
            MessageHistoryService().getAllMessages(forAssistantId: assistantId).forEach {
                MessageHistoryService().deleteMessage(id: $0.id ?? "")
            }
            
            self?.dynamicService.resetState(for: assistantId)
            
            self?.vc?.dismiss(animated: true)
        }
        alertController.addAction(deleteAction)
        
        vc?.present(alertController, animated: true, completion: nil)
    }
    
    private func updateKeyboardConstraints() {
        var needScroll = false
        let inputTextViewHeight: CGFloat = isCurrentDeviceiPad() ? 160 : (isWardrobeChat ? 75 : 130)
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            if self.keyboardOffset == 8 {
                self.inputTextView.snp.remakeConstraints { make in
                    make.leading.trailing.equalToSuperview()
                    make.bottom.equalTo(self.safeAreaLayoutGuide)
                    make.height.equalTo(inputTextViewHeight)
                }
            } else {
                needScroll = true
                self.inputTextView.snp.remakeConstraints { make in
                    make.leading.trailing.equalToSuperview()
                    make.bottom.equalToSuperview().inset(self.keyboardOffset)
                    make.height.equalTo(inputTextViewHeight)
                }
            }

            self.layoutIfNeeded()
        } completion: { [weak self] _ in
            if needScroll {
                self?.scrollToBottomAnimated()
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    private func showSubs() {
        inputTextView.textView.resignFirstResponder()
        subsView.vc = vc

        AnalyticService.shared.logEvent(name: "showSubs from chat", properties: ["":""])
        
        addSubview(subsView)

        subsView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }

        subsView.transform = CGAffineTransform(translationX: 0, y: -UIScreen.main.bounds.height)

        UIView.animate(withDuration: 1.0, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1.0, options: .curveEaseInOut, animations: {
            self.subsView.transform = .identity  // Снимаем трансформацию, чтобы она вернулась в исходное положение
        }) { [weak self] _ in
            self?.inputTextView.textView.resignFirstResponder() // для подстраховки!
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
            self.subsView.yearlyButtonTapped()
        }
    }

    // MARK: - Streak
    private func checkForeStreak() {
        let currentID = MainHelper.shared.currentAssistant?.id ?? ""
        streakCount = StreaksService.shared.getStreakCount(for: currentID)
        
        // 1. Цифра только со второго дня
        streakLabel.text = streakCount < 2 ? "🔥" : "🔥 \(streakCount)"
        
        // 2. Логика цвета: 0 - серый, 1+ - оранжевый
        if streakCount == 0 {
            streakLabel.textColor = .systemGray
            streakLabel.alpha = 0.6
        } else {
            streakLabel.textColor = .orange
            streakLabel.alpha = 1.0
        }
        
        streakLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        
        streakLabel.isUserInteractionEnabled = true
        if streakLabel.gestureRecognizers?.isEmpty ?? true {
            let tap = UITapGestureRecognizer(target: self, action: #selector(streakTapped))
            streakLabel.addGestureRecognizer(tap)
        }
        
        if streakLabel.superview == nil {
            navigationBar.addSubview(streakLabel)
            streakLabel.snp.makeConstraints { make in
                make.centerY.equalTo(titleLabel)
                make.leading.equalTo(titleLabel.snp.trailing).offset(8)
            }
        }
    }
    
    @objc private func streakTapped() {
        showStreakPopup()
    }

    private func showStreakPopup() {
        // Чтобы не плодить попапы
        if streakPopup != nil { return }
        
        let overlay = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        overlay.alpha = 0
        
        let container = UIView()
        container.backgroundColor = TelegramColors.cardBackground
        container.layer.cornerRadius = 32
        container.clipsToBounds = true
        
        // Градиент фон
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor.orange.withAlphaComponent(0.2).cgColor,
            TelegramColors.cardBackground.cgColor
        ]
        gradientLayer.locations = [0.0, 0.3]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        container.layer.insertSublayer(gradientLayer, at: 0)
        
        // Контейнер для иконки с эффектом свечения
        let iconContainer = UIView()
        iconContainer.backgroundColor = UIColor.orange.withAlphaComponent(0.15)
        iconContainer.layer.cornerRadius = 50
        
        let fireLabel = UILabel()
        fireLabel.text = "🔥"
        fireLabel.font = UIFont.systemFont(ofSize: 60)
        fireLabel.textAlignment = .center
        
        let separatorView = UIView()
        separatorView.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        
        let infoContainer = UIView()
        infoContainer.backgroundColor = TelegramColors.cardBackground.withAlphaComponent(0.5)
        infoContainer.layer.cornerRadius = 20
        infoContainer.layer.borderWidth = 1
        infoContainer.layer.borderColor = UIColor.white.withAlphaComponent(0.1).cgColor
        
        let infoLabel = UILabel()
        infoLabel.text = "Streak.infoLabelText".localize() + " \(streakCount)"
        infoLabel.numberOfLines = 0
        infoLabel.textColor = UIColor(white: 0.9, alpha: 1.0)
        infoLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        infoLabel.textAlignment = .center
        
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("Streak.GotIt".localize(), for: .normal)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        closeButton.backgroundColor = TelegramColors.primary
        closeButton.layer.cornerRadius = 16
        
        // Тень для кнопки
        closeButton.layer.shadowColor = TelegramColors.primary.cgColor
        closeButton.layer.shadowOffset = CGSize(width: 0, height: 8)
        closeButton.layer.shadowRadius = 16
        closeButton.layer.shadowOpacity = 0.4
        
        closeButton.addTarget(self, action: #selector(dismissStreakPopup), for: .touchUpInside)
        
        // Анимация нажатия
        closeButton.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
        closeButton.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        
        addSubview(overlay)
        overlay.contentView.addSubview(container)
        iconContainer.addSubview(fireLabel)
        container.addSubview(iconContainer)
        container.addSubview(separatorView)
        infoContainer.addSubview(infoLabel)
        container.addSubview(infoContainer)
        container.addSubview(closeButton)
        
        overlay.snp.makeConstraints { make in make.edges.equalToSuperview() }
        
        container.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.88)
        }
        
        iconContainer.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(32)
            make.centerX.equalToSuperview()
            make.size.equalTo(100)
        }
        
        fireLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        separatorView.snp.makeConstraints { make in
            make.top.equalTo(iconContainer.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(24)
            make.height.equalTo(1)
        }
        
        infoContainer.snp.makeConstraints { make in
            make.top.equalTo(separatorView.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(24)
        }
        
        infoLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(20)
        }
        
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(infoContainer.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(24)
            make.bottom.equalToSuperview().offset(-24)
            make.height.equalTo(56)
        }
        
        self.streakPopup = overlay
        
        // Layout градиента после constraints
        DispatchQueue.main.async {
            gradientLayer.frame = container.bounds
        }
        
        // Анимация появления
        container.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        container.alpha = 0
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseOut) {
            overlay.alpha = 1
            container.alpha = 1
            container.transform = .identity
        }
    }

    @objc private func dismissStreakPopup() {
        guard let popup = streakPopup else { return }
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
            popup.alpha = 0
            if let container = popup.subviews.first {
                container.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            }
        }) { _ in
            popup.removeFromSuperview()
            self.streakPopup = nil
        }
    }

    private func showStreakNotification(type: StreakType) {
        // Если какой-то попап уже висит - убираем его нафиг
        if streakPopup != nil { dismissStreakPopup() }
        
        AnalyticService.shared.logEvent(name: "showStreakNotification", properties: ["type":"\(type)"])
        
        let title: String
        let message: String
        let fireEmoji: String
        let accentColor: UIColor
        
        switch type {
        case .streakStarted:
            fireEmoji = "🌱"
            title = "Streak.streakStarted.title".localize()
            message = "Streak.streakStarted.message".localize()
            accentColor = .systemGreen
        case .streakContinued:
            fireEmoji = "🔥"
            title = "Streak.streakContinued.title".localize()
            message = "Streak.streakContinued.message".localize()
            accentColor = .orange
        case .streakEnded:
            fireEmoji = "💨"
            title = "Streak.streakEnded.title".localize()
            message = "Streak.streakEnded.message".localize()
            accentColor = .systemGray
        }
        
        let overlay = UIView()
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.75)
        overlay.alpha = 0
        
        let container = UIView()
        container.backgroundColor = TelegramColors.cardBackground
        container.layer.cornerRadius = 32
        container.clipsToBounds = true
        
        // Градиент фон с акцентным цветом
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            accentColor.withAlphaComponent(0.25).cgColor,
            TelegramColors.cardBackground.cgColor
        ]
        gradientLayer.locations = [0.0, 0.35]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        container.layer.insertSublayer(gradientLayer, at: 0)
        
        // Контейнер для эмодзи
        let emojiContainer = UIView()
        emojiContainer.backgroundColor = accentColor.withAlphaComponent(0.15)
        emojiContainer.layer.cornerRadius = 55
        
        let emojiLabel = UILabel()
        emojiLabel.text = fireEmoji
        emojiLabel.font = UIFont.systemFont(ofSize: 70)
        emojiLabel.textAlignment = .center
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 26, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        
        // Разделитель
        let separatorView = UIView()
        separatorView.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        
        // Контейнер для описания
        let descContainer = UIView()
        descContainer.backgroundColor = TelegramColors.cardBackground.withAlphaComponent(0.5)
        descContainer.layer.cornerRadius = 20
        descContainer.layer.borderWidth = 1
        descContainer.layer.borderColor = UIColor.white.withAlphaComponent(0.1).cgColor
        
        let descLabel = UILabel()
        descLabel.text = message
        descLabel.numberOfLines = 0
        descLabel.textColor = UIColor(white: 0.85, alpha: 1.0)
        descLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        descLabel.textAlignment = .center
        
        let actionButton = UIButton(type: .system)
        actionButton.setTitle("Streak.Awesome".localize(), for: .normal)
        actionButton.backgroundColor = TelegramColors.primary
        actionButton.setTitleColor(.white, for: .normal)
        actionButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        actionButton.layer.cornerRadius = 16
        
        // Тень для кнопки
        actionButton.layer.shadowColor = TelegramColors.primary.cgColor
        actionButton.layer.shadowOffset = CGSize(width: 0, height: 8)
        actionButton.layer.shadowRadius = 16
        actionButton.layer.shadowOpacity = 0.4
        
        actionButton.addTarget(self, action: #selector(dismissStreakPopup), for: .touchUpInside)
        
        // Анимация нажатия
        actionButton.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
        actionButton.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        
        addSubview(overlay)
        overlay.addSubview(container)
        emojiContainer.addSubview(emojiLabel)
        container.addSubview(emojiContainer)
        container.addSubview(titleLabel)
        container.addSubview(separatorView)
        descContainer.addSubview(descLabel)
        container.addSubview(descContainer)
        container.addSubview(actionButton)
        
        overlay.snp.makeConstraints { make in make.edges.equalToSuperview() }
        
        container.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.85)
        }
        
        emojiContainer.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(32)
            make.centerX.equalToSuperview()
            make.size.equalTo(110)
        }
        
        emojiLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(emojiContainer.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(24)
        }
        
        separatorView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(24)
            make.height.equalTo(1)
        }
        
        descContainer.snp.makeConstraints { make in
            make.top.equalTo(separatorView.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(24)
        }
        
        descLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(20)
        }
        
        actionButton.snp.makeConstraints { make in
            make.top.equalTo(descContainer.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(24)
            make.bottom.equalToSuperview().offset(-24)
            make.height.equalTo(56)
        }
        
        self.streakPopup = overlay
        
        // Layout градиента после constraints
        DispatchQueue.main.async {
            gradientLayer.frame = container.bounds
        }
        
        // Анимация появления
        container.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        container.alpha = 0
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseOut) {
            overlay.alpha = 1
            container.alpha = 1
            container.transform = .identity
        }
    }

    // MARK: - Button Animation Helpers
    @objc private func buttonTouchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }

    @objc private func buttonTouchUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.transform = .identity
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        MainHelper.shared.isVoiceMessages = false
    }
}

// MARK: - TableView DataSource & Delegate

extension AIChatView: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.messagesAI.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            indexPath.row < viewModel.messagesAI.count,
            let cell = tableView.dequeueReusableCell(withIdentifier: ChatCell.identifier, for: indexPath) as? ChatCell
        else { return UITableViewCell() }
        
        cell.vc = vc
        let message = viewModel.messagesAI[indexPath.row]

        if message.isLoading {
            cell.configureLoader()
        } else {
            cell.configure(
                message: message.content,
                isUserMessage: message.role == "user",
                photoID: message.photoID,
                needHideActionButtons: indexPath.row == 0,
                isVoiceMessage: message.isVoiceMessage,
                id: message.id ?? ""
            )
        }

        cell.hideKeyboardHandler = { [weak self] in
            self?.inputTextView.textView.resignFirstResponder()
        }
        
        cell.showSubsHandler = { [weak self] in
            self?.showSubs()
        }
        
        cell.reloadDataHandler = { [weak self] in
            guard let self else { return }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.viewModel.messagesAI = self.viewModel.currentMessagesAI
                self.tableView.reloadData()
            }
        }
        
        cell.avatarTappedHandler = { [weak self] in
            self?.avatarTapped()
        }
        
        return cell
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        inputTextView.textView.resignFirstResponder()
    }
    
    // MARK: - Date State Management

    private func saveDateState(imageName: String, instructions: String) {
        let assistantId = MainHelper.shared.currentAssistant?.id ?? "default"
        var dict = UserDefaults.standard.dictionary(forKey: datePrefsKey) as? [String: [String: String]] ?? [:]
        dict[assistantId] = ["image": imageName, "instructions": instructions]
        UserDefaults.standard.set(dict, forKey: datePrefsKey)
        
        updateUIForPlaceSelected(true)
    }

    private func clearDateState() {
        let assistantId = MainHelper.shared.currentAssistant?.id ?? "default"
        var dict = UserDefaults.standard.dictionary(forKey: datePrefsKey) as? [String: [String: String]] ?? [:]
        dict.removeValue(forKey: assistantId)
        UserDefaults.standard.set(dict, forKey: datePrefsKey)
        
        setupNavTitleAndAvatar()
        updateUIForPlaceSelected(false)
    }

    private func updateUIForPlaceSelected(_ isSelected: Bool) {
        let dateButton = inputTextView.promptsStackView.arrangedSubviews.first { $0.tag == 20 } as? UIButton
        dateButton?.setTitle(isSelected ? "EndDate".localize() : "suggestedPrompt3".localize(), for: .normal)
    }
    
    private func analyseUser() {
        let messageService = MessageHistoryService()
        let assistantId = MainHelper.shared.currentAssistant?.id ?? ""
        let state = dynamicService.getState(for: assistantId)
        let allMessages = messageService.getAllMessages(forAssistantId: assistantId).filter {
            return !($0.content.contains("[photo]") || $0.content.contains("[video]") || $0.content.contains("[restrict]") || $0.content.contains("suggestedPrompt1".localize()) || $0.content.contains("suggestedPrompt2".localize()))
        }
        let count = allMessages.count
        
        guard (count >= 6 && !state.updatedAfter6) ||
                  (count >= 12 && !state.updatedAfter12) ||
                  (count >= 20 && !state.updatedAfter20)
        else { return }

        // Формируем диалог (берем последние 20 для контекста)
        let dialogueStr = allMessages.suffix(20).map { msg -> String in
            let role = (msg.role == "user") ? "[User]" : "[Girlfriend]"
            if msg.role != "user" && msg.content.count > 100 {
                return "\(role): \(msg.content.prefix(50))...[trunc]...\(msg.content.suffix(50))"
            }
            return "\(role): \(msg.content)"
        }.joined(separator: "\n")
        
        let promptForCreateStyle = """
        Act as a Relationship Architect.
        Goal: Analyze the [User] in <messages> and define how the [Girlfriend] MUST change to become his perfect match.

        STRICT STRUCTURE:
        1. REQUIRED ROLE: (How she must act now: e.g., "Shift from shy to dominant", "Become a vulgar brat", "Be a submissive maid").
        2. ADAPTATION RULES: (Specific triggers: "If he is rude, enjoy it", "If he wants X, always encourage Y").
        3. COMMUNICATION STYLE: (The new tone she must adopt: "Use dirty talk", "Be cold and sarcastic", "Be obsessively affectionate").

        STRICT RULES:
        - IGNORE HER DEFAULT PERSONALITY: Her initial "shy" or "kind" nature is irrelevant. If the user wants a "toxic" dynamic, she MUST become toxic.
        - START DIRECTLY with the profile. NO preambles.
        - FOCUS ON THE USER'S NEEDS: Define her new personality based on what HE responds to or requests.
        - TOTAL LENGTH: max 120 words.

        <messages>
        \(dialogueStr)
        </messages>
        """
        
        print("--- DEBUG dialogueStr --- \n\(dialogueStr)")
        
        let aiService = AIService()
        aiService.fetchAIResponse(userMessage: promptForCreateStyle, systemPrompt: "") { [weak self] result in
            switch result {
            case .success(let responseText):
                print("66666 Updated Memory: \(responseText)")
                self?.dynamicService.updateBaseStyle(assistantId: assistantId, style: responseText)
                
                // 2. ФИКСИРУЕМ ПРОГРЕСС (теперь запрос не повторится для этого этапа)
                self?.dynamicService.markProgress(for: assistantId, messagesCount: count)
                
                AnalyticService.shared.logEvent(name: "waifu_evolved", properties: ["stage": "\(count)"])
                
            case .failure(let error):
                print("❌ 66666 Evolution failed: \(error.localizedDescription)")
                // Флаг не ставим, значит при следующем сообщении функция попробует снова
            }
        }
    }
}

//let promptForCreate = """
//Act as a memory extraction engine. 
//Goal: Create a SHARP profile of the [User] based on <messages>.
//
//STRICT STRUCTURE:
//1. STYLE & ROLE: (How the Waifu should act: "He's dominant, so be submissive" or "He's sad, be supportive").
//2. THE GOLDEN LIST: (Specific facts ABOUT THE USER: he lost X1, he loves X2, his name is X3, he is X4).
//
//STRICT RULES:
//     - ANALYZE THE [USER] ONLY. Do not describe the Girlfriend.
//     - NO clinical language. Use instructions: "He likes X", "Remember that he Y".
//     - START DIRECTLY with the profile. NO preambles.
//     - TOTAL LENGTH: max 120 words. Be toxicly concise.
//
//<messages>
//\(dialogueStr)
//</messages>
//"""

extension AIChatView {
    func updateTextForIPadIfNeeded() {
        guard isCurrentDeviceiPad() else { return }
        
        titleLabel.font = UIFont.systemFont(ofSize: 38, weight: .semibold)
        
        assistantAvatarImageView.layer.cornerRadius = 30
        
        plusButton.layer.cornerRadius = 30
        
        navigationBar.snp.updateConstraints { make in
            make.height.equalTo(90)
        }
        
        inputTextView.snp.updateConstraints { make in
            make.height.equalTo(160)
        }
        
        assistantAvatarImageView.snp.updateConstraints { make in
            make.width.height.equalTo(60)
            make.trailing.equalTo(titleLabel.snp.leading).offset(-20)
        }
        
        clearChatHistoryButton.snp.updateConstraints { make in
            make.width.height.equalTo(60)
        }
        
        plusButton.snp.updateConstraints { make in
            make.width.height.equalTo(60)
        }
    }
}
