import Foundation
import CoreML

class ModelManager {
    static let shared = ModelManager()
    var model: MLModel?  // 推論用に外からも参照できるように var に変更

    private init() {}

    // Dropbox からダウンロードしてコンパイルして読み込む
    func downloadAndLoadModel(from urlString: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }

        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destination = documents.appendingPathComponent("open_calm_1b_8bit.mlpackage")

        if FileManager.default.fileExists(atPath: destination.path) {
            // ここで loadModelAsync を呼ぶ
            loadModelAsync(from: destination) { loadedModel in
                self.model = loadedModel
                completion(loadedModel != nil)
            }
            return
        }

        URLSession.shared.downloadTask(with: url) { tempURL, _, error in
            guard let tempURL = tempURL, error == nil else {
                completion(false)
                return
            }

            do {
                if FileManager.default.fileExists(atPath: destination.path) {
                    try FileManager.default.removeItem(at: destination)
                }
                try FileManager.default.moveItem(at: tempURL, to: destination)

                self.loadModelAsync(from: destination) { loadedModel in
                    self.model = loadedModel
                    completion(loadedModel != nil)
                }

            } catch {
                print("❌ ファイル移動失敗:", error)
                completion(false)
            }
        }.resume()
    }

    // 非同期でコンパイル・ロード
    func loadModelAsync(from packageURL: URL, completion: @escaping (MLModel?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let compiledURL = try MLModel.compileModel(at: packageURL)
                let loadedModel = try MLModel(contentsOf: compiledURL)
                DispatchQueue.main.async {
                    completion(loadedModel)
                }
            } catch {
                print("❌ モデル読み込み失敗:", error)
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }

    // MLMultiArray 入力で推論
    func predict(inputArray: MLMultiArray) -> MLMultiArray? {
        guard let model = model else {
            print("⚠️ モデル未ロード")
            return nil
        }

        do {
            let input = try MLDictionaryFeatureProvider(dictionary: ["input_ids": inputArray])
            let output = try model.prediction(from: input)
            return output.featureValue(for: "logits")?.multiArrayValue
        } catch {
            print("❌ 推論失敗:", error)
            return nil
        }
    }
}
