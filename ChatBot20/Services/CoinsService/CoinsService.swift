import UIKit
import StoreKit

final class CoinsService {
    
    static let shared = CoinsService()
    
    private init() {}
    
    private let coinsKey = "userCoinsKey"
    private let sentGiftsKey = "userSentGiftsKey"
    
    // MARK: - Coins Storage
    
    /// Получить текущее количество монет (по умолчанию 10, если ещё не сохранено)
    func getCoins() -> Int {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: coinsKey) == nil {
            defaults.set(1, forKey: coinsKey) // начальное значение
        }
        return defaults.integer(forKey: coinsKey)
    }
    
    /// Добавить монеты к текущему балансу
    func addCoins(_ amount: Int) {
        let defaults = UserDefaults.standard
        let current = getCoins()
        defaults.set(current + amount, forKey: coinsKey)
    }
    
    /// Списать монеты (с проверкой, чтобы не уйти в минус)
    func spendCoins(_ amount: Int) -> Bool {
        let defaults = UserDefaults.standard
        let current = getCoins()
        guard current >= amount else { return false }
        defaults.set(current - amount, forKey: coinsKey)
        return true
    }
    
    // MARK: - Prices
    
    /// Получить локализованную цену по Product ID
    func localizedPrice(for coinID: String) -> String? {
        guard let product = IAPService.shared.products.first(where: { $0.productId == coinID }) else {
            return nil
        }
        return product.skProduct?.localizedPrice()
    }
    
    /// Получить все цены сразу словарём [CoinID: локализованная цена]
    func allLocalizedPrices() -> [String: String] {
        let ids = [
            CoinsIDs.coins10,
            CoinsIDs.coins20,
            CoinsIDs.coins50,
            CoinsIDs.coins100,
            CoinsIDs.coins500,
            CoinsIDs.coins1000
        ]
        
        var prices: [String: String] = [:]
        for id in ids {
            if let price = localizedPrice(for: id) {
                prices[id] = price
            }
        }
        return prices
    }
    
    // MARK: - Sent Gifts Storage
    
    /// Получить массив отправленных подарков по ключу ассистента
    func getSentGifts(for assistantID: String) -> [String] {
        let defaults = UserDefaults.standard
        let dictionary = defaults.dictionary(forKey: sentGiftsKey) as? [String: [String]] ?? [:]
        return dictionary[assistantID] ?? []
    }
    
    /// Добавить новый подарок к существующим отправленным
    func addSentGift(_ giftID: String, for assistantID: String) {
        let defaults = UserDefaults.standard
        var dictionary = defaults.dictionary(forKey: sentGiftsKey) as? [String: [String]] ?? [:]
        var gifts = dictionary[assistantID] ?? []
        gifts.append(giftID)
        dictionary[assistantID] = gifts
        defaults.set(dictionary, forKey: sentGiftsKey)
    }
    
    /// Удалить все отправленные подарки для ассистента
    func removeAllSentGifts(for assistantID: String) {
        let defaults = UserDefaults.standard
        var dictionary = defaults.dictionary(forKey: sentGiftsKey) as? [String: [String]] ?? [:]
        
        dictionary[assistantID] = []
        defaults.set(dictionary, forKey: sentGiftsKey)
    }
}
