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
    
    private let config: Realm.Configuration
    
    private var realm: Realm {
        return try! Realm(configuration: config)
    }
    
    private init() {
        let mainConfig = Realm.Configuration(
            schemaVersion: SchemaVersion.currentSchemaVersion,
            migrationBlock: { migration, oldSchemaVersion in
                // Логика миграции
            }
        )
        
        do {
            _ = try Realm(configuration: mainConfig)
            self.config = mainConfig
        } catch {
            self.config = Realm.Configuration(inMemoryIdentifier: "PhotoServiceFallback")
        }
    }
    
    /// Сохраняет изображение в базу данных (теперь полностью в фоне)
    func saveImage(for urlString: String, with imageName: String, data: Data) {
        let currentConfig = self.config
        
        DispatchQueue.global(qos: .userInitiated).async {
            let cachedImage = CachedImage()
            cachedImage.urlString = urlString
            cachedImage.imageName = imageName
            cachedImage.imageData = data
            
            do {
                let backgroundRealm = try Realm(configuration: currentConfig)
                try backgroundRealm.write {
                    backgroundRealm.add(cachedImage, update: .modified)
                }
            } catch {
                print("Failed to save image to Realm: \(error.localizedDescription)")
            }
        }
    }
    
    /// Получает изображение из базы данных по имени (безопасно для потоков)
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
        let cachedImages = realm.objects(CachedImage.self).filter("imageName CONTAINS %@", name)
        
        var images: [UIImage] = []
        for cachedImage in cachedImages {
            if let imageData = cachedImage.imageData, let image = UIImage(data: imageData) {
                images.append(image)
            }
        }
        return images
    }
    
    /// Проверяет, существует ли изображение в кэше по имени (безопасно для потоков)
    func isImageCached(by name: String) -> Bool {
        return realm.objects(CachedImage.self).first(where: { $0.imageName == name }) != nil
    }
}
