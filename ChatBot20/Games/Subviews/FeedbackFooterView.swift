import UIKit
import SnapKit

class FeedbackFooterView: UICollectionReusableView {
    static let identifier = "FeedbackFooterView"
    let button = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.lineBreakMode = .byWordWrapping
        
        addSubview(button)
        button.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.height.equalTo(100)
            make.leading.trailing.equalToSuperview().inset(40)
            make.bottom.equalToSuperview().offset(-20)
        }
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func configure() {
        let titleText = "Feedback.HighlightText".localize()
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .regular),
            .foregroundColor: UIColor.systemGray, // Более нейтральный цвет для анонимности
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        button.setAttributedTitle(NSAttributedString(string: titleText, attributes: attributes), for: .normal)
    }
}
