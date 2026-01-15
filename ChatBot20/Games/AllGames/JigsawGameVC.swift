import UIKit
import SnapKit

class JigsawGameVC: BaseGameViewController {
    
    // MARK: - State
    private var gridSize: Int {
        return userScore < 3 ? 3 : 4
    }
    
    private var tiles: [Int] = []
    private var tileButtons: [Int: UIButton] = [:]
    private var isShuffling = false
    
    override var gameRules: String {
        "gameRules2".localize()
    }

    override func didResetProgress() {
        setupGame()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadProgress()
        setupGame()
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
        
        UIView.transition(with: waifuImageView, duration: 0.8, options: .transitionCrossDissolve, animations: {
            self.waifuImageView.image = UIImage(named: imageName)
        }, completion: nil)
    }
    
    // MARK: - Game Setup
    private func setupGame() {
        gameContainerView.subviews.forEach { $0.removeFromSuperview() }
        tileButtons.removeAll()
        
        let totalTiles = gridSize * gridSize
        tiles = Array(0..<totalTiles)
        
        let boardView = UIView()
        boardView.backgroundColor = TelegramColors.cardBackground
        boardView.layer.cornerRadius = 16 // Чуть мягче углы
        boardView.clipsToBounds = true
        gameContainerView.addSubview(boardView)
        
        boardView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(min(view.frame.width - 40, 350))
        }
        
        createTiles(in: boardView)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.shuffleTiles()
        }
    }
    
    private func createTiles(in container: UIView) {
        let currentImageName = userScore < 8 ? "GameGirls\(userScore + 1)" : "GameGirls8"
        guard let fullImage = UIImage(named: currentImageName) else { return }
        
        let tileSize = 1.0 / CGFloat(gridSize)
        let totalTiles = gridSize * gridSize
        
        for i in 0..<totalTiles {
            if i == totalTiles - 1 { continue }
            
            let button = UIButton()
            button.backgroundColor = .darkGray
            button.tag = i
            button.layer.borderWidth = 1.0
            button.layer.borderColor = TelegramColors.background.cgColor
            button.layer.cornerRadius = 4
            button.clipsToBounds = true
            
            let row = i / gridSize
            let col = i % gridSize
            let rect = CGRect(x: CGFloat(col) * tileSize,
                             y: CGFloat(row) * tileSize,
                             width: tileSize,
                             height: tileSize)
            
            if let cropped = cropImage(ConfigService.shared.isTestB ? fullImage : UIImage(named: "place1")!, toRect: rect) {
                button.setImage(cropped, for: .normal)
                button.imageView?.contentMode = .scaleAspectFill
            }
            
            button.addTarget(self, action: #selector(tileTapped(_:)), for: .touchUpInside)
            container.addSubview(button)
            tileButtons[i] = button
        }
        
        updateTilePositions(animated: false)
    }
    
    // MARK: - Actions
    @objc private func tileTapped(_ sender: UIButton) {
        if isShuffling { return }
        
        let tileIndex = sender.tag
        guard let currentPos = tiles.firstIndex(of: tileIndex),
              let emptyPos = tiles.firstIndex(of: gridSize * gridSize - 1) else { return }
        
        if isAdjacent(pos1: currentPos, pos2: emptyPos) {
            tiles.swapAt(currentPos, emptyPos)
            
            // Эффект "нажатия" перед перемещением
            UIView.animate(withDuration: 0.1, animations: {
                sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            }) { _ in
                sender.transform = .identity
                self.updateTilePositions(animated: true)
                self.checkWinCondition()
            }
        }
    }
    
    private func isAdjacent(pos1: Int, pos2: Int) -> Bool {
        let row1 = pos1 / gridSize, col1 = pos1 % gridSize
        let row2 = pos2 / gridSize, col2 = pos2 % gridSize
        return abs(row1 - row2) + abs(col1 - col2) == 1
    }
    
    private func updateTilePositions(animated: Bool) {
        let containerWidth = min(view.frame.width - 40, 350)
        let tileSide = containerWidth / CGFloat(gridSize)
        
        for (pos, tileIndex) in tiles.enumerated() {
            guard let button = tileButtons[tileIndex] else { continue }
            
            let row = pos / gridSize
            let col = pos % gridSize
            
            let newFrame = CGRect(x: CGFloat(col) * tileSide,
                                y: CGFloat(row) * tileSide,
                                width: tileSide,
                                height: tileSide)
            
            if animated {
                // Использование Spring анимации для "физического" полета
                UIView.animate(withDuration: 0.35,
                               delay: 0,
                               usingSpringWithDamping: 0.75,
                               initialSpringVelocity: 0.8,
                               options: [.beginFromCurrentState, .curveEaseInOut],
                               animations: {
                    button.frame = newFrame
                    button.transform = .identity // Возвращаем масштаб к 1.0
                })
            } else {
                button.frame = newFrame
            }
        }
    }
    
    private func shuffleTiles() {
        isShuffling = true
        let totalTilesCount = gridSize * gridSize
        let emptyValue = totalTilesCount - 1
        
        // Логика перемешивания остается прежней
        for _ in 0..<totalTilesCount * 15 {
            let emptyPos = tiles.firstIndex(of: emptyValue)!
            var possibleMoves: [Int] = []
            
            let candidates = [emptyPos - gridSize, emptyPos + gridSize, emptyPos - 1, emptyPos + 1]
            for c in candidates {
                if c >= 0 && c < totalTilesCount {
                    if abs(c / gridSize - emptyPos / gridSize) + abs(c % gridSize - emptyPos % gridSize) == 1 {
                        possibleMoves.append(c)
                    }
                }
            }
            if let move = possibleMoves.randomElement() {
                tiles.swapAt(emptyPos, move)
            }
        }
        
        updateTilePositions(animated: true)
        isShuffling = false
    }
    
    private func checkWinCondition() {
        let win = tiles.enumerated().allSatisfy { $0.offset == $0.element }
        if win {
            playWinAnimation()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                self.updateScore(waifu: self.waifuScore, user: self.userScore + 1)
                self.setWaifuMessage("GamePhrases14".localize())
                self.showWinAlert()
            }
        }
    }

    private func playWinAnimation() {
        // Эффект вспышки всех плиток при победе
        for (_, button) in tileButtons {
            UIView.animate(withDuration: 0.3, animations: {
                button.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                button.layer.borderColor = UIColor.white.cgColor
                button.layer.borderWidth = 2
            }) { _ in
                UIView.animate(withDuration: 0.3) {
                    button.transform = .identity
                    button.layer.borderWidth = 0.5
                }
            }
        }
    }
    
    private func showWinAlert() {
        let alert = UIAlertController(title: "GamePhrases15".localize(), message: "GamePhrases16".localize(), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "GamePhrases17".localize(), style: .default) { _ in
            self.setupGame()
        })
        present(alert, animated: true)
    }
    
    private func cropImage(_ image: UIImage, toRect rect: CGRect) -> UIImage? {
        let width = image.size.width * rect.width
        let height = image.size.height * rect.height
        let x = image.size.width * rect.origin.x
        let y = image.size.height * rect.origin.y
        let cropRect = CGRect(x: x, y: y, width: width, height: height)
        
        if let cgImage = image.cgImage?.cropping(to: cropRect) {
            return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
        }
        return nil
    }
}
