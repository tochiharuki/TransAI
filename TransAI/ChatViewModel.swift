import SwiftUI
import Combine

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""

    // ユーザー送信
    func sendMessage(_ text: String) {
        let userMessage = ChatMessage(
            text: text,
            sender: .user,
            choices: nil,
            answerIndex: nil,
            explanation: nil
        )
        messages.append(userMessage)

        // AIに問い合わせ
        fetchAIResponse(prompt: text)
    }

    // privateを削除して外部からも呼べるように
    func fetchAIResponse(prompt: String) {
        APIService.shared.fetchQuiz(prompt: prompt) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let quiz):
                    let aiMessage = ChatMessage(
                        text: quiz.question,
                        sender: .ai,
                        choices: quiz.choices,
                        answerIndex: quiz.answerIndex,
                        explanation: quiz.explanation
                    )
                    self.messages.append(aiMessage)
                case .failure(let error):
                    let errorMessage = ChatMessage(
                        text: "エラー: \(error.localizedDescription)",
                        sender: .ai,
                        choices: nil,
                        answerIndex: nil,
                        explanation: nil
                    )
                    self.messages.append(errorMessage)
                }
            }
        }
    }

    func selectAnswer(message: ChatMessage, index: Int) {
        guard let answerIndex = message.answerIndex else { return }
    
        // 1. message の selectedIndex を更新
        if let i = messages.firstIndex(where: { $0.id == message.id }) {
            messages[i].selectedIndex = index
        }
    
        // 2. ユーザー選択を吹き出し表示
        let userChoiceMsg = ChatMessage(
            text: message.choices?[index] ?? "",
            sender: .user
        )
        messages.append(userChoiceMsg)
    
        // 3. 正誤 + 解説
        let isCorrect = (index == answerIndex)
        let result = isCorrect ? "⭕ 正解！" : "❌ 不正解"
    
        let aiMsg = ChatMessage(
            text: "\(result)\n解説: \(message.explanation ?? "")",
            sender: .ai
        )
    
        messages.append(aiMsg)
    }
}
