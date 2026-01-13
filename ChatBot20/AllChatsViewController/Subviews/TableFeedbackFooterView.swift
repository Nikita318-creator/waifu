import UIKit
import SnapKit

class TableFeedbackFooterView: UIView {
    let button = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.lineBreakMode = .byWordWrapping
        
        addSubview(button)
        button.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.bottom.equalToSuperview().offset(-40)
            make.leading.trailing.equalToSuperview().inset(30)
        }
    }

    required init?(coder: NSCoder) { fatalError() }
    
    func configure(title: NSAttributedString) {
        button.setAttributedTitle(title, for: .normal)
    }
}
