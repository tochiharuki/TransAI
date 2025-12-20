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
    private let baseURL = "https://harukitech.site/ask"

    // ---- quiz を取得する（QuizResponse を期待）
    func fetchQuiz(prompt: String, completion: @escaping (Result<QuizResponse, Error>) -> Void) {
        guard let url = URL(string: baseURL) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0)))
            return
        }
    
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
        let body: [String: Any] = [
            "message": prompt,
            "mode": "quiz"
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
    
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let e = error { completion(.failure(e)); return }
            guard let d = data else {
                completion(.failure(NSError(domain: "No data", code: 0)))
                return
            }
    
            do {
                let quiz = try JSONDecoder().decode(QuizResponse.self, from: d)
                completion(.success(quiz))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    // ---- 通常のテキスト応答を取る（サーバが { "answer": "..." } を返す場合）
    func sendMessage(prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: baseURL) else { completion(.failure(NSError(domain: "Invalid URL", code: 0))); return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "message": prompt,
            "mode": "chat"
        ]
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