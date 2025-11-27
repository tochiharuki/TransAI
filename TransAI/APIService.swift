// APIService.swift
import Foundation

struct QuizResponse: Codable {
    let title: String
    let question: String
    let choices: [String]
    let answerIndex: Int
    let explanation: String?
}

class APIService {
    static let shared = APIService()
    private let baseURL = "https://deepseek-api-server.onrender.com/ask"

    // ---- quiz を取得する（QuizResponse を期待）
    func fetchQuiz(prompt: String, completion: @escaping (Result<QuizResponse, Error>) -> Void) {
        guard let url = URL(string: baseURL) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0)))
            return
        }
    
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
        let body: [String: Any] = ["message": prompt]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
    
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 180
        config.timeoutIntervalForResource = 180
    
        let session = URLSession(configuration: config)
    
        session.dataTask(with: request) { data, response, error in
    
            // ネットワークエラー
            if let e = error {
                completion(.failure(e))
                return
            }
    
            guard let d = data else {
                completion(.failure(NSError(domain: "No data", code: 0)))
                return
            }
    
            do {
                // --- ① JSON としてパースを試す ---
                let quiz = try JSONDecoder().decode(QuizResponse.self, from: d)
                completion(.success(quiz))
                return
    
            } catch {
                // --- ② JSON でない → DeepSeek 初回レスポンスの可能性 ---
                if let text = String(data: d, encoding: .utf8) {
                    print("⚠️ DeepSeek 初回レスポンスが JSON ではありません:\n\(text)")
                }
    
                // JSON 不正として返す（ChatViewModel 側で再取得）
                let err = NSError(
                    domain: "QuizDecodeError",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "初回応答が JSON 形式ではありません"]
                )
                completion(.failure(err))
                return
            }
    
        }.resume()
    }

    // ---- 通常のテキスト応答を取る（サーバが { "answer": "..." } を返す場合）
    func sendMessage(prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: baseURL) else { completion(.failure(NSError(domain: "Invalid URL", code: 0))); return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["message": prompt]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 180
        config.timeoutIntervalForResource = 180
        let session = URLSession(configuration: config)
        session.dataTask(with: request) { data, response, error in
            if let e = error { completion(.failure(e)); return }
            guard let d = data else { completion(.failure(NSError(domain: "No data", code: 0))); return }
            do {
                if let json = try JSONSerialization.jsonObject(with: d) as? [String: Any],
                   let answer = json["answer"] as? String {
                    completion(.success(answer))
                } else {
                    // もしサーバが quiz JSON を返してしまった場合は quiz を文字列化して返す
                    if let txt = String(data: d, encoding: .utf8) {
                        completion(.success(txt))
                    } else {
                        completion(.failure(NSError(domain: "Invalid response", code: 0)))
                    }
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}