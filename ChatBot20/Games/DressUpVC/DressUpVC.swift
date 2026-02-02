import UIKit
import SnapKit

class DressUpVC: UIViewController {
    
    // MARK: - Properties
    struct TelegramColors {
        static let primary = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0)
        static let background = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
        static let cardBackground = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1.0)
        static let textPrimary = UIColor.white
    }
    
    private let outfitOptions = (1...19).map { "outfit_\($0)" }
    private let waifuImages   = (1...19).map { "waifuInOutfit_\($0)" }
    private let outfitPrice = 5
    private var currentAvatarImageName = ""
    
    private var userBalance: Int = CoinsService.shared.getCoins()
    
    // UI Elements
    private let customNavBar = UIView()
    private let titleLabel = UILabel()
    private let backButton = UIButton(type: .system)
    private let infoButton = UIButton(type: .system)
    
    private let waifuImageView = UIImageView()
    private let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    
    private let balanceView = UIView()
    private let coinIcon = UIImageView()
    private let balanceLabel = UILabel()
    
    private let chatButton = UIButton(type: .system)
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 100, height: 140)
        layout.minimumLineSpacing = 12
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.register(OutfitCell.self, forCellWithReuseIdentifier: "OutfitCell")
        cv.dataSource = self
        cv.delegate = self
        return cv
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        updateBalanceLabel()
        updateChatButtonState(for: "") // при отклытии не выбран наряд еще
        
        AnalyticService.shared.logEvent(name: "wardrobe opened", properties: ["":""])
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = TelegramColors.background
        
        // --- Навбар (Высота 60) ---
        view.addSubview(customNavBar)
        customNavBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(60)
        }
        
        // Кнопка Назад (Шеврон 28pt)
        let backConfig = UIImage.SymbolConfiguration(pointSize: 28, weight: .semibold)
        let backImage = UIImage(systemName: "chevron.left.circle.fill", withConfiguration: backConfig)
        backButton.setImage(backImage, for: .normal)
        backButton.tintColor = .white
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        customNavBar.addSubview(backButton)
        
        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(44)
        }
        
        // Заголовок (20pt Black)
        titleLabel.text = "Wardrobe".localize().uppercased()
        titleLabel.font = .systemFont(ofSize: 20, weight: .black)
        titleLabel.textColor = .white
        customNavBar.addSubview(titleLabel)
        
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        // Кнопка Инфо (24pt)
        let infoConfig = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        infoButton.setImage(UIImage(systemName: "info.circle.fill", withConfiguration: infoConfig), for: .normal)
        infoButton.tintColor = TelegramColors.primary
        infoButton.addTarget(self, action: #selector(showRules), for: .touchUpInside)
        customNavBar.addSubview(infoButton)
        
        infoButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(44)
        }
        
        // --- Остальные элементы (Твои исходные размеры) ---
        balanceView.backgroundColor = TelegramColors.cardBackground
        balanceView.layer.cornerRadius = 15
        balanceView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openCoins)))
        
        coinIcon.image = UIImage(systemName: "circle.fill")
        coinIcon.tintColor = .systemYellow
        balanceView.addSubview(coinIcon)
        
        balanceLabel.font = .systemFont(ofSize: 14, weight: .bold)
        balanceLabel.textColor = .white
        balanceView.addSubview(balanceLabel)
        
        waifuImageView.contentMode = .scaleAspectFill
        waifuImageView.clipsToBounds = true
        waifuImageView.layer.cornerRadius = 30
        waifuImageView.backgroundColor = TelegramColors.cardBackground
        waifuImageView.image = UIImage(named: "waifuInOutfit_start")
        waifuImageView.isUserInteractionEnabled = true
        waifuImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(waifuImageTapped)))
        view.addSubview(waifuImageView)
        view.addSubview(balanceView)

        blurEffectView.layer.cornerRadius = 30
        blurEffectView.clipsToBounds = true
        blurEffectView.alpha = 0
        waifuImageView.addSubview(blurEffectView)
        
        view.addSubview(collectionView)
        
        chatButton.setTitle("LET'S START CHATTING", for: .normal)
        chatButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .black)
        chatButton.backgroundColor = TelegramColors.primary
        chatButton.setTitleColor(.white, for: .normal)
        chatButton.layer.cornerRadius = 20
        chatButton.addTarget(self, action: #selector(chatTapped), for: .touchUpInside)
        view.addSubview(chatButton)
    }
    
    private func setupConstraints() {
        // Баланс сразу под навбаром
        balanceView.snp.makeConstraints { make in
            make.top.equalTo(customNavBar.snp.bottom).offset(5)
            make.trailing.equalToSuperview().offset(-20)
            make.height.equalTo(30)
            make.width.greaterThanOrEqualTo(70)
        }
        
        coinIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(8)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }
        
        balanceLabel.snp.makeConstraints { make in
            make.leading.equalTo(coinIcon.snp.trailing).offset(6)
            make.trailing.equalToSuperview().offset(-10)
            make.centerY.equalToSuperview()
        }
        
        // Фиксируем кнопку внизу
        chatButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.leading.trailing.equalToSuperview().inset(30)
            make.height.equalTo(54)
        }
        
        // Расчитываем высоту картинки, чтобы она не вытеснила всё остальное
        waifuImageView.snp.makeConstraints { make in
            make.top.equalTo(customNavBar.snp.bottom).offset(5)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.85)
            make.height.equalToSuperview().multipliedBy(0.45) // 45% высоты экрана
        }
        
        blurEffectView.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        // Коллекция зажимается МЕЖДУ картинкой и кнопкой
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(waifuImageView.snp.bottom).offset(15)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(chatButton.snp.top).offset(-15) // Дно коллекции привязано к верху кнопки
        }
    }
    
    // MARK: - Actions
    private func updateBalanceLabel() {
        balanceLabel.text = "\(userBalance)"
    }
    
    @objc private func backTapped() {
        dismiss(animated: true)
    }
    
    @objc private func chatTapped() {
        AnalyticService.shared.logEvent(name: "wardrobe chatTapped", properties: ["":""])

        let selectedAssistantID = UUID().uuidString
        let selectedAssistant = AssistantConfig(
            id: selectedAssistantID,
            assistantName: "Wardrobe.girl.name".localize(),
            expertise: .roleplay,
            assistantInfo: "",
            userInfo: "",
            avatarImageName: currentAvatarImageName
        )
        
        MainHelper.shared.currentAssistant = selectedAssistant
        MainHelper.shared.isFirstMessageInChat = true
        
        let aiChatViewController = MainChatVC(isWardrobeChat: true)
        aiChatViewController.modalPresentationStyle = .fullScreen
        aiChatViewController.isModalInPresentation = true
        present(aiChatViewController, animated: false)
    }
    
    @objc private func openCoins() {
        let coinsView = CoinsView(isWardrobe: true)
        coinsView.coinsAddedHandler = { [weak self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self?.userBalance = CoinsService.shared.getCoins()
                self?.updateBalanceLabel()
            }
        }
        view.addSubview(coinsView)
        coinsView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
    
    @objc private func showRules() {
        let alert = UIAlertController(title: "ClosetRules".localize(), message: "Wardrobe.rules".localize(), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Understand".localize(), style: .default))
        present(alert, animated: true)
    }
    
    @objc private func waifuImageTapped() {
        // Если блюр виден (alpha > 0), значит наряд не куплен — прерываем выполнение
        guard blurEffectView.alpha == 0 else {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            return
        }

        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        let fullScreenView = FullScreenImageView(image: waifuImageView.image)
        fullScreenView.vc = self
        fullScreenView.show(in: view)
    }
    
    private func isOutfitPurchased(id: String) -> Bool {
        return UserDefaults.standard.bool(forKey: "purchased_outfit_\(id)")
    }
    
    private func purchaseOutfit(id: String) {
        UserDefaults.standard.set(true, forKey: "purchased_outfit_\(id)")
        collectionView.reloadData()
    }
}

// MARK: - CollectionView Logic
extension DressUpVC: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return outfitOptions.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "OutfitCell", for: indexPath) as! OutfitCell
        let outfitId = outfitOptions[indexPath.item]
        let isBought = isOutfitPurchased(id: outfitId)
        cell.configure(imageName: outfitId, price: outfitPrice, isPurchased: isBought)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let outfitId = outfitOptions[indexPath.item]
        let haptic = UISelectionFeedbackGenerator()
        haptic.selectionChanged()
        
        waifuImageView.image = UIImage(named: waifuImages[indexPath.item])
        currentAvatarImageName = waifuImages[indexPath.item]
        
        AnalyticService.shared.logEvent(name: "wardrobe cell tapped", properties: ["isOutfitPurchased":"\(isOutfitPurchased(id: outfitId))"])

        if isOutfitPurchased(id: outfitId) {
            blurEffectView.alpha = 0
        } else {
            blurEffectView.alpha = 1
            showPurchaseAlert(for: outfitId)
        }
        
        updateChatButtonState(for: outfitId)
    }
    
    private func showPurchaseAlert(for outfitId: String) {
        let alert = UIAlertController(title: "New Outfit", message: "Do you want to buy this outfit for your waifu?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Buy for 5 coins", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            
            if self.userBalance >= self.outfitPrice {
                AnalyticService.shared.logEvent(name: "outfit purchased", properties: ["":""])

                if CoinsService.shared.spendCoins(self.outfitPrice) {
                    self.userBalance -= self.outfitPrice
                    self.updateBalanceLabel()
                    self.purchaseOutfit(id: outfitId)
                    self.blurEffectView.alpha = 0
                    self.updateChatButtonState(for: outfitId)
                }
            } else {
                let enoughAlert = NotEnoughCoinsAlert()
                enoughAlert.okButtonTappedHandler = { [weak self] in
                    self?.openCoins()
                    enoughAlert.removeFromSuperview()
                }
                enoughAlert.show(on: self)
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func updateChatButtonState(for outfitId: String) {
        let isBought = isOutfitPurchased(id: outfitId)
        let isAvailable = !outfitId.isEmpty && isBought
        chatButton.isEnabled = isAvailable
        UIView.animate(withDuration: 0.2) {
            self.chatButton.backgroundColor = isAvailable ? TelegramColors.primary : .systemGray
            self.chatButton.alpha = isAvailable ? 1.0 : 0.5
        }
    }
}
