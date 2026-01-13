import UIKit
import SnapKit

class Merge2048GameVC: BaseGameViewController {
    
    private let gridSize = 4
    private var board: [[Int]] = []
    private var tileViews: [UUID: TileView] = [:]
    private var tileIds: [[UUID?]] = Array(repeating: Array(repeating: nil, count: 4), count: 4)
    
    private let targetValue = 2048
    private var isGameOver = false
    private let spacing: CGFloat = 8
    private var cellSize: CGFloat = 0
    private let gridContainer = UIView()
    
    override var gameRules: String {
        "gameRules3".localize()
    }

    override func didResetProgress() {
        resetBoard()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadProgress()
        setupGameField()
        resetBoard()
        addSwipeGestures()
    }

    override func updateScore(waifu: Int, user: Int) {
        super.updateScore(waifu: waifu, user: user)

        let imageName: String
        switch userScore {
        case 0: imageName = "GameGirls1"
        case 1: imageName = "GameGirls2"
        case 2: imageName = "GameGirls3"
        case 3: imageName = "GameGirls4"
        case 4: imageName = "GameGirls5"
        case 5: imageName = "GameGirls6"
        case 6: imageName = "GameGirls7"
        case 7...:
            let suffix = (userScore % 2 == 0) ? "7" : "8"
            imageName = "GameGirls\(suffix)"
        default:
            imageName = "GameGirls8"
        }

        guard ConfigService.shared.isTestB else {
            self.waifuImageView.image = UIImage(named: "GameGirls1")
            return
        }
        
        UIView.animate(withDuration: 1) {
            self.waifuImageView.image = UIImage(named: imageName)
        }
    }
    
    private func setupGameField() {
        let fieldSize = min(view.frame.width - 40, 320)
        cellSize = (fieldSize - (CGFloat(gridSize + 1) * spacing)) / CGFloat(gridSize)
        
        gridContainer.backgroundColor = TelegramColors.bubbleBackground
        gridContainer.layer.cornerRadius = 12
        gameContainerView.addSubview(gridContainer)
        
        gridContainer.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(fieldSize)
        }
        
