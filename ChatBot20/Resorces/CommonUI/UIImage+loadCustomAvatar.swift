import UIKit

extension UIImage {
    /// Загружает изображение по имени. Сначала ищет в Assets, затем в Documents Directory.
    /// - Parameter imageName: Имя изображения (например, "CustomAvatar1" для ассета или "UUID.jpg" для файла).
    /// - Returns: UIImage, если изображение найдено, иначе nil.
    static func loadCustomAvatar(for imageName: String) -> UIImage? {
        // 1. Пробуем загрузить из Assets (для дефолтных аватаров)
        if let image = UIImage(named: imageName) {
            return image
        }
        
        // 2. Если не найдено в Assets, пробуем загрузить из Documents (для пользовательских аватаров)
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        // Правильное формирование URL к файлу в Documents Directory
        let fileURL = documentsDirectory.appendingPathComponent(imageName)
        
        do {
            let data = try Data(contentsOf: fileURL)
            return UIImage(data: data)
        } catch {
            // Выводим ошибку для отладки, но не прерываем работу приложения
            print("Error loading image from documents directory at \(fileURL.lastPathComponent): \(error)")
            return nil
        }
    }
}
