import UIKit
import SnapKit

class DayCell: UICollectionViewCell {
    static let identifier = "DayCell"
    
    private let container: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 12
        return v
    }()
    
    private let label: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 18, weight: .bold)
        l.textColor = .white
        return l
    }()
    
    private let giftIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "gift.fill"))
        iv.tintColor = .systemYellow
        iv.isHidden = true
        return iv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(container)
        container.addSubview(label)
        container.addSubview(giftIcon)
        
        container.snp.makeConstraints { $0.edges.equalToSuperview() }
        label.snp.makeConstraints { $0.center.equalToSuperview() }
        giftIcon.snp.makeConstraints { make in
            make.top.right.equalToSuperview().inset(4)
            make.size.equalTo(16)
        }
    }
    
    required init?(coder: NSCoder) { nil }
    
    func configure(day: Int, isCurrent: Bool, isPast: Bool) {
        label.text = "\(day)"
        giftIcon.isHidden = (day != 7)
        
        if isCurrent {
            container.backgroundColor = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0)
            container.layer.borderWidth = 2
            container.layer.borderColor = UIColor.white.cgColor
            container.transform = CGAffineTransform(scaleX: 1.1, y: 1.1) // Чуть увеличим текущий
        } else if isPast {
            container.backgroundColor = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 0.3)
            container.layer.borderWidth = 0
            container.transform = .identity
        } else {
            container.backgroundColor = UIColor(red: 0.28, green: 0.28, blue: 0.29, alpha: 1.0)
            container.layer.borderWidth = 0
            container.transform = .identity
        }
    }
}
