import UIKit
import SnapKit
import MessageUI

enum GameType: String {
    case checkers = "1"
    case jigsaw = "2"
    case merge2048 = "3"
    case tictactoe = "4"
    case rockPaperScissors = "5"
    case reversi = "6"

    var controller: UIViewController {
        switch self {
        case .checkers:  return CheckersGameVC()
        case .jigsaw:    return JigsawGameVC()
        case .merge2048: return Merge2048GameVC()
        case .tictactoe: return TicTacToeGameVC()
        case .rockPaperScissors: return RockPaperScissorsGameVC()
        case .reversi: return ReversiGameVC()
        }
    }
}

class GamesViewController: UIViewController {
    
    private struct TelegramColors {
        static let background = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
        static let cardBackground = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1.0)
    }

    private var collectionView: UICollectionView!
    
    private let games: [GameModel] = [
        GameModel(id: "1", title: "gameName1".localize(), imageName: "game_checkers"),
        GameModel(id: "2", title: "gameName2".localize(), imageName: "game_jigsaw"),
        GameModel(id: "3", title: "gameName3".localize(), imageName: "game_2048"),
        GameModel(id: "4", title: "gameName4".localize(), imageName: "game_tictactoe"),
        GameModel(id: "5", title: "gameName5".localize(), imageName: "game_rockPaperScissors"),
        GameModel(id: "6", title: "gameName6".localize(), imageName: "game_reversi")
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Перезагружаем лейаут, так как видимость хедера зависит от конфига
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.reloadData()
    }

    private func setupUI() {
        view.backgroundColor = TelegramColors.background
        title = "Games".localize()
        navigationController?.navigationBar.prefersLargeTitles = true
        
        setupCollectionView()
        
        // Добавляем отступ снизу, чтобы контент не залезал под кнопку
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
    }
    
    @objc private func feedbackTapped() {
        let feedbackAlert = FeedbackAlertView()
        
        feedbackAlert.onSendTapped = { [weak self] text in
            AnalyticService.shared.logEvent(name: "feedback_sent", properties: ["text":text])
            WebHookAnalyticsService.shared.sendAnalyticsReport(messageText: "Feedback Sent: \(text)")
            print("✅ Анонимный отзыв: \(text)")
            
            let toast = UIAlertController(title: nil, message: "FeedbackReceived".localize(), preferredStyle: .alert)
            self?.present(toast, animated: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                toast.dismiss(animated: true)
            }
        }
        
        feedbackAlert.show(in: self.view)
    }

    private func setupCollectionView() {
        let layout = createLayout()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        
        // Скрываем скролл индикаторы
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        
        collectionView.register(GameCell.self, forCellWithReuseIdentifier: GameCell.identifier)
        // Регистрируем хедер
        collectionView.register(BannerHeaderView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: BannerHeaderView.identifier)
        collectionView.register(FeedbackFooterView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
                                withReuseIdentifier: FeedbackFooterView.identifier)
        
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            
            // 1. Конфиг айтемов (без изменений)
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5),
                                                  heightDimension: .fractionalHeight(1.0))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)

            // 2. Конфиг группы (без изменений)
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                   heightDimension: .fractionalWidth(0.5 * 1.5))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 8, bottom: 16, trailing: 8)
            
            var boundaryItems: [NSCollectionLayoutBoundarySupplementaryItem] = []
            
            // 3. ВОЗВРАЩАЕМ ЖЕСТКИЙ ХЕДЕР (Как было до поломки)
            if ConfigService.shared.isTestB {
                let bannerWidth = layoutEnvironment.container.contentSize.width - 32
                // Используем .absolute, чтобы он НИКОГДА не тянулся лишнего
                let headerHeight = bannerWidth / 2 + 16
                let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                        heightDimension: .absolute(headerHeight))
                let header = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: headerSize,
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top
                )
                boundaryItems.append(header)
            }
            
            // 4. ФУТЕР С ФИДБЕКОМ (Многострочный)
            let footerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                    heightDimension: .estimated(60)) // Даем запас под 2-3 строки
            let footer = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: footerSize,
                elementKind: UICollectionView.elementKindSectionFooter,
                alignment: .bottom
            )
            boundaryItems.append(footer)
            
            section.boundarySupplementaryItems = boundaryItems
            return section
        }
    }
    
    @objc private func bannerTapped() {
        let dressUpVC = DressUpVC()
        dressUpVC.modalPresentationStyle = .fullScreen
        present(dressUpVC, animated: true)
    }
}

extension GamesViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return games.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GameCell.identifier, for: indexPath) as! GameCell
        cell.configure(with: games[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionView.elementKindSectionHeader {
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: BannerHeaderView.identifier, for: indexPath) as! BannerHeaderView
            let tap = UITapGestureRecognizer(target: self, action: #selector(bannerTapped))
            header.addGestureRecognizer(tap)
            return header
            
        } else if kind == UICollectionView.elementKindSectionFooter {
            let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: FeedbackFooterView.identifier, for: indexPath) as! FeedbackFooterView
            footer.configure()
            footer.button.addTarget(self, action: #selector(feedbackTapped), for: .touchUpInside)
            return footer
        }
        
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let gameData = games[indexPath.item]
        guard let type = GameType(rawValue: gameData.id) else { return }
        
        let vc = type.controller
        vc.modalPresentationStyle = .fullScreen
        vc.modalTransitionStyle = .coverVertical
        present(vc, animated: true)
    }
}

extension GamesViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}

