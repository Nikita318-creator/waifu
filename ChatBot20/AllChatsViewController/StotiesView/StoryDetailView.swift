import UIKit
import SnapKit

protocol StoryDetailViewDelegate: AnyObject {
    func storyDetailViewDidRequestNextStory(currentStoryId: String)
    func storyDetailViewDidRequestPreviousStory(currentStoryId: String)
    func storyDetailViewDidRequestStartChat(currentStoryId: String)
    func storyDetailViewDidClosed()
}

class StoryDetailView: UIView {

    private let backgroundImageView = UIImageView()
    private let closeButton = UIButton(type: .system)
    
    private let bubbleContainer = UIView()
    private let bubbleLabel = UILabel()
    private let bubbleTailLarge = UIView()
    private let bubbleTailSmall = UIView()

    private let progressBarBackground = UIView()
    private let progressBarFiller = UIView()

    weak var delegate: StoryDetailViewDelegate?
    private var storyTimer: Timer?
    private var progressUpdateTimer: Timer?
    private var startTime: Date?
    private let storyDuration: TimeInterval = 10.0
    private let progressUpdateTimeInterval: TimeInterval = 0.05
    private var currentStory: StoryModel?
    private var progressBarFillerWidthConstraint: Constraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupGestures()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupViews() {
        backgroundColor = .black

        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        addSubview(backgroundImageView)

        progressBarBackground.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        progressBarBackground.layer.cornerRadius = 2
        addSubview(progressBarBackground)

        progressBarFiller.backgroundColor = .white
        progressBarFiller.layer.cornerRadius = 2
        progressBarBackground.addSubview(progressBarFiller)

        closeButton.setImage(UIImage(systemName: "xmark")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
        ), for: .normal)
        closeButton.tintColor = .white
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        addSubview(closeButton)

        setupBubbleUI()

        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        progressBarBackground.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide).inset(10)
            make.leading.trailing.equalToSuperview().inset(10)
            make.height.equalTo(4)
        }

        progressBarFiller.snp.makeConstraints { make in
            make.top.bottom.leading.equalToSuperview()
            progressBarFillerWidthConstraint = make.width.equalTo(0).constraint
        }

        closeButton.snp.makeConstraints { make in
            make.top.equalTo(progressBarBackground.snp.bottom).offset(15)
            make.trailing.equalToSuperview().inset(15)
            make.width.height.equalTo(30)
        }
    }

    private func setupBubbleUI() {
        bubbleContainer.backgroundColor = .white
        bubbleContainer.layer.cornerRadius = 20
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

        bubbleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(15)
        }

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
        
        animateBubble()
        startStoryTimer()
    }
    
    private func animateBubble() {
        bubbleContainer.transform = CGAffineTransform(scaleX: 0.1, y: 0.1).translatedBy(x: 100, y: 100)
        bubbleContainer.alpha = 0
        [bubbleTailLarge, bubbleTailSmall].forEach { $0.alpha = 0 }
        
        UIView.animate(withDuration: 0.5, delay: 0.1, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseOut) {
            self.bubbleContainer.transform = .identity
            self.bubbleContainer.alpha = 1
            self.bubbleTailLarge.alpha = 1
            self.bubbleTailSmall.alpha = 1
        }
    }

    private func startStoryTimer() {
        invalidateAllTimers()
        progressBarFillerWidthConstraint?.update(offset: 0)
        layoutIfNeeded()

        startTime = Date()
        progressUpdateTimer = Timer.scheduledTimer(withTimeInterval: progressUpdateTimeInterval, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.startTime else { return }
            let elapsedTime = Date().timeIntervalSince(startTime)
            let progress = min(1.0, elapsedTime / self.storyDuration)
            let newWidth = self.progressBarBackground.bounds.width * CGFloat(progress)
            self.progressBarFillerWidthConstraint?.update(offset: newWidth)
        }
        
        storyTimer = Timer.scheduledTimer(withTimeInterval: storyDuration, repeats: false) { [weak self] _ in
            self?.showNextStory()
        }
    }

    private func invalidateAllTimers() {
        storyTimer?.invalidate()
        progressUpdateTimer?.invalidate()
        storyTimer = nil
        progressUpdateTimer = nil
    }

    private func setupGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tap)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.2
        addGestureRecognizer(longPress)
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        location.x < bounds.width / 2 ? showPreviousStory() : showNextStory()
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            invalidateAllTimers()
        } else if gesture.state == .ended {
            startStoryTimer()
        }
    }

    private func showNextStory() {
        if let id = currentStory?.id { delegate?.storyDetailViewDidRequestNextStory(currentStoryId: id) }
    }

    private func showPreviousStory() {
        if let id = currentStory?.id { delegate?.storyDetailViewDidRequestPreviousStory(currentStoryId: id) }
    }

    @objc private func closeButtonTapped() { dismiss() }

    func show(in view: UIView) {
        self.alpha = 0
        view.addSubview(self)
        self.snp.makeConstraints { $0.edges.equalToSuperview() }
        UIView.animate(withDuration: 0.3) { self.alpha = 1 }
    }

    func dismiss() {
        invalidateAllTimers()
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 0
        }) { _ in
            self.delegate?.storyDetailViewDidClosed()
            self.removeFromSuperview()
        }
    }
}
