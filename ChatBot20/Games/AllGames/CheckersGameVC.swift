import UIKit
import SnapKit

class CheckersGameVC: BaseGameViewController {
    
    // MARK: - Constants
    private var aiDepth = 4 // Глубина просчета
    
    // MARK: - Models
    enum PieceColor { case white, black }
    
    struct Piece: Equatable {
        var color: PieceColor
        var isKing: Bool = false
    }
    
    struct Position: Equatable, Hashable {
        let row: Int
        let col: Int
    }
    
    struct Move: Equatable {
        let from: Position
        let to: Position
        let captures: [Position]
        let becomesKing: Bool
    }
    
    // Typealias для удобства работы с копиями доски
    typealias Board = [[Piece?]]
    
    // MARK: - Game State
    private var board: Board = Array(repeating: Array(repeating: nil, count: 8), count: 8)
    private var cellViews: [[UIView]] = []
    private var selectedPosition: Position?
    private var validMoves: [Move] = []
    
    private var isUserTurn = true
    private var mustContinueCapture = false // Если игрок сбил, но может бить дальше той же шашкой
    
    // Счетчики для правила ничьей (40 ходов без взятия)
    private var consecutiveNonCaptures = 0
    private var userStartsNextGame = true
    
    // UI Elements
    private var boardContainer: UIView!
    private var cellSize: CGFloat = 0
    
    override var gameRules: String {
        "gameRules1".localize()
    }

    override func didResetProgress() {
        updateDifficultyBasedOnScore()
        resetGame()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupInitialBoardState()
        renderBoard()
        loadProgress()
        
        updateDifficultyBasedOnScore()
    }
    
    private func updateDifficultyBasedOnScore() {
        switch userScore {
        case 0: aiDepth = 1
        case 1: aiDepth = 2
        case 2: aiDepth = 3
        case 3...: aiDepth = 4
        default: aiDepth = 4
        }
        print("Текущая сложность AI: \(aiDepth)") // Для твоего контроля в консоли
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
    
    private func setupInitialBoardState() {
        board = Array(repeating: Array(repeating: nil, count: 8), count: 8)
        
        for row in 0..<8 {
            for col in 0..<8 {
                if (row + col) % 2 != 0 {
                    if row < 3 {
                        board[row][col] = Piece(color: .black)
                    } else if row > 4 {
                        board[row][col] = Piece(color: .white)
                    }
                }
            }
        }
    }
    
    // MARK: - UI Rendering
    private func renderBoard() {
        boardContainer = UIView()
        boardContainer.backgroundColor = .black
        boardContainer.layer.cornerRadius = 12
        boardContainer.layer.borderWidth = 3
        boardContainer.layer.borderColor = TelegramColors.primary.cgColor
        boardContainer.clipsToBounds = true
        
        gameContainerView.addSubview(boardContainer)
        let boardSize = min(view.frame.width - 40, 400)
        boardContainer.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(boardSize)
        }
        
        cellSize = boardSize / 8
        cellViews = []
        
        for row in 0..<8 {
            var rowViews: [UIView] = []
            for col in 0..<8 {
                let cell = createCell(row: row, col: col)
                rowViews.append(cell)
            }
            cellViews.append(rowViews)
        }
        
        updateAllCells()
    }
    
