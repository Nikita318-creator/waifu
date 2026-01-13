import Foundation

// MARK: - 1. Структуры для запроса (Request)
struct ProxyRequest: Encodable {
    let message: String
    let system_prompt: String
    let use_gemini_2_5: Bool?
    let useOnlyBillingApi: Bool?
}

// MARK: - 2. Структуры для ответа (Response)
struct ProxyResponse: Decodable {
    
    let response: String?
    let modelUsed: String?
    let usedBilling: Bool?
    let attemptsBeforeSuccess: Int?
    
    let error: String?
    
    let details: ProxyErrorDetails?

    enum CodingKeys: String, CodingKey {
        case response
        case modelUsed = "model_used"
        case usedBilling = "used_billing"
        case attemptsBeforeSuccess = "attempts_before_success"
        case error
        case details
    }
}

struct ProxyErrorDetails: Decodable {
    let error: ApiError?
    
    struct ApiError: Decodable {
        let message: String
        let code: Int
        let status: String
    }
}

// MARK: - 3. Обработка ошибок
enum AIError: Error {
    case invalidURL
    case networkError(Error)
    case apiError(String)
    case decodingError(Error)
    case emptyResponse
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid proxy URL address."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .apiError(let message):
            return "Proxy API error: \(message)"
        case .decodingError(let error):
            return "Unable to parse response: \(error.localizedDescription)"
        case .emptyResponse:
            return "The proxy returned an empty or malformed response."
        }
    }
}

// MARK: - 4. Сервис
class AIService {
    
    private let proxyURLString = ConfigService.shared.baseServer.isEmpty ? "https://gemini-proxy-service-138319918962.us-central1.run.app/api/gemini-proxy" : ConfigService.shared.baseServer

    private var appSecretToken: String {
        guard let infoDict = Bundle.main.infoDictionary else {
            return ""
        }
        
        guard let token = infoDict["AuthToken"] as? String else {
            return ""
        }
        
        return token
    }
    
    func fetchAIResponse(userMessage: String, systemPrompt: String, completion: @escaping (Result<String, AIError>) -> Void) {
        
        guard let url = URL(string: proxyURLString) else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(appSecretToken, forHTTPHeaderField: "X-App-Secret")
        
        let requestBody = ProxyRequest(message: userMessage, system_prompt: systemPrompt, use_gemini_2_5: false, useOnlyBillingApi: false)
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            completion(.failure(.decodingError(error)))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            
            DispatchQueue.main.async {
                
                if let error = error {
                    completion(.failure(.networkError(error)))
                    
                    AnalyticService.shared.logEvent(
                        name: "CustomServerResponce",
                        properties: [
                            "networkError":"\(error)"
                        ]
                    )
                    
                    // реально ли ошибка в интернете юзера или в чем то еще дело? - случается очень редко но иногда ловлю.
                    WebHookAnalyticsService.shared.sendAnalyticsReport(messageText: "CustomServerResponce error! networkError:\n \(error)")
                    
                    return
                }
                
                guard let data = data else {
                    completion(.failure(.emptyResponse))
                    
                    AnalyticService.shared.logEvent(
                        name: "CustomServerResponce",
                        properties: [
                            "emptyResponse":"emptyResponse"
                        ]
                    )
                    
                    // Это «косяк» сервера или прокси, а не цензура: либо мой сервер либо гугл сервер вернул 500 (внутренняя ошибка бека)
                    WebHookAnalyticsService.shared.sendAnalyticsReport(messageText: "CustomServerResponce error! emptyResponse")
                    
                    return
                }
                
                do {
                    let proxyResponse = try JSONDecoder().decode(ProxyResponse.self, from: data)
                    
                    AnalyticService.shared.logEvent(
                        name: "CustomServerResponce",
                        properties: [
                            "attemptsBeforeSuccess":"\(proxyResponse.attemptsBeforeSuccess ?? 0)",
                            "modelUsed":"\(proxyResponse.modelUsed ?? "")",
                            "usedBilling":"\(proxyResponse.usedBilling ?? false)"
                        ]
                    )
                    
                    print()
                    print("proxyResponse: \(proxyResponse)")
                    print()

                    if let finalResponse = proxyResponse.response, !finalResponse.isEmpty {
                        completion(.success(finalResponse))
                        
                    } else if let errorMessage = proxyResponse.error {
                        completion(.failure(.apiError(errorMessage)))
                        // Лимит токенов, слишком длинный контекст или временная перегрузка самой модели - поэтому не смогли распарсить ответ, ответ есть но у него не та структура как при ответе текстом (для ошибки другая модель должна парсится)?
                        WebHookAnalyticsService.shared.sendAnalyticsReport(messageText: "CustomServerResponce error! empty response error:\n \(errorMessage)")
                        
                    } else if let details = proxyResponse.details, let message = details.error?.message {
                        completion(.failure(.apiError(message)))
                        
                        // Юзер ввел какое-то хитрое сочетание символов, эмодзи или невидимых знаков (например, при копипасте), которые ломают JSON на стороне прокси или не нравятся API Google
                        WebHookAnalyticsService.shared.sendAnalyticsReport(messageText: "CustomServerResponce error! empty response parsing details error:\n \(message)")
                        
                    } else {
                        completion(.failure(.emptyResponse))
                        
                        // пришел JSON, который не содержит ни текста, ни явной ошибки.
                        WebHookAnalyticsService.shared.sendAnalyticsReport(messageText: "CustomServerResponce error! UNKNOWN ERROR \(proxyResponse)")
                    }
                    
                } catch let decodingError {
                    if let rawString = String(data: data, encoding: .utf8) {
                         print("❌ RAW RESPONSE: \(rawString)")
                    }
                    // Gemini начал отвечать, но на середине предложения у него кончились токены или сервер обрубил связь, он может прислать «битый» JSON (незакрытая фигурная скобка и т.д.)

                    WebHookAnalyticsService.shared.sendAnalyticsReport(messageText: "CustomServerResponce error! decodingError \(decodingError)")
                    AnalyticService.shared.logEvent(
                        name: "CustomServerResponce",
                        properties: [
                            "decodingError":"\(decodingError)"
                        ]
                    )
                    completion(.failure(.decodingError(decodingError)))
                }
            }
        }.resume()
    }
}
