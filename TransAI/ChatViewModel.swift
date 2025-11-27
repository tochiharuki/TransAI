// ChatViewModel.swift
import Foundation
import Combine

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var usedQuestions: Set<String> = []
    
    var avoidList: String {
        usedQuestions.joined(separator: "\n")
    }

    let api = APIService.shared

    // ユーザが「質問」を送るとき（通常の Q&A）
    func sendUserQuestion(_ text: String) {
        let userMessage = ChatMessage(text: text, sender: .user)
        messages.append(userMessage)

        let prompt = buildContextPrompt(userMessage: text)
        fetchAIResponse(prompt: prompt, expectsQuiz: false)
    }

    // 次の問題を明示的に取得するとき
    func fetchQuiz() {
        let avoidText = avoidList.isEmpty ? "なし" : avoidList

        let payload: [String: Any] = [
            "prompt": [
                "numQuestions": 1,
                "avoid": avoidText
            ]
        ]
    
        let prompt = """
基本情報技術者試験の4択問題を1問作成してください。

必ず次の形式のJSONで返してください：
{
  "title": "問題を短く表すタイトル（10〜30文字）",
  "question": "問題文全文",
  "choices": ["A", "B", "C", "D"],
  "answerIndex": 数値,
  "explanation": "解説文"
}

ただし、以下のタイトルと重複する問題は絶対に出題しないでください：
\(avoidList)
"""
    
        fetchAIResponse(prompt: prompt, expectsQuiz: true)
    }

    // 中心処理: expectsQuiz によって呼び分け
    func fetchAIResponse(prompt: String, expectsQuiz: Bool) {
        if expectsQuiz {
            api.fetchQuiz(prompt: prompt) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let quiz):
                        let title = quiz.title
                        self.usedQuestions.insert(title)
                        // ここで「問題」を UI に追加（問題文 + 選択肢）
                        let qMsg = ChatMessage(
                            text: quiz.question,
                            sender: .ai,
                            choices: quiz.choices,
                            answerIndex: quiz.answerIndex,
                            explanation: quiz.explanation
                        )
                        self.messages.append(qMsg)
                    case .failure(let err):
                        // quiz 取得失敗時はエラーメッセージ（選択肢なし）
                        let errMsg = ChatMessage(text: "問題を取得できませんでした: \(err.localizedDescription)", sender: .ai)
                        self.messages.append(errMsg)
                    }
                }
            }
        } else {
            // 通常のテキスト回答を期待する場合
            api.sendMessage(prompt: prompt) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let answerText):
                        let reply = ChatMessage(text: answerText, sender: .ai)
                        self.messages.append(reply)
                    case .failure(let err):
                        let errMsg = ChatMessage(text: "エラーが発生しました。もう一度お試しください。", sender: .ai)
                        self.messages.append(errMsg)
                    }
                }
            }
        }
    }

    // ユーザが選択肢を選んだときの処理（既存ロジックを踏襲）
    func selectAnswer(message: ChatMessage, index: Int) {
        guard let answerIndex = message.answerIndex else { return }

        if let i = messages.firstIndex(where: { $0.id == message.id }) {
            messages[i].selectedIndex = index
        }

        let userChoiceMsg = ChatMessage(text: message.choices?[index] ?? "", sender: .user)
        messages.append(userChoiceMsg)

        let isCorrect = (index == answerIndex)
        let result = isCorrect ? "⭕ 正解！" : "❌ 不正解"

        let aiMsg = ChatMessage(text: "\(result)\n解説: \(message.explanation ?? "")", sender: .ai)
        messages.append(aiMsg)
    }

    // 直近の問題コンテキストを作る（簡易版）
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
        上記を踏まえて、簡潔にかつ正確に回答してください。
        """
    }
}