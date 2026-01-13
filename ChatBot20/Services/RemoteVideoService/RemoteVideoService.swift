import UIKit

final class RemoteVideoService {

    static let shared = RemoteVideoService()

    // Базовый URL для всех видео
    private let baseUrl = "https://raw.githubusercontent.com/uvarovn771-blip/anime_rol/main/rolVid"
    
    // Пул ссылок, которые еще НЕ были показаны в текущей сессии
    private var availableLinks: [String] = []
    
    // Все возможные ссылки (для быстрого сброса сессии)
    private var allLinks: [String] = []

    private init() {
        setupAllLinks()
        resetSession()
    }
    
    // Генерируем список от 1 до 100
    private func setupAllLinks() {
        allLinks = (1...164).map { "\(baseUrl)\($0).mp4" } 
    }

    private func resetSession() {
        print("RemoteVideoService: Session reset, shuffling links.")
        availableLinks = allLinks.shuffled()
    }

    // MARK: - Public API
    
    /// Основной метод. Теперь параметр avatar игнорируется для упрощения.
    func getVideoData(for avatar: String? = nil, completion: @escaping (String?) -> Void) {
        
        // 1. Выбираем следующую ссылку
        let urlString = selectNextUrl()
        
        guard let name = extractVideoName(from: urlString) else {
            completion(nil)
            return
        }
        
        // 2. Проверяем кэш (Realm)
        if RemoteRealmVideoService.shared.isVideoCached(name: name) {
            print("Video found in Realm: \(name)")
            completion(name)
            return
        }
        
        // 3. Качаем, если нет в кэше
        downloadVideo(from: urlString) { cachedName in
            completion(cachedName)
        }
    }
    
    // MARK: - Private Logic

    private func selectNextUrl() -> String {
        // Если просмотрели все 100 видео — обновляем список (рандомно)
        if availableLinks.isEmpty {
            resetSession()
        }
        
        // Достаем последнее видео из перемешанного списка
        return availableLinks.popLast() ?? allLinks.randomElement()!
    }

    private func downloadVideo(from urlString: String, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: urlString),
              let name = extractVideoName(from: urlString) else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                print("Download Error: \(error?.localizedDescription ?? "Unknown")")
                DispatchQueue.main.async { completion(nil) }
                return
            }

            // Сохраняем в Realm на главном потоке
            DispatchQueue.main.async {
                RemoteRealmVideoService.shared.saveVideo(
                    urlString: urlString,
                    name: name,
                    data: data
                )
                completion(name)
            }
        }.resume()
    }

    private func extractVideoName(from urlString: String) -> String? {
        URL(string: urlString)?
            .deletingPathExtension()
            .lastPathComponent
    }
}
