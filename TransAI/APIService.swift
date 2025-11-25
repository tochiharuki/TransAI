import Foundation

struct QuizResponse: Codable {
    let question: String
    let choices: [String]
    let answerIndex: Int
    let explanation: String?
}

class APIService {
    static let shared = APIService()
    private let baseURL = "https://deepseek-api-server.onrender.com/ask"

    // 任意のメッセージを送れるように変更
    func fetchQuiz(prompt: String, completion: @escaping (Result<QuizResponse, Error>) -> Void) {
        guard let url = URL(string: baseURL) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["message": prompt]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        // タイムアウト延長
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 180    // リクエスト送信待ち最大時間（秒）
        config.timeoutIntervalForResource = 180   // レスポンス全体を待つ最大時間（秒）
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
