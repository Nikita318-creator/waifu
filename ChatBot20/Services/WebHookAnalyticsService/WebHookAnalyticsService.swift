import UIKit

final class WebHookAnalyticsService {
    static let shared = WebHookAnalyticsService()
    
    private let telegramBotToken: String = "8440212874:AAEEG5gjda8shhELPpvf1Qv2HIKHgbBGA44"
    private let telegramChatID: String = "1059302098"
    
    // Тот самый короткий ID пользователя
    var userShortID: String {
        if let savedID = UserDefaults.standard.string(forKey: "user_analytics_id") {
            return savedID
        }
        
        // Генерируем новый: берем последние 8 символов UUID
        let newID = String(UUID().uuidString.suffix(8))
        UserDefaults.standard.set(newID, forKey: "user_analytics_id")
        return newID
    }

    private init() {}

    func sendAnalyticsReport(messageText: String) {
//        guard AnalyticService.shared.environment == .prod else { return }

        let isPremium = IAPService.shared.hasActiveSubscription
        var versionText = "V:"
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            versionText += " \(version)(\(build)) "
        }
        
        let firstLaunchDate: String
        if let firstLaunch = UserDefaults.standard.string(forKey: "firstLaunchDate") {
            firstLaunchDate = firstLaunch
        } else {
            firstLaunchDate = ""
        }
        
        var finalText: String

        finalText = messageText + "\n\(versionText), \nisPremium: \(isPremium), \nfirst Launch Date: \(firstLaunchDate) \nUserID: [\(userShortID), \nLocale: \(Locale.preferredLanguages.first ?? "nil")]"

        finalText = finalText.replacingOccurrences(of: "_", with: "-")

        let parameters: [String: Any] = [
            "chat_id": telegramChatID,
            "text": finalText,
            "parse_mode": "Markdown"
        ]

        let urlString = "https://api.telegram.org/bot\(telegramBotToken)/sendMessage"
        guard let telegramURL = URL(string: urlString) else {
            return
        }

        var request = URLRequest(url: telegramURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: parameters, options: [])
            request.httpBody = jsonData
        } catch {
            print("Failed to encode request body: \(error.localizedDescription)")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, taskError in
            if let taskError = taskError {
                print("Error sending report to Telegram: \(taskError.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                return
            }
            
            print("report successfully sent to Telegram.")
        }
        
        task.resume()
    }
}
