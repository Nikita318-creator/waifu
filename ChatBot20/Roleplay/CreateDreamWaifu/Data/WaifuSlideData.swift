import Foundation

struct WaifuSlideData {
    let title: String
    let marketingText: String
    let imageName: String
    let questions: [WaifuQuestion]
}

struct WaifuQuestion {
    let id: String // Уникальный ID для сохранения выбора
    let title: String
    let options: [String] // Массив опций для выбора
    let allowMultipleSelection: Bool // Можно ли выбрать несколько
}
