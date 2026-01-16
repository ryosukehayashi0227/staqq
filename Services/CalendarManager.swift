
import SwiftUI
import EventKit
import EventKitUI

/// カレンダーへのアクセスとイベント生成を管理するクラス
class CalendarManager: ObservableObject {
    static let shared = CalendarManager()
    let eventStore = EKEventStore()
    
    // カレンダーアクセス権限のリクエスト（iOS 17対応）
    func requestAccess() async -> Bool {
        if #available(iOS 17.0, *) {
            return await requestAccessiOS17()
        } else {
            return await requestAccessLegacy()
        }
    }
    
    @available(iOS 17.0, *)
    private func requestAccessiOS17() async -> Bool {
        do {
            // .writeOnly または .fullAccess をリクエスト
            return try await eventStore.requestWriteOnlyAccessToEvents()
        } catch {
            print("Calendar access denied: \(error)")
            return false
        }
    }
    
    private func requestAccessLegacy() async -> Bool {
        do {
            return try await eventStore.requestAccess(to: .event)
        } catch {
            print("Legacy calendar access denied: \(error)")
            return false
        }
    }
    
    // イベントを作成して返す（保存はEKEventEditViewControllerでユーザーが行う）
    func createEvent(from document: DocumentCard) -> EKEvent {
        let event = EKEvent(eventStore: eventStore)
        event.title = document.title
        
        // 日付の設定優先度: deadlineDate > eventDate > 現在時刻
        let targetDate = document.deadlineDate ?? document.eventDate ?? Date()
        
        event.startDate = targetDate
        event.endDate = targetDate.addingTimeInterval(3600) // 1時間
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        // メモに詳細情報を入れる
        var notes = "Staqqでスキャンしたドキュメント"
        if !document.childTag.isEmpty {
            notes += "\nタグ: \(document.childTag)"
        }
        event.notes = notes
        
        return event
    }
}

/// iOS標準のカレンダー編集画面を表示するラッパー
struct EventEditView: UIViewControllerRepresentable {
    @Binding var event: EKEvent?
    let eventStore: EKEventStore
    
    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let controller = EKEventEditViewController()
        controller.eventStore = eventStore
        controller.event = event
        controller.editViewDelegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: EKEventEditViewController, context: Context) {
        // UI更新は不要
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, EKEventEditViewDelegate {
        var parent: EventEditView
        
        init(_ parent: EventEditView) {
            self.parent = parent
        }
        
        func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
            controller.dismiss(animated: true)
            // 完了後にイベントの選択を解除するなどの処理があればここに記述
            parent.event = nil
        }
    }
}
