import Foundation
import RealmSwift

// Новая модель для динамических данных (LTM - Long Term Memory)
class AssistantDynamicStateObject: Object {
    @Persisted(primaryKey: true) var assistantId: String // Совпадает с ID ассистента
    @Persisted var baseStyle: String = ""  // Результат обучения после 10+ сообщений
    @Persisted var memory: String = ""     // Factual Golden List
    @Persisted var updatedAt: Date = Date()
    @Persisted var updatedAfter6: Bool = false
    @Persisted var updatedAfter12: Bool = false
    @Persisted var updatedAfter20: Bool = false

    convenience init(assistantId: String) {
        self.init()
        self.assistantId = assistantId
        self.updatedAt = Date()
    }
}

class AssistantDynamicService {
    private let realm: Realm
    
    init() {
        let config = Realm.Configuration(
            schemaVersion: SchemaVersion.currentSchemaVersion,
            migrationBlock: { migration, oldSchemaVersion in
                // Здесь будет логика миграции при изменении схемы
            }
        )
        
        do {
            self.realm = try Realm(configuration: config)
        } catch {
            print("Failed to init Realm for DynamicService, falling back to in-memory: \(error)")
            let fallbackConfig = Realm.Configuration(inMemoryIdentifier: "AssistantDynamicServiceFallback")
            self.realm = try! Realm(configuration: fallbackConfig)
        }
    }
    
    // Получить существующее состояние или создать новое в транзакции
    func getState(for assistantId: String) -> AssistantDynamicStateObject {
        if let existing = realm.object(ofType: AssistantDynamicStateObject.self, forPrimaryKey: assistantId) {
            return existing
        }
        
        let newState = AssistantDynamicStateObject(assistantId: assistantId)
        try? realm.write {
            realm.add(newState, update: .all)
        }
        return newState
    }

    // Обновление памяти (Golden List)
    func updateMemory(assistantId: String, newMemory: String) {
        let state = getState(for: assistantId)
        try? realm.write {
            state.memory = newMemory
            state.updatedAt = Date()
        }
    }

    // Обновление стиля (Результат обучения)
    func updateBaseStyle(assistantId: String, style: String) {
        let state = getState(for: assistantId)
        try? realm.write {
            state.baseStyle = style
            state.updatedAt = Date()
        }
    }
    
    func markProgress(for assistantId: String, messagesCount: Int) {
        let state = getState(for: assistantId)
        try? realm.write {
            if messagesCount >= 20 {
                state.updatedAfter20 = true
            } else if messagesCount >= 12 {
                state.updatedAfter12 = true
            } else if messagesCount >= 6 {
                state.updatedAfter6 = true
            }
            state.updatedAt = Date()
        }
    }

    // Метод для сброса при удалении чата
    func resetState(for assistantId: String) {
        if let state = realm.object(ofType: AssistantDynamicStateObject.self, forPrimaryKey: assistantId) {
            try? realm.write {
                state.baseStyle = ""
                state.memory = ""
                state.updatedAfter6 = false
                state.updatedAfter12 = false
                state.updatedAfter20 = false
                state.updatedAt = Date()
            }
        }
    }
}
