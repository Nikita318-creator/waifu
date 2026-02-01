import UIKit
import SnapKit
import AudioToolbox

class RoleplayVC: UIViewController {
    
    // MARK: - UI Components
    private let titleLabel = UILabel()
    private let collectionView: UICollectionView
    
    // MARK: - Data
    private var roles: [RoleplayModel] = (1...12).compactMap { index in
        if ConfigService.shared.isTestB {
            return RoleplayModel(
                id: index,
                name: "role.roleplay\(index).name".localize(),
                role: "role.roleplay\(index)".localize(),
                image: "roleplay\(index)",
                assistantInfo: "Roleplay.firstMessage\(index)".localize()
            )
        } else {
            if index == 5 || index == 9 || index == 10 {
                return nil
            }
            
            return RoleplayModel(
                id: index,
                name: "role.roleplay\(index).name".localize(),
                role: "role.roleplay\(index)".localize(),
                image: "roleplay\(index)",
                assistantInfo: "Roleplay.firstMessage\(index)".localize()
            )
        }
    }.shuffled()

    
    // MARK: - Initializers
    init() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 16
        
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateTextForIPadIfNeeded()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        collectionView.collectionViewLayout.invalidateLayout()
        
        if ConfigService.shared.isFreeMode {
            showFreeModePopup()
        }
        
        if MainHelper.shared.needShowPaywallForDiscountOffer {
            MainHelper.shared.needShowPaywallForDiscountOffer = false
            showSubs()
        }
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
        
        // Setup Title Label
        titleLabel.text = "roleplay.title".localize()
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)
        
        // Setup Collection View
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(RoleplayCell.self, forCellWithReuseIdentifier: RoleplayCell.identifier)
        collectionView.register(CreateWaifuHeader.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: CreateWaifuHeader.identifier)
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 100, right: 0)
        view.addSubview(collectionView)
        
        // Setup Constraints
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).inset(20)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(30)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview()
        }
    }
    
    private func showFreeModePopup() {
        let lastShowDateKey = "last_free_mode_show_date"
        let streakCountKey = "user_login_streak_count"
        let premActivationDateKey = "free_premium_start_date"
        let isPremActiveKey = "is_free_premium_active"
        
        let calendar = Calendar.current
        let today = Date()
        
        // Форматируем дату для сравнения "был ли вход сегодня"
        let todayString = "\(calendar.component(.year, from: today))-\(calendar.component(.month, from: today))-\(calendar.component(.day, from: today))"
        let lastDate = UserDefaults.standard.string(forKey: lastShowDateKey)
        
        // 1. Проверка: показывали ли уже сегодня?
        if lastDate == todayString {
            print("сегодня уже видел свой подарок. Не части.")
            return
        }
        
        var currentStreak = UserDefaults.standard.integer(forKey: streakCountKey)

        // сброс стрика при пропуске дня
        if let lastDateString = lastDate {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-M-d"
            
            if let lastShowDate = dateFormatter.date(from: lastDateString) {
                let diff = calendar.dateComponents([.day], from: calendar.startOfDay(for: lastShowDate), to: calendar.startOfDay(for: today)).day ?? 0
                
                if diff > 1 {
                    print("Пропуск дня! Стрик сброшен.")
                    currentStreak = 1
                }
            }
        }
        
        if currentStreak > 0, currentStreak <= 7, !IAPService.shared.hasActiveSubscription {
            let popup = FreeModePopupView(currentDay: currentStreak)
            popup.alpha = 0
            view.addSubview(popup)
            
            popup.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            
            UIView.animate(withDuration: 0.4) {
                popup.alpha = 1
            }
        }
        
        if currentStreak == 7 {
            // --- ПРАЗДНИЧНЫЙ ЭФФЕКТ ---
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            AudioServicesPlaySystemSound(1022) // Звук успеха
            
            // --- АКТИВАЦИЯ ПРЕМИУМА ---
            UserDefaults.standard.set(true, forKey: isPremActiveKey)
            UserDefaults.standard.set(today, forKey: premActivationDateKey)
            
        } else if currentStreak > 7 {
            // --- ПРОВЕРКА ИСТЕЧЕНИЯ 3-Х ДНЕЙ ---
            if let activationDate = UserDefaults.standard.object(forKey: premActivationDateKey) as? Date {
                let daysPassed = calendar.dateComponents([.day], from: activationDate, to: today).day ?? 0
                
                AnalyticService.shared.logEvent(name: "FreeMode daysPassed", properties: ["daysPassed":"\(daysPassed)"])
                
                if daysPassed >= 3 {
                    // Срок вышел — обнуляем всё по кругу
                    currentStreak = 0
                    UserDefaults.standard.set(false, forKey: isPremActiveKey)
                    UserDefaults.standard.removeObject(forKey: premActivationDateKey)
                    print("Premium период окончен. Стрик сброшен для нового цикла.")
                }
            }
        }
        
        AnalyticService.shared.logEvent(name: "FreeMode currentStreak", properties: ["currentStreak":"\(currentStreak)"])
        
        currentStreak += 1
        UserDefaults.standard.set(todayString, forKey: lastShowDateKey)
        UserDefaults.standard.set(currentStreak, forKey: streakCountKey)
        UserDefaults.standard.synchronize()
    }
    
    private func showSubs() {
        let subsView = SubsView()
        subsView.vc = self
        subsView.alpha = 0
        
        AnalyticService.shared.logEvent(name: "showSubs For Discount", properties: [:])
        
        view.addSubview(subsView)
        subsView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        UIView.animate(withDuration: 0.4, delay: 0, options: [.curveEaseOut]) {
            subsView.alpha = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            subsView.yearlyButtonTapped()
        }
    }
}

