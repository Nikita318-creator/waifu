import UIKit
import SnapKit

class StoriesView: UIView {
    // Telegram цвета (скопированы для независимости, но лучше использовать общий файл)
    private struct TelegramColors {
        static let background = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0) // #1C1C1E
        static let cardBackground = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1.0) // #2C2C2E
        static let textSecondary = UIColor(red: 0.64, green: 0.64, blue: 0.66, alpha: 1.0) // #A4A4A8
    }

    private var collectionView: UICollectionView?
    var stories: [StoryModel] = [] {
        didSet {
            DispatchQueue.main.async {
                self.collectionView?.reloadData()
            }
        }
    }
    
    var onStoryTapped: ((StoryModel) -> Void)?
    var currentStoryIndex = 0
    var textForStoriesGeneratedCount: Int = 0
    
    var storiesTexts: [String] {
        (1...420).map { index in
            "stories.text\(index)".localize()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateOnStoriesOnMode),
            name: .modUpdated,
            object: nil
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateForRLTIfNeeded() {
        guard let collectionView else { return }
        let rightOffset = CGPoint(x: collectionView.contentSize.width - collectionView.bounds.width + collectionView.contentInset.right, y: 0)
        collectionView.setContentOffset(rightOffset, animated: false)
    }
    
    private func setup() {
        backgroundColor = TelegramColors.background
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let layoutItemSize = isCurrentDeviceiPad() ? CGSize(width: 106, height: 122) : CGSize(width: 70, height: 90)
        layout.itemSize = layoutItemSize // Ширина для кружка + имени
        layout.minimumLineSpacing = 8 // Минимальный отступ между ячейками
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16) // Отступы секции

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView?.backgroundColor = .clear // Прозрачный фон для коллекции
        collectionView?.showsHorizontalScrollIndicator = false // Скрыть индикатор прокрутки
        collectionView?.dataSource = self
        collectionView?.delegate = self
        collectionView?.register(StoryCell.self, forCellWithReuseIdentifier: StoryCell.identifier)
        
        if let collectionView {
            addSubview(collectionView)
        }
        
        collectionView?.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    func setupMockStories() {
        let seenIDs = MainHelper.shared.viewedStoriesId
        stories = [
            StoryModel(id: "1", imageName: "paywallB", detailImageName: "paywallB", title: "", description: "Stories.Text1".localize(), isViewed: seenIDs.contains("1")),
            StoryModel(id: "2", imageName: "onbordA3", detailImageName: "onbordA3", title: "", description: "Stories.Text2".localize(), isViewed: seenIDs.contains("2")),
            StoryModel(id: "3", imageName: "roleplay1", detailImageName: "roleplay1", title: "", description: "Stories.Text3".localize(), isViewed: seenIDs.contains("3")),
            StoryModel(id: "4", imageName: "roleplay4", detailImageName: "roleplay4", title: "", description: "Stories.Text4".localize(), isViewed: seenIDs.contains("4")),
            StoryModel(id: "5", imageName: "roleplay5", detailImageName: "roleplay5", title: "", description: "Stories.Text5".localize(), isViewed: seenIDs.contains("5"))
        ]
        stories.sort { !$0.isViewed && $1.isViewed }
    }
    
    @objc private func updateOnStoriesOnMode() {
        setupMockStories()
        collectionView?.reloadData()
    }
}

// MARK: - UICollectionViewDataSource

extension StoriesView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return stories.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StoryCell.identifier, for: indexPath) as? StoryCell else { return UICollectionViewCell() }
        let story = stories[indexPath.item]
        cell.configure(with: story)
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension StoriesView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Устанавливаем, что сторис просмотрена
        stories[indexPath.item].isViewed = true
        collectionView.reloadItems(at: [indexPath]) // Обновить только эту ячейку
        currentStoryIndex = indexPath.item
        onStoryTapped?(stories[indexPath.item])
    }
}
