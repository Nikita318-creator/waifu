import UIKit
import SnapKit

class OnboardingVC: UIViewController {
    
    private var currentPage = 0
    private var pages: [(title: String, image: String)] {
        return [
            (
                "Onboarding.title1".localize(),
                "1"
            ),
            (
                "Onboarding.title2".localize(),
                "latina1"
            ),
            (
                "Onboarding.title3".localize(),
                "5"
            )
        ]
    }
    
    // MARK: - UI Components
    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.isPagingEnabled = true
        sv.showsHorizontalScrollIndicator = false
        sv.showsVerticalScrollIndicator = false
        sv.delegate = self
        sv.bounces = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    private let contentStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.distribution = .fillEqually
        sv.spacing = 0
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    private let pageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.numberOfPages = 3
        pc.currentPageIndicatorTintColor = UIColor(red: 0.29, green: 0.56, blue: 0.89, alpha: 1.0)
        pc.pageIndicatorTintColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 0.6)
        pc.translatesAutoresizingMaskIntoConstraints = false
        pc.isUserInteractionEnabled = false
        pc.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        return pc
    }()
    
    private let nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor(red: 0.29, green: 0.56, blue: 0.89, alpha: 1.0)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.layer.cornerRadius = 28
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowOpacity = 0.2
        button.layer.shadowRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    var onbordingFinishedHandler: (() -> Void)?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackground()
        setupUI()
        setupPages()
        updateNavigationButtons()
        
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        
        // Add button press animations
        addButtonAnimations()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        guard view.isCurrentDeviceiPad() else { return }
        
        coordinator.animate(alongsideTransition: { _ in
            self.view.layoutIfNeeded()
            self.scrollToCurrentPage(animated: false)
        }, completion: nil)
    }
    
    // MARK: - Setup Methods
    private func setupBackground() {
        // Темный градиент
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 0.05, green: 0.05, blue: 0.08, alpha: 1.0).cgColor,
            UIColor(red: 0.08, green: 0.08, blue: 0.12, alpha: 1.0).cgColor,
            UIColor(red: 0.12, green: 0.12, blue: 0.16, alpha: 1.0).cgColor
        ]
        gradientLayer.locations = [0.0, 0.5, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.frame = view.bounds
        view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let gradientLayer = view.layer.sublayers?.first as? CAGradientLayer {
            gradientLayer.frame = view.bounds
        }
    }
    
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)
        view.addSubview(pageControl)
        view.addSubview(nextButton)
        
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(pageControl.snp.top).offset(-50)
        }
        
        contentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalToSuperview()
            make.width.equalTo(scrollView.snp.width).multipliedBy(pages.count)
        }
        
        pageControl.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(nextButton.snp.top).offset(-40)
        }
        
        nextButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-30)
            make.height.equalTo(56)
            make.width.equalTo(200)
        }
    }
    
    private func setupPages() {
        for (index, page) in pages.enumerated() {
            let pageView = createPageView(title: page.title, imageName: page.image, index: index)
            contentStackView.addArrangedSubview(pageView)
        }
    }
    
    private func createPageView(title: String, imageName: String, index: Int) -> UIView {
        let containerView = UIView()
        
        let verticalStackView: UIStackView = {
            let sv = UIStackView()
            sv.axis = .vertical
            sv.alignment = .fill
            sv.spacing = 24
            sv.translatesAutoresizingMaskIntoConstraints = false
            return sv
        }()
        
        containerView.addSubview(verticalStackView)
        
        let imageContainer = UIView()
        imageContainer.backgroundColor = UIColor.white.withAlphaComponent(0.06)
        imageContainer.layer.cornerRadius = 16
        imageContainer.translatesAutoresizingMaskIntoConstraints = false
        
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: imageName)
        imageView.tintColor = UIColor.white.withAlphaComponent(0.95)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Создаем контейнер для пузыря с хвостиком
        let bubbleWrapper = UIView()
        bubbleWrapper.translatesAutoresizingMaskIntoConstraints = false
        
        // Создаем кастомную view для пузыря с хвостиком
        let bubbleWithTail = BubbleView()
        bubbleWithTail.backgroundColor = .clear
        bubbleWithTail.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Добавляем элементы
        bubbleWrapper.addSubview(bubbleWithTail)
        bubbleWithTail.addSubview(titleLabel)
        
        // Добавление элементов в иерархию
        imageContainer.addSubview(imageView)
        verticalStackView.addArrangedSubview(imageContainer)
        verticalStackView.setCustomSpacing(40, after: imageContainer)
        verticalStackView.addArrangedSubview(bubbleWrapper)
        
        // Констрейнты для вертикального стека
        verticalStackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(32)
            make.top.greaterThanOrEqualToSuperview().offset(20)
            make.bottom.lessThanOrEqualToSuperview().offset(-20)
        }
        
        // Констрейнты для imageContainer
        if view.isCurrentDeviceiPad() {
            let smallerSide = UIScreen.main.bounds.height < UIScreen.main.bounds.width ? UIScreen.main.bounds.height : UIScreen.main.bounds.width
            imageContainer.snp.makeConstraints { make in
                make.width.height.equalTo(smallerSide / 2)
            }
            
            imageView.snp.makeConstraints { make in
                make.leading.top.equalToSuperview()
                make.width.height.equalTo(smallerSide / 2)
            }
            
            imageContainer.backgroundColor = .clear

            imageView.layer.cornerRadius = 20
            imageView.layer.borderWidth = 10
            imageView.layer.borderColor = UIColor.white.withAlphaComponent(0.8).cgColor
            imageView.layer.masksToBounds = true
            
            nextButton.titleLabel?.font = .systemFont(ofSize: 28, weight: .semibold)
            titleLabel.font = .systemFont(ofSize: 30, weight: .semibold)

        } else {
            imageContainer.snp.makeConstraints { make in
                make.width.height.equalTo(UIScreen.main.bounds.width / 1.2)
            }
            
            imageView.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(12)
            }
        }
        
        // Констрейнты для bubbleWrapper
        bubbleWrapper.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.lessThanOrEqualTo(verticalStackView).multipliedBy(0.9)
        }
        
        // Констрейнты для bubbleWithTail
        bubbleWithTail.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // Констрейнты для titleLabel с учетом хвостика
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalToSuperview().offset(24)
            make.trailing.equalToSuperview().offset(-24)
            make.bottom.equalToSuperview().offset(-28) // Больше отступ снизу для хвостика
        }
        
        return containerView
    }
    
    private func addButtonAnimations() {
        [nextButton].forEach { button in
            button.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
            button.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        }
    }
    
    @objc private func buttonTouchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1, delay: 0, options: [.allowUserInteraction, .curveEaseInOut], animations: {
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        })
    }
    
    @objc private func buttonTouchUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: [.allowUserInteraction], animations: {
            sender.transform = .identity
        })
    }
    
    @objc private func nextTapped() {
        if currentPage < pages.count - 1 {
            currentPage += 1
            scrollToCurrentPage(animated: true)
        } else {
            onboardingCompleted()
        }
    }
    
    @objc private func skipTapped() {
        onboardingCompleted()
    }
    
    // MARK: - Helper Methods
    private func scrollToCurrentPage(animated: Bool) {
        let offsetX = CGFloat(currentPage) * scrollView.frame.width
        scrollView.setContentOffset(CGPoint(x: offsetX, y: 0), animated: animated)
        updatePageControl()
        updateNavigationButtons()
    }
    
    private func updatePageControl() {
        pageControl.currentPage = currentPage
    }
    
    private func updateNavigationButtons() {
        if currentPage == pages.count - 1 {
            nextButton.setTitle("GetStarted".localize(), for: .normal)
            nextButton.backgroundColor = UIColor(red: 0.2, green: 0.78, blue: 0.35, alpha: 1.0)
        } else {
            nextButton.setTitle("Next".localize(), for: .normal)
            nextButton.backgroundColor = UIColor(red: 0.29, green: 0.56, blue: 0.89, alpha: 1.0)
        }
    }
    
    private func onboardingCompleted() {
        UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseInOut, animations: {
            self.view.alpha = 0
        }) { [weak self] _ in
            self?.dismiss(animated: false) {
                self?.onbordingFinishedHandler?()
            }
        }
    }
}

// MARK: - UIScrollViewDelegate
extension OnboardingVC: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageIndex = round(scrollView.contentOffset.x / scrollView.frame.width)
        let newPage = max(0, min(Int(pageIndex), pages.count - 1))
        
        if newPage != currentPage {
            currentPage = newPage
            updatePageControl()
            updateNavigationButtons()
        }
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let pageIndex = targetContentOffset.pointee.x / scrollView.frame.width
        currentPage = max(0, min(Int(pageIndex), pages.count - 1))
    }
}

