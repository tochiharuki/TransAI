import Foundation
import CoreML

class ModelManager {
    static let shared = ModelManager()
    var model: MLModel?

    private init() {}

    func downloadAndLoadModel(from urlString: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }

        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let zipURL = documents.appendingPathComponent("open_calm_1b_8bit.mlmodelc.zip")
        let unzipDir = documents.appendingPathComponent("open_calm_1b_8bit.mlmodelc")

        try? FileManager.default.removeItem(at: zipURL)
        try? FileManager.default.removeItem(at: unzipDir)

        URLSession.shared.downloadTask(with: url) { tempURL, _, error in
            guard let tempURL = tempURL, error == nil else {
                print("❌ ダウンロード失敗:", error?.localizedDescription ?? "不明なエラー")
                completion(false)
                return
            }

            do {
                try FileManager.default.moveItem(at: tempURL, to: zipURL)
                try self.unzipFile(at: zipURL, to: documents)
                self.loadModelAsync(from: unzipDir) { loadedModel in
                    self.model = loadedModel
                    completion(loadedModel != nil)
                }
            } catch {
                print("❌ 展開または読み込み失敗:", error)
                completion(false)
            }
        }.resume()
    }

    func unzipFile(at sourceURL: URL, to destinationURL: URL) throws {
        let archive = try Archive(url: sourceURL, accessMode: .read)
        for entry in archive {
            let destinationPath = destinationURL.appendingPathComponent(entry.path)
            _ = try archive.extract(entry, to: destinationPath)
        }
    }

    func loadModelAsync(from packageURL: URL, completion: @escaping (MLModel?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let model = try MLModel(contentsOf: packageURL)
                DispatchQueue.main.async { completion(model) }
            } catch {
                print("❌ モデル読み込み失敗:", error)
                DispatchQueue.main.async { completion(nil) }
            }
        }
    }

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