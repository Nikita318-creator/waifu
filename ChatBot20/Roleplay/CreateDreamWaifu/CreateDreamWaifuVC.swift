import UIKit
import SnapKit

class CreateDreamWaifuVC: UIViewController {

    // MARK: - UI Colors
    struct TelegramColors {
        static let primary = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0)
        static let background = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
        static let cardBackground = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1.0)
        static let textPrimary = UIColor.white
        static let textSecondary = UIColor(red: 0.64, green: 0.64, blue: 0.66, alpha: 1.0)
        static let bubbleBackground = UIColor(red: 0.22, green: 0.22, blue: 0.24, alpha: 1.0)
        static let accentRed = UIColor(red: 0.9, green: 0.3, blue: 0.3, alpha: 1.0)
        static let selectedOption = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 0.3)
        static let unselectedOption = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1.0)
    }

    private let viewModel = CreateDreamWaifuViewModel()
    private lazy var slides: [WaifuSlideData] = viewModel.slides
    
    // MARK: - UI Components
    private lazy var progressBar: UIProgressView = {
        let view = UIProgressView(progressViewStyle: .bar)
        view.trackTintColor = TelegramColors.bubbleBackground
        view.progressTintColor = TelegramColors.primary
        view.layer.cornerRadius = 2
        view.clipsToBounds = true
        return view
    }()

    private lazy var closeButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "xmark"), for: .normal)
        btn.tintColor = TelegramColors.textSecondary
        btn.addTarget(self, action: #selector(handleClose), for: .touchUpInside)
        return btn
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.isPagingEnabled = true
        cv.showsHorizontalScrollIndicator = false
        cv.isScrollEnabled = false
        cv.register(DreamWaifuCell.self, forCellWithReuseIdentifier: DreamWaifuCell.identifier)
        cv.dataSource = self
        cv.delegate = self
        return cv
    }()

    private lazy var actionButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("CreateDreamWaifu.action.next".localize(), for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = TelegramColors.textSecondary
        btn.layer.cornerRadius = 16
        btn.addTarget(self, action: #selector(handleNext), for: .touchUpInside)
        btn.isEnabled = false
        return btn
    }()

    private var currentIndex: Int = 0
    private let selectionManager = WaifuSelectionManager.shared

    var onSuccessCreated: (() -> Void)?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateProgress()
        updateTextForIPadIfNeeded()
        checkSlideCompletion()
        
        AnalyticService.shared.logEvent(name: "CreateDreamWaifuVC opend", properties: ["":""])
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = TelegramColors.background
        collectionView.semanticContentAttribute = .forceLeftToRight
        
        view.addSubview(progressBar)
        view.addSubview(collectionView)
        view.addSubview(actionButton)
        view.addSubview(closeButton)
        
        progressBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(4)
        }
        
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.trailing.equalToSuperview().inset(16)
            make.size.equalTo(40)
        }
        
        actionButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(56)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(progressBar.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(actionButton.snp.top).offset(-20)
        }
    }
    
    // MARK: - Actions
    @objc private func handleClose() {
        dismiss(animated: true)
    }
    
    @objc private func handleNext() {
        if currentIndex < slides.count - 1 {
            currentIndex += 1
            let indexPath = IndexPath(item: currentIndex, section: 0)
            collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            updateProgress()
            updateButtonTitle()
            checkSlideCompletion()
        } else {
            checkSubscriptionAndFinish()
        }
    }
    
    private func checkSubscriptionAndFinish() {
        if IAPService.shared.hasActiveSubscription {
            let config = selectionManager.getFinalConfiguration()
            print("✅ Waifu Created!")
            AnalyticService.shared.logEvent(name: "CreateDreamWaifuVC Waifu Created!", properties: ["config":"\(config)"])
            
            let waifuDict = config["waifu_config"] as? [String: [String]] ?? [:]
//            let userInfo = waifuDict.compactMap { key, values -> String? in
//                guard let value = values.first else { return nil }
//                let readableKey = key.replacingOccurrences(of: "_", with: " ").capitalized
//                return "\(readableKey): \(value)"
//            }.joined(separator: ", ")

            var userInfo = waifuDict["archetype"]?.first ?? "Classic"
            print("🤖 System Prompt Context: \(userInfo)")
            
            let assistantName = (1...20)
                .map { "CreateDreamWaifu.name\($0)" }
                .randomElement() ?? "CreateDreamWaifu.name1"

            // MARK: - Logic for dynamic Image selection
            let eyeType = (config["waifu_config"] as? [String: [String]])?["eye_type"]?.first ?? ""
            let avatarImageName: String
            let countKey = "count_\(eyeType)"
            let lastIdxKey = "lastIdx_\(eyeType)"
            let creationCount = UserDefaults.standard.integer(forKey: countKey)
            let lastIndex = UserDefaults.standard.integer(forKey: lastIdxKey) // 1 или 2
            
            let imagePrefix: String
            switch eyeType {
            case "CreateDreamWaifu.option.almond".localize():           imagePrefix = "CreateDreamWaifu1"
            case "CreateDreamWaifu.option.big_doe".localize():          imagePrefix = "CreateDreamWaifu2"
            case "CreateDreamWaifu.option.glowing_red".localize():      imagePrefix = "CreateDreamWaifu3"
            case "CreateDreamWaifu.option.mysterious_purple".localize(): imagePrefix = "CreateDreamWaifu4"
            default:                                                    imagePrefix = "CreateDreamWaifu1"
            }
            
            if creationCount >= 3 {
                let randomSuffix = ["", "_1"].randomElement() ?? ""
                avatarImageName = "\(imagePrefix)\(randomSuffix)"
            } else {
                let newIndex = (lastIndex == 1) ? 2 : 1
                let suffix = (newIndex == 2) ? "_1" : ""
                avatarImageName = "\(imagePrefix)\(suffix)"
                
                UserDefaults.standard.set(newIndex, forKey: lastIdxKey)
                UserDefaults.standard.set(creationCount + 1, forKey: countKey)
            }
            
            let createdAssistantID = UUID().uuidString
            let createdAssistant = AssistantConfig(
                id: createdAssistantID,
                assistantName: assistantName.localize(),
                expertise: .roleplay,
                assistantInfo: "",
                userInfo: userInfo,
                avatarImageName: avatarImageName
            )
            
            let messageId = UUID().uuidString
            AssistantsService().addConfig(createdAssistant)
            MessageHistoryService().addMessage(
                Message(role: "assistant", content: "Roleplay.Hi".localize(), id: messageId),
                assistantId: createdAssistantID,
                messageId: messageId
            )
            
            MainHelper.shared.needOpenChatWithId = createdAssistantID

            showCompletionAlert()
        } else {
            UIView.animate(withDuration: 0.3) {
                self.showSubs()
            }
        }
    }
    
    private func showSubs() {
        let subsView = SubsView()
        subsView.vc = self
        subsView.onPaywallClosedHandler = { [weak self] in
            self?.tabBarController?.tabBar.isHidden = false
        }
        
        AnalyticService.shared.logEvent(name: "showSubs from CreateDreamWaifu", properties: ["":""])
        
        view.addSubview(subsView)

        subsView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            subsView.yearlyButtonTapped()
        }
    }
    
    private func showCompletionAlert() {
        let alert = UIAlertController(
            title: "CreateDreamWaifu.alert.title".localize(),
            message: "CreateDreamWaifu.alert.message".localize(),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "CreateDreamWaifu.alert.button".localize(), style: .default) { _ in
            self.onSuccessCreated?()
            self.selectionManager.clearAll() // только тут сбрасывать думаю - а иначе не сбрасываем прогресс юзера
            self.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
    
    private func updateProgress() {
        let progress = Float(currentIndex + 1) / Float(slides.count)
        progressBar.setProgress(progress, animated: true)
    }
    
    private func updateButtonTitle() {
        if currentIndex == slides.count - 1 {
            actionButton.setTitle("CreateDreamWaifu.action.finish".localize(), for: .normal)
        } else {
            let remaining = slides.count - currentIndex - 1
            let format = "CreateDreamWaifu.action.next_count".localize()
            actionButton.setTitle(String(format: format, remaining), for: .normal)
        }
    }
    
    // MARK: - Selection Callback
    func didUpdateSelection() {
        checkSlideCompletion()
        
        let indexPath = IndexPath(item: currentIndex, section: 0)
        if let cell = collectionView.cellForItem(at: indexPath) as? DreamWaifuCell {
            cell.refreshSelections()
        }
    }
    
    private func checkSlideCompletion() {
        let currentSlide = slides[currentIndex]
        let isComplete = selectionManager.isSlideComplete(questions: currentSlide.questions)
        
        actionButton.isEnabled = isComplete
        
        UIView.animate(withDuration: 0.3) {
            self.actionButton.backgroundColor = isComplete
                ? (self.currentIndex == self.slides.count - 1
                    ? TelegramColors.accentRed
                    : TelegramColors.primary)
                : TelegramColors.textSecondary
        }
    }
}

// MARK: - UICollectionView DataSource & Delegate
extension CreateDreamWaifuVC: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return slides.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DreamWaifuCell.identifier, for: indexPath) as? DreamWaifuCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: slides[indexPath.item], delegate: self)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.bounds.size
    }
}

// MARK: - iPad Support
extension CreateDreamWaifuVC {
    func updateTextForIPadIfNeeded() {
        guard view.isCurrentDeviceiPad() else { return }
        actionButton.titleLabel?.font = .systemFont(ofSize: 24, weight: .bold)
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            self.collectionView.collectionViewLayout.invalidateLayout()
            let indexPath = IndexPath(item: self.currentIndex, section: 0)
            self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
        }, completion: nil)
    }
}
