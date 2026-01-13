import UIKit
import SnapKit

class RockPaperScissorsGameVC: BaseGameViewController {
    
    enum Choice: String, CaseIterable {
        case rock = "👊"
        case paper = "✋"
        case scissors = "✌️"
        
        static func random() -> Choice {
            return Choice.allCases.randomElement()!
        }
        
        func beats(_ other: Choice) -> Bool? {
            if self == other { return nil }
            switch self {
            case .rock: return other == .scissors
            case .paper: return other == .rock
            case .scissors: return other == .paper
            }
        }
    }
    
    // MARK: - State
    private var userChoice: Choice = .rock
    private var isCounting = false
    private var countdownTimer: Timer?
    private var currentCount = 0
    private let countdownKeys = ["GameCount1", "GameCount2", "GameCount3", "GameCount4"]
    
    // MARK: - UI Elements
    private let waifuChoiceLabel = UILabel()
    private let userChoiceLabel = UILabel()
    private let vsLabel = UILabel()
    private let playButton = UIButton(type: .system)
    private var choiceButtons: [Choice: UIButton] = [:]
    
    override var gameRules: String {
        "gameRulesRPS".localize()
    }
    
    override func didResetProgress() {
        resetToIdle()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGameUI()
        loadProgress()
        resetToIdle()
    }
    
    override func updateScore(waifu: Int, user: Int) {
        super.updateScore(waifu: waifu, user: user)

        let imageName: String
        switch userScore {
        case 0: imageName = "roleplay11"
        case 1: imageName = "CGameGirls1"
        case 2: imageName = "CGameGirls2"
        case 3: imageName = "CGameGirls3"
        case 4: imageName = "CGameGirls4"
        case 5: imageName = "CGameGirls5"
        case 6: imageName = "CGameGirls6"
        case 7: imageName = "CGameGirls7"
        case 8: imageName = "CGameGirls8"
        case 9: imageName = "CGameGirls9"
        case 10...:
            let suffix = (userScore % 2 == 0) ? "8" : "9"
            imageName = "CGameGirls\(suffix)"
        default:
            imageName = "AGameGirls8"
        }

        guard ConfigService.shared.isTestB else {
            self.waifuImageView.image = UIImage(named: "roleplay11")
            return
        }
            
        UIView.animate(withDuration: 1) {
            self.waifuImageView.image = UIImage(named: imageName)
        }
    }
    
    // MARK: - UI Setup
    private func setupGameUI() {
        vsLabel.text = "VS"
        vsLabel.font = .systemFont(ofSize: 32, weight: .black)
        vsLabel.textColor = TelegramColors.textSecondary
        gameContainerView.addSubview(vsLabel)
        
        waifuChoiceLabel.font = .systemFont(ofSize: 90)
        waifuChoiceLabel.text = "❓"
        gameContainerView.addSubview(waifuChoiceLabel)
        
        userChoiceLabel.font = .systemFont(ofSize: 90)
        userChoiceLabel.text = "👊"
        gameContainerView.addSubview(userChoiceLabel)
        
        let controlsStack = UIStackView()
        controlsStack.axis = .horizontal
        controlsStack.distribution = .fillEqually
        controlsStack.spacing = 15
        gameContainerView.addSubview(controlsStack)
        
        playButton.setTitle("GameStartBtn".localize(), for: .normal)
        playButton.titleLabel?.font = .systemFont(ofSize: 22, weight: .bold)
        playButton.backgroundColor = TelegramColors.primary
        playButton.tintColor = .white
        playButton.layer.cornerRadius = 25
        playButton.addTarget(self, action: #selector(startRound), for: .touchUpInside)
        gameContainerView.addSubview(playButton)

        // --- CONSTRAINTS ---

        controlsStack.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(30)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(80)
        }

        playButton.snp.makeConstraints { make in
            make.bottom.equalTo(controlsStack.snp.top).offset(-25)
            make.centerX.equalToSuperview()
            make.width.equalTo(220)
            make.height.equalTo(55)
        }

        vsLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(playButton.snp.top).offset(-60)
        }

