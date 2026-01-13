import Foundation

class WaifuSelectionManager {
    static let shared = WaifuSelectionManager()
    
    // Хранилище выборов: [questionId: [selectedOptions]]
    private var selections: [String: [String]] = [:]
    
    func saveSelection(questionId: String, options: [String]) {
        selections[questionId] = options
    }
    
    func getSelection(questionId: String) -> [String] {
        return selections[questionId] ?? []
    }
    
    func clearAll() {
        selections.removeAll()
    }
    
    func getFinalConfiguration() -> [String: Any] {
        // Формируем финальный JSON для отправки на сервер
        return [
            "waifu_config": selections,
            "timestamp": Date().timeIntervalSince1970,
            "completed": true
        ]
    }
    
    func isSlideComplete(questions: [WaifuQuestion]) -> Bool {
        // Проверяем, что на все вопросы слайда даны ответы
        return questions.allSatisfy { question in
            !getSelection(questionId: question.id).isEmpty
        }
    }
}
