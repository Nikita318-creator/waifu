import Foundation
import UIKit

class AllChatsViewModel {
    var chats: [ChatModel] = [] {
        didSet {
            onChatsUpdated?()
        }
    }

    var onChatsUpdated: (() -> Void)?
    var moveOnChatsTabHandler: (() -> Void)?

    let assistantsService = AssistantsService()
    let messageHistoryService = MessageHistoryService()
    
    var unreadAssistantID = ""
    
    init() {
        loadChats()
        
        handleAppDidBecomeActive() // первое открытие
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidBecomeActive), // открытие после сворачивания
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func loadChats() {
        chats = assistantsService.getAllConfigs().map {
            let lastMessage = messageHistoryService.getAllMessages(
                forAssistantId: $0.id ?? ""
            ).last?.content ?? $0.expertise.rawValue.localize()

            return ChatModel(
                id: $0.id ?? "",
                assistantName: $0.assistantName,
                lastMessage: lastMessage,
                lastMessageTime: "",
                assistantAvatar: $0.avatarImageName,
                isUnread: unreadAssistantID == $0.id ?? "" ? true : false
            )
        }
    }
    
    func chat(at indexPath: IndexPath) -> ChatModel {
        return chats[indexPath.row]
    }
    
    @objc private func handleAppDidBecomeActive() {
        // вначале смотрим нужно ли ставить анрид мессадж
        if UnreadMessagesService.shared.needSetUnreadMessageInChats() {
            guard assistantsService.getAllConfigs().first?.id != nil else { return }
            fetchUnreadMessage()
        }
        
        // потом сбрасываем пуш и дату ласт входа
        UnreadMessagesService.shared.needAddUnreadMessage()
    }
    
    private func fetchUnreadMessage() {
        let messageService = MessageHistoryService()
        let assistantId = MainHelper.shared.currentAssistant?.id ?? ""
        
        let allMessages = messageService.getAllMessages(forAssistantId: assistantId)
        let dialogueStr = allMessages.suffix(6).map { msg -> String in
            let role = (msg.role == "user") ? "[User]" : "[Girlfriend]"
            return "\(role): \(msg.content)"
        }.joined(separator: "\n")

        let promptForMemory = MainHelper.shared.getSystemPromptForCurrentAssistant(isSafe: true) + " The user has not entered the application for a long time - write to him first based on your past correspondence: \(dialogueStr)"
        
        let aiService = AIService()
        aiService.fetchAIResponse(userMessage: promptForMemory, systemPrompt: "") { [weak self] result in
            switch result {
            case .success(let responseText):
                let cleanResponse = responseText.replacingOccurrences(of: "\\[.*?\\]", with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "^:\\s*", with: "", options: .regularExpression) // На случай если осталось ": Привет"
                
                AnalyticService.shared.logEvent(name: "fetchUnreadMessage", properties: ["responseText": "\(cleanResponse)"])
                
                guard let self else { return }
                
                let messageId = UUID().uuidString
                // Сохраняем уже чистый текст
                let newMessage = Message(role: "assistant", content: cleanResponse, id: messageId)
                messageService.addMessage(newMessage, assistantId: assistantId, messageId: messageId)
                
                DispatchQueue.main.async {
                    self.unreadAssistantID = assistantId
                    self.loadChats()
                    self.moveOnChatsTabHandler?()
                }
                
            case .failure(let error):
                AnalyticService.shared.logEvent(name: "waifu_memory_failed", properties: ["error": error.localizedDescription])
                print("❌ fetchUnreadMessage failed: \(error.localizedDescription)")
            }
        }
    }
}