// MARK: - UICollectionViewDataSource
extension RoleplayVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return roles.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RoleplayCell.identifier, for: indexPath) as? RoleplayCell else {
            return UICollectionViewCell()
        }
        
        let roleplay = roles[indexPath.row]
        cell.configure(with: roleplay)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        AnalyticService.shared.logEvent(name: "Chat selected", properties: ["index:":"\(indexPath.row)", "role:":" \(roles[indexPath.row].role)", "name:":"\(roles[indexPath.row].name)"])

        var selectedAssistant = AssistantsService().getAllConfigs().first(where: { $0.avatarImageName == roles[indexPath.row].image })
        
        if selectedAssistant == nil {
            let selectedAssistantID = UUID().uuidString
            selectedAssistant = AssistantConfig(
                id: selectedAssistantID,
                assistantName: roles[indexPath.row].name,
                expertise: .roleplay,
                assistantInfo: roles[indexPath.row].assistantInfo,
                userInfo: "",
                avatarImageName: roles[indexPath.row].image ?? ""
            )
            if let selectedAssistant {
                AssistantsService().addConfig(selectedAssistant)
            }
            
            let messageId = UUID().uuidString
            MessageHistoryService().addMessage(
                Message(role: "assistant", content: "Roleplay.firstMessage\(roles[indexPath.row].id)".localize(), id: messageId),
                assistantId: selectedAssistantID,
                messageId: messageId
            )
        }
        
        MainHelper.shared.currentAssistant = selectedAssistant
        MainHelper.shared.isFirstMessageInChat = true
        
        let aiChatViewController = MainChatVC()
        aiChatViewController.modalPresentationStyle = .fullScreen
        aiChatViewController.isModalInPresentation = true
        present(aiChatViewController, animated: false)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: CreateWaifuHeader.identifier, for: indexPath) as! CreateWaifuHeader
            
            header.isHidden = !ConfigService.shared.isTestB
            
            header.onButtonTap = { [weak self] in
                let createVC = CreateDreamWaifuVC()
                createVC.modalPresentationStyle = .fullScreen
                createVC.onSuccessCreated = { [weak self] in
                    self?.tabBarController?.selectedIndex = 0
                }
                self?.present(createVC, animated: true)
            }
            
            return header
        }
        return UICollectionReusableView()
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension RoleplayVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let totalWidth = collectionView.bounds.width
        let cellWidth = totalWidth
        let aspectRatio: CGFloat = 1.25
        let cellHeight = cellWidth / aspectRatio
        return CGSize(width: cellWidth, height: cellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        // Если хедер активен (TestB), делаем отступ 30, если нет — оставляем 0
        let topInset: CGFloat = ConfigService.shared.isTestB ? 30 : 0
        return UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if ConfigService.shared.isTestB {
            return CGSize(width: collectionView.frame.width, height: 90)
        } else {
            return .zero
        }
    }
}

extension RoleplayVC {
    func updateTextForIPadIfNeeded() {
        guard view.isCurrentDeviceiPad() else { return }
        titleLabel.font = .systemFont(ofSize: 38, weight: .bold)
    }
}
