import Foundation
import CoreML
import Compression

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

        // 古いファイル削除
        try? FileManager.default.removeItem(at: zipURL)
        try? FileManager.default.removeItem(at: unzipDir)

        // ダウンロード開始
        URLSession.shared.downloadTask(with: url) { tempURL, _, error in
            guard let tempURL = tempURL, error == nil else {
                print("❌ ダウンロード失敗:", error?.localizedDescription ?? "不明なエラー")
                completion(false)
                return
            }

            do {
                try FileManager.default.moveItem(at: tempURL, to: zipURL)
                try self.unzipSingleFile(from: zipURL, to: unzipDir)
                print("✅ ZIP展開完了: \(unzipDir.lastPathComponent)")

                // モデルロード
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

    /// 単一ファイルZIP用の軽量展開処理
    private func unzipSingleFile(from zipURL: URL, to destinationURL: URL) throws {
        let data = try Data(contentsOf: zipURL)

        var dst = Data()
        try data.withUnsafeBytes { (srcPtr: UnsafeRawBufferPointer) in
            guard let base = srcPtr.bindMemory(to: UInt8.self).baseAddress else { return }

            let bufferSize = 64_000
            let dstBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            defer { dstBuffer.deallocate() }

            var stream = compression_stream()
            var status = compression_stream_init(&stream, COMPRESSION_STREAM_DECODE, COMPRESSION_ZLIB)
            guard status != COMPRESSION_STATUS_ERROR else {
                throw NSError(domain: "CompressionError", code: -1)
            }
            defer { compression_stream_destroy(&stream) }

            stream.src_ptr = base
            stream.src_size = data.count
            stream.dst_ptr = dstBuffer
            stream.dst_size = bufferSize

            repeat {
                status = compression_stream_process(&stream, 0)
                let count = bufferSize - stream.dst_size
                if count > 0 {
                    dst.append(dstBuffer, count: count)
                }
                stream.dst_ptr = dstBuffer
                stream.dst_size = bufferSize
            } while status == COMPRESSION_STATUS_OK
        }

        try dst.write(to: destinationURL)
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