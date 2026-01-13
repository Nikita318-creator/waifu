import UIKit
import SnapKit

class DatePreferencesView: UIView {
    
    // MARK: - Telegram Colors
    private struct TelegramColors {
        static let primary = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0)
        static let background = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
        static let cardBackground = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1.0)
        static let textPrimary = UIColor.white
        static let textSecondary = UIColor(red: 0.64, green: 0.64, blue: 0.66, alpha: 1.0)
    }
    
    private let charLimit = 2000 // Лимит символов
    
    // MARK: - UI Components
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let textView = UITextView()
    private let placeholderLabel = UILabel()
    private let charCountLabel = UILabel() // Счетчик символов
    private let continueButton = UIButton(type: .system)
    
    var onContinue: ((String) -> Void)?
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        setupKeyboardObservers()
        setupGestures()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupUI() {
        backgroundColor = TelegramColors.background
        
        titleLabel.text = "Date.instructions.title".localize()
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = TelegramColors.textPrimary
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        
        subtitleLabel.text = "Date.instructions.subtitle".localize()
        subtitleLabel.font = .systemFont(ofSize: 16)
        subtitleLabel.textColor = TelegramColors.textSecondary
        subtitleLabel.numberOfLines = 0
        subtitleLabel.textAlignment = .center
        
        // TextView
        textView.backgroundColor = TelegramColors.cardBackground
        textView.textColor = TelegramColors.textPrimary
        textView.font = .systemFont(ofSize: 16)
        textView.layer.cornerRadius = 12
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 30, right: 12)
        textView.keyboardAppearance = .dark
        textView.delegate = self
        
        // Placeholder
        placeholderLabel.text = "Date.instructions.placeholder".localize()
        placeholderLabel.font = .systemFont(ofSize: 16)
        placeholderLabel.textColor = TelegramColors.textSecondary
        
        // Character Count Label
        charCountLabel.text = "0 / \(charLimit)"
        charCountLabel.font = .systemFont(ofSize: 12)
        charCountLabel.textColor = TelegramColors.textSecondary
        charCountLabel.textAlignment = .right
        
        // Button
        continueButton.setTitle("Continue".localize(), for: .normal)
        continueButton.setTitleColor(.white, for: .normal)
        continueButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        continueButton.backgroundColor = TelegramColors.primary
        continueButton.layer.cornerRadius = 14
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
    }
    
    private func setupConstraints() {
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(textView)
        textView.addSubview(placeholderLabel)
        addSubview(charCountLabel) // Добавляем счетчик поверх или под TextView
        addSubview(continueButton)
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide).offset(40)
            make.leading.trailing.equalToSuperview().inset(24)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(24)
        }
        
        textView.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(160)
        }
        
        placeholderLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(16)
        }
        
        // Прижимаем счетчик к правому нижнему углу внутри или под TextView
        charCountLabel.snp.makeConstraints { make in
            make.bottom.equalTo(textView.snp.bottom).offset(-8)
            make.trailing.equalTo(textView.snp.trailing).offset(-12)
        }
        
        continueButton.snp.makeConstraints { make in
            make.bottom.equalTo(safeAreaLayoutGuide).inset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(56)
        }
    }
    
    // (Методы Keyboard Handling и Gestures остаются без изменений...)
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let offset = keyboardSize.height - safeAreaInsets.bottom + 10
            continueButton.snp.updateConstraints { make in
                make.bottom.equalTo(safeAreaLayoutGuide).inset(offset)
            }
            UIView.animate(withDuration: 0.3) { self.layoutIfNeeded() }
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        continueButton.snp.updateConstraints { make in
            make.bottom.equalTo(safeAreaLayoutGuide).inset(20)
        }
        UIView.animate(withDuration: 0.3) { self.layoutIfNeeded() }
    }
    
    private func setupGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        addGestureRecognizer(tap)
    }
    
    @objc private func dismissKeyboard() {
        endEditing(true)
    }
    
    @objc private func continueTapped() {
        onContinue?(textView.text ?? "")
    }
    
    func focusTextView() {
        textView.becomeFirstResponder()
    }
}

// MARK: - UITextViewDelegate
extension DatePreferencesView: UITextViewDelegate {
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // Проверка лимита при вставке или вводе текста
        let currentText = textView.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: text)
        
        return updatedText.count <= charLimit
    }
    
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
        
        // Обновление счетчика
        let count = textView.text.count
        charCountLabel.text = "\(count) / \(charLimit)"
        
        // Можно добавить визуальную индикацию, если лимит достигнут
        charCountLabel.textColor = count >= charLimit ? .systemRed : TelegramColors.textSecondary
    }
}
