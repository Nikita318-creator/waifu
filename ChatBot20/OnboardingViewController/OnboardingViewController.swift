import UIKit
import SnapKit

class OnboardingViewController: UIViewController {
    
    var onFinish: (() -> Void)?
    
    private var collectionView: UICollectionView!
    private let nextButton = UIButton()
    private let pageControl = UIPageControl()
    private let gradientBackground = CAGradientLayer()
    
    private let buttonGradient = CAGradientLayer()
    
    private struct TelegramColors {
        static let primary = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0)
        static let secondary = UIColor(red: 0.60, green: 0.40, blue: 0.90, alpha: 1.0)
        static let background = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
    }

    private let slides: [OnboardingSlide] = [
        OnboardingSlide(image: ConfigService.shared.isTestB ? "onbordB1" : "onbordA1",
                        title: "Onboarding.text1".localize()),
        OnboardingSlide(image: ConfigService.shared.isTestB ? "onbordB2" : "onbordA2",
                        title: "Onboarding.text2".localize()),
        OnboardingSlide(image: ConfigService.shared.isTestB ? "onbordB3" : "onbordA3",
                        title: "Onboarding.text3".localize())
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGradientBackground()
        setupCollection()
        setupCommonUI()
        animateInitialAppearance()
    }
    
    private func setupGradientBackground() {
        gradientBackground.colors = [
            TelegramColors.background.cgColor,
            UIColor(red: 0.15, green: 0.15, blue: 0.20, alpha: 1.0).cgColor
        ]
        gradientBackground.locations = [0.0, 1.0]
        view.layer.insertSublayer(gradientBackground, at: 0)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientBackground.frame = view.bounds
        buttonGradient.frame = nextButton.bounds
    }
    
    private func setupCollection() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.isPagingEnabled = true
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .clear
        collectionView.register(OnboardingCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.decelerationRate = .fast
        
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in make.edges.equalToSuperview() }
    }
    
    private func setupCommonUI() {
        // Градиентная кнопка Next
        nextButton.setTitle("Next".localize(), for: .normal)
        nextButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        nextButton.layer.cornerRadius = 28
        nextButton.layer.cornerCurve = .continuous
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        
        // Градиент для кнопки
        buttonGradient.colors = [
            TelegramColors.primary.cgColor,
            TelegramColors.secondary.cgColor
        ]
        buttonGradient.startPoint = CGPoint(x: 0, y: 0.5)
        buttonGradient.endPoint = CGPoint(x: 1, y: 0.5)
        buttonGradient.cornerRadius = 28
        buttonGradient.cornerCurve = .continuous
        nextButton.layer.insertSublayer(buttonGradient, at: 0)
        
        // Тень для кнопки
        nextButton.layer.shadowColor = TelegramColors.primary.cgColor
        nextButton.layer.shadowOffset = CGSize(width: 0, height: 8)
        nextButton.layer.shadowOpacity = 0.4
        nextButton.layer.shadowRadius = 16
        
        view.addSubview(nextButton)
        nextButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-30)
            make.left.right.equalToSuperview().inset(40)
            make.height.equalTo(56)
        }
        
        // Modern Page Control
        pageControl.numberOfPages = slides.count
        pageControl.currentPage = 0
        pageControl.pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.3)
        pageControl.currentPageIndicatorTintColor = TelegramColors.primary
        
        if #available(iOS 14.0, *) {
            pageControl.backgroundStyle = .minimal
        }
        
        view.addSubview(pageControl)
        pageControl.snp.makeConstraints { make in
            make.bottom.equalTo(nextButton.snp.top).offset(-20)
            make.centerX.equalToSuperview()
        }
    }
    
    private func animateInitialAppearance() {
        nextButton.alpha = 0
        nextButton.transform = CGAffineTransform(translationX: 0, y: 50)
        pageControl.alpha = 0
        
        UIView.animate(withDuration: 0.8, delay: 0.5, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [.curveEaseOut]) {
            self.nextButton.alpha = 1
            self.nextButton.transform = .identity
        }
        
        UIView.animate(withDuration: 0.6, delay: 0.6, options: [.curveEaseOut]) {
            self.pageControl.alpha = 1
        }
    }
    
    @objc private func nextTapped() {
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        // Анимация нажатия кнопки
        UIView.animate(withDuration: 0.1, animations: {
            self.nextButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.nextButton.transform = .identity
            }
        }
        
        let nextIndex = min(pageControl.currentPage + 1, slides.count - 1)
        
        if pageControl.currentPage == slides.count - 1 {
            animateButtonToFinish()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.showSubs()
            }
        } else {
            let indexPath = IndexPath(item: nextIndex, section: 0)
            collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            pageControl.currentPage = nextIndex
            
            // Обновляем текст кнопки на последнем слайде
            if nextIndex == slides.count - 1 {
                UIView.transition(with: nextButton, duration: 0.3, options: .transitionCrossDissolve) {
                    self.nextButton.setTitle("GetStarted".localize(), for: .normal)
                }
            }
        }
    }
    
    private func animateButtonToFinish() {
        UIView.animate(withDuration: 0.3, animations: {
            self.nextButton.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            self.nextButton.alpha = 0.8
        }) { _ in
            UIView.animate(withDuration: 0.2) {
                self.nextButton.transform = .identity
                self.nextButton.alpha = 1
            }
        }
    }

    private func showSubs() {
        let subsView = SubsView(isOnboarding: true)
        subsView.vc = self
        subsView.alpha = 0
        
        subsView.onPaywallClosedHandler = { [weak self] in
            self?.onFinish?()
        }
        
        AnalyticService.shared.logEvent(name: "showSubs from Onboarding", properties: [:])
        
        view.addSubview(subsView)
        subsView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        UIView.animate(withDuration: 0.4, delay: 0, options: [.curveEaseOut]) {
            subsView.alpha = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            subsView.yearlyButtonTapped()
        }
    }
}

// MARK: - Collection Extensions
extension OnboardingViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return slides.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! OnboardingCell
        cell.configure(with: slides[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return view.bounds.size
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let page = Int(scrollView.contentOffset.x / scrollView.frame.width)
        pageControl.currentPage = page
        
        // Обновляем текст кнопки
        if page == slides.count - 1 {
            UIView.transition(with: nextButton, duration: 0.3, options: .transitionCrossDissolve) {
                self.nextButton.setTitle("GetStarted".localize(), for: .normal)
            }
        } else {
            UIView.transition(with: nextButton, duration: 0.3, options: .transitionCrossDissolve) {
                self.nextButton.setTitle("Next".localize(), for: .normal)
            }
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let width = scrollView.frame.width
        guard width > 0 else { return }
        
        // Используем abs() для безопасности, либо нормализуем через max(0, ...)
        let offset = scrollView.contentOffset.x
        let progress = max(0, offset / width)
        
        let color1 = TelegramColors.background
        let color2 = UIColor(red: 0.15, green: 0.15, blue: 0.20, alpha: 1.0)
        let color3 = UIColor(red: 0.12, green: 0.12, blue: 0.18, alpha: 1.0)
        
        let colors = [color1.cgColor, color2.cgColor, color3.cgColor]
        
        // Безопасное получение индексов
        let index = Int(progress) % colors.count
        let nextIndex = (index + 1) % colors.count
        
        // Дополнительная проверка границ на всякий случай
        if index >= 0 && nextIndex < colors.count {
            gradientBackground.colors = [colors[index], colors[nextIndex]]
        }
    }
}
