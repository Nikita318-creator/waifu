import UIKit
import ApphudSDK
import AmplitudeUnified

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
//        CoinsService.shared.addCoins(100)
        
        let _ = AnalyticService.shared

        ConfigService.shared.fetchConfig { isTestB in
            print("✅ isTestB = \(isTestB)")
            AnalyticService.shared.logEvent(name: "✅ isTestB = \(isTestB)", properties: ["":""])
            if !isTestB {
                let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
                let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String

                let currentVersion: String
                
                if let version = appVersion, let build = buildNumber {
                    let displayString = "Version: \(version) (\(build))"
                    currentVersion = displayString
                } else {
                    currentVersion = ""
                }
                
                AnalyticService.shared.logEvent(
                    name: "Open for testA",
                    properties: [
                        "preferredLanguages:":"\(Locale.preferredLanguages.first ?? "???")",
                        "currentVersion": "\(currentVersion)"
                    ]
                )
            }
        }
        
        // Apphud:
        Apphud.start(apiKey: "app_pCfawoXTbbEHX4qk6pRA1zATGDxNgp")
        let idfv = UIDevice.current.identifierForVendor?.uuidString ?? ""
        Apphud.setDeviceIdentifiers(idfa: nil, idfv: idfv)
        
        DispatchQueue.main.async {
            self.setFirstLaunchDate()
            self.checkForDiscountOffer()
        }
         
        return true
    }
    
    private func checkForDiscountOffer() {
        guard !IAPService.shared.hasActiveSubscription else { return }
        
//        MainHelper.shared.isDiscountOffer = true
//        MainHelper.shared.needShowPaywallForDiscountOffer = true
        
        let defaults = UserDefaults.standard
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        
        guard let dateString = defaults.string(forKey: "firstLaunchDate"),
              let firstLaunchDate = formatter.date(from: dateString) else { return }
        
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: firstLaunchDate, to: now)
        let daysSinceInstallation = components.day ?? 0
        
        // Новые вехи
        let milestones = [30, 7, 2]
        
        // 3. Генерируем ключи на основе milestones, чтобы не было расхождений
        let offerKeys = milestones.map { "discount_start_\($0)" }
        
        // Проверяем, не идет ли сейчас какой-то из уже активированных офферов (24 часа)
        for key in offerKeys {
            if let startTime = defaults.object(forKey: key) as? Date {
                let secondsInDay: TimeInterval = 24 * 60 * 60
                if now.timeIntervalSince(startTime) < secondsInDay {
                    MainHelper.shared.isDiscountOffer = true
                    print("🔥 Discount Active! Under key: \(key)")
                    return
                }
            }
        }
        
        // 4. Проверяем пора ли активировать новый
        for milestone in milestones {
            let startKey = "discount_start_\(milestone)"
            let usedKey = "discount_used_\(milestone)"
            
            if daysSinceInstallation >= milestone && !defaults.bool(forKey: usedKey) {
                defaults.set(now, forKey: startKey)
                defaults.set(true, forKey: usedKey)
                
                MainHelper.shared.isDiscountOffer = true
                MainHelper.shared.needShowPaywallForDiscountOffer = true
                print("✨ Milestone \(milestone) reached. Starting 24h discount.")
                
                AnalyticService.shared.logEvent(name: "DiscountActivated", properties: ["milestone": "\(milestone)"])
                return
            }
        }
    }
    
    // это не трогаем это отдельно для аналитики-ретеншена собираю
    private func setFirstLaunchDate() {
        let defaults = UserDefaults.standard
        let key = "firstLaunchDate"
        
        if defaults.string(forKey: key) == nil {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd.MM.yyyy"
            let today = formatter.string(from: Date())
            defaults.set(today, forKey: key)
            print("🔹 First launch date saved: \(today)")
        }
        
        AnalyticService.shared.logEvent(name: "FirstLaunchDate", properties: ["FirstLaunchDate: ":"\(defaults.string(forKey: key) ?? "")"])
    }
}

