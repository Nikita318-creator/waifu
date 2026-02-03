import UIKit
import MessageUI
import SnapKit

class AllChatsViewController: UIViewController {

    private struct TelegramColors {
        static let background = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
        static let textPrimary = UIColor.white
    }
    
    private enum RowType {
        case customHeader
        case stories
        case chat(index: Int)
    }
    
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let storiesView = StoriesView()
    private var storyDetailView = StoryDetailView()
    private let viewModel = AllChatsViewModel()
    private var rows: [RowType] = []

    private lazy var feedbackFooter: TableFeedbackFooterView = {
        let footer = TableFeedbackFooterView()
        footer.configure()
        footer.button.addTarget(self, action: #selector(feedbackTapped), for: .touchUpInside)
        let targetSize = CGSize(width: UIScreen.main.bounds.width, height: UIView.layoutFittingCompressedSize.height)
        let size = footer.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
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
        
        storiesView.onStoryTapped = { [weak self] story in
            self?.presentStoryDetail(story: story)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        viewModel.loadChats()
        
        if let id = MainHelper.shared.needOpenChatWithId {
            MainHelper.shared.needOpenChatWithId = nil
            let selectedAssistant = AssistantsService().getAllConfigs().first(where: { $0.id == id })
            MainHelper.shared.currentAssistant = selectedAssistant
            MainHelper.shared.isFirstMessageInChat = true
            let aiChatViewController = MainChatVC()
            aiChatViewController.modalPresentationStyle = .fullScreen
            aiChatViewController.isModalInPresentation = true
            present(aiChatViewController, animated: false)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
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
                if self.viewModel.chats.isEmpty {
                    self.tableView.tableFooterView = nil
                } else {
                    self.tableView.tableFooterView = self.feedbackFooter
                }
            }
        }
        
        viewModel.moveOnChatsTabHandler = { [weak self] in
            self?.tabBarController?.selectedIndex = 0
        }
    }
    
    private func presentStoryDetail(story: StoryModel) {
        tabBarController?.tabBar.isHidden = true
        storyDetailView.removeFromSuperview()
        storyDetailView = StoryDetailView()
        storyDetailView.configure(with: story)
        storyDetailView.show(in: view)
        storyDetailView.delegate = self
    }
    
    @objc private func feedbackTapped() {
        let feedbackAlert = FeedbackAlertView()
        feedbackAlert.onSendTapped = { [weak self] text in
            AnalyticService.shared.logEvent(name: "feedback_sent", properties: ["text":text])
            WebHookAnalyticsService.shared.sendAnalyticsReport(messageText: "Feedback Sent: \(text)")
            print("✅ Анонимный отзыв: \(text)")
            
            let toast = UIAlertController(title: nil, message: "FeedbackReceived".localize(), preferredStyle: .alert)
            self?.present(toast, animated: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { toast.dismiss(animated: true) }
        }
        feedbackAlert.show(in: self.view)
    }
}

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
            var chat = viewModel.chats[index]
            
            if chat.id == viewModel.unreadAssistantID {
                chat.isUnread = false
                viewModel.unreadAssistantID = ""
            }
            
            let selectedAssistant = AssistantsService().getAllConfigs().first { $0.id == chat.id }
            MainHelper.shared.currentAssistant = selectedAssistant
            MainHelper.shared.isFirstMessageInChat = true
            
            AnalyticService.shared.logEvent(name: "chat selected", properties: [
                "index:": "\(index)",
                "name:": "\(selectedAssistant?.assistantName ?? "")"
            ])
            
            let aiChatViewController = MainChatVC()
            aiChatViewController.modalPresentationStyle = .fullScreen
            aiChatViewController.isModalInPresentation = true
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

extension AllChatsViewController: StoryDetailViewDelegate {
    func storyDetailViewDidClosed() {
        tabBarController?.tabBar.isHidden = false
    }
    
    func storyDetailViewDidRequestStartChat(currentStoryId: String) { }
    
    func storyDetailViewDidRequestNextStory(currentStoryId: String) {
        storiesView.currentStoryIndex += 1
        goToStory()
    }
    
    func storyDetailViewDidRequestPreviousStory(currentStoryId: String) {
        storiesView.currentStoryIndex -= 1
        goToStory()
    }
    
    private func goToStory() {
        guard storiesView.stories.indices.contains(storiesView.currentStoryIndex) else {
            storyDetailView.dismiss()
            return
        }
        storiesView.stories[storiesView.currentStoryIndex].isViewed = true
        presentStoryDetail(story: storiesView.stories[storiesView.currentStoryIndex])
    }
}
