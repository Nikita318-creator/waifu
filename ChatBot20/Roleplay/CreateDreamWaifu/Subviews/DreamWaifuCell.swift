import UIKit
import SnapKit

class DreamWaifuCell: UICollectionViewCell {
    static let identifier = "DreamWaifuCell"
    
    let scrollView = UIScrollView()
    private let contentContainer = UIView()
    
    private let waifuImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 12
        iv.layer.borderWidth = 1
        iv.layer.borderColor = UIColor.white.withAlphaComponent(0.1).cgColor
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.textColor = CreateDreamWaifuVC.TelegramColors.textPrimary
        lbl.font = .systemFont(ofSize: 28, weight: .heavy)
        lbl.numberOfLines = 0
        lbl.textAlignment = .left
        return lbl
    }()
    
    private let marketingLabel: UILabel = {
        let lbl = UILabel()
        lbl.textColor = CreateDreamWaifuVC.TelegramColors.textSecondary
        lbl.font = .italicSystemFont(ofSize: 14)
        lbl.numberOfLines = 0
        return lbl
    }()
    
    private let questionsStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 16
        return sv
    }()
    
    private weak var delegate: CreateDreamWaifuVC?
    private var currentSlide: WaifuSlideData?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupLayout() {
        addSubview(scrollView)
        scrollView.addSubview(contentContainer)
        
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        contentContainer.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }
        
        contentContainer.addSubview(waifuImageView)
        contentContainer.addSubview(titleLabel)
        contentContainer.addSubview(marketingLabel)
        contentContainer.addSubview(questionsStack)
        
        waifuImageView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(220)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(waifuImageView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        marketingLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        questionsStack.snp.makeConstraints { make in
            make.top.equalTo(marketingLabel.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(40)
        }
    }
    
    func configure(with slide: WaifuSlideData, delegate: CreateDreamWaifuVC) {
        self.currentSlide = slide
        self.delegate = delegate
        
        waifuImageView.image = UIImage(named: slide.imageName)
        titleLabel.text = slide.title
        marketingLabel.text = slide.marketingText
        
        questionsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        slide.questions.forEach { question in
            let qView = WaifuQuestionView()
            qView.configure(with: question, delegate: self)
            questionsStack.addArrangedSubview(qView)
        }
    }
    
    func refreshSelections() {
        guard let slide = currentSlide else { return }
        
        for (index, _) in slide.questions.enumerated() {
            if let qView = questionsStack.arrangedSubviews[index] as? WaifuQuestionView {
                qView.refreshSelection()
            }
        }
    }
}

extension DreamWaifuCell: WaifuQuestionViewDelegate {
    func didSelectOption(questionId: String) {
        delegate?.didUpdateSelection()
    }
}
