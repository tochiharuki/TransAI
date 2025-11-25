import Foundation

class QuizModel: ObservableObject {
    @Published var quiz: QuizResponse?
    @Published var selectedIndex: Int? = nil
    @Published var isCorrect: Bool? = nil

    func loadNewQuiz() {
        APIService.shared.fetchQuiz { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let quiz):
                    self.quiz = quiz
                    self.selectedIndex = nil
                    self.isCorrect = nil
                case .failure(let error):
                    print("API Error:", error)
                }
            }
        }
    }

    func selectAnswer(_ index: Int) {
        selectedIndex = index
        isCorrect = (index == quiz?.answerIndex)
    }
}
