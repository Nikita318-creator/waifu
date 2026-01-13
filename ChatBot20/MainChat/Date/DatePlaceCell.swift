import UIKit
import SnapKit

struct DatePlaceItem {
    let imageName: String
}

class DatePlaceCell: UICollectionViewCell {
    static let reuseIdentifier = "DatePlaceCell"
    private let imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.layer.cornerRadius = 16
        contentView.clipsToBounds = true
        
        imageView.contentMode = .scaleAspectFill
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    func configure(with item: DatePlaceItem) {
        imageView.image = UIImage(named: item.imageName)
        imageView.backgroundColor = .secondarySystemBackground
    }
}
