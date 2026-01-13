import UIKit
import SnapKit

class FreeModePopupView: UIView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    private let currentDay: Int
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1.0)
        view.layer.cornerRadius = 32
        view.clipsToBounds = true
        
        return view
    }()
    
    private let gradientLayer: CAGradientLayer = {
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 0.15).cgColor,
            UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1.0).cgColor
        ]
        gradient.locations = [0.0, 0.4]
        gradient.startPoint = CGPoint(x: 0.5, y: 0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1)
        return gradient
    }()
    
    private let iconContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 0.15)
        view.layer.cornerRadius = 95
        return view
    }()
    
    private lazy var iconImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "roleplay10"))
        iv.contentMode = .scaleAspectFit
        iv.tintColor = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0)
        iv.layer.cornerRadius = 90
        iv.clipsToBounds = true
        return iv
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 16
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.register(DayCell.self, forCellWithReuseIdentifier: DayCell.identifier)
        cv.dataSource = self
        cv.delegate = self
        cv.contentInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        cv.decelerationRate = .fast
        return cv
    }()
    
    private let infoContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.22, green: 0.22, blue: 0.23, alpha: 1.0)
        view.layer.cornerRadius = 20
        return view
    }()
    
    private let infoLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = UIColor(red: 0.85, green: 0.85, blue: 0.87, alpha: 1.0)
        label.font = .systemFont(ofSize: 17, weight: .regular)
        return label
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0)
        button.layer.cornerRadius = 16
        
        // Добавляем тень для кнопки
        button.layer.shadowColor = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 0.4).cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 8)
        button.layer.shadowRadius = 16
        button.layer.shadowOpacity = 1.0
        
        return button
    }()
    
    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.30, green: 0.30, blue: 0.31, alpha: 1.0)
        return view
    }()

    init(currentDay: Int) {
        self.currentDay = currentDay
        super.init(frame: .zero)
        setupUI()
        
        DispatchQueue.main.async {
            let indexPath = IndexPath(item: max(0, currentDay - 1), section: 0)
            self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        }
    }
    
    required init?(coder: NSCoder) { nil }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = containerView.bounds
    }
    
    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.75)
        
        // Добавляем blur эффект для фона
        let blurEffect = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        insertSubview(blurView, at: 0)
        
        addSubview(containerView)
        containerView.layer.insertSublayer(gradientLayer, at: 0)
        
        iconContainerView.addSubview(iconImageView)
        [iconContainerView, separatorView, collectionView, infoContainerView, closeButton].forEach {
            containerView.addSubview($0)
        }
        infoContainerView.addSubview(infoLabel)
        
        containerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.9)
            make.height.lessThanOrEqualToSuperview().multipliedBy(0.85)
        }
        
        iconContainerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(32)
            make.centerX.equalToSuperview()
            make.size.equalTo(190)
        }
        
        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(180)
        }
        
        separatorView.snp.makeConstraints { make in
            make.top.equalTo(iconContainerView.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(24)
            make.height.equalTo(1)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(separatorView.snp.bottom).offset(24)
            make.left.right.equalToSuperview()
            make.height.equalTo(90)
        }
        
        infoContainerView.snp.makeConstraints { make in
            make.top.equalTo(collectionView.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(24)
        }
        
        infoLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(20)
        }
        
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(infoContainerView.snp.bottom).offset(24)
            make.left.right.bottom.equalToSuperview().inset(24)
            make.height.equalTo(56)
        }
        
        closeButton.setTitle("GotIt".localize(), for: .normal)
        closeButton.addTarget(self, action: #selector(dismiss), for: .touchUpInside)
        
        // Добавляем анимацию нажатия для кнопки
        closeButton.addTarget(self, action: #selector(buttonTouchDown), for: .touchDown)
        closeButton.addTarget(self, action: #selector(buttonTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        
        infoLabel.text = currentDay == 7 ? "FreeMode.MessageOnDay7".localize() : "FreeMode.Message".localize()
        
        // Анимация появления
        containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        containerView.alpha = 0
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseOut) {
            self.containerView.transform = .identity
            self.containerView.alpha = 1
        }
    }
    
    @objc private func buttonTouchDown() {
        UIView.animate(withDuration: 0.1) {
            self.closeButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }
    
    @objc private func buttonTouchUp() {
        UIView.animate(withDuration: 0.1) {
            self.closeButton.transform = .identity
        }
    }
    
    // MARK: - CollectionView DataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 7
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DayCell.identifier, for: indexPath) as! DayCell
        let day = indexPath.item + 1
        cell.configure(day: day, isCurrent: day == currentDay, isPast: day < currentDay)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let day = indexPath.item + 1
        return day == 7 ? CGSize(width: 80, height: 80) : CGSize(width: 65, height: 65)
    }
    
    @objc private func dismiss() {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
            self.containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            self.containerView.alpha = 0
            self.alpha = 0
        }) { _ in
            self.removeFromSuperview()
        }
    }
}
