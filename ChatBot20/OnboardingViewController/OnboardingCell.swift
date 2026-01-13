import UIKit
import SnapKit

struct OnboardingSlide {
    let image: String
    let title: String
}

class OnboardingCell: UICollectionViewCell {
    private let imageView = UIImageView()
    private let gradientOverlay = CAGradientLayer()
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let titleLabel = UILabel()
    private let particleLayer = CAEmitterLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupParticles()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        // 1. Image - в самый низ
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 2. Градиент
        gradientOverlay.colors = [
            UIColor.black.withAlphaComponent(0.0).cgColor,
            UIColor.black.withAlphaComponent(0.3).cgColor,
            UIColor.black.withAlphaComponent(0.8).cgColor // Чуть темнее внизу для читаемости
        ]
        gradientOverlay.locations = [0.0, 0.5, 1.0]
        // Вставляем градиент СРАЗУ над слоем картинки
        contentView.layer.addSublayer(gradientOverlay)
        
        // 3. Blur подложка
        contentView.addSubview(blurView)
        blurView.layer.cornerRadius = 24
        blurView.layer.cornerCurve = .continuous
        blurView.clipsToBounds = true
        
        blurView.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-140)
            make.left.right.equalToSuperview().inset(24)
            make.height.greaterThanOrEqualTo(100)
        }
        
        // 4. Title внутри Blur
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        
        blurView.contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(24)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientOverlay.frame = bounds
        particleLayer.frame = bounds
        
        contentView.layer.insertSublayer(gradientOverlay, at: 1)
        contentView.layer.insertSublayer(particleLayer, at: 2)
    }
    
    private func setupParticles() {
        // Добавляем subtle частицы для премиум эффекта
        particleLayer.emitterPosition = CGPoint(x: bounds.width / 2, y: 0)
        particleLayer.emitterShape = .line
        particleLayer.emitterSize = CGSize(width: bounds.width, height: 1)
        particleLayer.renderMode = .additive
        
        let cell = CAEmitterCell()
        cell.birthRate = 3
        cell.lifetime = 8.0
        cell.velocity = 30
        cell.velocityRange = 20
        cell.emissionLongitude = .pi
        cell.emissionRange = .pi / 8
        cell.scale = 0.3
        cell.scaleRange = 0.2
        cell.alphaSpeed = -0.1
        cell.contents = createParticleImage().cgImage
        
        particleLayer.emitterCells = [cell]
        contentView.layer.insertSublayer(particleLayer, above: gradientOverlay)
    }
    
    private func createParticleImage() -> UIImage {
        let size = CGSize(width: 8, height: 8)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.white.cgColor)
        context?.fillEllipse(in: CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image ?? UIImage()
    }
    
    func configure(with slide: OnboardingSlide) {
        imageView.image = UIImage(named: slide.image)
        titleLabel.text = slide.title
        
        // Анимация появления
        titleLabel.alpha = 0
        titleLabel.transform = CGAffineTransform(translationX: 0, y: 30)
        
        UIView.animate(withDuration: 0.8, delay: 0.2, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [.curveEaseOut]) {
            self.titleLabel.alpha = 1
            self.titleLabel.transform = .identity
        }
        
        blurView.alpha = 0
        blurView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        
        UIView.animate(withDuration: 0.6, delay: 0.1, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: [.curveEaseOut]) {
            self.blurView.alpha = 0.95
            self.blurView.transform = .identity
        }
    }
}
