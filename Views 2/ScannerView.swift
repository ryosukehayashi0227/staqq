
import SwiftUI
import VisionKit
import SwiftData

struct ScannerView: UIViewControllerRepresentable {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // シミュレータかどうかを判定
    private var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        if isSimulator {
            // シミュレータの場合はダミーのビューコントローラーを返す
            let controller = UIViewController()
            let button = UIButton(type: .system)
            button.setTitle("シミュレータ用ダミー画像生成", for: .normal)
            button.addTarget(context.coordinator, action: #selector(Coordinator.simulateScan), for: .touchUpInside)
            button.frame = CGRect(x: 0, y: 0, width: 300, height: 50)
            button.center = controller.view.center
            controller.view.addSubview(button)
            controller.view.backgroundColor = .white
            return controller
        } else {
            let scannerViewController = VNDocumentCameraViewController()
            scannerViewController.delegate = context.coordinator
            return scannerViewController
        }
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: ScannerView
        
        init(parent: ScannerView) {
            self.parent = parent
        }
        
        @objc func simulateScan() {
            // ダミー画像を作成（グラデーションなど）
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: 600, height: 800))
            let image = renderer.image { ctx in
                UIColor.systemGray6.setFill()
                ctx.fill(CGRect(x: 0, y: 0, width: 600, height: 800))
                
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .center
                
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 32, weight: .bold),
                    .foregroundColor: UIColor.black,
                    .paragraphStyle: paragraphStyle
                ]
                
                let text = "Staqq Document\n\nDate: 2026-08-01"
                text.draw(with: CGRect(x: 20, y: 100, width: 560, height: 400), options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
            }
            
            if let data = image.jpegData(compressionQuality: 0.8) {
                saveDocument(imageDataArray: [data])
            }
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            var imageDataArray: [Data] = []
            
            for pageIndex in 0..<scan.pageCount {
                let image = scan.imageOfPage(at: pageIndex)
                if let data = image.jpegData(compressionQuality: 0.8) {
                    imageDataArray.append(data)
                }
            }
            
            saveDocument(imageDataArray: imageDataArray)
        }
        
        private func saveDocument(imageDataArray: [Data]) {
            if !imageDataArray.isEmpty {
                let newDocument = DocumentCard(imageData: imageDataArray)
                parent.modelContext.insert(newDocument)
                
                Task {
                    let (title, eventDate) = await OCRDocumentService.shared.analyze(imageDataArray: imageDataArray)
                    await MainActor.run {
                        newDocument.title = title
                        newDocument.eventDate = eventDate
                    }
                }
            }
            parent.dismiss()
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.dismiss()
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            print("Scanner failed with error: \(error)")
            parent.dismiss()
        }
    }
}
