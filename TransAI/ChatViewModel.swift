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
        guard let answerIndex = message.answerIndex, let choices = message.choices else { return }

        // 1. ユーザーの選択肢をメッセージとして追加
        let userChoiceMessage = ChatMessage(
            text: choices[index],
            sender: .user,
            choices: nil,
            answerIndex: nil,
            explanation: nil
        )
        messages.append(userChoiceMessage)

        // 2. 正誤 + 解説を AI メッセージとして追加
        let isCorrect = (index == answerIndex)
        let responseText = isCorrect ? "⭕ 正解！" : "❌ 不正解"
        let explanationText = message.explanation ?? ""

        let aiFeedback = ChatMessage(
            text: "\(responseText)\n解説: \(explanationText)",
            sender: .ai,
            choices: nil,
            answerIndex: nil,
            explanation: nil
        )
        messages.append(aiFeedback)
    }
}
