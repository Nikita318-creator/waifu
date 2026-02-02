import UIKit

struct Message {
    let role: String
    let content: String
    var isLoading: Bool = false
    var photoID: String = ""
    var isVoiceMessage: Bool = false
    var id: String? = nil
    var reaction: String? = nil
}

struct AIMessage: Codable {
    let role: String
    let content: String
}

enum AIMessageType: String {
    case typing = "AIMessageType.typing"
    case recordingAudio = "AIMessageType.recordingAudio"
    case sendingPhoto = "AIMessageType.sendingPhoto"
    case recordingVideo = "AIMessageType.recordingVideo"
}

class AIChatViewModel {
    let messageService = MessageHistoryService()
    var messagesAI: [Message] = []
    var onMessagesUpdated: ((Bool) -> Void)?
    var onMessageReceived: (() -> Void)?
    var systemPrompt: String?
    var systemPromptSafe: String?

    private var messageIds: [Int: String] = [:]
    
    var currentMessagesAI: [Message] {
        messageService.getAllMessages(forAssistantId: MainHelper.shared.currentAssistant?.id ?? "")
    }
    
    func sendMessageViaCustomServer(_ text: String, isNeedOnlyReply: Bool = false, isReplyOnGift: Bool = false) {
        AnalyticService.shared.logEvent(name: "sendMessage", properties: ["sendMessage: ":[text]])
        
        guard let assistantId = MainHelper.shared.currentAssistant?.id else {
            print("No current assistant selected")
            onMessageReceived?() // важно - размораживаем кнопку сент в инпуте!
            onMessagesUpdated?(false)
            return
        }
        
        if !isNeedOnlyReply, !isReplyOnGift {
            DispatchQueue.main.async { [self] in
                let messageId = UUID().uuidString
                let userMessage = Message(role: "user", content: text, id: messageId)
                messagesAI.append(userMessage)
                messageIds[messagesAI.count - 1] = messageId
                messageService.addMessage(userMessage, assistantId: assistantId, messageId: messageId)
                onMessagesUpdated?(true)
            }
        }
        
        messagesAI.removeAll(where: { $0.isLoading })
        onMessagesUpdated?(true)
        
        if !ConfigService.shared.messageFromDeveloper.isEmpty, !isNeedOnlyReply {
            
            // достаём массив уже отправленных сообщений (или пустой)
            var sentMessages = UserDefaults.standard.stringArray(forKey: "developerMessagesSent") ?? []
            
            let currentMessage = ConfigService.shared.messageFromDeveloper
            
            // проверяем, что такого сообщения ещё не было
            if !sentMessages.contains(currentMessage) {
                AnalyticService.shared.logEvent(
                    name: "developerMessageSent",
                    properties: ["developerMessageSent": [currentMessage]]
                )
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.handleSuccessResponse(for: currentMessage)
                    self.onMessagesUpdated?(true)
                    
                    // добавляем новое сообщение в массив и сохраняем
                    sentMessages.append(currentMessage)
                    UserDefaults.standard.set(sentMessages, forKey: "developerMessagesSent")
                }
                
                return
            }
        }
        
        if text.contains("suggestedPrompt1".localize()) {
            AnalyticService.shared.logEvent(name: "responseMessage", properties: ["[photo]: ":["from mock"]])
            MainHelper.shared.currentAIMessageType = .sendingPhoto
            addLoadingMessage()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.handleSuccessResponse(for: "[photo]")
                self.onMessagesUpdated?(true)
            }
            
