
import UIKit

class RemotePhotoService {

    static let shared = RemotePhotoService()

    private var allLinks: [String] {
        (1...236).map { "\(ConfigService.shared.additionalPhotos)\($0).jpg" }
    }
    private var isTimeReady = false
    private let firstLaunchKey = "RemotePhotoServiceFirstLaunchDate"

    var isTestPhotosReady: Bool {
        RemoteRealmPhotoService.shared.getAllCachedImages().count > 0 // массив не пустой
        && (isTimeReady || !ConfigService.shared.needWait24h) // прошли сутки минимум
        && IAPService.shared.hasActiveSubscription // есть полдписка
        && !ConfigService.shared.additionalPhotos.isEmpty // не пустой параметр запроса
    }
    var alreadyShownPics: [String] = []
    
    private init() {
        checkFirstLaunch()
    }
    
    private func checkFirstLaunch() {
        let defaults = UserDefaults.standard
        
        if let savedDate = defaults.object(forKey: firstLaunchKey) as? Date {
            // Дата уже есть — проверяем, прошло ли больше 24 часов
            if Date().timeIntervalSince(savedDate) > 24 * 60 * 60 {
                isTimeReady = true
            } else {
                isTimeReady = false
            }
        } else {
            // Сохраняем текущую дату как первый запуск
            defaults.set(Date(), forKey: firstLaunchKey)
            isTimeReady = false
        }   
    }
    
    // Вспомогательный метод для получения имени файла без расширения
    private func extractImageName(from urlString: String) -> String? {
        guard let url = URL(string: urlString) else { return nil }
        let fileNameWithExtension = url.lastPathComponent
        let fileName = (fileNameWithExtension as NSString).deletingPathExtension
        return fileName
    }
    
    func startFetching() {
        let allLinksToDownload = UserDefaults.standard.bool(forKey: "didRequestSuchPhoto") ? allLinks : allLinks.suffix(10)
        
        for link in allLinksToDownload {
            guard let imageName = extractImageName(from: link) else {
                print("Invalid URL or could not extract image name from \(link)")
                continue
            }
            
            // Проверяем, есть ли картинка в кэше по её имени
            if RemoteRealmPhotoService.shared.isImageCached(by: imageName) {
                print("Image with name \(imageName) is already cached. Skipping download.")
                continue
            }
            
            // Если нет, начинаем загрузку
            fetchImage(from: link) { image in
                if let downloadedImage = image {
                    print("Successfully downloaded image with name \(imageName).")
                    
                    // Сохраняем загруженное изображение в Realm
                    if let imageData = downloadedImage.pngData() {
                        RemoteRealmPhotoService.shared.saveImage(for: link, with: imageName, data: imageData)
                    }
                } else {
                    print("Failed to download image from \(link).")
                    AnalyticService.shared.logEvent(name: "Failed to download image", properties: ["url: ":"\(link)"])
                }
            }
        }
    }

    private func fetchImage(from urlString: String, completion: @escaping (UIImage?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Error downloading image: \(error?.localizedDescription ?? "unknown error")")
                AnalyticService.shared.logEvent(name: "Error downloading image", properties: ["error: ":"\(error?.localizedDescription ?? "unknown error")"])
                WebHookAnalyticsService.shared.sendAnalyticsReport(messageText: "Error downloading image: \(error?.localizedDescription ?? "unknown error")")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            let image = UIImage(data: data)
            
            DispatchQueue.main.async {
                completion(image)
            }
        }.resume()
    }
}
