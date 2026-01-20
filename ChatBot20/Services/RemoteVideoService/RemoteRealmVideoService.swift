import Foundation
import RealmSwift
import UIKit

class CachedVideo: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var urlString: String
    @Persisted var videoName: String
    @Persisted var videoData: Data
    @Persisted var thumbnailData: Data?
}

class RemoteRealmVideoService {
    static let shared = RemoteRealmVideoService()
    private let realm: Realm
    
    private init() {
        let config = Realm.Configuration(
            schemaVersion: SchemaVersion.currentSchemaVersion
        )

        do {
            self.realm = try Realm(configuration: config)
        } catch {
            let fallbackConfig = Realm.Configuration(inMemoryIdentifier: "CachedVideoFallbackRealm")
            self.realm = try! Realm(configuration: fallbackConfig)
        }
    }
    
    // MARK: - Save
    func saveVideo(urlString: String, name: String, data: Data) {
        
        let thumbnailImage = data.generateVideoThumbnail()
        let thumbnailData = thumbnailImage?.jpegData(compressionQuality: 0.8)
        
        let video = CachedVideo()
        video.urlString = urlString
        video.videoName = name
        video.videoData = data
        video.thumbnailData = thumbnailData
        
        do {
            try realm.write {
                realm.add(video, update: .modified)
            }
        } catch {
            print("❌ Ошибка сохранения видео в Realm: \(error)")
        }
    }
    
    // MARK: - Read (ОБНОВЛЕНО)
    
    func getThumbnailData(name: String) -> Data? {
        return realm.objects(CachedVideo.self)
            .filter("videoName == %@", name)
            .first?
            .thumbnailData
    }
    
    func isVideoCached(name: String) -> Bool {
        realm.objects(CachedVideo.self)
            .filter("videoName == %@", name)
            .first != nil
    }
    
    func getVideoData(name: String) -> Data? {
        realm.objects(CachedVideo.self)
            .filter("videoName == %@", name)
            .first?
            .videoData
    }
    
    func getAllVideos() -> [CachedVideo] {
        Array(realm.objects(CachedVideo.self))
    }
}
