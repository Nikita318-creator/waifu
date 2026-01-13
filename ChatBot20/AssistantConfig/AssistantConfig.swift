import Foundation

struct AssistantConfig: Codable {
    var id: String?
    var assistantName: String = ""
    var expertise: Expertise = .roleplay // todo ПОМНИ тут храним ласт месаадж - просто я идиот и говно-костыле кодер
    var assistantInfo: String = ""
    var userInfo: String = ""
    var avatarImageName: String = "0"
}

enum Expertise: String, CaseIterable, Codable {
    case roleplay = "Roleplay.Hi"

    var image: String {
        return "Roleplay.Hi".localize()
    }
    
    static func convert(for expertiseString: String) -> Expertise {
        switch expertiseString {
        default:
            return .roleplay
        }
    }
}
