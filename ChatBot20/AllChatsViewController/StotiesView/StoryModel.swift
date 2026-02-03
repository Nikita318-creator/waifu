import Foundation

// MARK: - StoryModel

// Модель для данных одной сторис
struct StoryModel {
    let id: String // Уникальный идентификатор сторис
    let imageName: String // Имя изображения для кружка-аватарки сторис (из Assets.xcassets)
    var detailImageName: String // Имя изображения для полноэкранного просмотра сторис (из Assets.xcassets)
    let title: String // Заголовок/имя персонажа сторис
    var description: String // Текст, отображаемый на полноэкранной сторис
    var isViewed: Bool = false // Флаг, просмотрена ли сторис
}
