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
            make.leading.trailing.equalToSuperview().inset(40)
        }
    }

    required init?(coder: NSCoder) { fatalError() }
    
    func configure() {
        let titleText = "Feedback.HighlightText".localize()
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .regular),
            .foregroundColor: UIColor.systemGray, // Нейтральный цвет, чтобы не отвлекать от чатов
            .underlineStyle: NSUnderlineStyle.single.rawValue | NSUnderlineStyle.byWord.rawValue
        ]
        button.setAttributedTitle(NSAttributedString(string: titleText, attributes: attributes), for: .normal)
    }
}
