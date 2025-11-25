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
        guard let msgIndex = messages.firstIndex(where: { $0.id == message.id }) else { return }
    
        // --- ① どの選択肢を選んだか保存する ---
        messages[msgIndex].selectedIndex = index
    
        // --- ② ユーザーの選択肢を吹き出しとして表示 ---
        if let choices = msg.choices {
            ForEach(choices.indices, id: \.self) { i in
                
                let isSelected = (msg.selectedIndex == i)
                let isCorrect = (i == msg.answerIndex)
        
                Button(action: {
                    if msg.selectedIndex == nil { // 1回だけ選択可能
                        onSelectAnswer(i)
                    }
                }) {
                    Text(choices[i])
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            msg.selectedIndex == nil
                            ? Color.gray.opacity(0.3)
                            : (isCorrect ? Color.green.opacity(0.6)
                                         : (isSelected ? Color.red.opacity(0.6)
                                                       : Color.gray.opacity(0.3)))
                        )
                        .cornerRadius(10)
                        .foregroundColor(.black)
                }
                .disabled(msg.selectedIndex != nil)
            }
        }
    
        // --- ③ 正誤判定 ---
        let isCorrect = (index == message.answerIndex)
        let resultText = isCorrect ? "⭕ 正解！" : "❌ 不正解"
    
        // --- ④ AIの解説メッセージ ---
        let aiMessage = ChatMessage(
            text: "\(resultText)\n解説: \(message.explanation ?? "")",
            sender: .ai,
            choices: nil,
            answerIndex: nil,
            explanation: nil
        )
        messages.append(aiMessage)
}
}
