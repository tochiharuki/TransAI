import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = QuizModel()

    var body: some View {
        VStack(spacing: 20) {

            if let quiz = viewModel.quiz {
                Text(quiz.question)
                    .font(.title2)
                    .padding()

                ForEach(0..<quiz.choices.count, id: \.self) { i in
                    Button(action: {
                        viewModel.selectAnswer(i)
                    }) {
                        Text(quiz.choices[i])
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(buttonColor(for: i))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }

                if let isCorrect = viewModel.isCorrect {
                    Text(isCorrect ? "⭕ 正解！" : "❌ 不正解")
                        .font(.title)
                        .padding()
                }
            }

            Button("新しい問題を取得") {
                viewModel.loadNewQuiz()
            }
            .padding()
        }
        .padding()
        .onAppear {
            viewModel.loadNewQuiz()
        }
    }

    private func buttonColor(for index: Int) -> Color {
        if let selected = viewModel.selectedIndex {
            if selected == index {
                return viewModel.isCorrect ?? false ? .green : .red
            }
        }
        return .blue
    }
}
