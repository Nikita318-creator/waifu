import UIKit
import SnapKit

protocol WaifuQuestionViewDelegate: AnyObject {
    func didSelectOption(questionId: String)
}

class WaifuQuestionView: UIView {
    
    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.textColor = .white
        lbl.font = .systemFont(ofSize: 16, weight: .bold)
        lbl.numberOfLines = 0
        return lbl
    }()
    
    private let optionsStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 8
        return sv
    }()
    
    private var question: WaifuQuestion?
    private weak var delegate: WaifuQuestionViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = CreateDreamWaifuVC.TelegramColors.cardBackground
        layer.cornerRadius = 12
        
        addSubview(titleLabel)
        addSubview(optionsStack)
        
        titleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(12)
        }
        
        optionsStack.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview().inset(12)
        }
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func configure(with question: WaifuQuestion, delegate: WaifuQuestionViewDelegate) {
        self.question = question
        self.delegate = delegate
        titleLabel.text = question.title
        
        optionsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        let savedSelections = WaifuSelectionManager.shared.getSelection(questionId: question.id)
        
        question.options.forEach { option in
            let button = createOptionButton(
                text: option,
                isSelected: savedSelections.contains(option)
            )
            optionsStack.addArrangedSubview(button)
        }
    }
    
    private func createOptionButton(text: String, isSelected: Bool) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(text, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.contentHorizontalAlignment = .left
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        button.layer.cornerRadius = 8
        
        updateButtonAppearance(button, isSelected: isSelected)
        button.addTarget(self, action: #selector(optionTapped(_:)), for: .touchUpInside)
        
        return button
    }
    
    private func updateButtonAppearance(_ button: UIButton, isSelected: Bool) {
        if isSelected {
            button.backgroundColor = CreateDreamWaifuVC.TelegramColors.selectedOption
            button.setTitleColor(CreateDreamWaifuVC.TelegramColors.primary, for: .normal)
            button.layer.borderWidth = 2
            button.layer.borderColor = CreateDreamWaifuVC.TelegramColors.primary.cgColor
        } else {
            button.backgroundColor = CreateDreamWaifuVC.TelegramColors.unselectedOption
            button.setTitleColor(CreateDreamWaifuVC.TelegramColors.textSecondary, for: .normal)
            button.layer.borderWidth = 1
            button.layer.borderColor = CreateDreamWaifuVC.TelegramColors.bubbleBackground.cgColor
        }
    }
    
    @objc private func optionTapped(_ sender: UIButton) {
        guard let question = question,
              let optionText = sender.title(for: .normal) else { return }
        
        var currentSelections = WaifuSelectionManager.shared.getSelection(questionId: question.id)
        
        if question.allowMultipleSelection {
            if let index = currentSelections.firstIndex(of: optionText) {
                currentSelections.remove(at: index)
            } else {
                currentSelections.append(optionText)
            }
        } else {
            currentSelections = [optionText]
        }
        
        WaifuSelectionManager.shared.saveSelection(questionId: question.id, options: currentSelections)
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        refreshSelection()
        delegate?.didSelectOption(questionId: question.id)
    }
    
    func refreshSelection() {
        guard let question = question else { return }
        let savedSelections = WaifuSelectionManager.shared.getSelection(questionId: question.id)
        
        for button in optionsStack.arrangedSubviews {
            guard let btn = button as? UIButton,
                  let title = btn.title(for: .normal) else { continue }
            
            let isSelected = savedSelections.contains(title)
            updateButtonAppearance(btn, isSelected: isSelected)
        }
    }
}
