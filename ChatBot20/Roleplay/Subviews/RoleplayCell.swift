import UIKit
import SnapKit

// MARK: - Data Model
struct RoleplayModel {
    let id: Int
    let name: String
    let role: String
    let image: String?
    let assistantInfo: String
}

class RoleplayCell: UICollectionViewCell {
    
    static let identifier = "RoleplayCell"
    
    // MARK: - UI Components
    private let imageView = UIImageView()
    private let bioLabel = UILabel()
    private let nameLabel = UILabel()
    
    private let blurView: UIVisualEffectView = {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        view.alpha = 0.5
        return view
    }()
    
    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        updateTextForIPadIfNeeded()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.layer.cornerRadius = 16
        contentView.layer.masksToBounds = true
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        contentView.backgroundColor = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1.0)
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)
        
        contentView.addSubview(blurView)
        
        bioLabel.textColor = .white
        bioLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        bioLabel.textAlignment = .left
        bioLabel.numberOfLines = 0
        bioLabel.layer.shadowColor = UIColor.black.cgColor
        bioLabel.layer.shadowOffset = CGSize(width: 1, height: 1)
        bioLabel.layer.shadowOpacity = 1
        bioLabel.layer.shadowRadius = 3
        bioLabel.layer.masksToBounds = false
        contentView.addSubview(bioLabel)

        
        nameLabel.textColor = .white
        nameLabel.font = .systemFont(ofSize: 20, weight: .medium)
        nameLabel.textAlignment = .center
        nameLabel.backgroundColor = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0)
        nameLabel.layer.cornerRadius = 8
        nameLabel.clipsToBounds = true
        nameLabel.numberOfLines = 2
        contentView.addSubview(nameLabel)
        
        // Setup Constraints
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        blurView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(bioLabel.snp.top).offset(-4)
            make.bottom.equalToSuperview()
        }
        
        bioLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(8)
            make.trailing.equalToSuperview().inset(28)
            make.bottom.equalToSuperview().inset(8)
        }
        
        nameLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(8)
            make.trailing.equalToSuperview().inset(8)
            make.height.greaterThanOrEqualTo(24)
            make.width.lessThanOrEqualToSuperview().multipliedBy(0.8)
        }
    }
    
    // MARK: - Configure Cell
    func configure(with model: RoleplayModel) {
        imageView.image = UIImage(named: model.image ?? "")
        bioLabel.text = model.role
        nameLabel.text = " " + model.name + "  "
    }
}

extension RoleplayCell {
    func updateTextForIPadIfNeeded() {
        guard isCurrentDeviceiPad() else { return }
        
        bioLabel.font = .systemFont(ofSize: 40, weight: .semibold)
        nameLabel.font = .systemFont(ofSize: 32, weight: .medium)
    }
}
