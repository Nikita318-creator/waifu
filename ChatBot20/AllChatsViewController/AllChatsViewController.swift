import UIKit
import MessageUI
import SnapKit

class AllChatsViewController: UIViewController {

    private struct TelegramColors {
        static let background = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
        static let textPrimary = UIColor.white
    }
    
    private enum RowType {
        case customHeader     // Твой единственный заголовок "Messages"
        case stories          // Твои сторизы
        case chat(index: Int) // Список чатов
    }
    
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let storiesView = StoriesView()
    private let viewModel = AllChatsViewModel()
    private var rows: [RowType] = []

    private lazy var feedbackFooter: TableFeedbackFooterView = {
        let footer = TableFeedbackFooterView()
        footer.configure()
        footer.button.addTarget(self, action: #selector(feedbackTapped), for: .touchUpInside)
        
        // Твой родной расчет высоты футера, чтобы кнопка не сплющивалась
        let targetSize = CGSize(width: UIScreen.main.bounds.width, height: UIView.layoutFittingCompressedSize.height)
        let size = footer.systemLayoutSizeFitting(targetSize,
                                                  withHorizontalFittingPriority: .required,
                                                  verticalFittingPriority: .fittingSizeLevel)
        footer.frame.size.height = size.height
        return footer
    }()
    
    init() {
        super.init(nibName: nil, bundle: nil)
        setupViewModel()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBaseUI()
        setupNavigationBar()
        setupTableView()
        viewModel.loadChats()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Полностью убиваем системный бар, чтобы работал только наш кастомный заголовок
        navigationController?.setNavigationBarHidden(true, animated: animated)
        viewModel.loadChats()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Возвращаем бар для экрана чата
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    private func setupBaseUI() {
        view.backgroundColor = TelegramColors.background
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func setupNavigationBar() {
        // Выключаем системные тайтлы
        navigationItem.title = ""
        navigationController?.navigationBar.prefersLargeTitles = false
    }
    
    private func setupTableView() {
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(ChatListItemCell.self, forCellReuseIdentifier: ChatListItemCell.identifier)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "HeaderCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "StoriesCell")
        
        // Инсеты: сверху 0 (так как хедер в таблице), снизу ТВОИ 100
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.contentInset = UIEdgeInsets(top: 40, left: 0, bottom: 200, right: 0)
    }

    private func updateRows() {
        rows = [.customHeader, .stories]
        for i in 0..<viewModel.chats.count {
            rows.append(.chat(index: i))
        }
    }

    private func setupViewModel() {
        viewModel.onChatsUpdated = { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.updateRows()
                self.tableView.reloadData()
                
                // Футер только если есть чаты
                if self.viewModel.chats.isEmpty {
                    self.tableView.tableFooterView = nil
                } else {
                    self.tableView.tableFooterView = self.feedbackFooter
                }
            }
        }
    }
    
    @objc private func feedbackTapped() {
        let feedbackAlert = FeedbackAlertView()
        feedbackAlert.onSendTapped = { [weak self] text in
            let toast = UIAlertController(title: nil, message: "FeedbackReceived".localize(), preferredStyle: .alert)
            self?.present(toast, animated: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { toast.dismiss(animated: true) }
        }
        feedbackAlert.show(in: self.view)
    }
}

// MARK: - UITableViewDataSource & Delegate
extension AllChatsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rows[indexPath.row]
        
        switch row {
        case .customHeader:
            let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderCell", for: indexPath)
            cell.backgroundColor = .clear
            cell.selectionStyle = .none
            
            if cell.contentView.subviews.isEmpty {
                let label = UILabel()
                label.text = "Messages".localize()
                label.font = .systemFont(ofSize: 34, weight: .bold)
                label.textColor = .white
                cell.contentView.addSubview(label)
                label.snp.makeConstraints { make in
                    make.leading.equalToSuperview().offset(16)
                    make.bottom.equalToSuperview().offset(-10)
                }
            }
            return cell
            
        case .stories:
            let cell = tableView.dequeueReusableCell(withIdentifier: "StoriesCell", for: indexPath)
            cell.backgroundColor = .clear
            cell.selectionStyle = .none
            if !cell.contentView.subviews.contains(storiesView) {
                cell.contentView.addSubview(storiesView)
                storiesView.setupMockStories()
                storiesView.snp.makeConstraints { make in
                    make.top.equalToSuperview().offset(5)
                    make.leading.trailing.bottom.equalToSuperview()
                }
            }
            return cell
            
        case .chat(let index):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: ChatListItemCell.identifier, for: indexPath) as? ChatListItemCell else { return UITableViewCell() }
            let chat = viewModel.chats[index]
            cell.configure(with: chat)
            cell.setUnread(chat.isUnread)
            return cell
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = rows[indexPath.row]
        switch row {
        case .customHeader:
            let topPadding = UIApplication.shared.windows.first?.safeAreaInsets.top ?? 44
            return 50 + topPadding
        case .stories:
            return view.isCurrentDeviceiPad() ? 140 : 115
        case .chat:
            return view.isCurrentDeviceiPad() ? 150 : 100
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if case .chat(let index) = rows[indexPath.row] {
            let chat = viewModel.chats[index]
            let selectedAssistant = AssistantsService().getAllConfigs().first { $0.id == chat.id }
            MainHelper.shared.currentAssistant = selectedAssistant
            MainHelper.shared.isFirstMessageInChat = true
            let aiChatViewController = MainChatVC()
            aiChatViewController.modalPresentationStyle = .fullScreen
            present(aiChatViewController, animated: false)
        }
    }
    
//    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//        // Твои анимации только для ячеек чата
//        if case .chat = rows[indexPath.row] {
//            cell.alpha = 0
//            cell.transform = CGAffineTransform(translationX: 0, y: 20)
//            UIView.animate(withDuration: 0.4, delay: 0.05 * Double(indexPath.row), options: .curveEaseOut, animations: {
//                cell.alpha = 1
//                cell.transform = .identity
//            })
//        }
//    }
}
