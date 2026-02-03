import UIKit
import SnapKit

// MARK: - StoryDetailViewDelegate
// Протокол для уведомления родительской View (AllChatsView) о событиях в StoryDetailView
// НОВОЕ: Добавлены методы для запроса следующей/предыдущей сторис.
protocol StoryDetailViewDelegate: AnyObject {
    func storyDetailViewDidRequestNextStory(currentStoryId: String) // Запрос следующей сторис
    func storyDetailViewDidRequestPreviousStory(currentStoryId: String) // Запрос предыдущей сторис
    func storyDetailViewDidRequestStartChat(currentStoryId: String)
    func storyDetailViewDidClosed()
}

class StoryDetailView: UIView {

    // MARK: - UI Elements

    private let backgroundImageView = UIImageView()
    private let dimmingView = UIView() // Полупрозрачный черный фон для затемнения изображения
    private let descriptionLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    // НОВОЕ: Кнопка "Start Chatting"
    private let startChatButton = UIButton(type: .system)

    // Единая полоска прогресса
    private let progressBarBackground = UIView() // Фон для единой полоски прогресса
    private let progressBarFiller = UIView()     // Заполняющая полоска прогресса (двигается слева направо)

    // MARK: - Properties

    weak var delegate: StoryDetailViewDelegate?

    private var storyTimer: Timer? // Таймер для закрытия сторис через storyDuration
    private var progressUpdateTimer: Timer? // Таймер для пошагового обновления прогресс-бара
    private var startTime: Date? // Время начала показа текущей сторис

    private let storyDuration: TimeInterval = 5.0 // Длительность показа сторис (5 секунд)
    private let progressUpdateTimeInterval: TimeInterval = 0.05 // Частота обновления прогресс-бара

    private var currentStory: StoryModel?

    // Ссылка на констрейнт ширины progressBarFiller
    private var progressBarFillerWidthConstraint: Constraint?
    private let isRTL = UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft

