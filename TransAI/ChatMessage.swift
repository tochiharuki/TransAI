import Foundation

enum Sender {
    case user
    case ai
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let sender: Sender
    let choices: [String]? // 選択肢がある場合
    let answerIndex: Int?  // 正解インデックス
    let explanation: String? // 解説
    var selectedIndex: Int? = nil
}
