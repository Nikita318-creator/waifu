import AVFoundation

class GoogleTTSManager: NSObject {
    static let shared = GoogleTTSManager()
    
    var audioPlayer: AVPlayer?
    private let apiKey = APIs.googleTTSManagerAPIKey
    
    var currentSpeakinID: String?
    private var isPreparing: Bool = false

    // Теперь UI сразу увидит, что процесс пошел
    var isSpeaking: Bool {
        if isPreparing {
            return true
        }
        return audioPlayer?.rate != 0 && audioPlayer?.error == nil && audioPlayer != nil
    }

    private override init() {
        super.init()
    }

    func speak(text: String) {
        stopSpeaking()
        
        isPreparing = true
        NotificationCenter.default.post(name: NSNotification.Name("updateAllAudioCellsOnStart"), object: nil)
        
        // 1. Берем код языка
        let langCode = String((MainHelper.shared.currentLanguage.isEmpty ? (Locale.current.languageCode ?? "en") : MainHelper.shared.currentLanguage).prefix(2)).lowercased()

        // 2. Мапим на лучшие доступные голоса (Tier 1 & Tier 2)
        var langTag = "en-US"
        var voiceName = "en-US-Neural2-H"

        switch langCode {
        // --- TIER 1 ---
        case "en": // English (US)
            langTag = "en-US"; voiceName = "en-US-Neural2-H"
        case "ja": // Japanese
            langTag = "ja-JP"; voiceName = "ja-JP-Neural2-B"
        case "zh": // Chinese (Mandarin)
            langTag = "cmn-CN"; voiceName = "cmn-CN-Wavenet-A"
        case "de": // German
            langTag = "de-DE"; voiceName = "de-DE-Neural2-F"
        case "fr": // French
            langTag = "fr-FR"; voiceName = "fr-FR-Neural2-A"
        case "es": // Spanish (Spain)
            langTag = "es-ES"; voiceName = "es-ES-Neural2-E"
        case "ko": // Korean
            langTag = "ko-KR"; voiceName = "ko-KR-Neural2-B"

        // --- TIER 2 ---
        case "it": // Italian
            langTag = "it-IT"; voiceName = "it-IT-Neural2-A"
        case "pt": // Portuguese (Brazil)
            langTag = "pt-BR"; voiceName = "pt-BR-Neural2-A"
        case "ru": // Russian
            langTag = "ru-RU"; voiceName = "ru-RU-Wavenet-A"
        case "tr": // Turkish
            langTag = "tr-TR"; voiceName = "tr-TR-Wavenet-A"
        case "vi": // Vietnamese
            langTag = "vi-VN"; voiceName = "vi-VN-Wavenet-A"
        case "th": // Thai
            langTag = "th-TH"; voiceName = "th-TH-Standard-A" // У Тайланда только стандарт
        case "nl": // Dutch
            langTag = "nl-NL"; voiceName = "nl-NL-Wavenet-A"
        case "pl": // Polish
            langTag = "pl-PL"; voiceName = "pl-PL-Wavenet-A"

        default:
            // Если языка нет в списке, используем международный английский
            langTag = "en-US"
            voiceName = "en-US-Neural2-H"
        }

        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.playback, mode: .spokenAudio, options: [])
        try? audioSession.setActive(true)
        
        guard let url = URL(string: "https://texttospeech.googleapis.com/v1/text:synthesize?key=\(apiKey)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let json: [String: Any] = [
            "input": ["text": text],
            "voice": [
                "languageCode": langTag,
                "name": voiceName
            ],
            "audioConfig": [
                "audioEncoding": "MP3",
                "pitch": 4.0,
                "speakingRate": 1.05
            ]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: json)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            // Если пришла ошибка или данных нет — сбрасываем индикатор
            guard let data = data, error == nil else {
                print("❌ Ошибка сети: \(error?.localizedDescription ?? "no data")")
                WebHookAnalyticsService.shared.sendAnalyticsReport(messageText: "audio message error:\n \(error?.localizedDescription ?? "no data")")
                self?.handleError()
                return
            }
            
            // Читаем JSON. Если там ошибка (например, 400), выходим
            guard let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: String],
                  let audioContent = jsonResponse["audioContent"],
                  let audioData = Data(base64Encoded: audioContent) else {
                print("❌ Google вернул ошибку: \(String(data: data, encoding: .utf8) ?? "")")
                WebHookAnalyticsService.shared.sendAnalyticsReport(messageText: "audio message JSON-error:\n \(String(data: data, encoding: .utf8) ?? "")")
                self?.handleError()
                return
            }
            
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("speech.mp3")
            try? audioData.write(to: tempURL)
            
            DispatchQueue.main.async {
                self?.isPreparing = false
                self?.play(url: tempURL)
            }
        }.resume()
    }

    // Доп. метод для сброса стейта при ошибке, чтобы ячейка не "висла"
    private func handleError() {
        DispatchQueue.main.async {
            self.isPreparing = false
            self.handleFinished()
        }
    }

    private func play(url: URL) {
        let playerItem = AVPlayerItem(url: url)
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        
        audioPlayer = AVPlayer(playerItem: playerItem)
        audioPlayer?.play()
        
        // Дублируем нотификацию на случай, если за это время что-то сбросилось
        NotificationCenter.default.post(name: NSNotification.Name("updateAllAudioCellsOnStart"), object: nil)
    }

    func stopSpeaking() {
        isPreparing = false
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        audioPlayer?.pause()
        audioPlayer = nil
        handleFinished()
    }

    @objc private func playerDidFinishPlaying() {
        handleFinished()
    }
    
    private func handleFinished() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name("updateAllAudioCellsOnFinish"), object: nil)
        }
    }
}
