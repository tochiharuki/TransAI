import SwiftUI
import Combine

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""

    // ユーザー送信
    func sendMessage(_ text: String) {
        let userMessage = ChatMessage(
            text: text,
            sender: .user
        )
        messages.append(userMessage)
    
        // コンテキスト込みのプロンプト生成
        let prompt = buildContextPrompt(userMessage: text)
    
        fetchAIResponse(prompt: prompt)
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
    
    func buildContextPrompt(userMessage: String) -> String {
        // 直近の問題（AI の最後の問題メッセージ）を取得
        guard let lastQuiz = messages.last(where: { $0.sender == .ai && $0.choices != nil }) else {
            return userMessage   // 問題がまだ無い場合はそのまま
        }
    
        let question = lastQuiz.text
        let choices = lastQuiz.choices?.joined(separator: " / ") ?? ""
        let explanation = lastQuiz.explanation ?? ""
        let answerIndex = lastQuiz.answerIndex ?? -1
    
        // ユーザー回答
        let userAnswer = messages.first(where: {
            $0.sender == .user && $0.text == (lastQuiz.choices?[lastQuiz.selectedIndex ?? -1] ?? "")
        })?.text ?? "未回答"
    
        return """
    【直近の問題】
    問題文: \(question)
    選択肢: \(choices)
    ユーザーの回答: \(userAnswer)
    正解番号: \(answerIndex)
    解説: \(explanation)
    
    【ユーザーからの質問】
    \(userMessage)
    
    【指示】
    上記の問題内容とユーザーの回答状況を踏まえて、わかりやすく回答してください。
    """
    }
}
