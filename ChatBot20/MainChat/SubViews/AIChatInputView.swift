import UIKit
import SnapKit

class AIChatInputView: UIView {
    let textView = UITextView()
    let sendButton = UIButton(type: .system)
    let placeholderLabel = UILabel()
    private let inputContainer = UIView()
    private let backgroundBlurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    private let separatorView = UIView()

    private let promptsScrollView = UIScrollView()
    let promptsStackView = UIStackView()

    var sendMessageHandler: ((String) -> Void)?
    var showInternetErrorAlertHandler: (() -> Void)?
    var giftSendedHandler: ((GiftItem) -> Void)?
    var pleaseWaitHandler: (() -> Void)?
    var textDidChangedHandler: (() -> Void)?
    var placeSelectedHandler: ((String, String) -> Void)?
    var endDateHandlerHandler: (() -> Void)?
    var needPremiumForAudioHandler: (() -> Void)?

    // Telegram цвета
    private struct TelegramColors {
        static let primary = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0) // #3390DC
        static let background = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1.0) // #2C2C2E
        static let inputBackground = UIColor(red: 0.22, green: 0.22, blue: 0.24, alpha: 1.0) // #38383A
        static let textPrimary = UIColor.white
        static let textSecondary = UIColor(red: 0.64, green: 0.64, blue: 0.66, alpha: 1.0) // #A4A4A8
        static let separator = UIColor(red: 0.28, green: 0.28, blue: 0.29, alpha: 0.3) // #48484A
    }
    
    private var textViewHeightConstraint: Constraint?
    private let maxTextViewHeight: CGFloat = 120
    private lazy var minTextViewHeight: CGFloat = isCurrentDeviceiPad() ? 50 : 36
    private var isHandlingImage = false
    private var canSendMessage = true
    private var needScrollTotTheEnd: Bool = true // for RTL (arabic)

    weak var vc: UIViewController?

    private var promptsHeightConstraint: Constraint?
    var isPromptsHidden: Bool = false {
        didSet {
            promptsScrollView.isHidden = isPromptsHidden
            
            inputContainer.snp.remakeConstraints { make in
                make.leading.equalToSuperview().offset(16)
                make.trailing.equalTo(sendButton.snp.leading).offset(-16)
                make.top.equalToSuperview().inset(12)
                
                if isPromptsHidden {
                    make.bottom.equalToSuperview().inset(12)
                } else {
                    make.bottom.equalTo(promptsScrollView.snp.top).offset(-12)
                }
            }
            
            promptsScrollView.snp.updateConstraints { make in
                make.height.equalTo(isPromptsHidden ? 0 : (isCurrentDeviceiPad() ? 60 : 50))
            }

            self.layoutIfNeeded()
        }
    }
    
    func setup() {
        setupBackground()
        setupPromptsScrollView()
        setupInputContainer()
        setupTextView()
        setupButtons()
        setupConstraints()
        updateActionButtonUI()
        updateTextForIPadIfNeeded()
    }
    
    func updateForRLTIfNeeded() {
        let isRTL = UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft
        if isRTL, needScrollTotTheEnd {
            let rightOffset = CGPoint(x: promptsScrollView.contentSize.width - promptsScrollView.bounds.width + promptsScrollView.contentInset.right, y: 0)
            promptsScrollView.setContentOffset(rightOffset, animated: false)
        }
    }
    
    private func setupBackground() {
        backgroundColor = .clear
        
        backgroundBlurView.alpha = 0.3
        addSubview(backgroundBlurView)
        
        separatorView.backgroundColor = TelegramColors.separator
        addSubview(separatorView)
    }

    private func setupPromptsScrollView() {
        setGiftButtonToPrompts()
        setDateButtonToPrompts()
        setPromptsButtonsToPrompts()
    }
    
    private func setGiftButtonToPrompts() {
        promptsScrollView.showsHorizontalScrollIndicator = false
        promptsScrollView.clipsToBounds = false
        promptsScrollView.alwaysBounceHorizontal = true
        addSubview(promptsScrollView)
        
        promptsStackView.axis = .horizontal
        promptsStackView.spacing = 8
        promptsStackView.alignment = .fill
        promptsStackView.distribution = .fill
        promptsScrollView.addSubview(promptsStackView)
        
        let giftButton = UIButton(type: .system)
        let giftTitle = "SendGift".localize()
        giftButton.setTitle(giftTitle, for: .normal)
        let giftButtonFontSize: CGFloat = isCurrentDeviceiPad() ? 24 : 14
        let giftButtonCornerRadius: CGFloat = isCurrentDeviceiPad() ? 24 : 16
        
        giftButton.titleLabel?.font = UIFont.systemFont(ofSize: giftButtonFontSize, weight: .medium)
        giftButton.setTitleColor(TelegramColors.textPrimary, for: .normal)
        giftButton.backgroundColor = TelegramColors.inputBackground
        giftButton.layer.cornerRadius = giftButtonCornerRadius
        giftButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        
        giftButton.layer.shadowColor = UIColor.systemBlue.cgColor
        giftButton.layer.shadowOpacity = 0.5
        giftButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        giftButton.layer.shadowRadius = 4
        giftButton.layer.masksToBounds = false
        giftButton.layer.borderWidth = 2
        giftButton.layer.borderColor = UIColor.systemBlue.cgColor
        
        if let giftImage = UIImage(systemName: "gift.fill")?.withTintColor(.white, renderingMode: .alwaysOriginal) {
            giftButton.setImage(giftImage, for: .normal)
            giftButton.imageView?.contentMode = .scaleAspectFit
            giftButton.tag = 19
            
            let isRTL = UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft
            if isRTL {
                giftButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: -4)
                giftButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 4)
            } else {
                giftButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 4)
                giftButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: -4)
            }
        }
        
        giftButton.addTarget(self, action: #selector(promptButtonTapped(_:)), for: .touchUpInside)
        giftButton.accessibilityIdentifier = "giftButton"
        promptsStackView.addArrangedSubview(giftButton)
    }
    
    private func setDateButtonToPrompts() {
        let dateButton = UIButton(type: .system)
        let dateTitle = "suggestedPrompt3".localize()
        
        let dateButtonFontSize: CGFloat = isCurrentDeviceiPad() ? 24 : 14
        let dateButtonCornerRadius: CGFloat = isCurrentDeviceiPad() ? 24 : 16
        let dateFont = UIFont.systemFont(ofSize: dateButtonFontSize, weight: .medium)
        
        dateButton.setTitle(dateTitle, for: .normal)
        dateButton.titleLabel?.font = dateFont
        dateButton.titleLabel?.numberOfLines = 2
        dateButton.titleLabel?.lineBreakMode = .byWordWrapping
        dateButton.titleLabel?.textAlignment = .center
        
        dateButton.setTitleColor(TelegramColors.textPrimary, for: .normal)
        dateButton.backgroundColor = TelegramColors.inputBackground
        dateButton.layer.cornerRadius = dateButtonCornerRadius
        
        // Увеличиваем отступы, чтобы текст не прилипал к краям
        dateButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        
        // Стилизация (рамка и тень)
        dateButton.layer.shadowColor = UIColor.systemBlue.cgColor
        dateButton.layer.shadowOpacity = 0.5
        dateButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        dateButton.layer.shadowRadius = 4
        dateButton.layer.masksToBounds = false
        dateButton.layer.borderWidth = 2
        dateButton.layer.borderColor = UIColor.systemBlue.cgColor
        
        dateButton.addTarget(self, action: #selector(promptButtonTapped(_:)), for: .touchUpInside)
        dateButton.tag = 20
        
        let maxSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        let attributes: [NSAttributedString.Key: Any] = [.font: dateFont]
        let boundingRect = (dateTitle as NSString).boundingRect(
            with: maxSize,
            options: .usesLineFragmentOrigin,
            attributes: attributes,
            context: nil
        )
        
        let estimatedTwoLineWidth = ceil(boundingRect.width / 1.8)
        let finalWidth = max(isCurrentDeviceiPad() ? 100 : 80, estimatedTwoLineWidth + dateButton.contentEdgeInsets.left + dateButton.contentEdgeInsets.right + 10)
        
        dateButton.snp.makeConstraints { make in
            make.width.equalTo(finalWidth).priority(.required)
        }
        
        dateButton.setContentHuggingPriority(.required, for: .horizontal)
        dateButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        promptsStackView.addArrangedSubview(dateButton)
    }
    
    private func setPromptsButtonsToPrompts() {
        let allPrompts = Array(ConfigService.shared.isVideoReady ? ["suggestedPrompt4".localize(), "suggestedPrompt1".localize(), "suggestedPrompt2".localize()] : ["suggestedPrompt4".localize(), "suggestedPrompt1".localize()])

        let promptButtonSize: CGFloat = isCurrentDeviceiPad() ? 24 : 14
        let promptButtonCornerRadius: CGFloat = isCurrentDeviceiPad() ? 24 : 16
        let font = UIFont.systemFont(ofSize: promptButtonSize, weight: .medium)
        
        for promptText in allPrompts {
            let button = UIButton(type: .system)
            button.setTitle(promptText, for: .normal)
            button.titleLabel?.font = font
            button.titleLabel?.numberOfLines = 2
            button.titleLabel?.lineBreakMode = .byWordWrapping
            button.titleLabel?.textAlignment = .center
            button.setTitleColor(TelegramColors.textPrimary, for: .normal)
            button.backgroundColor = TelegramColors.inputBackground
            button.layer.cornerRadius = promptButtonCornerRadius
            button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
            button.layer.shadowColor = UIColor.systemBlue.cgColor
            button.layer.shadowOpacity = 0.5
            button.layer.shadowOffset = CGSize(width: 0, height: 2)
            button.layer.shadowRadius = 4
            button.layer.masksToBounds = false
            button.layer.borderWidth = 2
            button.layer.borderColor = UIColor.systemBlue.cgColor
            
            if button.titleLabel?.text?.contains("suggestedPrompt4".localize()) ?? false {
                button.tag = 21
            }
            
            button.addTarget(self, action: #selector(promptButtonTapped(_:)), for: .touchUpInside)
            
            let textWidthSingleLine = (promptText as NSString).size(withAttributes: [.font: font]).width
            var calculatedWidth = ceil(textWidthSingleLine / 2.0) + button.contentEdgeInsets.left + button.contentEdgeInsets.right
            calculatedWidth += 20
            
            let absoluteMinWidth: CGFloat = isCurrentDeviceiPad() ? 100 : 80
            let finalWidth = max(absoluteMinWidth, calculatedWidth)
            
            button.snp.makeConstraints { make in
                make.width.equalTo(finalWidth).priority(.required)
            }
            
            button.setContentHuggingPriority(.required, for: .horizontal)
            button.setContentCompressionResistancePriority(.required, for: .horizontal)
            
            promptsStackView.addArrangedSubview(button)
        }
    }
    
    func updateAudioMessagePrompText() {
        promptsStackView.arrangedSubviews.forEach { view in
            if view.tag == 21, let button = view as? UIButton {
                let newText = MainHelper.shared.isVoiceMessages ? "suggestedPrompt5".localize() : "suggestedPrompt4".localize()
                button.setTitle(newText, for: .normal)
                
                // 2. Если кнопка должна менять ширину под новый текст,
                // нужно обновить констрейнты, которые ты жестко задал при создании
                let font = button.titleLabel?.font ?? UIFont.systemFont(ofSize: isCurrentDeviceiPad() ? 24 : 14, weight: .medium)
                let textWidthSingleLine = (newText as NSString).size(withAttributes: [.font: font]).width
                var calculatedWidth = ceil(textWidthSingleLine / 2.0) + button.contentEdgeInsets.left + button.contentEdgeInsets.right
                calculatedWidth += 20
                
                let absoluteMinWidth: CGFloat = isCurrentDeviceiPad() ? 100 : 80
                let finalWidth = max(absoluteMinWidth, calculatedWidth)
                
                button.snp.updateConstraints { make in
                    make.width.equalTo(finalWidth).priority(.required)
                }
                
                // 3. Пиннаем лейаут, чтобы изменения вступили в силу
                button.setNeedsLayout()
                button.layoutIfNeeded()
            }
        }
    }
    
    private func setupInputContainer() {
        inputContainer.backgroundColor = TelegramColors.inputBackground
        inputContainer.layer.cornerRadius = 18
        inputContainer.layer.shadowColor = UIColor.black.cgColor
        inputContainer.layer.shadowOpacity = 0.1
        inputContainer.layer.shadowOffset = CGSize(width: 0, height: 1)
        inputContainer.layer.shadowRadius = 3
        addSubview(inputContainer)
    }
    
    private func setupTextView() {
        let isRTL = UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft
        semanticContentAttribute = isRTL ? .forceRightToLeft : .forceLeftToRight
        
        textView.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        textView.textColor = TelegramColors.textPrimary
        textView.backgroundColor = .clear
        textView.textAlignment = isRTL ? .right : .left
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        textView.textContainer.lineFragmentPadding = 0
        textView.delegate = self
        textView.showsVerticalScrollIndicator = false
        textView.showsHorizontalScrollIndicator = false
        textView.isScrollEnabled = true
        textView.returnKeyType = .send
        textView.enablesReturnKeyAutomatically = true
        
        placeholderLabel.text = "WriteMessage".localize()
        placeholderLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        placeholderLabel.textColor = TelegramColors.textSecondary
        placeholderLabel.textAlignment = isRTL ? .right : .left
        placeholderLabel.isHidden = !textView.text.isEmpty
        
        inputContainer.addSubview(textView)
        inputContainer.addSubview(placeholderLabel)
    }
    
    private func setupButtons() {
        sendButton.layer.cornerRadius = 18
        sendButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        addSubview(sendButton)
    }
    
    private func setupConstraints() {
        backgroundBlurView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().inset(-100)
        }
        
        separatorView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(0.5)
        }
        
        // 1. Промпты теперь прижаты к низу (к SafeArea)
        promptsScrollView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(safeAreaLayoutGuide).inset(8) // Нижняя точка теперь тут
            promptsHeightConstraint = make.height.equalTo(isCurrentDeviceiPad() ? 60 : 50).constraint
        }
        
        promptsStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalToSuperview()
        }
        
        // 2. Кнопка отправки привязана к контейнеру инпута
        sendButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalTo(inputContainer) // Центрируем по инпуту
            make.width.height.equalTo(36)
        }
        
        // 3. Инпут контейнер теперь НАД промптами
        inputContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalTo(sendButton.snp.leading).offset(-16) // Исправил inset на offset для корректного отступа
            make.bottom.equalTo(promptsScrollView.snp.top).offset(-12) // Привязка к верху промптов
            make.top.equalToSuperview().inset(12) // Даем отступ сверху, чтобы контейнер расширял вьюху
        }
        
        textView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.top.bottom.equalToSuperview().inset(6)
            textViewHeightConstraint = make.height.equalTo(minTextViewHeight).constraint
        }
        
        placeholderLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(textView)
            make.centerY.equalTo(textView)
        }
    }
    
    private func updateActionButtonUI() {
        var image: UIImage?
        var backgroundColor: UIColor
        
        textView.isHidden = false
        placeholderLabel.isHidden = !textView.text.isEmpty
        
        let pointSize: CGFloat = isCurrentDeviceiPad() ? 24 : 16
        image = UIImage(systemName: "paperplane.fill")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: pointSize, weight: .semibold)
        )
        backgroundColor = canSendMessage ? TelegramColors.primary : TelegramColors.inputBackground
        if textView.inputView != nil {
            textView.resignFirstResponder()
            textView.inputView = nil
            textView.reloadInputViews()
        }
        
        sendButton.setImage(image, for: .normal)
        sendButton.tintColor = TelegramColors.textPrimary
        sendButton.backgroundColor = backgroundColor
        
        UIView.animate(withDuration: 0.2) {
            self.sendButton.transform = .identity
        }
    }
    
    private func updateTextViewHeight() {
        let size = textView.sizeThatFits(CGSize(width: textView.frame.width, height: CGFloat.greatestFiniteMagnitude))
        let newHeight = max(minTextViewHeight, min(maxTextViewHeight, size.height))
        
        textViewHeightConstraint?.update(offset: newHeight)
        
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
            self.layoutIfNeeded()
        }
        
        textView.isScrollEnabled = true
    }
        
    @objc private func actionButtonTapped() {
        sendButtonTapped()
    }
    
    func enableSendButton() {
        canSendMessage = true
        sendButton.backgroundColor = TelegramColors.primary
    }
    
    private func sendButtonTapped() {
        guard canSendMessage, let text = textView.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            pleaseWaitHandler?()
            return
        }
        canSendMessage = false
        self.sendButton.backgroundColor = TelegramColors.inputBackground

        guard NetworkMonitor.shared.isConnected else {
            showInternetErrorAlertHandler?()
            return
        }
        
        let haptic = UIImpactFeedbackGenerator(style: .medium)
        haptic.impactOccurred()
        
        if let language = textView.textInputMode?.primaryLanguage {
            print("currentLanguage \(language)")
            MainHelper.shared.currentLanguage = language
        }
        sendMessageHandler?(text.trimmingCharacters(in: .whitespacesAndNewlines))
        
        UIView.animate(withDuration: 0.2, animations: {
            self.textView.alpha = 0.5
        }) { _ in
            self.textView.text = ""
            self.textView.alpha = 1.0
            self.placeholderLabel.isHidden = false
            self.updateTextViewHeight()
        }
    }
    
    @objc private func promptButtonTapped(_ sender: UIButton) {
        guard canSendMessage else {
            pleaseWaitHandler?()
            return
        }
        
        needScrollTotTheEnd = false
        
        if sender.accessibilityIdentifier == "giftButton" {
            sendGiftButtonTapped()
        } else if sender.tag == 20 {
            if sender.titleLabel?.text?.contains("EndDate".localize()) == true {
                endDateHandlerHandler?()
            } else {
                AnalyticService.shared.logEvent(name: "lets Go On Date Tapped", properties: ["":""])
                letsGoOnDateTapped()
            }
        } else if let promptText = sender.titleLabel?.text {
            if sender.tag == 21 {
                if !IAPService.shared.hasActiveSubscription {
                    needPremiumForAudioHandler?()
                    return
                } else {
                    AnalyticService.shared.logEvent(name: "Audio Message Prompt Tapped", properties: ["":""])
                    MainHelper.shared.isVoiceMessages.toggle()
                    updateAudioMessagePrompText()
                }
            }

            canSendMessage = false
            sendMessageHandler?(promptText)
        }
    }
    
    func sendGiftButtonTapped() {
        let giftVC = GiftVC()
        giftVC.sendGiftHandler = { [weak self] gift in
            self?.giftSendedHandler?(gift)
            giftVC.dismiss(animated: true)
        }
        vc?.present(giftVC, animated: true, completion: nil)
    }
    
    func letsGoOnDateTapped() {
        let dateVC = DateVC()
        dateVC.placeSelectedHandler = { [weak self] placeImageName, instructions in
            self?.placeSelectedHandler?(placeImageName, instructions)
            dateVC.dismiss(animated: true)
        }
        vc?.present(dateVC, animated: true, completion: nil)
    }
}

