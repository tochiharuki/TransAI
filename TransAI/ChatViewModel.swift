import SwiftUI
import Combine

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""

    let api = APIService.shared   // ← 追加

    // ユーザー送信

    func sendUserQuestion(_ text: String) {
        // ① ユーザーメッセージをまず追加
        let userMessage = ChatMessage(text: text, sender: .user)
        messages.append(userMessage)
    
        // ② コンテキスト付きプロンプト生成
        let prompt = buildContextPrompt(userMessage: text)
    
        // ③ AI へ送信（通常回答モード）
        fetchAIResponse(prompt: prompt, expectsQuiz: false)
    }

    func fetchAIResponse(prompt: String, expectsQuiz: Bool) {

        api.fetchQuiz(prompt: prompt) { result in    // ← 修正 (send → fetchQuiz)
            DispatchQueue.main.async {
                switch result {
                case .success(let quiz):

                    if expectsQuiz {
                        // 問題として追加
                        self.messages.append(.init(
                            text: quiz.explanation ?? "(内容なし)",
                            sender: .ai
                        ))

                    } else {
                        // ユーザ質問 → 通常回答
                        self.messages.append(.init(
                            text: "回答:\n\(quiz.explanation ?? "")",
                            sender: .ai
                        ))
                    }

                case .failure(_):
                    self.messages.append(.init(
                        text: "エラーが発生しました。もう一度お試しください。",
                        sender: .ai
                    ))
                }
            }
        }
    }

    // JSON パース関数（必要なら残す）
    func parseQuizJSON(_ jsonString: String) -> QuizResponse? {
        let data = jsonString.data(using: .utf8)!
        return try? JSONDecoder().decode(QuizResponse.self, from: data)
    }


    func fetchQuiz() {
        let prompt = """
        基本情報技術者試験の4択問題を1問作成してください。
        出力形式はJSONで question / choices / answerIndex / explanation を返してください。
        """

        fetchAIResponse(prompt: prompt, expectsQuiz: true)
    }


    func selectAnswer(message: ChatMessage, index: Int) {
        guard let answerIndex = message.answerIndex else { return }

        // message の selectedIndex を更新
        if let i = messages.firstIndex(where: { $0.id == message.id }) {
            messages[i].selectedIndex = index
        }

        // ユーザー選択の表示
        let userChoiceMsg = ChatMessage(
            text: message.choices?[index] ?? "",
            sender: .user
        )
        messages.append(userChoiceMsg)

        // 正誤判定
        let isCorrect = (index == answerIndex)
        let result = isCorrect ? "⭕ 正解！" : "❌ 不正解"

        let aiMsg = ChatMessage(
            text: "\(result)\n解説: \(message.explanation ?? "")",
            sender: .ai
        )

        messages.append(aiMsg)
    }


    func buildContextPrompt(userMessage: String) -> String {
        guard let lastQuiz = messages.last(where: { $0.sender == .ai && $0.choices != nil }) else {
            return userMessage
        }

        let question = lastQuiz.text
        let choices = lastQuiz.choices?.joined(separator: " / ") ?? ""
        let explanation = lastQuiz.explanation ?? ""
        let answerIndex = lastQuiz.answerIndex ?? -1

        let userAnswer = messages.last(where: { $0.sender == .user })?.text ?? "未回答"

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
        上記を踏まえて、丁寧に回答してください。
        """
    }
}