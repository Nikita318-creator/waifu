import UIKit
import SnapKit

class BannerHeaderView: UICollectionReusableView {
    static let identifier = "BannerHeaderView"
    
    private let containerView = UIView()
    private let imageView = UIImageView()
    private let labelBackground = UIView()
    private let titleLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupViews() {
        addSubview(containerView)
        containerView.layer.cornerRadius = 16
        containerView.clipsToBounds = true
        containerView.backgroundColor = .darkGray
        
        containerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview()
        }
        
        imageView.contentMode = .scaleAspectFill
        imageView.image = UIImage(named: "banner_wardrob_bg")
        containerView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        labelBackground.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
        labelBackground.layer.cornerRadius = 10
        labelBackground.layer.borderWidth = 1.0
        labelBackground.layer.borderColor = UIColor.white.withAlphaComponent(0.1).cgColor
        labelBackground.alpha = 0.95
        containerView.addSubview(labelBackground)
        
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.text = "playDressUp".localize()
        labelBackground.addSubview(titleLabel)
        
        labelBackground.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(12)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16))
        }
    }
}
