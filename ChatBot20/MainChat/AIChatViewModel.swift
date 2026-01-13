import UIKit

struct Message {
    let role: String
    let content: String
    var isLoading: Bool = false
    var photoID: String = ""
    var isVoiceMessage: Bool = false
    var id: String? = nil
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
        
        aiService.fetchAIResponse(userMessage: (systemPrompt ?? "") + "\n" + text, systemPrompt: "") { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let responseText):
                AnalyticService.shared.logEvent(name: "responseMessage", properties: ["responseMessage: ":[responseText]])
                self.handleSuccessResponse(for: responseText.trimmingCharacters(in: .whitespacesAndNewlines))
                
            case .failure(let error):
                AnalyticService.shared.logEvent(name: "failure sendMessage", properties: ["error type: ":"\(error)", "error localizedDescription: ":"\(error.localizedDescription)"])
                
                let messageId = UUID().uuidString
                let errorMessage = Message(role: "assistant", content: "LocationError.NewErrorText".localize(), id: messageId)
                self.messagesAI[self.messagesAI.count - 1] = errorMessage
                self.onMessagesUpdated?(true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.onMessageReceived?()
                }
            }
        }
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
