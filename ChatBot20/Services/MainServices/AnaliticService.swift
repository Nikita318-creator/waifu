import AmplitudeUnified

enum Environment {
    case prod
    case dev
}

class AnalyticService {
    static let shared = AnalyticService()
    
    let amplitude = Amplitude(apiKey: "d4154e9a8b46ee8e34fafe54f381da2f", serverZone: .EU)

    private init() {}
    
    let environment: Environment = .dev
    
    func logEvent(name: String, properties: [AnyHashable : Any]) {
        guard environment == .prod else { return }
        
        var versionText = "V:"
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            versionText += " \(version)(\(build)) "
        }
        
        var eventProperties = properties.reduce(into: [String: Any]()) { result, pair in
            if let key = pair.key as? String {
                result[key] = pair.value
            } else {
                result["\(pair.key)"] = pair.value
            }
        }
        
        eventProperties["app_version"] = versionText

        let event = BaseEvent(
            eventType: name,
            eventProperties: eventProperties,
            userProperties: nil
        )
        
        amplitude.track(event: event)
    }
}
