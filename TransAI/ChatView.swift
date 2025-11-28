import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()   // ← アプリ全体を白背景にする

            VStack {
                ScrollViewReader { scrollView in
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(viewModel.messages) { msg in
                                ChatMessageView(msg: msg) { index in
                                    viewModel.selectAnswer(message: msg, index: index)
                                }
                                .id(msg.id)   // ← ここに移動！
                            }
                            
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        // 新規メッセージ追加時に最下部へ
                        if let lastID = viewModel.messages.last?.id {
                            withAnimation(.easeOut(duration: 0.25)) {
                                scrollView.scrollTo(lastID, anchor: .bottom)
                            }
                        }
                    }

                    .onAppear {
                    viewModel.fetchAIResponse(
                        prompt: """
基本情報技術者試験の4択問題を1問作成してください。

必ず次の形式のJSONで返してください：
{
  "title": "問題を短く表すタイトル（10〜30文字）",
  "question": "問題文全文",
  "choices": ["A", "B", "C", "D"],
  "answerIndex": 数値,
  "explanation": "解説文"
}
""",
                        expectsQuiz: true
                    )


                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            if let lastID = viewModel.messages.last?.id {
                                withAnimation {
                                    scrollView.scrollTo(lastID, anchor: .bottom)
                                }
                            }
                        }

                    }
                }
                
                

                HStack(spacing: 8) {

                    // ▼ テキスト入力
                    TextField("メッセージを入力…", text: $viewModel.inputText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(minHeight: 36)
                        .colorScheme(.light)
                
                    // ▼ 送信ボタン
                  
                    Button(action: {
                        let text = viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !text.isEmpty else { return }
                    
                        viewModel.sendUserQuestion(text)   // ← ここを変更！
                    
                        viewModel.inputText = ""
                    }) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 18))
                    }
                
                    // ▼ Next（次の問題）ボタン — 右端
                    Button(action: {
                        viewModel.fetchQuiz()
                    }) {
                        Text("次の問題")
                            .font(.system(size: 12))
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(Color.blue.opacity(0.9))
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
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
        }
    }
}
