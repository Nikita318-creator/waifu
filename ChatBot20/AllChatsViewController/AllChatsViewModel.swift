import Foundation
import UIKit

class AllChatsViewModel {
    var chats: [ChatModel] = [] {
        didSet {
            onChatsUpdated?()
        }
    }

    var onChatsUpdated: (() -> Void)?

    let assistantsService = AssistantsService()
    
    init() {
        loadChats()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func loadChats() {
        chats = assistantsService.getAllConfigs().map {
            let lastMessage = MessageHistoryService().getAllMessages(
                forAssistantId: $0.id ?? ""
            ).last?.content ?? $0.expertise.rawValue.localize()

            return ChatModel(
                id: $0.id ?? "",
                assistantName: $0.assistantName,
                lastMessage: lastMessage,
                lastMessageTime: "",
                assistantAvatar: $0.avatarImageName,
                isPremium: false
            )
        }
    }
    
    func chat(at indexPath: IndexPath) -> ChatModel {
        return chats[indexPath.row]
    }
    
    @objc private func handleAppDidBecomeActive() {
        UnreadMessagesService.shared.needAddUnreadMessage()
    }
}
