//
//  BlurryOverlayView.swift
//  ChatBot20
//

import UIKit

class BlurryOverlayView: UIView {
    
    private let blurEffectView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectView.alpha = 0.95 // Настраиваем прозрачность блюра
        return blurEffectView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        // Добавляем блюр-эффект на всю площадь
        blurEffectView.frame = self.bounds
        addSubview(blurEffectView)
        
        // Добавляем надпись, которая будет намекать на необходимость подписки
        let label = UILabel()
        label.text = "premiumAssistant.Label".localize()
        label.textColor = .white
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
    }
}
