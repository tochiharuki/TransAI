import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()

    var body: some View {
        VStack {
            ScrollViewReader { scrollView in
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(viewModel.messages) { msg in
                            ChatMessageView(msg: msg) { index in
                                viewModel.selectAnswer(message: msg, index: index)
                            }
                        }
                    }
                    .padding()
                }
                .background(Color.white)
                .onChange(of: viewModel.messages.count) { _ in
                    withAnimation { scrollView.scrollTo(viewModel.messages.last?.id) }
                }
                .onAppear {
                    viewModel.fetchAIResponse(prompt: "基本情報技術者試験の4択問題を1問作成してください。出力形式はJSONで question / choices / answerIndex / explanation を返してください。")
                }
            }

            HStack {
                TextField("メッセージを入力", text: $viewModel.inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("送信") {
                    let text = viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !text.isEmpty else { return }
                    viewModel.sendMessage(text)
                    viewModel.inputText = ""
                }
            }
            .padding()
        }
    }
}

struct ChatMessageView: View {
    let msg: ChatMessage
    let onSelectAnswer: (Int) -> Void

    var body: some View {
        let triangleWidth: CGFloat = 12

        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if msg.sender == .user { Spacer() }
            
                Text(msg.text)
                    .padding(12)
                    .padding(.leading, msg.sender == .ai ? 14 : 0)
                    .padding(.trailing, msg.sender == .user ? 14 : 0)
                    .foregroundColor(msg.sender == .user ? .white : .black)
                    .background(
                        SpeechBubble(isUser: msg.sender == .user)
                            .fill(msg.sender == .user ? Color.blue : Color.gray.opacity(0.2))
                    )
                    .frame(maxWidth: 250, alignment: msg.sender == .user ? .trailing : .leading)
            
                if msg.sender == .ai { Spacer() }
            }

            if let choices = msg.choices {
                ForEach(choices.indices, id: \.self) { i in
                    Button(action: { onSelectAnswer(i) }) {
                        Text(choices[i])
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(10)
                    }
                }
            }
        }
    }
}
