import Foundation

struct QuizResponse: Codable {
    let question: String
    let choices: [String]
    let answerIndex: Int
    let explanation: String?  // 解説用
}

class APIService {
    static let shared = APIService()

    private let baseURL = "https://deepseek-api-server.onrender.com/ask"

    func fetchQuiz(completion: @escaping (Result<QuizResponse, Error>) -> Void) {
        guard let url = URL(string: baseURL) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // DeepSeekに送るプロンプト
        let body: [String: Any] = [
            "message": """
            基本情報技術者試験の4択問題を1問だけ作成してください。
            出力形式はJSON形式で、次のキーを返してください:
            {
                "question": "問題文",
                "choices": ["選択肢1", "選択肢2", "選択肢3", "選択肢4"],
                "answerIndex": 0〜3の数字（正解のインデックス）,
                "explanation": "解説文"
            }
            絶対にJSONのみ返してください。
            """
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

        // タイムアウトを延長
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 120
        let session = URLSession(configuration: config)

        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: 0)))
                return
            }

            do {
                let quiz = try JSONDecoder().decode(QuizResponse.self, from: data)
                completion(.success(quiz))
            } catch {
                print("Decoding error:", error)
                print("Raw:", String(data: data, encoding: .utf8) ?? "")
                completion(.failure(error))
            }
        }.resume()
    }
}



