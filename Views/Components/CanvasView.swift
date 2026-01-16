
import SwiftUI
import PencilKit

struct CanvasView: UIViewRepresentable {
    @Binding var drawingData: Data
    var backgroundImage: UIImage?
    var isEditable: Bool = true
    
    // 描画が変更されたことを検知するためのCoordinator
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        
        // ツールピッカーの設定（iPad等でのツールバー表示）
        canvas.drawingPolicy = .anyInput // 指でも描けるようにする（必要に応じて .pencilOnly に変更）
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.delegate = context.coordinator
        
        // 背景画像の設定
        if let image = backgroundImage {
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            imageView.frame = canvas.bounds
            imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            // canvasのサブビューの最背面に配置
            canvas.insertSubview(imageView, at: 0)
        }
        
        // 初期データのロード
        if let drawing = try? PKDrawing(data: drawingData) {
            canvas.drawing = drawing
        }
        
        // 編集可否
        canvas.isUserInteractionEnabled = isEditable
        
        return canvas
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        uiView.isUserInteractionEnabled = isEditable
        
        let toolPicker = context.coordinator.toolPicker
        if isEditable {
            toolPicker.setVisible(true, forFirstResponder: uiView)
            toolPicker.addObserver(uiView)
            uiView.becomeFirstResponder()
        } else {
            toolPicker.setVisible(false, forFirstResponder: uiView)
            toolPicker.removeObserver(uiView)
            uiView.resignFirstResponder()
        }
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: CanvasView
        let toolPicker = PKToolPicker()
        
        init(_ parent: CanvasView) {
            self.parent = parent
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            // 描画データが変わったら親に通知
            parent.drawingData = canvasView.drawing.dataRepresentation()
        }
    }
}