// MARK: - UITextViewDelegate

extension AIChatInputView: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        textDidChangedHandler?()
        placeholderLabel.isHidden = !textView.text.isEmpty
        updateTextViewHeight()
    }
    
    func textView(_ textView: UITextView,
                  shouldChangeTextIn range: NSRange,
                  replacementText text: String) -> Bool {
        
        // Лимит на длину текста
        let currentText = textView.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        
        let updatedText = currentText.replacingCharacters(in: stringRange, with: text)
        
        if updatedText.count > 2000 {
            return false
        }
        
        return true
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.inputContainer.layer.shadowOpacity = 0.2
            self.inputContainer.layer.shadowRadius = 6
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.inputContainer.layer.shadowOpacity = 0.1
            self.inputContainer.layer.shadowRadius = 3
            self.inputContainer.transform = .identity
        }
    }
}

extension AIChatInputView {
    func updateTextForIPadIfNeeded() {
        guard isCurrentDeviceiPad() else { return }
        
        inputContainer.layer.cornerRadius = 28
        sendButton.layer.cornerRadius = 28
        
        textView.font = UIFont.systemFont(ofSize: 26, weight: .regular)
        placeholderLabel.font = UIFont.systemFont(ofSize: 26, weight: .regular)

        sendButton.snp.updateConstraints { make in
            make.width.height.equalTo(56)
        }
    }
}
