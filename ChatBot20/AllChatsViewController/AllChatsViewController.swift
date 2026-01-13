import UIKit
import MessageUI
import SnapKit

class AllChatsViewController: UIViewController {

    private struct TelegramColors {
        static let primary = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0) // #3390DC
        static let background = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0) // #1C1C1E
        static let cardBackground = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1.0) // #2C2C2E
        static let messageBackground = UIColor(red: 0.22, green: 0.22, blue: 0.24, alpha: 1.0) // #38383A
        static let userMessageBackground = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0) // #3390DC
        static let textPrimary = UIColor.white
        static let textSecondary = UIColor(red: 0.64, green: 0.64, blue: 0.66, alpha: 1.0) // #A4A4A8
        static let separator = UIColor(red: 0.28, green: 0.28, blue: 0.29, alpha: 1.0) // #48484A
    }
    
    private let allChatsView = AllChatsView()
    private let viewModel = AllChatsViewModel()

    private lazy var feedbackFooter: TableFeedbackFooterView = {
        let footer = TableFeedbackFooterView()
        let titleText = "BugReportText".localize()
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .medium),
            .foregroundColor: UIColor.systemBlue,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        footer.configure(title: NSAttributedString(string: titleText, attributes: attributes))
        footer.button.addTarget(self, action: #selector(feedbackTapped), for: .touchUpInside)
        
        let size = footer.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        footer.frame.size.height = size.height
        return footer
    }()
    
    override func loadView() {
        view = allChatsView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
    
    private func setupTableView() {
        allChatsView.tableView.delegate = self
        allChatsView.tableView.dataSource = self
    }

    private func setupViewModel() {
        viewModel.onChatsUpdated = { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.allChatsView.tableView.reloadData()
                
                // Управляем футером: если чаты есть — показываем, если нет — nil
                if self.viewModel.chats.isEmpty {
                    self.allChatsView.tableView.tableFooterView = nil
                } else {
                    self.allChatsView.tableView.tableFooterView = self.feedbackFooter
                }
            }
        }
        viewModel.loadChats()
    }
    
    @objc private func feedbackTapped() {
        let email = "nikuvar77@gmail.com" // test111
        let subject = "Feedback: My Waifu App"
        let body = "\n\n--- Device Info ---\nModel: \(UIDevice.current.modelName)\nOS: \(UIDevice.current.systemVersion)"
        
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients([email])
            mail.setSubject(subject)
            mail.setMessageBody(body, isHTML: false)
            present(mail, animated: true)
        } else {
            let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let urlString = "mailto:\(email)?subject=\(encodedSubject)&body=\(encodedBody)"
            if let url = URL(string: urlString) {
                UIApplication.shared.open(url)
            }
        }
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension AllChatsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.chats.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ChatListItemCell.identifier, for: indexPath) as? ChatListItemCell else { return UITableViewCell() }
        let chat = viewModel.chat(at: indexPath)
        cell.configure(with: chat)

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedAssistant = AssistantsService().getAllConfigs().first(where: { $0.id == viewModel.chat(at: indexPath).id })
        MainHelper.shared.currentAssistant = selectedAssistant
        MainHelper.shared.isFirstMessageInChat = true
        AnalyticService.shared.logEvent(name: "chat selected", properties: ["index:":"\(indexPath.row)", "name:":"\(selectedAssistant?.assistantName ?? "")"])
        
        let aiChatViewController = MainChatVC()
        aiChatViewController.modalPresentationStyle = .fullScreen
        aiChatViewController.isModalInPresentation = true
        present(aiChatViewController, animated: false)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return view.isCurrentDeviceiPad() ? 150 : 100
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.alpha = 0
        cell.transform = CGAffineTransform(translationX: 0, y: 20)
        
        UIView.animate(withDuration: 0.4, delay: 0.05 * Double(indexPath.row), options: .curveEaseOut, animations: {
            cell.alpha = 1
            cell.transform = .identity
        })
    }
}

extension AllChatsViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}
