
import Foundation
import RealmSwift

enum SchemaVersion {
    static let currentSchemaVersion: UInt64 = 2
}

class MessageHistoryServiceObject: Object {
    @Persisted(primaryKey: true) var id: String
    @Persisted var assistantId: String
    @Persisted var role: String
    @Persisted var content: String
    @Persisted var isLoading: Bool
    @Persisted var isVoiceMessage: Bool
    @Persisted var photoID: String
    @Persisted var createdAt: Date
    @Persisted var updatedAt: Date
    
    convenience init(message: Message, assistantId: String, id: String) {
        self.init()
        self.id = id
        self.assistantId = assistantId
        self.role = message.role
        self.content = message.content
        self.isLoading = message.isLoading
        self.isVoiceMessage = message.isVoiceMessage
        self.photoID = message.photoID
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    func toMessage() -> Message {
        return Message(role: role, content: content, isLoading: isLoading, photoID: photoID, isVoiceMessage: isVoiceMessage, id: id)
    }
}

class MessageHistoryService {
    private let realm: Realm
    
    init() {
        // Настраиваем конфигурацию Realm с миграцией - не забывай это
        let config = Realm.Configuration(
            schemaVersion: SchemaVersion.currentSchemaVersion,
            migrationBlock: { migration, oldSchemaVersion in
                //
            }
        )
        
        do {
            self.realm = try Realm(configuration: config)
        } catch {
            let fallbackConfig = Realm.Configuration(inMemoryIdentifier: "MessageHistoryServiceFallbackRealm")
            self.realm = try! Realm(configuration: fallbackConfig)
        }
    }
    
    // Добавление нового сообщения
    func addMessage(_ message: Message, assistantId: String, messageId: String) {
        let object = MessageHistoryServiceObject(message: message, assistantId: assistantId, id: messageId)
        
        do {
            try realm.write {
                let messages = realm.objects(MessageHistoryServiceObject.self)
                    .filter("assistantId == %@", assistantId)
                    .sorted(byKeyPath: "createdAt", ascending: true)

                if messages.count >= 100, let oldest = messages.first {
                    realm.delete(oldest)
                }

                realm.add(object)
            }
        } catch {
            print("Failed to add message: \(error)")
        }
    }
    
    // Обновление сообщения по ID
    func updateMessage(id: String, message: Message, assistantId: String) {
        guard let object = realm.object(ofType: MessageHistoryServiceObject.self, forPrimaryKey: id) else {
            print("Message with ID \(id) not found")
            return
        }
        do {
            try realm.write {
                object.assistantId = assistantId
                object.role = message.role
                object.content = message.content
                object.isLoading = message.isLoading
                object.updatedAt = Date()
            }
        } catch {
            print("Failed to update message: \(error)")
        }
    }
    
    // Удаление сообщения по ID
    func deleteMessage(id: String) {
        guard let object = realm.object(ofType: MessageHistoryServiceObject.self, forPrimaryKey: id) else {
            print("Message with ID \(id) not found")
            return
        }
        do {
            try realm.write {
                realm.delete(object)
            }
        } catch {
            print("Failed to delete message: \(error)")
        }
    }
    
    // Получение всех сообщений для ассистента, отсортированных по createdAt
    func getAllMessages(forAssistantId assistantId: String) -> [Message] {
        let objects = realm.objects(MessageHistoryServiceObject.self)
            .filter("assistantId == %@", assistantId)
            .sorted(byKeyPath: "createdAt", ascending: true)
        return objects.map { $0.toMessage() }
    }
    
    // Получение сообщения по ID
    func getMessage(id: String) -> Message? {
        return realm.object(ofType: MessageHistoryServiceObject.self, forPrimaryKey: id)?.toMessage()
    }
}
