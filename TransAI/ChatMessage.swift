import Foundation

struct ChatMessage: Identifiable, Hashable {
    let id = UUID()
    var text: String
    var sender: Sender

    // 選択肢クイズ用
    var choices: [String]?          // AI が出す選択肢
    var answerIndex: Int?           // 正解の番号
    var explanation: String?        // 解説
    var selectedIndex: Int?         // ユーザーが選んだ選択肢（UIで色付け用）

    enum Sender {
        case user
        case ai
    }
}