import UIKit
import SnapKit

protocol StoryDetailViewDelegate: AnyObject {
    func storyDetailViewDidUpdateCurrentStory(index: Int)
    func storyDetailViewDidClosed()
}

class StoryDetailView: UIView, UIScrollViewDelegate {
    private let scrollView = UIScrollView()
    private var pages: [SingleStoryPageView] = []
    weak var delegate: StoryDetailViewDelegate?
    
    private var stories: [StoryModel] = []
    private var currentIndex: Int = 0
    private var isDismissing = false // Чтобы не вызвать dismiss дважды

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupScrollView()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupScrollView() {
        backgroundColor = .black
        scrollView.isPagingEnabled = true
        // ВКЛЮЧАЕМ BOUNCES, чтобы можно было оттянуть край для закрытия
        scrollView.bounces = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        scrollView.delaysContentTouches = false
        addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    func configure(with stories: [StoryModel], startIndex: Int) {
        self.stories = stories
        self.currentIndex = startIndex
        self.isDismissing = false
        
        pages.forEach { $0.removeFromSuperview() }
        pages.removeAll()

        let screenWidth = UIScreen.main.bounds.width
        // Явно задаем contentSize ПЕРЕД констрейнтами
        scrollView.contentSize = CGSize(width: CGFloat(stories.count) * screenWidth, height: 0)

        for (index, story) in stories.enumerated() {
            let page = SingleStoryPageView()
            page.configure(with: story)
            
            page.onNextRequested = { [weak self] in self?.scrollToNext() }
            page.onPrevRequested = { [weak self] in self?.scrollToPrevious() }
            page.onCloseRequested = { [weak self] in self?.dismiss() }
            
            scrollView.addSubview(page)
            pages.append(page)
            
            page.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview()
                make.width.height.equalTo(self) // Страница во весь экран
                
                // Позиционируем через offset
                make.leading.equalToSuperview().offset(CGFloat(index) * screenWidth)
                
                // ПРИБИВАЕМ ТРЕЙЛИНГ ПОСЛЕДНЕЙ, раз уж ширина контента известна
                if index == stories.count - 1 {
                    make.trailing.equalToSuperview()
                }
            }
        }
        
        layoutIfNeeded()
    }

    func scrollToNext() {
        guard !isDismissing else { return }
        if currentIndex < stories.count - 1 {
            let nextIndex = currentIndex + 1
            let offset = CGPoint(x: CGFloat(nextIndex) * bounds.width, y: 0)
            scrollView.setContentOffset(offset, animated: true)
        } else {
            // Если это последняя стори и таймер истек или тапнули вправо -> закрываем
            dismiss()
        }
    }

    func scrollToPrevious() {
        guard !isDismissing else { return }
        if currentIndex > 0 {
            let prevIndex = currentIndex - 1
            let offset = CGPoint(x: CGFloat(prevIndex) * bounds.width, y: 0)
            scrollView.setContentOffset(offset, animated: true)
        } else {
            // Если это первая стори и тапнули влево -> закрываем
            dismiss()
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateCurrentPage()
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        updateCurrentPage()
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard !isDismissing else { return }
        pages[currentIndex].pauseStoryTimer()
    }
    
    // ВАЖНО: Обработка свайпов за границы
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !isDismissing else { return }
        
        let offsetX = scrollView.contentOffset.x
        let contentWidth = scrollView.contentSize.width
        let frameWidth = scrollView.frame.width
        
        // Порог срабатывания свайпа (50 пикселей)
        let threshold: CGFloat = 50.0
        
        // 1. Свайп вправо на первой сторис (тянем влево за экран)
        if offsetX < -threshold {
            isDismissing = true
            dismiss()
        }
        
        // 2. Свайп влево на последней сторис (тянем вправо за экран)
        // Проверяем, что контент вообще есть, чтобы не крашнуло при инициализации
        if contentWidth > 0 && offsetX > (contentWidth - frameWidth + threshold) {
            isDismissing = true
            dismiss()
        }
    }

    private func updateCurrentPage() {
        guard !isDismissing else { return }
        
        let newIndex = Int(round(scrollView.contentOffset.x / bounds.width))
        if newIndex < 0 || newIndex >= stories.count { return }
        
        if newIndex != currentIndex {
            pages[currentIndex].stopAndReset()
            currentIndex = newIndex
            pages[currentIndex].startStoryTimer()
            delegate?.storyDetailViewDidUpdateCurrentStory(index: currentIndex)
        } else {
            pages[currentIndex].resumeStoryTimer()
        }
    }

    func show(in view: UIView) {
        self.alpha = 0
        view.addSubview(self)
        self.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        layoutIfNeeded()

        // Используем экранную ширину для гарантии точности
        let width = UIScreen.main.bounds.width
        let offset = CGFloat(currentIndex) * width
        
        // Ставим офсет ПЕРЕД показом
        scrollView.setContentOffset(CGPoint(x: offset, y: 0), animated: false)
        
        if pages.indices.contains(currentIndex) {
            pages[currentIndex].startStoryTimer()
        }
        
        UIView.animate(withDuration: 0.3) {
            self.alpha = 1
        }
    }

    func dismiss() {
        // Останавливаем все таймеры перед закрытием
        pages.forEach { $0.stopAndReset() }
        
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 0
            // Немного уменьшаем масштаб для красивого ухода (как в инсте)
            self.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            self.delegate?.storyDetailViewDidClosed()
            self.removeFromSuperview()
        }
    }
}