        for r in 0..<gridSize {
            for c in 0..<gridSize {
                let bg = UIView()
                bg.backgroundColor = TelegramColors.cardBackground
                bg.layer.cornerRadius = 8
                gridContainer.addSubview(bg)
                bg.frame = frameForCell(atRow: r, col: c)
            }
        }
    }

    private func frameForCell(atRow row: Int, col: Int) -> CGRect {
        let x = spacing + CGFloat(col) * (cellSize + spacing)
        let y = spacing + CGFloat(row) * (cellSize + spacing)
        return CGRect(x: x, y: y, width: cellSize, height: cellSize)
    }

    private func resetBoard() {
        board = Array(repeating: Array(repeating: 0, count: gridSize), count: gridSize)
        tileIds = Array(repeating: Array(repeating: nil, count: gridSize), count: gridSize)
        tileViews.values.forEach { $0.removeFromSuperview() }
        tileViews.removeAll()
        
        isGameOver = false
        addRandomTile()
        addRandomTile()
    }

    private func addRandomTile() {
        var emptyCells: [(Int, Int)] = []
        for r in 0..<gridSize {
            for c in 0..<gridSize {
                if board[r][c] == 0 { emptyCells.append((r, c)) }
            }
        }
        
        if let randomCell = emptyCells.randomElement() {
            let value = Double.random(in: 0...1) < 0.9 ? 2 : 4
            let r = randomCell.0, c = randomCell.1
            let id = UUID()
            
            board[r][c] = value
            tileIds[r][c] = id
            
            let tile = TileView(frame: frameForCell(atRow: r, col: c), value: value)
            tile.backgroundColor = getTileColor(value)
            gridContainer.addSubview(tile)
            tileViews[id] = tile
            tile.appearanceAnim()
        }
    }

    private func renderBoard() {
        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseOut) {
            for r in 0..<self.gridSize {
                for c in 0..<self.gridSize {
                    if let id = self.tileIds[r][c], let tile = self.tileViews[id] {
                        tile.frame = self.frameForCell(atRow: r, col: c)
                        tile.update(value: self.board[r][c], color: self.getTileColor(self.board[r][c]))
                    }
                }
            }
        }
    }

    private func getTileColor(_ value: Int) -> UIColor {
        switch value {
        case 0: return TelegramColors.cardBackground
        case 2, 4: return UIColor(white: 0.3, alpha: 1)
        case 8, 16: return UIColor.orange
        case 32, 64: return UIColor.systemRed
        case 128, 256: return UIColor.systemYellow
        case 512, 1024: return TelegramColors.primary
        case 2048: return .systemPurple
        default: return .black
        }
    }

    private func addSwipeGestures() {
        let directions: [UISwipeGestureRecognizer.Direction] = [.left, .right, .up, .down]
        for direction in directions {
            let swipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
            swipe.direction = direction
            view.addGestureRecognizer(swipe)
        }
    }

    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        guard !isGameOver else { return }
        let oldBoard = board
        
        let range = Array(0..<gridSize)
        let reversed = Array((0..<gridSize).reversed())

        switch gesture.direction {
        case .left:  move(rows: range, cols: range, dr: 0, dc: -1)
        case .right: move(rows: range, cols: reversed, dr: 0, dc: 1)
        case .up:    move(rows: range, cols: range, dr: -1, dc: 0)
        case .down:  move(rows: reversed, cols: range, dr: 1, dc: 0)
        default: break
        }
        
        if board != oldBoard {
            renderBoard()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                self.addRandomTile()
                self.checkGameState()
            }
        }
    }

    private func move(rows: [Int], cols: [Int], dr: Int, dc: Int) {
        var hasMerged = Array(repeating: Array(repeating: false, count: gridSize), count: gridSize)
        for r in rows {
            for c in cols {
                if board[r][c] == 0 { continue }
                var currR = r, currC = c
                while true {
                    let nextR = currR + dr, nextC = currC + dc
                    if nextR < 0 || nextR >= gridSize || nextC < 0 || nextC >= gridSize { break }
                    
                    if board[nextR][nextC] == 0 {
                        board[nextR][nextC] = board[currR][currC]
                        board[currR][currC] = 0
                        tileIds[nextR][nextC] = tileIds[currR][currC]
                        tileIds[currR][currC] = nil
                        currR = nextR; currC = nextC
                    } else if board[nextR][nextC] == board[currR][currC] && !hasMerged[nextR][nextC] {
                        let newValue = board[nextR][nextC] * 2
                        board[nextR][nextC] = newValue
                        board[currR][currC] = 0
                        if let oldId = tileIds[currR][currC] {
                            tileViews[oldId]?.removeFromSuperview()
                            tileViews.removeValue(forKey: oldId)
                        }
                        tileIds[currR][currC] = nil
                        hasMerged[nextR][nextC] = true
                        if newValue >= 128 { setWaifuMessage("Wow! \(newValue)? " + "GamePhrases9".localize()) }
                        break
                    } else { break }
                }
            }
        }
    }

    private func checkGameState() {
        if board.flatMap({ $0 }).contains(targetValue) {
            userScore += 1
            updateScore(waifu: waifuScore, user: userScore)
            setWaifuMessage("GamePhrases10".localize())
            isGameOver = true
            showRestartButton()
            return
        }
        
        if !canMove() {
            waifuScore += 1
            updateScore(waifu: waifuScore, user: userScore)
            setWaifuMessage("GamePhrases11".localize())
            isGameOver = true
            showRestartButton()
        }
    }

    private func canMove() -> Bool {
        for r in 0..<gridSize {
            for c in 0..<gridSize {
                if board[r][c] == 0 { return true }
                if c < gridSize - 1 && board[r][c] == board[r][c+1] { return true }
                if r < gridSize - 1 && board[r][c] == board[r+1][c] { return true }
            }
        }
        return false
    }

    private func showRestartButton() {
        let btn = UIButton(type: .system)
        btn.setTitle("GamePhrases12".localize(), for: .normal)
        btn.backgroundColor = TelegramColors.primary
        btn.tintColor = .white
        btn.layer.cornerRadius = 20
        btn.addTarget(self, action: #selector(restartGame), for: .touchUpInside)
        view.addSubview(btn)
        btn.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(30)
            make.width.equalTo(180); make.height.equalTo(50)
        }
    }

    @objc private func restartGame(sender: UIButton) {
        sender.removeFromSuperview()
        resetBoard()
        setWaifuMessage("GamePhrases13".localize())
    }
}

class TileView: UIView {
    private let label = UILabel()
    private var lastValue: Int = 0

    init(frame: CGRect, value: Int) {
        super.init(frame: frame)
        layer.cornerRadius = 8
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textColor = .white
        addSubview(label)
        label.snp.makeConstraints { $0.edges.equalToSuperview() }
        update(value: value, color: .gray)
    }
    
    required init?(coder: NSCoder) { fatalError() }

    func update(value: Int, color: UIColor) {
        label.text = "\(value)"
        backgroundColor = color
        if value > lastValue && lastValue != 0 { mergeAnim() }
        lastValue = value
    }

    func appearanceAnim() {
        self.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        UIView.animate(withDuration: 0.2) { self.transform = .identity }
    }

    private func mergeAnim() {
        UIView.animate(withDuration: 0.1, animations: {
            self.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
        }) { _ in
            UIView.animate(withDuration: 0.1) { self.transform = .identity }
        }
    }
}