    // Telegram цвета (лучше вынести в общий файл)
    private struct TelegramColors {
        static let textPrimary = UIColor.white
        static let progressBackground = UIColor.white.withAlphaComponent(0.2)
        static let progressForeground = UIColor.white
        static let primaryButtonBackground = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0) // #3390DC
    }

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupGestures() // НОВОЕ: Настройка жестов
        updateTextForIPadIfNeeded()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup UI

    private func setupViews() {
        backgroundColor = .clear // Прозрачный фон для анимации

        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        addSubview(backgroundImageView)

        dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        addSubview(dimmingView)
        
        // Единый прогресс-бар (фон)
        progressBarBackground.backgroundColor = TelegramColors.progressBackground
        progressBarBackground.layer.cornerRadius = 1
        progressBarBackground.clipsToBounds = true
        addSubview(progressBarBackground)

        // Единый прогресс-бар (заполняющая часть)
        progressBarFiller.backgroundColor = TelegramColors.progressForeground
        progressBarFiller.layer.cornerRadius = 1
        progressBarBackground.addSubview(progressBarFiller) // Filler внутри Background
        
        // Текст описания
        descriptionLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        descriptionLabel.textColor = TelegramColors.textPrimary
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
        descriptionLabel.shadowColor = .black
        descriptionLabel.shadowOffset = CGSize(width: 1, height: 1)
        dimmingView.addSubview(descriptionLabel)

        // Кнопка закрытия
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 28, weight: .bold)
        ), for: .normal)
        closeButton.tintColor = .white.withAlphaComponent(0.8)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        addSubview(closeButton)
        
        // НОВОЕ: Кнопка "Start Chatting"
        startChatButton.setTitle("StartChatting".localize(), for: .normal)
        startChatButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        startChatButton.backgroundColor = TelegramColors.primaryButtonBackground
        startChatButton.setTitleColor(TelegramColors.textPrimary, for: .normal)
        startChatButton.layer.cornerRadius = 12
        startChatButton.clipsToBounds = true
        startChatButton.addTarget(self, action: #selector(startChatButtonTapped), for: .touchUpInside)
        addSubview(startChatButton)

        // Constraints
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        dimmingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // Констрейнты для единого прогресс-бара
        progressBarBackground.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide).inset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(4) // Высота полоски
        }

        // Констрейнты для заполняющей части (изначально 0 ширина)
        progressBarFiller.snp.makeConstraints { make in
            make.top.bottom.leading.equalToSuperview()
            // Присваиваем констрейнт ширины свойству
            progressBarFillerWidthConstraint = make.width.equalTo(0).constraint
        }

        closeButton.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide).inset(16)
            make.trailing.equalToSuperview().inset(16)
            make.width.height.equalTo(44)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(40)
            make.bottom.equalTo(startChatButton.snp.top).offset(-20) // НОВОЕ: descriptionLabel над кнопкой
        }

        // НОВОЕ: Констрейнты для кнопки "Start Chatting"
        startChatButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(40)
            make.bottom.equalTo(safeAreaLayoutGuide).inset(20)
            make.height.equalTo(50)
        }
    }

    // НОВОЕ: Настройка жестов
    private func setupGestures() {
        // Жест тапа (разделение на левую/правую половину)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        dimmingView.addGestureRecognizer(tapGesture)

        // Жест свайпа влево
        let swipeLeftGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeGesture(_:)))
        swipeLeftGesture.direction = .left
        dimmingView.addGestureRecognizer(swipeLeftGesture)

        // Жест свайпа вправо
        let swipeRightGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeGesture(_:)))
        swipeRightGesture.direction = .right
        dimmingView.addGestureRecognizer(swipeRightGesture)
        
        // Жест долгого нажатия для паузы
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressGesture(_:)))
        longPressGesture.minimumPressDuration = 0.2 // Короткое нажатие, чтобы реагировало быстро
        dimmingView.addGestureRecognizer(longPressGesture)
    }

    // MARK: - Configuration

    func configure(with story: StoryModel) {
        AnalyticService.shared.logEvent(name: "Story viewed with id: \(story.id)", properties: ["":""])
        
        self.currentStory = story
        
        backgroundImageView.image = UIImage(named: story.detailImageName)
        
        descriptionLabel.text = story.description
        
        if !MainHelper.shared.viewedStoriesId.contains(story.id) {
            MainHelper.shared.viewedStoriesId.append(story.id)
        }
        
        startStoryTimer() // Запускаем таймеры для этой сторис
    }

    // MARK: - Timer & Progress Animation

    private func startStoryTimer() {
        invalidateAllTimers() // Очищаем все предыдущие таймеры

        // Сбрасываем ширину прогресс-бара до нуля через констрейнт
        progressBarFillerWidthConstraint?.update(offset: 0)
        self.layoutIfNeeded() // Принудительно обновляем лейаут для начального состояния (0 ширина)

        startTime = Date() // Запоминаем время начала показа сторис

        // Таймер для пошагового обновления прогресс-бара
        progressUpdateTimer = Timer.scheduledTimer(withTimeInterval: progressUpdateTimeInterval, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.startTime else { return }

            let elapsedTime = Date().timeIntervalSince(startTime)
            let progress = min(1.0, elapsedTime / self.storyDuration) // Прогресс от 0.0 до 1.0

            let newWidth = self.progressBarBackground.bounds.width * CGFloat(progress)
            
            // Анимируем изменение ширины прогресс-бара
            // Анимация должна быть очень короткой, чтобы имитировать плавное движение
            UIView.animate(withDuration: self.progressUpdateTimeInterval, delay: 0, options: .curveLinear) {
                self.progressBarFillerWidthConstraint?.update(offset: newWidth)
                // !!! ВАЖНО: layoutIfNeeded() НЕ должен быть здесь внутри анимационного блока для плавного прогресса
                // Он вызывался бы на каждом шаге таймера, мгновенно пересчитывая лейаут
            }
            

            // Если прогресс достиг 100%, останавливаем таймер обновления прогресса
            if progress >= 1.0 {
                self.progressUpdateTimer?.invalidate()
                self.progressUpdateTimer = nil
            }
        }
        
        // Таймер для закрытия сторис по истечении storyDuration
        storyTimer = Timer.scheduledTimer(withTimeInterval: storyDuration, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.showNextStory() // Закрываем сторис по истечении 5 секунд
        }
    }
    
    private func invalidateAllTimers() {
        storyTimer?.invalidate()
        storyTimer = nil
        progressUpdateTimer?.invalidate()
        progressUpdateTimer = nil
        // НОВОЕ: Сброс анимации прогресс-бара при остановке таймеров
        progressBarFiller.layer.removeAllAnimations()
    }
    
    // MARK: - Actions

    @objc private func startChatButtonTapped() {
        if let currentStoryId = currentStory?.id {
            dismiss()
            delegate?.storyDetailViewDidRequestStartChat(currentStoryId: currentStoryId)
        }
    }
    
    @objc private func closeButtonTapped() {
        dismiss()
    }
    
    // НОВОЕ: Обработчик тапа по экрану (разделение на левую/правую половину)
    @objc private func handleTapGesture(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        let screenWidth = bounds.width

        if isRTL {
            if location.x < screenWidth / 2 {
                showNextStory()
            } else {
                showPreviousStory()
            }
        } else {
            if location.x < screenWidth / 2 {
                showPreviousStory()
            } else {
                showNextStory()
            }
        }
    }

    // НОВОЕ: Обработчик свайпа
    @objc private func handleSwipeGesture(_ gesture: UISwipeGestureRecognizer) {
        switch gesture.direction {
        case .left:
            if isRTL {
                showPreviousStory()
            } else {
                showNextStory()
            }
        case .right:
            if isRTL {
                showNextStory()
            } else {
                showPreviousStory()
            }
        default:
            break
        }
    }
    
    // НОВОЕ: Обработчик долгого нажатия для паузы/возобновления
    @objc private func handleLongPressGesture(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            pauseStory() // Пауза при начале долгого нажатия
        case .ended, .cancelled:
            resumeStory() // Возобновление при отпускании или отмене
        default:
            break
        }
    }

    private func pauseStory() {
        storyTimer?.invalidate() // Останавливаем таймер закрытия
        progressUpdateTimer?.invalidate() // Останавливаем таймер обновления прогресса
        progressBarFiller.layer.pauseAnimation() // Паузим анимацию прогресс-бара
    }

    private func resumeStory() {
        progressBarFiller.layer.resumeAnimation()
        storyTimer = Timer.scheduledTimer(withTimeInterval: storyDuration, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.showNextStory()
        }
        startStoryTimer()
    }
    
    // НОВОЕ: Методы для запроса следующей/предыдущей сторис (информируют делегат)
    private func showNextStory() {
        if let currentStoryId = currentStory?.id {
            delegate?.storyDetailViewDidRequestNextStory(currentStoryId: currentStoryId)
        }
        invalidateAllTimers() // Останавливаем таймеры текущей сторис
    }

    private func showPreviousStory() {
        if let currentStoryId = currentStory?.id {
            delegate?.storyDetailViewDidRequestPreviousStory(currentStoryId: currentStoryId)
        }
        invalidateAllTimers() // Останавливаем таймеры текущей сторис
    }

    // MARK: - Presentation and Dismissal

    func show(in view: UIView) {
        self.alpha = 0
        self.transform = CGAffineTransform(scaleX: 0.8, y: 0.8) // Начальное состояние для анимации
        view.addSubview(self) // Добавляем себя как субвью к родительской вью (AllChatsView)

        self.snp.makeConstraints { make in
            make.edges.equalToSuperview() // Растягиваем на всю родительскую вью
        }
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
            self.alpha = 1
            self.transform = .identity
        }, completion: nil)
    }

    func dismiss() {
        invalidateAllTimers() // Останавливаем все таймеры при закрытии
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 0
            self.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            self.delegate?.storyDetailViewDidClosed()
        }) { [weak self] _ in
            self?.removeFromSuperview() // Удаляем себя из иерархии вью
        }
    }
    
    deinit {
        invalidateAllTimers() // Гарантируем остановку таймеров при deinit
    }
}

extension StoryDetailView {
    func updateTextForIPadIfNeeded() {
        guard isCurrentDeviceiPad() else { return }
        
        descriptionLabel.font = UIFont.systemFont(ofSize: 40, weight: .semibold)
        startChatButton.titleLabel?.font = UIFont.systemFont(ofSize: 38, weight: .bold)
        
        descriptionLabel.snp.updateConstraints { make in
            make.leading.trailing.equalToSuperview().inset(80)
            make.bottom.equalTo(startChatButton.snp.top).offset(-80)
        }
        
        startChatButton.snp.updateConstraints { make in
            make.height.equalTo(80)
        }
    }
}
