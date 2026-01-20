import Foundation
import RealmSwift

class StreakObject: Object {
    @Persisted(primaryKey: true) var chatID: String
    @Persisted var count: Int = 0
    @Persisted var lastUpdateDate: Date?

    convenience init(chatID: String, count: Int, lastUpdateDate: Date?) {
        self.init()
        self.chatID = chatID
        self.count = count
        self.lastUpdateDate = lastUpdateDate
    }
}

enum StreakType {
    case streakStarted
    case streakEnded
    case streakContinued
}

class StreaksService {
    static let shared = StreaksService()
    private let realm: Realm

    private init() {
        do {
            self.realm = try Realm()
        } catch {
            let fallbackConfig = Realm.Configuration(inMemoryIdentifier: "StreaksServiceFallbackRealm")
            self.realm = try! Realm(configuration: fallbackConfig)
        }
    }

    @discardableResult
    func checkAndUpdateStreak(for chatID: String) -> StreakType? {
        let now = Date()
        let calendar = Calendar.current
        let streak = realm.object(ofType: StreakObject.self, forPrimaryKey: chatID)
        ?? StreakObject(chatID: chatID, count: 0, lastUpdateDate: nil)
        
        return try? realm.write {
            var currentStreakType: StreakType?
            
            if let lastDate = streak.lastUpdateDate {
                if calendar.isDateInToday(lastDate) {
                    return nil // Уже заходил, не спамим
                } else if calendar.isDateInYesterday(lastDate) {
                    streak.count += 1
                    streak.lastUpdateDate = now
                    
                    // Если стало 2 — это визуальный старт, если 3+ — продолжение
                    currentStreakType = (streak.count == 2) ? .streakStarted : .streakContinued
                } else {
                    currentStreakType = .streakEnded
                    streak.count = 1 // Сбрасываем на 1
                    streak.lastUpdateDate = now
                }
            } else {
                // Самый первый раз в жизни
                streak.count = 1
                streak.lastUpdateDate = now
                currentStreakType = nil // Тут реально ничего не показываем
            }
            
            realm.add(streak, update: .modified)
            return currentStreakType
        }
    }

    func getStreakCount(for chatID: String) -> Int {
        return realm.object(ofType: StreakObject.self, forPrimaryKey: chatID)?.count ?? 0
    }
}