    private func createCell(row: Int, col: Int) -> UIView {
        let cell = UIView()
        let isDark = (row + col) % 2 != 0
        cell.backgroundColor = isDark ? UIColor(white: 0.3, alpha: 1) : UIColor(white: 0.9, alpha: 1)
        
        boardContainer.addSubview(cell)
        cell.snp.makeConstraints { make in
            make.width.height.equalTo(cellSize)
            make.top.equalToSuperview().offset(CGFloat(row) * cellSize)
            make.leading.equalToSuperview().offset(CGFloat(col) * cellSize)
        }
        
        if isDark {
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleCellTap(_:)))
            cell.tag = row * 10 + col
            cell.addGestureRecognizer(tap)
            cell.isUserInteractionEnabled = true
        }
        
        return cell
    }
    
    private func updateAllCells() {
        for row in 0..<8 {
            for col in 0..<8 {
                updateCell(at: Position(row: row, col: col))
            }
        }
    }
    
    private func updateCell(at pos: Position) {
        let cell = cellViews[pos.row][pos.col]
        cell.subviews.forEach { $0.removeFromSuperview() }
        
        // Highlight valid move destinations
        if let selected = selectedPosition {
            let isValidDest = validMoves.contains { $0.from == selected && $0.to == pos }
            if isValidDest {
                let highlight = UIView()
                highlight.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.4)
                highlight.layer.cornerRadius = cellSize * 0.15
                cell.addSubview(highlight)
                highlight.snp.makeConstraints { make in
                    make.center.equalToSuperview()
                    make.width.height.equalTo(cellSize * 0.3)
                }
            }
        }
        
        guard let piece = board[pos.row][pos.col] else { return }
        
        let pieceView = UIView()
        pieceView.layer.cornerRadius = cellSize * 0.35
        pieceView.backgroundColor = piece.color == .white ? .white : TelegramColors.primary
        pieceView.layer.shadowColor = UIColor.black.cgColor
        pieceView.layer.shadowOffset = CGSize(width: 0, height: 2)
        pieceView.layer.shadowRadius = 4
        pieceView.layer.shadowOpacity = 0.3
        
        // Selection highlight
        if let selected = selectedPosition, selected == pos {
            pieceView.layer.borderWidth = 3
            pieceView.layer.borderColor = UIColor.systemYellow.cgColor
        }
        
        cell.addSubview(pieceView)
        pieceView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(cellSize * 0.7)
        }
        
        if piece.isKing {
            let crown = UILabel()
            crown.text = "👑"
            crown.font = .systemFont(ofSize: cellSize * 0.35)
            crown.textAlignment = .center
            pieceView.addSubview(crown)
            crown.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }
        }
    }
    
    // MARK: - User Interaction
    @objc private func handleCellTap(_ sender: UITapGestureRecognizer) {
        guard isUserTurn else { return }
        
        guard let cell = sender.view else { return }
        let row = cell.tag / 10
        let col = cell.tag % 10
        let tappedPos = Position(row: row, col: col)
        
        // 1. Попытка хода
        if let selected = selectedPosition {
            if let move = validMoves.first(where: { $0.from == selected && $0.to == tappedPos }) {
                executeUserMove(move)
                return
            }
        }
        
        // Если мы в середине серии взятий, нельзя менять шашку
        if mustContinueCapture { return }
        
        // 2. Выбор шашки
        if board[row][col]?.color == .white {
            selectedPosition = tappedPos
            calculateUserMoves()
            updateAllCells()
        } else {
            // Сброс выбора, если тапнули в пустоту или во врага
            // (но только если не обязаны бить)
            if !mustContinueCapture {
                selectedPosition = nil
                validMoves = []
                updateAllCells()
            }
        }
    }
    
    // MARK: - Move Generation Logic (Engine)
    
    private func calculateUserMoves() {
        validMoves = []
        guard let selected = selectedPosition else { return }
        
        // Генерируем все легальные ходы для белых
        let allMoves = getLegalMoves(for: board, color: .white)
        
        // Фильтруем только те, что относятся к выбранной шашке
        validMoves = allMoves.filter { $0.from == selected }
    }
    
    /// Основная функция правил.
    /// Если на доске есть хоть один бой для цвета, возвращает ТОЛЬКО бои.
    /// Иначе возвращает обычные ходы.
    private func getLegalMoves(for currentBoard: Board, color: PieceColor) -> [Move] {
        var captureMoves: [Move] = []
        var regularMoves: [Move] = []
        
        for row in 0..<8 {
            for col in 0..<8 {
                guard let piece = currentBoard[row][col], piece.color == color else { continue }
                let pos = Position(row: row, col: col)
                
                // Ищем бои
                let captures = getCaptureMoves(board: currentBoard, from: pos)
                captureMoves.append(contentsOf: captures)
                
                // Ищем обычные ходы (только если пока нет боев, для оптимизации можно и сразу, но по правилам бои приоритетнее)
                if captureMoves.isEmpty {
                    let walks = getRegularMoves(board: currentBoard, from: pos)
                    regularMoves.append(contentsOf: walks)
                }
            }
        }
        
        // Если есть взятия - только их и возвращаем (Правило обязательного боя)
        if !captureMoves.isEmpty {
            return captureMoves
        }
        
        return regularMoves
    }
    
    private func getRegularMoves(board: Board, from pos: Position) -> [Move] {
        guard let piece = board[pos.row][pos.col] else { return [] }
        var moves: [Move] = []
        
        let directions: [(Int, Int)] = piece.isKing ?
            [(-1, -1), (-1, 1), (1, -1), (1, 1)] :
            (piece.color == .white ? [(-1, -1), (-1, 1)] : [(1, -1), (1, 1)])
        
        for (dRow, dCol) in directions {
            let newRow = pos.row + dRow
            let newCol = pos.col + dCol
            
            if isValid(newRow, newCol), board[newRow][newCol] == nil {
                let newPos = Position(row: newRow, col: newCol)
                moves.append(Move(
                    from: pos,
                    to: newPos,
                    captures: [],
                    becomesKing: willBecomeKing(at: newPos, color: piece.color, isKing: piece.isKing)
                ))
            }
        }
        return moves
    }
    
    private func getCaptureMoves(board: Board, from pos: Position) -> [Move] {
        guard let piece = board[pos.row][pos.col] else { return [] }
        
        // Начинаем рекурсивный поиск цепочек
        return findJumps(board: board, currentPos: pos, color: piece.color, isKing: piece.isKing, capturedSoFar: [])
    }
    
    private func findJumps(board: Board, currentPos: Position, color: PieceColor, isKing: Bool, capturedSoFar: [Position]) -> [Move] {
        var moves: [Move] = []
        
        // ИСПРАВЛЕННАЯ ЛОГИКА: Обычная шашка бьет только вперед, Дамка — во все стороны
        let directions: [(Int, Int)] = isKing ?
            [(-1, -1), (-1, 1), (1, -1), (1, 1)] :
            (color == .white ? [(-1, -1), (-1, 1)] : [(1, -1), (1, 1)])
        
        // Чтобы нельзя было бить одну и ту же шашку дважды за ход
        // мы проверяем capturedSoFar
        
        for (dRow, dCol) in directions {
            let enemyRow = currentPos.row + dRow
            let enemyCol = currentPos.col + dCol
            let landRow = currentPos.row + dRow * 2
            let landCol = currentPos.col + dCol * 2
            
            let enemyPos = Position(row: enemyRow, col: enemyCol)
            
            // Проверки валидности прыжка
            if isValid(landRow, landCol),
               let enemyPiece = board[enemyRow][enemyCol],
               enemyPiece.color != color,
               board[landRow][landCol] == nil,
               !capturedSoFar.contains(enemyPos) {
                
                // Симулируем прыжок
                var nextBoard = board
                nextBoard[landRow][landCol] = nextBoard[currentPos.row][currentPos.col]
                nextBoard[currentPos.row][currentPos.col] = nil
                nextBoard[enemyRow][enemyCol] = nil // Временно убираем, чтобы не мешала
                
                let landPos = Position(row: landRow, col: landCol)
                var newCaptures = capturedSoFar
                newCaptures.append(enemyPos)
                
                // Проверяем, стала ли дамкой ПРЯМО СЕЙЧАС
                let promoted = willBecomeKing(at: landPos, color: color, isKing: isKing)
                
                // Если шашка стала дамкой в процессе боя, по большинству правил ход завершается
                if promoted && !isKing {
                    moves.append(Move(from: currentPos,
                                      to: landPos,
                                      captures: newCaptures,
                                      becomesKing: true))
                } else {
                    // Рекурсивно ищем продолжение
                    let subMoves = findJumps(board: nextBoard, currentPos: landPos, color: color, isKing: isKing, capturedSoFar: newCaptures)
                    
                    if subMoves.isEmpty {
                        // Цепочка закончилась
                        moves.append(Move(from: currentPos,
                                          to: landPos,
                                          captures: newCaptures,
                                          becomesKing: isKing)) // Остается какой была
                    } else {
                        moves.append(contentsOf: subMoves)
                    }
                }
            }
        }
        
        // Пересоберем moves, чтобы from был правильным
        return moves.map { move in
            return Move(from: currentPos, to: move.to, captures: move.captures, becomesKing: move.becomesKing)
        }
    }
    
    // MARK: - Game Loop
    
    private func executeUserMove(_ move: Move) {
        animateMove(move) {
            self.finalizeMove(move)
            
            // Проверка мульти-джампа
            if !move.captures.isEmpty {
                let canCaptureMore = !self.getCaptureMoves(board: self.board, from: move.to).isEmpty
                if canCaptureMore && !move.becomesKing {
                    self.mustContinueCapture = true
                    self.selectedPosition = move.to
                    self.calculateUserMoves()
                    self.updateAllCells()
                    return
                }
            }
            
            self.mustContinueCapture = false
            // Передаем ход
            self.isUserTurn = false
            
            // ПРОВЕРКА: может ли AI ходить после нашего хода?
            if self.checkWinCondition() { return }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.aiTurn()
            }
        }
    }
    
    private func finalizeMove(_ move: Move) {
        // Remove captures
        for capture in move.captures {
            board[capture.row][capture.col] = nil
        }
        
        // Move piece
        let movingPiece = board[move.from.row][move.from.col]
        board[move.to.row][move.to.col] = movingPiece
        board[move.from.row][move.from.col] = nil
        
        // Promote
        if move.becomesKing {
            board[move.to.row][move.to.col]?.isKing = true
        }
        
        // Stats
        if !move.captures.isEmpty {
            consecutiveNonCaptures = 0
            
            // Phrases
            if isUserTurn {
                let messages = ["GamePhrases19".localize(), "GamePhrases20".localize(), "GamePhrases21".localize()]
                setWaifuMessage(messages.randomElement()!)
            } else {
                let messages = ["GamePhrases24".localize(), "GamePhrases25".localize(), "GamePhrases26".localize()]
                setWaifuMessage(messages.randomElement()!)
            }
        } else {
            consecutiveNonCaptures += 1
        }
        
        selectedPosition = nil
        validMoves = []
        updateAllCells()
    }
    
    // MARK: - SUPERIOR AI Logic (Minimax + AlphaBeta)
    
    private func aiTurn() {
        guard !isUserTurn else { return } // Защита от случайного вызова
        
        setWaifuMessage("GamePhrases18".localize())
        
        DispatchQueue.global(qos: .userInitiated).async {
            let bestMove = self.runMinimax()
            
            DispatchQueue.main.async {
                guard let move = bestMove else {
                    // Если ходов нет вообще
                    self.handleAILoss()
                    return
                }
                
                self.executeAIMove(move)
            }
        }
    }

    private func executeAIMove(_ move: Move) {
        animateMove(move) {
            self.finalizeMove(move)
            
            // После хода AI отдаем ход игроку
            self.isUserTurn = true
            
            // ПРОВЕРКА: может ли человек ходить после хода AI?
            if self.checkWinCondition() { return }
            
            self.setWaifuMessage("GamePhrases19".localize())
        }
    }
    
    // --- Minimax Engine ---
    
    private func runMinimax() -> Move? {
        // Белые (User) - minimizing, Черные (AI) - maximizing
        let possibleMoves = getLegalMoves(for: board, color: .black)
        
        // Если только один ход - не тратим время
        if possibleMoves.count == 1 { return possibleMoves.first }
        if possibleMoves.isEmpty { return nil }
        
        var bestMove: Move?
        var maxEval = Int.min
        
        // Alpha-Beta
        let alpha = Int.min
        let beta = Int.max
        
        for move in possibleMoves {
            let simulatedBoard = applyMoveToBoard(board, move: move)
            // Запускаем рекурсию
            let eval = minimax(board: simulatedBoard, depth: aiDepth - 1, alpha: alpha, beta: beta, isMaximizing: false)
            
            if eval > maxEval {
                maxEval = eval
                bestMove = move
            }
        }
        
        return bestMove
    }
    
    private func minimax(board: Board, depth: Int, alpha: Int, beta: Int, isMaximizing: Bool) -> Int {
        if depth == 0 {
            return evaluateBoard(board)
        }
        
        // Проверка победы/поражения в узле
        let color: PieceColor = isMaximizing ? .black : .white
        let moves = getLegalMoves(for: board, color: color)
        
        if moves.isEmpty {
            if isMaximizing {
                return -100000 + (aiDepth - depth)
            } else {
                return 100000 - (aiDepth - depth)
            }
        }
        
        var currentAlpha = alpha
        var currentBeta = beta
        
        if isMaximizing {
            var maxEval = Int.min
            for move in moves {
                let nextBoard = applyMoveToBoard(board, move: move)
                let eval = minimax(board: nextBoard, depth: depth - 1, alpha: currentAlpha, beta: currentBeta, isMaximizing: false)
                maxEval = max(maxEval, eval)
                currentAlpha = max(currentAlpha, eval)
                if currentBeta <= currentAlpha {
                    break // Alpha Cutoff
                }
            }
            return maxEval
        } else {
            var minEval = Int.max
            for move in moves {
                let nextBoard = applyMoveToBoard(board, move: move)
                let eval = minimax(board: nextBoard, depth: depth - 1, alpha: currentAlpha, beta: currentBeta, isMaximizing: true)
                minEval = min(minEval, eval)
                currentBeta = min(currentBeta, eval)
                if currentBeta <= currentAlpha {
                    break // Beta Cutoff
                }
            }
            return minEval
        }
    }
    
    private func applyMoveToBoard(_ currentBoard: Board, move: Move) -> Board {
        var newBoard = currentBoard
        for capture in move.captures {
            newBoard[capture.row][capture.col] = nil
        }
        if let piece = newBoard[move.from.row][move.from.col] {
            newBoard[move.to.row][move.to.col] = piece
            newBoard[move.from.row][move.from.col] = nil
            if move.becomesKing {
                newBoard[move.to.row][move.to.col]?.isKing = true
            }
        }
        return newBoard
    }
    
    private func evaluateBoard(_ board: Board) -> Int {
        var score = 0
        var whitePieces: [Position] = []
        var blackPieces: [Position] = []

        for row in 0..<8 {
            for col in 0..<8 {
                guard let piece = board[row][col] else { continue }
                let pos = Position(row: row, col: col)
                
                // Базовый вес
                let value = piece.isKing ? 500 : 100
                let sideMult = (piece.color == .black ? 1 : -1)
                score += value * sideMult
                
                if piece.color == .black { blackPieces.append(pos) }
                else { whitePieces.append(pos) }
            }
        }

        // Если у юзера мало фигур, заставляем AI "давить"
        if whitePieces.count <= 2 && !blackPieces.isEmpty {
            for bPos in blackPieces {
                for wPos in whitePieces {
                    let dist = abs(bPos.row - wPos.row) + abs(bPos.col - wPos.col)
                    // Чем меньше дистанция, тем больше очков черным (AI)
                    score += (14 - dist) * 5
                }
            }
        }
        return score
    }
    
    // MARK: - Helpers & Animation
    
    private func animateMove(_ move: Move, completion: @escaping () -> Void) {
        let fromCell = cellViews[move.from.row][move.from.col]
        let toCell = cellViews[move.to.row][move.to.col]
        
        guard let pieceView = fromCell.subviews.first(where: { $0.layer.cornerRadius > 5 }) else {
            completion()
            return
        }
        
        let tempPiece = UIView()
        tempPiece.backgroundColor = pieceView.backgroundColor
        tempPiece.layer.cornerRadius = pieceView.layer.cornerRadius
        tempPiece.layer.shadowColor = pieceView.layer.shadowColor
        tempPiece.layer.shadowOffset = pieceView.layer.shadowOffset
        tempPiece.layer.shadowRadius = pieceView.layer.shadowRadius
        tempPiece.layer.shadowOpacity = pieceView.layer.shadowOpacity
        
        if let existingCrown = pieceView.subviews.first(where: { ($0 as? UILabel)?.text == "👑" }) as? UILabel {
            let crown = UILabel()
            crown.text = "👑"
            crown.font = existingCrown.font
            crown.textAlignment = .center
            tempPiece.addSubview(crown)
            crown.snp.makeConstraints { $0.center.equalToSuperview() }
        }
        
        boardContainer.addSubview(tempPiece)
        let initialFrame = boardContainer.convert(pieceView.frame, from: fromCell)
        tempPiece.frame = initialFrame
        pieceView.alpha = 0
        
        let targetCenter = boardContainer.convert(toCell.center, from: boardContainer)
        let targetFrame = CGRect(
            x: targetCenter.x - initialFrame.width / 2,
            y: targetCenter.y - initialFrame.height / 2,
            width: initialFrame.width,
            height: initialFrame.height
        )
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseOut) {
            tempPiece.frame = targetFrame
        } completion: { _ in
            tempPiece.removeFromSuperview()
            completion()
        }
    }
    
    private func isValid(_ row: Int, _ col: Int) -> Bool {
        return row >= 0 && row < 8 && col >= 0 && col < 8
    }
    
    private func willBecomeKing(at pos: Position, color: PieceColor, isKing: Bool) -> Bool {
        if isKing { return true }
        return (color == .white && pos.row == 0) || (color == .black && pos.row == 7)
    }

    private func checkWinCondition() -> Bool {
        let whitePieces = board.flatMap { $0 }.compactMap { $0 }.filter { $0.color == .white }
        let blackPieces = board.flatMap { $0 }.compactMap { $0 }.filter { $0.color == .black }
        
        // 1. Проверка на полное съедение
        if whitePieces.isEmpty { handleAIWin(); return true }
        if blackPieces.isEmpty { handleUserWin(); return true }
        
        // 2. Проверка на отсутствие ходов (Запирание)
        let currentTurnColor: PieceColor = isUserTurn ? .white : .black
        let availableMoves = getLegalMoves(for: board, color: currentTurnColor)
        
        if availableMoves.isEmpty {
            if isUserTurn {
                handleAIWin()
            } else {
                handleUserWin()
            }
            return true
        }
        
        if consecutiveNonCaptures >= 40 {
            setWaifuMessage("GamePhrases27".localize())
            showGameOverAlert(title: "Draw", message: "GamePhrases27".localize())
            return true
        }
        
        return false
    }
    
    private func handleUserWin() {
        updateScore(waifu: waifuScore, user: userScore + 1)
        updateDifficultyBasedOnScore()
        setWaifuMessage("GamePhrases28".localize())
        showGameOverAlert(title: "GamePhrases29".localize(), message: "GamePhrases30".localize())
    }

    private func handleAIWin() {
        updateScore(waifu: waifuScore + 1, user: userScore)
        setWaifuMessage("GamePhrases31".localize())
        showGameOverAlert(title: "GamePhrases32".localize(), message: "GamePhrases33".localize())
    }
    
    private func handleAILoss() {
        updateScore(waifu: waifuScore + 1, user: userScore)
        setWaifuMessage("GamePhrases36".localize())
        showGameOverAlert(title: "GamePhrases29".localize(), message: "GamePhrases37".localize())
    }

    private func resetGame() {
        board = Array(repeating: Array(repeating: nil, count: 8), count: 8)
        selectedPosition = nil
        validMoves = []
        mustContinueCapture = false
        consecutiveNonCaptures = 0
        userStartsNextGame.toggle()
        isUserTurn = userStartsNextGame
        setupInitialBoardState()
        updateAllCells()
        setWaifuMessage(isUserTurn ? "GamePhrases34".localize() : "GamePhrases35".localize())
        if !isUserTurn {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { self.aiTurn() }
        }
    }
    
    private func showGameOverAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "GamePhrases38".localize(), style: .default) { _ in
            self.resetGame()
        })
        present(alert, animated: true)
    }
}
