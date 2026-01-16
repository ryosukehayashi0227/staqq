
import Foundation
import Vision
import UIKit

actor OCRDocumentService {
    static let shared = OCRDocumentService()
    
    // 画像データ配列を受け取り、解析結果（タイトルと日付と全文）を返す
    func analyze(imageDataArray: [Data]) async -> (title: String, eventDate: Date?, allText: String) {
        var allText = ""
        var candidates: [(text: String, height: CGFloat)] = []
        
        for data in imageDataArray {
            if let uiImage = UIImage(data: data), let cgImage = uiImage.cgImage {
                let pageResults = await recognizeText(from: cgImage)
                candidates.append(contentsOf: pageResults)
                
                let pageText = pageResults.map { $0.text }.joined(separator: "\n")
                allText += pageText + "\n"
            }
        }
        
        // タイトル推定: 文字の高さが大きい順にソートし、適切な候補を選ぶ
        // VisionのboundingBox.heightは画像の高さに対する相対値
        let sortedCandidates = candidates.sorted { $0.height > $1.height }
        
        // 最初の候補（最も大きい文字）をタイトルとして採用するが、条件フィルタリングを行う
        let titleCandidate = sortedCandidates.first { candidate in
            let text = candidate.text.trimmingCharacters(in: .whitespacesAndNewlines)
            // 除外条件: 空文字、または2文字以下（短すぎる）
            if text.isEmpty || text.count <= 2 { return false }
            
            // 除外条件: 数字と記号のみの行（日付や電話番号などを誤検知しないようにする）
            let letterSet = CharacterSet.letters.union(.init(charactersIn: "ぁ-んァ-ン一-龯")) // 平仮名カタカナ漢字
            return text.rangeOfCharacter(from: letterSet) != nil
        }
        
        let title = titleCandidate?.text ?? "新しいドキュメント"
        
        // 日付の推定
        let eventDate = detectDate(from: allText)
        
        return (title, eventDate, allText)
    }
    
    private func recognizeText(from image: CGImage) async -> [(text: String, height: CGFloat)] {
        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                // 認識されたテキストと高さを抽出
                let results = observations.compactMap { observation -> (String, CGFloat)? in
                    guard let candidate = observation.topCandidates(1).first else { return nil }
                    return (candidate.string, observation.boundingBox.height)
                }
                
                continuation.resume(returning: results)
            }
            
            // 日本語と英語を認識するように設定
            request.recognitionLanguages = ["ja-JP", "en-US"]
            // 精度優先モード（処理時間はかかるが認識率が高い）
            request.recognitionLevel = .accurate
            
            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                print("Failed to perform OCR: \(error)")
                continuation.resume(returning: [])
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
