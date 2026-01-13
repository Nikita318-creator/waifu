import UIKit

class UnreadMessagesService {
    static let shared = UnreadMessagesService()

    private let lastCheckedKey = "UnreadMessagesService.lastChecked"
    private let intervalHours: TimeInterval = 24 * 60 * 60
    private let defaults = UserDefaults.standard
    
    var lasChatUnreadID: String? = nil
    
    private init() {}

    func needAddUnreadMessage() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["inactivity_notification"])

        let bodyMessageKey = "unreadMessage.Push.Message" + ((1...12).map { String($0) }.randomElement() ?? "2")
        let content = UNMutableNotificationContent()
        content.title = "unreadMessage.Push.Title".localize()
        content.body = bodyMessageKey.localize()
        content.sound = .default
        content.badge = NSNumber(value: 1)

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: intervalHours, repeats: false)
        let request = UNNotificationRequest(identifier: "inactivity_notification", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        
        defaults.set(Date(), forKey: lastCheckedKey)
    }
}
