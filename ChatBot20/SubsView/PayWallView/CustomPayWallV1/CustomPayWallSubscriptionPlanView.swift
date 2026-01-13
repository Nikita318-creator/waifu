import UIKit
import SnapKit

class CustomPayWallSubscriptionPlanView: UIControl {
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let popularTagView = UIView()
    private let popularLabel = UILabel()
    private let discountBadge = UIView()
    private let discountLabel = UILabel()
    
    private var isPopular: Bool = false
    private var hasDiscount: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        // Container View
        containerView.backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1)
        containerView.layer.cornerRadius = 16
        containerView.layer.borderWidth = 2
        containerView.layer.borderColor = UIColor.systemGray4.cgColor
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowRadius = 5
        containerView.layer.shadowOpacity = 0.1
        addSubview(containerView)
        
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // Title Label
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont(name: "AvenirNext-DemiBold", size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = UIColor(red: 50/255, green: 50/255, blue: 50/255, alpha: 1)
        containerView.addSubview(titleLabel)
        
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.equalToSuperview().offset(8)
            make.trailing.equalToSuperview().offset(-8)
        }
        
        // Popular Tag View
        popularTagView.backgroundColor = UIColor(red: 255/255, green: 144/255, blue: 154/255, alpha: 1)
        popularTagView.layer.cornerRadius = 10
        popularTagView.isHidden = true
//        containerView.addSubview(popularTagView)
//        popularTagView.snp.makeConstraints { make in
//            make.centerX.equalToSuperview()
//            make.top.equalToSuperview().offset(-10)
//            make.width.equalTo(70)
//            make.height.equalTo(20)
//        }
        
        addSubview(popularTagView)
        popularTagView.snp.makeConstraints { make in
            make.centerX.equalTo(containerView)
            make.bottom.equalTo(containerView.snp.top).offset(10)
            make.width.equalTo(70)
            make.height.equalTo(20)
        }
        
        // Popular Label
        popularLabel.text = "Subs.POPULAR".localize()
        popularLabel.textAlignment = .center
        popularLabel.font = UIFont(name: "AvenirNext-Bold", size: 10) ?? UIFont.systemFont(ofSize: 10, weight: .bold)
        popularLabel.textColor = .white
        popularTagView.addSubview(popularLabel)
        
        popularLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        // Discount Badge
        discountBadge.backgroundColor = UIColor(red: 255/255, green: 223/255, blue: 128/255, alpha: 1)
        discountBadge.layer.cornerRadius = 12
        discountBadge.isHidden = true
//        containerView.addSubview(discountBadge)
//        discountBadge.snp.makeConstraints { make in
//            make.trailing.equalToSuperview().offset(5)
//            make.bottom.equalToSuperview().offset(5)
//            make.width.equalTo(50)
//            make.height.equalTo(24)
//        }
        
        addSubview(discountBadge)
        discountBadge.snp.makeConstraints { make in
            make.trailing.equalTo(containerView).offset(5)
            make.bottom.equalTo(containerView).offset(5)
            make.width.equalTo(50)
            make.height.equalTo(24)
        }
        
        // Discount Label
        discountLabel.text = "-33%"
        discountLabel.textAlignment = .center
        discountLabel.font = UIFont(name: "AvenirNext-Bold", size: 10) ?? UIFont.systemFont(ofSize: 10, weight: .bold)
        discountLabel.textColor = UIColor(red: 50/255, green: 50/255, blue: 50/255, alpha: 1)
        discountBadge.addSubview(discountLabel)
        
        discountLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        if isCurrentDeviceiPad() {
            setupForIpad()
        }
    }
    
    func setTitle(_ title: String) {
        titleLabel.text = title
        
        // Set popular tag for monthly
        if title == "Subs.month".localize() {
            isPopular = true
            popularTagView.isHidden = false
        }
        
        // Set discount badge for yearly
        if title == "Subs.year".localize() {
            hasDiscount = true
            discountBadge.isHidden = false
        }
    }
    
    func setSelected(_ selected: Bool) {
        UIView.animate(withDuration: 0.2) {
            if selected {
                self.containerView.backgroundColor = UIColor(red: 255/255, green: 144/255, blue: 154/255, alpha: 0.2)
                self.containerView.layer.borderColor = UIColor(red: 255/255, green: 144/255, blue: 154/255, alpha: 1).cgColor
                self.containerView.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                self.containerView.layer.shadowOpacity = 0.2
            } else {
                self.containerView.backgroundColor = UIColor.white
                self.containerView.layer.borderColor = UIColor.systemGray4.cgColor
                self.containerView.transform = CGAffineTransform.identity
                self.containerView.layer.shadowOpacity = 0.1
            }
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.1) {
                if self.isHighlighted {
                    self.containerView.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
                    self.containerView.alpha = 0.9
                } else {
                    self.containerView.transform = self.isSelected ? CGAffineTransform(scaleX: 1.05, y: 1.05) : CGAffineTransform.identity
                    self.containerView.alpha = 1.0
                }
            }
        }
    }
}

extension CustomPayWallSubscriptionPlanView {
    func setupForIpad() {
        titleLabel.font = UIFont(name: "AvenirNext-DemiBold", size: 26) ?? UIFont.systemFont(ofSize: 16, weight: .semibold)
    }
}
