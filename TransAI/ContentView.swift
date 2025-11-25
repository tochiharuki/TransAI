import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = QuizModel()

    var body: some View {
        VStack(spacing: 20) {

            if let quiz = viewModel.quiz {
                // 問題文
                Text(quiz.question)
                    .font(.title2)
                    .padding()
                    .background(Color(white: 0.95))
                    .cornerRadius(12)

                // 選択肢
                ForEach(0..<quiz.choices.count, id: \.self) { i in
                    Button(action: {
                        viewModel.selectAnswer(i)
                    }) {
                        Text(quiz.choices[i])
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(viewModel.buttonColor(for: i))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(viewModel.selectedIndex != nil) // 一度選んだら押せない
                }

                // 正解 / 不正解表示
                if let isCorrect = viewModel.isCorrect {
                    Text(isCorrect ? "⭕ 正解！" : "❌ 不正解")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(isCorrect ? .green : .red)
                        .padding(.top, 10)
                }

                // 解説表示
                if viewModel.showExplanation, let explanation = quiz.explanation {
                    Text("解説: \(explanation)")
                        .padding()
                        .background(Color(white: 0.95))
                        .cornerRadius(12)
                        .padding(.top, 5)
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
}

extension QuizModel {
    func buttonColor(for index: Int) -> Color {
        guard let selected = selectedIndex else { return Color.blue }
        if selected == index {
            return isCorrect ?? false ? .green : .red
        } else if index == quiz?.answerIndex {
            return .green
        }
        return Color.gray.opacity(0.3)
    }
}