        waifuChoiceLabel.snp.makeConstraints { make in
            make.centerY.equalTo(vsLabel.snp.centerY).offset(-40)
            make.centerX.equalTo(vsLabel.snp.centerX).offset(100)
        }

        userChoiceLabel.snp.makeConstraints { make in
            make.centerY.equalTo(vsLabel.snp.centerY).offset(-40)
            make.centerX.equalTo(vsLabel.snp.centerX).offset(-100)
        }

        for choice in Choice.allCases {
            let btn = UIButton()
            btn.setTitle(choice.rawValue, for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 40)
            btn.backgroundColor = TelegramColors.cardBackground
            btn.layer.cornerRadius = 20
            btn.layer.borderWidth = 3
            btn.layer.borderColor = UIColor.clear.cgColor
            btn.addTarget(self, action: #selector(choiceTapped(_:)), for: .touchUpInside)
            choiceButtons[choice] = btn
            controlsStack.addArrangedSubview(btn)
        }
    }
    
    @objc private func choiceTapped(_ sender: UIButton) {
        // Логика: выбор работает только когда идет отсчет
        guard isCounting,
              let choiceStr = sender.title(for: .normal),
              let choice = Choice.allCases.first(where: { $0.rawValue == choiceStr }) else { return }
        
        userChoice = choice
        updateChoiceSelection()
        userChoiceLabel.text = choice.rawValue
        
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
    
    @objc private func startRound() {
        guard !isCounting else { return }
        
        isCounting = true
        currentCount = 0
        
        // Визуальное состояние кнопок при старте
        playButton.isEnabled = false
        playButton.alpha = 0.5
        
        // Разблокируем выбор для пользователя
        choiceButtons.values.forEach {
            $0.isEnabled = true
            $0.alpha = 1.0
        }
        
        waifuChoiceLabel.text = "❓"
        userChoice = .rock
        updateChoiceSelection()
        userChoiceLabel.text = userChoice.rawValue
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 0.7, repeats: true) { [weak self] timer in
            self?.handleTimerTick()
        }
    }
    
    private func handleTimerTick() {
        if currentCount < countdownKeys.count {
            setWaifuMessage(countdownKeys[currentCount].localize())
            currentCount += 1
            animateShake()
        } else {
            finishRound()
        }
    }
    
    private func finishRound() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        isCounting = false
        
        // Блокируем выбор обратно - раунд окончен
        choiceButtons.values.forEach {
            $0.isEnabled = false
            $0.alpha = 0.6
        }
        
        let waifuChoice = Choice.random()
        waifuChoiceLabel.text = waifuChoice.rawValue
        
        if let userWins = userChoice.beats(waifuChoice) {
            if userWins {
                userScore += 1
                setWaifuMessage("GameWinRPS".localize())
            } else {
                waifuScore += 1
                setWaifuMessage("GameLoseRPS".localize())
            }
            updateScore(waifu: waifuScore, user: userScore)
        } else {
            setWaifuMessage("GameDrawRPS".localize())
        }
        
        playButton.isEnabled = true
        playButton.alpha = 1.0
        playButton.setTitle("GameAgainBtn".localize(), for: .normal)
    }
    
    private func updateChoiceSelection() {
        choiceButtons.forEach { choice, btn in
            btn.layer.borderColor = (choice == userChoice) ? TelegramColors.primary.cgColor : UIColor.clear.cgColor
        }
    }
    
    private func resetToIdle() {
        userChoice = .rock
        updateChoiceSelection()
        
        // Кнопки заблокированы до нажатия PLAY
        choiceButtons.values.forEach {
            $0.isEnabled = false
            $0.alpha = 0.6
        }
    }
    
    private func animateShake() {
        [waifuChoiceLabel, userChoiceLabel].forEach { label in
            let anim = CABasicAnimation(keyPath: "position")
            anim.duration = 0.07
            anim.repeatCount = 2
            anim.autoreverses = true
            anim.fromValue = NSValue(cgPoint: CGPoint(x: label.center.x - 10, y: label.center.y))
            anim.toValue = NSValue(cgPoint: CGPoint(x: label.center.x + 10, y: label.center.y))
            label.layer.add(anim, forKey: "position")
        }
    }
}
