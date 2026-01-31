import ApphudSDK
import UIKit

enum SubsIDs {
    static let weeklyPROSubsId = "weeklyPROSubsId"
    static let monthlyPROSubsId = "monthlyPROSubsId"
    
    static let weeklySubsId =  "weeklySubsIdNew"
    static let monthlySubsId = "monthlySubsIdNew"
}

enum CoinsIDs {
    static let coins10   = "IAP.coins10"
    static let coins20   = "IAP.coins20"
    static let coins50   = "IAP.coins50"
    static let coins100  = "IAP.coins100"
    static let coins500  = "IAP.coins500"
    static let coins1000 = "IAP.coins1000"
}

enum InAppPurchaseResult {
    case purchased
    case failed
    case restored
}

struct SubscriptionStatus {
    let isActive: Bool
    let isTrialPeriod: Bool
    let remainingTrialDays: Int?
}

class IAPService: NSObject {
    static let shared = IAPService()
    
    var closure: ((InAppPurchaseResult) -> Void)?
    var products: [ApphudProduct] = []
    
    var hasActiveSubscription: Bool {
//        Apphud.hasActiveSubscription()
//        false
        AnalyticService.shared.environment == .prod
            ? (Apphud.hasActiveSubscription() || (ConfigService.shared.isFreeMode && UserDefaults.standard.bool(forKey: "is_free_premium_active")))
            : true
    }
    
    private override init() {
        super.init()
        // Apphud уже настроен в AppDelegate, инициализируем и загружаем продукты
        fetchProducts()
    }
    
    // Предварительная загрузка продуктов при инициализации
    private func fetchProducts() {
        Task {
            // Получаем placements с ожиданием загрузки SKProducts
            let placements = await Apphud.placements(maxAttempts: 3)
            if let placement = placements.first, let paywall = placement.paywall, !paywall.products.isEmpty {
                self.products = paywall.products
                print("Продукты загружены: \(self.products.map { $0.productId })")
                AnalyticService.shared.logEvent(name: "products fetched: \(self.products.map { $0.productId })", properties: ["":""])

            } else {
                AnalyticService.shared.logEvent(name: "ERROR fetch products", properties: ["":""])
                print("Нет доступных продуктов или paywall")
                self.products = []
            }
        }
    }
    
    // MARK: - Product Request
    func getProducts() -> [ApphudProduct] {
        return products
    }
    
    // MARK: - Purchases
    func purchase(productId: String, closure: @escaping (InAppPurchaseResult) -> Void) {
        self.closure = closure
        
        guard let product = products.first(where: { $0.productId == productId }) else {
            print("Продукт \(productId) не найден")
           
            AnalyticService.shared.logEvent(name: "ERROR product not found: \(productId)", properties: ["":""])

            closure(.failed)
            return
        }
        
        Task { @MainActor in
            Apphud.purchase(product, callback: { result in
                if let error = result.error {
                    print("Ошибка покупки: \(error.localizedDescription)")
                  
                    if error.localizedDescription.contains("SKErrorDomain error 2") {
                        AnalyticService.shared.logEvent(name: "canceled purchase", properties: ["":""])
                    } else {
                        AnalyticService.shared.logEvent(name: "ERROR purchase: \(error.localizedDescription)", properties: ["":""])
                    }

                    closure(.failed)
                    return
                }
                
                if result.transaction != nil {
                    AnalyticService.shared.logEvent(name: "!!! Purchased: \(product.productId)", properties: ["":""])

                    closure(.purchased)
                } else {
                    
                    AnalyticService.shared.logEvent(name: "ERROR purchase - unknown?", properties: ["":""])

                    print("Покупка отменена или не завершена")
                    closure(.failed)
                }
            })
        }
    }
    
    func restorePurchases(closure: @escaping (InAppPurchaseResult) -> Void) {
        Task { @MainActor in
            let error = await Apphud.restorePurchases()
            if let error = error {
                print("Ошибка восстановления: \(error.localizedDescription)")
               
                closure(.failed)
                return
            }
            
            if hasActiveSubscription || (Apphud.subscriptions()?.isEmpty == false) {
               
                closure(.restored)
            } else {
                
                closure(.failed)
            }
        }
    }
}

// Обновление статуса подписки
extension IAPService {
    func apphudDidUpdateUserInfo(_ userInfo: ApphudUser) { }
}
