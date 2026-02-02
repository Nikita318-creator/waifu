import Foundation

struct Config: Codable { // новые поля обязательно опциональны должны быть иначе не распарситься json из кеша!
    let configVersion: Int
    let isTestB: Bool
    let needWait24h: Bool
    let isProPrice: Bool
    let needResetData: Bool
    let isVideoReady: Bool
    let isFreeMode: Bool
    let isDiscountOfferAvailable: Bool
    let isGameText: Bool?
    let dailyLimits: Int
    let initialLimit: Int
    let promptText: String
    let messageFromDeveloper: String
    let audioHalfKey: String
    let additionalPhotos: String
    let baseServer: String
}

final class ConfigService {
    static let shared = ConfigService()
    
    private(set) var needWait24h: Bool = false
    private(set) var isProPrice: Bool = true
    private(set) var isTestB: Bool = false
    private(set) var needResetData: Bool = false
    private(set) var isVideoReady: Bool = false
    private(set) var isFreeMode: Bool = false
    private(set) var isDiscountOfferAvailable: Bool = false
    private(set) var isGameText: Bool = false
    private(set) var dailyLimits = 1
    private(set) var initialLimit = 3
    private(set) var timeIntervalBetweenRequests = 0.1
    private(set) var messageFromDeveloper = ""
    private(set) var promptText = ""
    private(set) var audioHalfKey = ""
    private(set) var baseServer = ""
    private(set) var additionalPhotos = "" {
        didSet {
            if isTestB && IAPService.shared.hasActiveSubscription {
                DispatchQueue.main.async {
                    RemotePhotoService.shared.startFetching()
                }
            }
        }
    }

    private let configURL = URL(string: "https://raw.githubusercontent.com/Nikita318-creator/analitics-data/main/analiticsWaifu2.json")
    private let cachedConfigKey = "cachedConfigKey"

    private init() {}
    
    func fetchConfig(completion: ((Bool) -> Void)? = nil) {
        guard let configURL else { return }
        
        let request = URLRequest(url: configURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let self = self else { return }
            
            guard let data = data, error == nil,
                  let remoteConfig = try? JSONDecoder().decode(Config.self, from: data) else {
                DispatchQueue.main.async {
                    self.loadFromCacheOnly()
                    completion?(false)
                }
                return
            }

            DispatchQueue.main.async {
                self.processConfig(remoteConfig)
                completion?(remoteConfig.isTestB)
            }
        }.resume()
    }
    
    private func loadFromCacheOnly() {
        if let data = UserDefaults.standard.data(forKey: cachedConfigKey),
           let cached = try? JSONDecoder().decode(Config.self, from: data) {
            self.setFrom(cached)
        }
    }
    
    private func processConfig(_ remoteConfig: Config) {
        var cachedConfig: Config? = nil
        if let data = UserDefaults.standard.data(forKey: cachedConfigKey) {
            cachedConfig = try? JSONDecoder().decode(Config.self, from: data)
        }
        
        mergeAndApply(remote: remoteConfig, cached: cachedConfig)
    }
    
    // MARK: - Core Logic (Merge Strategy)
    private func mergeAndApply(remote: Config, cached: Config?) {
        if remote.needResetData {
            setFrom(remote)
            cacheConfig(remote)
            return
        }

        let stickyIsTestB = remote.isTestB || (cached?.isTestB ?? false)
        let stickyIsGameText = (remote.isGameText ?? false) || (cached?.isGameText ?? false)
        
        let finalPhotos: String
        if let cachedPhotos = cached?.additionalPhotos, !cachedPhotos.isEmpty {
            finalPhotos = cachedPhotos
        } else {
            finalPhotos = remote.additionalPhotos
        }

        let finalPromptText: String
        if let cachedPromptText = cached?.promptText, !cachedPromptText.isEmpty {
            finalPromptText = cachedPromptText
        } else {
            finalPromptText = remote.promptText
        }
        
        let mergedConfig = Config(
            configVersion: remote.configVersion,
            isTestB: stickyIsTestB,
            needWait24h: remote.needWait24h,
            isProPrice: remote.isProPrice,
            needResetData: remote.needResetData,
            isVideoReady: remote.isVideoReady,
            isFreeMode: remote.isFreeMode,
            isDiscountOfferAvailable: remote.isDiscountOfferAvailable,
            isGameText: stickyIsGameText,
            dailyLimits: remote.dailyLimits,
            initialLimit: remote.initialLimit,
            promptText: finalPromptText,
            messageFromDeveloper: remote.messageFromDeveloper,
            audioHalfKey: remote.audioHalfKey,
            additionalPhotos: finalPhotos,
            baseServer: remote.baseServer
        )

        setFrom(mergedConfig)
        cacheConfig(mergedConfig)
    }

    private func setFrom(_ config: Config) {
        self.isTestB = config.isTestB
        self.needWait24h = config.needWait24h
        self.isProPrice = config.isProPrice
        self.needResetData = config.needResetData
        self.isVideoReady = config.isVideoReady
        self.isFreeMode = config.isFreeMode
        self.isDiscountOfferAvailable = config.isDiscountOfferAvailable
        self.isGameText = config.isGameText ?? false
        self.dailyLimits = config.dailyLimits
        self.initialLimit = config.initialLimit
        self.audioHalfKey = config.audioHalfKey
        self.promptText = config.promptText
        self.messageFromDeveloper = config.messageFromDeveloper
        self.additionalPhotos = config.additionalPhotos
        self.baseServer = config.baseServer
    }

    private func cacheConfig(_ config: Config) {
        if let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: cachedConfigKey)
        }
    }
}
