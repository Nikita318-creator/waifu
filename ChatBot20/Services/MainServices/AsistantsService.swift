import Foundation
import RealmSwift

// Модель для Realm
class AssistantConfigObject: Object {
    @Persisted(primaryKey: true) var id: String
    @Persisted var assistantName: String
    @Persisted var expertise: String
    @Persisted var assistantInfo: String
    @Persisted var userInfo: String
    @Persisted var createdAt: Date
    @Persisted var updatedAt: Date
    @Persisted var isPremium: Bool
    @Persisted var avatarImageName: String
    
    // Инициализатор
    convenience init(id: String, config: AssistantConfig, isPremium: Bool = false) {
        self.init()
        self.id = id
        self.assistantName = config.assistantName
        self.expertise = config.expertise.rawValue.localize()
        self.assistantInfo = config.assistantInfo
        self.userInfo = config.userInfo
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isPremium = isPremium
        self.avatarImageName = config.avatarImageName
    }
    
    // Конвертация в AssistantConfig
    func toAssistantConfig() -> AssistantConfig {
        return AssistantConfig(
            id: id,
            assistantName: assistantName,
            expertise: Expertise.convert(for: expertise),
            assistantInfo: assistantInfo,
            userInfo: userInfo,
            avatarImageName: avatarImageName
        )
    }
}

class AssistantsService {
    private let realm: Realm
    
    init() {
        // Настраиваем конфигурацию Realm с миграцией - не забывай это
        let config = Realm.Configuration(
            schemaVersion: SchemaVersion.currentSchemaVersion,
            migrationBlock: { migration, oldSchemaVersion in
                //
            }
        )
        Realm.Configuration.defaultConfiguration = config
        
        do {
            self.realm = try Realm(configuration: config)
        } catch {
            let fallbackConfig = Realm.Configuration(inMemoryIdentifier: "AssistantsServiceFallbackRealm")
            self.realm = try! Realm(configuration: fallbackConfig)
        }
    }
    
    // Добавление новой конфигурации
    func addConfig(_ config: AssistantConfig) {
        let id = config.id ?? UUID().uuidString
        var newConfig = config
        newConfig.id = id
        let object = AssistantConfigObject(id: id, config: newConfig)
        do {
            try realm.write {
                realm.add(object)
            }
        } catch {
            print("Failed to add config: \(error)")
        }
    }
    
    // Обновление конфигурации по ID
    func updateConfig(id: String, config: AssistantConfig) {
        guard let object = realm.object(ofType: AssistantConfigObject.self, forPrimaryKey: id) else {
            print("Config with ID \(id) not found")
            return
        }
        do {
            try realm.write {
                object.assistantName = config.assistantName
                object.expertise = config.expertise.rawValue.localize()
                object.assistantInfo = config.assistantInfo
                object.userInfo = config.userInfo
                object.avatarImageName = config.avatarImageName
                object.updatedAt = Date()
            }
            realm.refresh()
        } catch {
            print("Failed to update config: \(error)")
        }
    }
    
    // Удаление конфигурации по ID
    func deleteConfig(id: String) {
        guard let object = realm.object(ofType: AssistantConfigObject.self, forPrimaryKey: id) else {
            print("Config with ID \(id) not found")
            return
        }
        do {
            try realm.write {
                realm.delete(object)
            }
        } catch {
            print("Failed to delete config: \(error)")
        }
    }
    
    // Получение всех конфигураций, отсортированных по updatedAt
    func getAllConfigs() -> [AssistantConfig] {
        let objects = realm.objects(AssistantConfigObject.self)
            .sorted(byKeyPath: "updatedAt", ascending: false)
        return objects.map { $0.toAssistantConfig() }
    }
    
    // Получение конфигурации по ID
    func getConfig(id: String) -> AssistantConfig? {
        return realm.object(ofType: AssistantConfigObject.self, forPrimaryKey: id)?.toAssistantConfig()
    }
}
