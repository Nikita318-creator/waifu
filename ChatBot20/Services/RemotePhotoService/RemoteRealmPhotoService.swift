

import Foundation
import RealmSwift
import UIKit

class CachedImage: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var urlString: String = ""
    @Persisted var imageName: String = ""
    @Persisted var imageData: Data?
}

class RemoteRealmPhotoService {
    
    static let shared = RemoteRealmPhotoService()
    
    private let realm: Realm
    
    private init() {
        let config = Realm.Configuration(
            schemaVersion: SchemaVersion.currentSchemaVersion,
            migrationBlock: { migration, oldSchemaVersion in
             // Логика миграции
            }
        )
        
        do {
            self.realm = try Realm(configuration: config)
        } catch {
            let fallbackConfig = Realm.Configuration(inMemoryIdentifier: "PhotoServiceFallback")
            self.realm = try! Realm(configuration: fallbackConfig)
        }
    }
    
    /// Сохраняет изображение в базу данных
    func saveImage(for urlString: String, with imageName: String, data: Data) {
        let cachedImage = CachedImage()
        cachedImage.urlString = urlString
        cachedImage.imageName = imageName
        cachedImage.imageData = data
        
        do {
            try realm.write {
                realm.add(cachedImage)
            }
        } catch {
            print("Failed to save image to Realm: \(error.localizedDescription)")
        }
    }
    
    /// Получает изображение из базы данных по имени
    func getImage(by name: String) -> UIImage? {
        if let cachedImage = realm.objects(CachedImage.self).first(where: { $0.imageName == name }) {
            if let imageData = cachedImage.imageData {
                return UIImage(data: imageData)
            }
        }
        return nil
    }
    
    /// Получает все изображения из базы данных
    func getAllCachedImages() -> [CachedImage] {
        return Array(realm.objects(CachedImage.self))
    }
    
    /// Получает массив изображений из базы данных по части имени
    func getGroupImages(by name: String) -> [UIImage] {
        // 1. Используем Realm.objects для получения коллекции объектов.
        // 2. Используем .filter с NSPredicate для эффективного поиска по части имени
        //    Realm оптимизирует этот поиск, и он будет быстрее, чем фильтрация на Swift
        let cachedImages = realm.objects(CachedImage.self).filter("imageName CONTAINS %@", name)
        
        // 3. Создаем пустой массив для изображений
        var images: [UIImage] = []
        
        // 4. Проходимся по найденным объектам
        for cachedImage in cachedImages {
            if let imageData = cachedImage.imageData, let image = UIImage(data: imageData) {
                // 5. Преобразуем данные в UIImage и добавляем в массив
                images.append(image)
            }
        }
        
        // 6. Возвращаем итоговый массив
        return images
    }
    
    /// Проверяет, существует ли изображение в кэше по имени
    func isImageCached(by name: String) -> Bool {
        return realm.objects(CachedImage.self).first(where: { $0.imageName == name }) != nil
    }
}