            return
        }

        if text.contains("suggestedPrompt2".localize()) {
            AnalyticService.shared.logEvent(name: "responseMessage", properties: ["[video]: ":["from mock"]])
            MainHelper.shared.currentAIMessageType = .recordingVideo
            addLoadingMessage()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.handleSuccessResponse(for: "[video]")
                self.onMessagesUpdated?(true)
            }
            
            return
        }
        
        MainHelper.shared.currentAIMessageType = MainHelper.shared.isVoiceMessages ? .recordingAudio : .typing
        addLoadingMessage()
        
        // ================= дальше кастом сервер логика идет ================================ \\
        
        let aiService = AIService()
        var fullMessage = (systemPrompt ?? "") + "\n" + text
        
        // Внутренняя функция для повторного запроса
        func fetchWithRetry(attempt: Int) {
            aiService.fetchAIResponse(userMessage: fullMessage, systemPrompt: "") { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success(let responseText):
                    AnalyticService.shared.logEvent(name: "responseMessage", properties: ["responseMessage: ":[responseText]])
                    self.handleSuccessResponse(for: responseText.trimmingCharacters(in: .whitespacesAndNewlines))
                    
                case .failure(let error):
                    if attempt < 1 { // Если это была первая попытка (index 0)
                        fullMessage = (systemPromptSafe ?? "") + "\n" + text
                        print("⚠️ Request failed, retrying in 1s... Error: \(error.localizedDescription)")
                        AnalyticService.shared.logEvent(name: "Request failed, retrying in 1s", properties: ["fullMessage": "\(fullMessage)"])

                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            fetchWithRetry(attempt: attempt + 1)
                        }
                    } else if attempt < 2 {
                        // Полностью заменяем текст юзера на безопасную историю
                        let safeHistory = "Then I asked: hi! how are you! you know, the weather was beautiful this morning, but I want to hear how your day went and what your plans are for tomorrow — tell me, and then you said that you couldn't reply to the message right away, so I had to wait longer for a response, but I asked: will you apologize for the delay? you said: yes, I said it's fine and we continued our chat."
                        fullMessage = (systemPromptSafe ?? "") + "\n" + safeHistory
                        
                        print("⚠️ Request failed_2, context replaced with safe story. Retrying...")
                        AnalyticService.shared.logEvent(name: "Request failed, replaced with safe story", properties: ["fullMessage": "\(fullMessage)"])
                        
                        // Увеличили задержку до 3.0, как ты и хотел
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            fetchWithRetry(attempt: attempt + 1)
                        }
                    } else {
                        // Если упал уже третий раз — показываем ошибку юзеру
                        print("❌ Request failed after retry. Logging error.")
                        AnalyticService.shared.logEvent(name: "failure sendMessage", properties: [
                            "error type: ": "\(error)",
                            "error localizedDescription: ": "\(error.localizedDescription)"
                        ])
                        
                        let messageId = UUID().uuidString
                        let errorMessage = Message(role: "assistant", content: "LocationError.NewErrorText".localize(), id: messageId)
                        
                        // Заменяем лоадер на сообщение об ошибке
                        DispatchQueue.main.async {
                            if !self.messagesAI.isEmpty {
                                self.messagesAI[self.messagesAI.count - 1] = errorMessage
                                self.onMessagesUpdated?(true)
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                self.onMessageReceived?()
                            }
                        }
                    }
                }
            }
        }
        
        // Запускаем первую попытку
        fetchWithRetry(attempt: 0)
    }
    
    private func addLoadingMessage() {
        let messageId = UUID().uuidString
        let loadingMessage = Message(role: "assistant", content: "", isLoading: true, id: messageId)
        DispatchQueue.main.async { [self] in
            messagesAI.append(loadingMessage)
            messageIds[messagesAI.count - 1] = messageId
            onMessagesUpdated?(true)
        }
    }
    
    private func handleSuccessResponse(for responseText: String) {
        var photoID = ""
        let avatar = MainHelper.shared.currentAssistant?.avatarImageName ?? ""
        var testResponce: String?
        
        if responseText.contains("[restrict]") {
            MainHelper.shared.currentAIMessageType = .sendingPhoto

            UserDefaults.standard.set(true, forKey: "didRequestSuchPhoto")
            RemotePhotoService.shared.startFetching()
            
            photoID = ""
            let allResponses = (1...20).map { "responseToTestRequest\($0)".localize() }
            testResponce = allResponses.randomElement() ?? ""
            AnalyticService.shared.logEvent(name: "requested gift", properties: ["":""])
            WebHookAnalyticsService.shared.sendAnalyticsReport(messageText: "requested gift")
        }
        
        if responseText.contains("[photo]") {
            MainHelper.shared.currentAIMessageType = .sendingPhoto
            photoID = getPhotoID(for: avatar)
        } else {
            MainHelper.shared.currentAIMessageType = .typing
        }
        
        if responseText.contains("[video]") {
            MainHelper.shared.currentAIMessageType = .recordingVideo
            RemoteVideoService.shared.getVideoData(for: avatar) { [weak self] videoID in
                guard let self else { return }
                
                let messageId = UUID().uuidString
                let aiMessage = Message(role: "assistant", content: "[video]", photoID: videoID ?? "", id: messageId)
                messagesAI[messagesAI.count - 1] = aiMessage
                
                messageService.addMessage(aiMessage, assistantId: MainHelper.shared.currentAssistant?.id ?? "", messageId: messageId)
                onMessageReceived?()
                onMessagesUpdated?(true)
            }
            
            return
        }
        
        let isVoiceMessage = MainHelper.shared.isVoiceMessages && !responseText.contains("[restrict]") && !responseText.contains("[photo]")
        if isVoiceMessage {
            MainHelper.shared.currentAIMessageType = .recordingAudio
        }
        
        let messageId = UUID().uuidString
        let aiMessage = Message(role: "assistant", content: testResponce ?? responseText, photoID: photoID, isVoiceMessage: isVoiceMessage, id: messageId)
        messagesAI[messagesAI.count - 1] = aiMessage
        
        messageService.addMessage(aiMessage, assistantId: MainHelper.shared.currentAssistant?.id ?? "", messageId: messageId)
        onMessageReceived?()
        onMessagesUpdated?(true)
    }
    
    func getPhotoID(for avatar: String) -> String {
        // важно! для Created Dream Waifu - просто будут рандомно показываться любые фотки, без привязки к ее внешке
        let service = AvatarsService.shared
        let isTestB = ConfigService.shared.isTestB
        
        func getRandomAllPhoto() -> String {
            if isTestB {
                return service.allPhotos.randomElement() ?? ""
            } else {
                return service.allPhotos.filter { !service.testBAvatars.contains($0) }.randomElement() ?? ""
            }
        }

        guard
            avatar.hasPrefix("roleplay"),
            let role = Int(avatar.replacingOccurrences(of: "roleplay", with: ""))
        else {
            return getRandomAllPhoto()
        }

        guard var rolePhotos = service.roleplayAvatars[role] else {
            return getRandomAllPhoto()
        }

        if !isTestB {
            rolePhotos.removeAll { service.testBAvatars.contains($0) }
        }

        if let photo = rolePhotos.randomElement() {
            service.roleplayAvatars[role]?.removeAll { $0 == photo }
            return photo
        }

        return getRandomAllPhoto()
    }
}
