import UIKit
import SnapKit

class SingleStoryPageView: UIView {
    private let backgroundImageView = UIImageView()
    private let closeButton = UIButton(type: .system)
    
    // UI элементы бабла
    private let bubbleContainer = UIView()
    private let bubbleLabel = UILabel()
    private let bubbleTailLarge = UIView()
    private let bubbleTailSmall = UIView()
    
    // UI элементы прогресс-бара
    private let progressBarBackground = UIView()
    private let progressBarFiller = UIView()
    
    // Таймеры
    private var storyTimer: Timer?
    private var progressUpdateTimer: Timer?
    private let storyDuration: TimeInterval = 10.0
    
    // Состояние
    private var startTime: Date?
    private var elapsedBeforePause: TimeInterval = 0
    private var isPaused = false
    
    private var progressBarFillerWidthConstraint: Constraint?
    private var currentStory: StoryModel?

    // Колбеки
    var onNextRequested: (() -> Void)?
    var onPrevRequested: (() -> Void)?
    var onCloseRequested: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupGestures()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupViews() {
        // Картинка
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        addSubview(backgroundImageView)
        backgroundImageView.snp.makeConstraints { $0.edges.equalToSuperview() }

        // --- Прогресс бар (Улучшенный дизайн) ---
        // Делаем фон чуть темнее, чтобы видно было на белом, + тень и обводка
        progressBarBackground.backgroundColor = UIColor(white: 0.0, alpha: 0.2) // Темный полупрозрачный фон
        progressBarBackground.layer.cornerRadius = 2
        progressBarBackground.layer.borderWidth = 0.5
        progressBarBackground.layer.borderColor = UIColor.black.withAlphaComponent(0.1).cgColor
        addSubview(progressBarBackground)
        
        progressBarBackground.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide).inset(10)
            make.leading.trailing.equalToSuperview().inset(10)
            make.height.equalTo(4)
        }

        progressBarFiller.backgroundColor = .white
        progressBarFiller.layer.cornerRadius = 2
        
        // Тень для белого заполнителя, чтобы он не сливался с белым фоном сторис
        progressBarFiller.layer.shadowColor = UIColor.black.cgColor
        progressBarFiller.layer.shadowOffset = CGSize(width: 0, height: 1)
        progressBarFiller.layer.shadowOpacity = 0.5
        progressBarFiller.layer.shadowRadius = 2
        
        progressBarBackground.addSubview(progressBarFiller)
        progressBarFiller.snp.makeConstraints { make in
            make.top.bottom.leading.equalToSuperview()
            progressBarFillerWidthConstraint = make.width.equalTo(0).constraint
        }

        // --- Кнопка закрытия (Улучшенный дизайн) ---
        let xImage = UIImage(systemName: "xmark")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .bold))
        closeButton.setImage(xImage, for: .normal)
        closeButton.tintColor = .white
        
        // Жирная тень для крестика, чтобы видно было на любом фоне
        closeButton.layer.shadowColor = UIColor.black.cgColor
        closeButton.layer.shadowOffset = CGSize(width: 0, height: 1)
        closeButton.layer.shadowOpacity = 0.8
        closeButton.layer.shadowRadius = 3
        
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(progressBarBackground.snp.bottom).offset(15)
            make.trailing.equalToSuperview().inset(15)
            make.width.height.equalTo(30)
        }

        setupBubbleUI()
    }

    private func setupBubbleUI() {
        bubbleContainer.backgroundColor = .white
        bubbleContainer.layer.cornerRadius = 20
        // Тень для бабла (опционально, для красоты)
        bubbleContainer.layer.shadowColor = UIColor.black.cgColor
        bubbleContainer.layer.shadowOpacity = 0.1
        bubbleContainer.layer.shadowOffset = CGSize(width: 0, height: 2)
        bubbleContainer.layer.shadowRadius = 4
        
        addSubview(bubbleContainer)
        
        bubbleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        bubbleLabel.textColor = .black
        bubbleLabel.numberOfLines = 0
        bubbleContainer.addSubview(bubbleLabel)
        
        bubbleTailLarge.backgroundColor = .white
        bubbleTailLarge.layer.cornerRadius = 7
        addSubview(bubbleTailLarge)
        
        bubbleTailSmall.backgroundColor = .white
        bubbleTailSmall.layer.cornerRadius = 4
        addSubview(bubbleTailSmall)

        bubbleContainer.snp.makeConstraints { make in
            make.bottom.equalTo(safeAreaLayoutGuide).inset(40)
            make.trailing.equalToSuperview().inset(25)
            make.width.lessThanOrEqualTo(260)
        }
        bubbleLabel.snp.makeConstraints { make in make.edges.equalToSuperview().inset(15) }
        
        bubbleTailLarge.snp.makeConstraints { make in
            make.bottom.equalTo(bubbleContainer.snp.top).offset(2)
            make.leading.equalTo(bubbleContainer.snp.leading).inset(25)
            make.width.height.equalTo(14)
        }
        bubbleTailSmall.snp.makeConstraints { make in
            make.bottom.equalTo(bubbleTailLarge.snp.top).offset(-4)
            make.leading.equalTo(bubbleTailLarge.snp.leading).inset(-8)
            make.width.height.equalTo(8)
        }
    }

    func configure(with story: StoryModel) {
        self.currentStory = story
        backgroundImageView.image = UIImage(named: story.detailImageName)
        let key = "Stories.Tex\(story.id)"
        let localized = NSLocalizedString(key, comment: "")
        bubbleLabel.text = (localized != key) ? localized : story.description
        
        resetState()
        animateBubble()
    }
    
    // MARK: - Timer Logic
    
    func startStoryTimer() {
        if storyTimer != nil { return }
        isPaused = false
        startTime = Date()
        
        progressUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { [weak self] _ in
            self?.updateProgress()
        }
        
        let remainingTime = storyDuration - elapsedBeforePause
        // ВАЖНО: Если осталось мало времени, сразу переключаем
        if remainingTime <= 0 {
            onNextRequested?()
            return
        }
        
        storyTimer = Timer.scheduledTimer(withTimeInterval: remainingTime, repeats: false) { [weak self] _ in
            self?.onNextRequested?()
        }
    }
    
    private func updateProgress() {
        guard let startTime = startTime else { return }
        let currentSegmentTime = Date().timeIntervalSince(startTime)
        let totalElapsed = elapsedBeforePause + currentSegmentTime
        
        let progress = min(1.0, totalElapsed / storyDuration)
        let width = progressBarBackground.bounds.width * CGFloat(progress)
        progressBarFillerWidthConstraint?.update(offset: width)
    }

    func pauseStoryTimer() {
        guard !isPaused, let startTime = startTime else { return }
        isPaused = true
        elapsedBeforePause += Date().timeIntervalSince(startTime)
        invalidateTimers()
    }
    
    func resumeStoryTimer() {
        if isPaused {
            startStoryTimer()
        }
    }
    
    func stopAndReset() {
        invalidateTimers()
        elapsedBeforePause = 0
        isPaused = false
        progressBarFillerWidthConstraint?.update(offset: 0)
    }

    private func invalidateTimers() {
        storyTimer?.invalidate()
        progressUpdateTimer?.invalidate()
        storyTimer = nil
        progressUpdateTimer = nil
    }
    
    private func resetState() {
        stopAndReset()
    }

    // MARK: - Gestures
    
    private func setupGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tap)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.2
        addGestureRecognizer(longPress)
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        // Делим экран пополам: слева - назад, справа - вперед
        location.x < bounds.width / 2 ? onPrevRequested?() : onNextRequested?()
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            pauseStoryTimer()
            UIView.animate(withDuration: 0.2) {
                self.bubbleContainer.alpha = 0
                self.bubbleTailLarge.alpha = 0
                self.bubbleTailSmall.alpha = 0
                self.progressBarBackground.alpha = 0
                self.closeButton.alpha = 0
            }
        case .ended, .cancelled, .failed:
            resumeStoryTimer()
            UIView.animate(withDuration: 0.2) {
                self.bubbleContainer.alpha = 1
                self.bubbleTailLarge.alpha = 1
                self.bubbleTailSmall.alpha = 1
                self.progressBarBackground.alpha = 1
                self.closeButton.alpha = 1
            }
        default: break
        }
    }

    private func animateBubble() {
        bubbleContainer.transform = CGAffineTransform(scaleX: 0.1, y: 0.1).translatedBy(x: 100, y: 100)
        bubbleContainer.alpha = 0
        [bubbleTailLarge, bubbleTailSmall].forEach { $0.alpha = 0 }
        
        UIView.animate(withDuration: 0.5, delay: 0.1, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseOut) {
            self.bubbleContainer.transform = .identity
            self.bubbleContainer.alpha = 1
            [self.bubbleTailLarge, self.bubbleTailSmall].forEach { $0.alpha = 1 }
        }
    }

    @objc private func closeButtonTapped() { onCloseRequested?() }
}
