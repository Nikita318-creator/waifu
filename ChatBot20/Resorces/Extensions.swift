import UIKit
import StoreKit
import AVFoundation

extension UIDevice {
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        return machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
    }
}

extension String {
    func localize() -> String {
        return NSLocalizedString(self, comment: "")
    }
    
    func localize(attribut: String, arguments: CVarArg...) -> String {
        let localizedString = NSLocalizedString(attribut, comment: "")
        return String(format: localizedString, arguments: arguments)
    }
}

extension SKProduct {
    func localizedPrice() -> String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = self.priceLocale
        return formatter.string(from: self.price)
    }
}

// UIColor extension for hex colors
extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}

extension Notification.Name {
    static let updateAllAudioCellsOnStart = Notification.Name("updateAllAudioCellsOnStart")
    static let updateAllAudioCellsOnFinish = Notification.Name("updateAllAudioCellsOnFinish")
    
    static let modUpdated = Notification.Name("modUpdated")
}

extension UIView {
    func isCurrentDeviceiPad() -> Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
}

// MARK: - CALayer Extension for Pause/Resume Animation
// Этот extension нужен для корректной паузы/возобновления анимаций слоев.
extension CALayer {
    func pauseAnimation() {
        let pausedTime: CFTimeInterval = convertTime(CACurrentMediaTime(), from: nil)
        speed = 0.0
        timeOffset = pausedTime
    }

    func resumeAnimation() {
        let pausedTime: CFTimeInterval = timeOffset
        speed = 1.0
        timeOffset = 0.0
        beginTime = 0.0
        let timeSincePause: CFTimeInterval = convertTime(CACurrentMediaTime(), from: nil) - pausedTime
        beginTime = timeSincePause
    }
}

extension UIImage {
    func saveToDocuments(withName name: String) -> String? {
        guard let data = self.jpegData(compressionQuality: 0.9) else { return nil }
        let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = "\(name).jpg"
        let fileURL = docsURL.appendingPathComponent(fileName)
        do {
            try data.write(to: fileURL)
            return fileName   // возвращаем только имя файла
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }
}

extension Data {
    func generateVideoThumbnail(at time: CMTime = CMTime(value: 60, timescale: 60)) -> UIImage? {
        let temporaryFileName = UUID().uuidString + ".mp4"
        let temporaryFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(temporaryFileName)

        do {
            try self.write(to: temporaryFileURL, options: .atomic)
        } catch {
            print("ERROR: Failed to write video data to temporary file: \(error)")
            return nil
        }

        let asset = AVAsset(url: temporaryFileURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        
        imageGenerator.maximumSize = CGSize(width: 300, height: 300)
        imageGenerator.appliesPreferredTrackTransform = true

        do {
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            let thumbnail = UIImage(cgImage: cgImage)
            
            try? FileManager.default.removeItem(at: temporaryFileURL)
            
            return thumbnail
            
        } catch {
            print("ERROR: Failed to generate thumbnail from video data: \(error.localizedDescription)")
            try? FileManager.default.removeItem(at: temporaryFileURL)
            return nil
        }
    }
}
