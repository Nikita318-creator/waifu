import UIKit
import SnapKit

class CreateWaifuHeader: UICollectionReusableView {
    static let identifier = "CreateWaifuHeader"
    
    let button = UIButton(type: .system)
    var onButtonTap: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        button.setTitle("CreateDreamWaifu".localize(), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(red: 0.35, green: 0.35, blue: 0.9, alpha: 1.0) 
        button.layer.cornerRadius = 16
        
        addSubview(button)
        button.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(18)
        }
        
        button.addTarget(self, action: #selector(tapped), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    @objc private func tapped() {
        onButtonTap?()
    }
}
