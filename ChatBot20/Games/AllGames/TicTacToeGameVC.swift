import UIKit
import SnapKit

class TicTacToeGameVC: BaseGameViewController {
    
    // MARK: - State
    enum Player {
        case user   // "X"
        case waifu  // "O"
    }
    
    private var board: [Player?] = Array(repeating: nil, count: 9)
    private var buttons: [UIButton] = []
    private var isGameOver = false
    
    private var userStartsNextGame = true
    private var isUserTurn = true

    override var gameRules: String {
        "gameRules4".localize()
    }

    override func didResetProgress() {
        resetGame(sender: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGameGrid()
        loadProgress()
        isUserTurn = userStartsNextGame
    }
    
    override func updateScore(waifu: Int, user: Int) {
        super.updateScore(waifu: waifu, user: user)

        let imageName: String
        switch userScore {
        case 0: imageName = "AGameGirls1"
        case 1: imageName = "AGameGirls2"
        case 2: imageName = "AGameGirls3"
        case 3: imageName = "AGameGirls4"
        case 4: imageName = "AGameGirls5"
        case 5: imageName = "AGameGirls6"
        case 6: imageName = "AGameGirls7"
        case 7: imageName = "AGameGirls8"
        case 8: imageName = "AGameGirls9"
        case 9...:
            let suffix = (userScore % 2 == 0) ? "7" : "9"
            imageName = "AGameGirls\(suffix)"
        default:
            imageName = "AGameGirls8"
        }

        guard ConfigService.shared.isTestB else {
            self.waifuImageView.image = UIImage(named: "AGameGirls1")
            return
        }
        
        UIView.animate(withDuration: 1) {
            self.waifuImageView.image = UIImage(named: imageName)
        }
    }
    
    // MARK: - UI Setup
    private func setupGameGrid() {
        let gridContainer = UIView()
        gameContainerView.addSubview(gridContainer)
        
        gridContainer.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(min(view.frame.width - 60, 300))
        }
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 10
        gridContainer.addSubview(stackView)
        
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        for row in 0..<3 {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fillEqually
            rowStack.spacing = 10
            stackView.addArrangedSubview(rowStack)
            
            for col in 0..<3 {
                let index = row * 3 + col
                let button = UIButton()
                button.backgroundColor = TelegramColors.cardBackground
                button.layer.cornerRadius = 12
                button.titleLabel?.font = .systemFont(ofSize: 40, weight: .bold)
                button.tag = index
                button.addTarget(self, action: #selector(cellTapped(_:)), for: .touchUpInside)
                
                rowStack.addArrangedSubview(button)
                buttons.append(button)
            }
        }
    }

    // MARK: - Game Logic
    @objc private func cellTapped(_ sender: UIButton) {
        let index = sender.tag
        
        // Добавлена проверка isUserTurn
        guard board[index] == nil, !isGameOver, isUserTurn else { return }
        
        isUserTurn = false // Блокируем ход юзера
        makeMove(at: index, for: .user)
        
        if !checkWinner() {
            setWaifuMessage("GamePhrases1".localize())
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                self?.waifuMove()
            }
        }
    }
    
    private func makeMove(at index: Int, for player: Player) {
        board[index] = player
        let symbol = (player == .user) ? "X" : "O"
        let color = (player == .user) ? .white : TelegramColors.primary
        
        buttons[index].setTitle(symbol, for: .normal)
        buttons[index].setTitleColor(color, for: .normal)
        
        buttons[index].transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        UIView.animate(withDuration: 0.2) {
            self.buttons[index].transform = .identity
        }
    }
    
    private func waifuMove() {
        guard !isGameOver else { return }
        
        let bestMove = findBestMove()
        makeMove(at: bestMove, for: .waifu)
        
        if !checkWinner() {
            isUserTurn = true // Возвращаем ход игроку
            setWaifuMessage("GamePhrases2".localize())
        }
    }
    
    private func findBestMove() -> Int {
        let winPatterns: [[Int]] = [
            [0,1,2], [3,4,5], [6,7,8],
            [0,3,6], [1,4,7], [2,5,8],
            [0,4,8], [2,4,6]
        ]
        
        for p in winPatterns {
            let vals = p.map { board[$0] }
            if vals.filter({ $0 == .waifu }).count == 2 && vals.filter({ $0 == nil }).count == 1 {
                return p[vals.firstIndex(of: nil)!]
            }
        }
        
        for p in winPatterns {
            let vals = p.map { board[$0] }
            if vals.filter({ $0 == .user }).count == 2 && vals.filter({ $0 == nil }).count == 1 {
                return p[vals.firstIndex(of: nil)!]
            }
        }
        
        if board[4] == nil { return 4 }
        
        let emptyIndices = board.enumerated().compactMap { $1 == nil ? $0 : nil }
        return emptyIndices.randomElement() ?? 0
    }
    
    private func checkWinner() -> Bool {
        let winPatterns: [[Int]] = [
            [0,1,2], [3,4,5], [6,7,8],
            [0,3,6], [1,4,7], [2,5,8],
            [0,4,8], [2,4,6]
        ]
        
        for p in winPatterns {
            if let p0 = board[p[0]], p0 == board[p[1]], p0 == board[p[2]] {
                declareWinner(p0)
                return true
            }
        }
        
        if !board.contains(nil) {
            declareWinner(nil)
            return true
        }
        
        return false
    }
    
    private func declareWinner(_ winner: Player?) {
        isGameOver = true
        if let winner = winner {
            if winner == .user {
                userScore += 1
                setWaifuMessage("GamePhrases3".localize())
            } else {
                waifuScore += 1
                setWaifuMessage("GamePhrases4".localize())
            }
            updateScore(waifu: waifuScore, user: userScore)
        } else {
            setWaifuMessage("GamePhrases5".localize())
        }
        
        showRestartButton()
    }
    
    private func showRestartButton() {
        let btn = UIButton(type: .system)
        btn.setTitle("GamePhrases6".localize(), for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        btn.tintColor = .white
        btn.backgroundColor = TelegramColors.primary
        btn.layer.cornerRadius = 20
        btn.addTarget(self, action: #selector(resetGame), for: .touchUpInside)
        
        view.addSubview(btn)
        btn.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(20)
            make.width.equalTo(200)
            make.height.equalTo(50)
        }
    }
    
    @objc private func resetGame(sender: UIButton?) {
        board = Array(repeating: nil, count: 9)
        buttons.forEach {
            $0.setTitle(nil, for: .normal)
            $0.transform = .identity
        }
        isGameOver = false
        sender?.removeFromSuperview()
        
        // ЛОГИКА ЧЕРЕДОВАНИЯ ХОДОВ
        userStartsNextGame.toggle()
        isUserTurn = userStartsNextGame
        
        if isUserTurn {
            setWaifuMessage("GamePhrases7".localize())
        } else {
            setWaifuMessage("GamePhrases8".localize())
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.waifuMove()
            }
        }
    }
}
