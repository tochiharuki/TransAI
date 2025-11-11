import SwiftUI
import CoreML

struct ContentView: View {
    @State private var isModelLoaded = false
    @State private var isLoading = false
    @State private var outputText = "出力なし"

    var body: some View {
        VStack(spacing: 20) {
            Button(isLoading ? "読み込み中..." : "モデル読み込み") {
                guard !isLoading else { return }
                isLoading = true
                ModelManager.shared.downloadAndLoadModel(
                    from: "https://www.dropbox.com/scl/fi/2lszs52ce5mzjrm1t94t6/open_calm_1b_8bit.mlmodelc.zip?rlkey=zo4rnuywouw1p814kulozz439&st=p3qji3eo&dl=1"
                ) { success in
                    DispatchQueue.main.async {
                        isModelLoaded = success
                        isLoading = false
                        outputText = success ? "✅ モデル読み込み完了" : "❌ モデル読み込み失敗"
                    }
                }
            }

            Button("推論テスト") {
                guard isModelLoaded else {
                    outputText = "⚠️ モデル未ロード"
                    return
                }

                outputText = "推論中..."
                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        let prompt = "こんにちは"
                        let inputArray = try prompt.toMLMultiArray()
                        if let result = ModelManager.shared.predict(inputArray: inputArray) {
                            DispatchQueue.main.async {
                                outputText = "✅ 推論成功: \(result)"
                            }
                        } else {
                            DispatchQueue.main.async {
                                outputText = "❌ 推論失敗"
                            }
                        }
                    } catch {
                        DispatchQueue.main.async {
                            outputText = "❌ 配列変換失敗: \(error)"
                        }
                    }
                }
            }

            Text(outputText)
                .padding()
        }
        .padding()
    }
}

extension String {
    func toMLMultiArray() throws -> MLMultiArray {
        let array = try MLMultiArray(shape: [1, NSNumber(value: self.count)], dataType: .double)
        for (i, char) in self.enumerated() {
            array[i] = NSNumber(value: Double(char.asciiValue ?? 0))
        }
        return array
    }
}

#Preview {
    ContentView()
}