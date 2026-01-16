
import Foundation
import Vision
import UIKit

actor OCRDocumentService {
    static let shared = OCRDocumentService()
    
    // 画像データ配列を受け取り、解析結果（タイトルと日付）を返す
    func analyze(imageDataArray: [Data]) async -> (title: String, eventDate: Date?) {
        var allText = ""
        
        // すべてのページのテキストを結合して解析
        for data in imageDataArray {
            if let uiImage = UIImage(data: data), let cgImage = uiImage.cgImage {
                let text = await recognizeText(from: cgImage)
                allText += text + "\n"
            }
        }
        
        // タイトルの推定（最初の空でない行をタイトルとする簡易実装）
        let lines = allText.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        let title = lines.first ?? "新しいドキュメント"
        
        // 日付の推定
        let eventDate = detectDate(from: allText)
        
        return (title, eventDate)
    }
    
    private func recognizeText(from image: CGImage) async -> String {
        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }
                
                // 認識されたテキストを結合
                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                
                continuation.resume(returning: recognizedStrings.joined(separator: "\n"))
            }
            
            // 日本語と英語を認識
            request.recognitionLanguages = ["ja-JP", "en-US"]
            request.recognitionLevel = .accurate
            
            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                print("Failed to perform OCR: \(error)")
                continuation.resume(returning: "")
            }
        }
    }
    
    private func detectDate(from text: String) -> Date? {
        do {
            // NSDataDetectorを使用して日付を抽出
            let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
            let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
            
            // 最初に見つかった日付を返す（将来的には文脈から「行事日」「提出期限」を区別したい）
            // 未来の日付を優先するなどのロジックも検討可能
            return matches.first?.date
        } catch {
            print("Failed to detect date: \(error)")
            return nil
        }
    }
}
