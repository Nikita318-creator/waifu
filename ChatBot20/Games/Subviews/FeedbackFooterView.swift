import UIKit
import SnapKit

class FeedbackFooterView: UICollectionReusableView {
    static let identifier = "FeedbackFooterView"
    let button = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // КРИТИЧНО для многострочности в кнопке
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.lineBreakMode = .byWordWrapping
        
        addSubview(button)
        button.snp.makeConstraints { make in
            // Делаем небольшие отступы, чтобы не липло к краям
            make.top.equalToSuperview().offset(10)
            make.bottom.equalToSuperview().offset(-20)
            make.leading.trailing.equalToSuperview().inset(30)
        }
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func configure(title: NSAttributedString) {
        button.setAttributedTitle(title, for: .normal)
    }
}
