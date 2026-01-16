import SwiftUI
import SwiftData
import PencilKit
import EventKit
import EventKitUI
import PDFKit
import CoreTransferable
import UniformTypeIdentifiers

struct DocumentDetailView: View {
    @Bindable var document: DocumentCard
    var onClose: (() -> Void)? = nil
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \AppTag.createdAt) private var appTags: [AppTag]
    
    @State private var calendarEventWrapper: IdentifiableEvent?
    @State private var showCalendarError = false
    @State private var showDeleteAlert = false
    @State private var showShareSheet = false
    @State private var pdfURL: URL?
    @State private var isDrawingMode = false
    @State private var showEventDatePopover = false
    @State private var showDeadlinePopover = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if document.imageData.isEmpty {
                    ContentUnavailableView {
                        Label("No Images", systemImage: "photo.on.rectangle")
                    } description: {
                        Text("This document has no images.")
                    }
                    .frame(minHeight: 300)
                } else {
                    ForEach(document.imageData.indices, id: \.self) { index in
                        if let uiImage = UIImage(data: document.imageData[index]) {
                            VStack {
                                // UIImageのサイズ比率に合わせてフレームを調整
                                let aspectRatio = uiImage.size.width / uiImage.size.height
                                
                                // 配列の安全なアクセス
                                if document.drawingData.indices.contains(index) {
                                    CanvasView(
                                        drawingData: $document.drawingData[index],
                                        backgroundImage: uiImage,
                                        isEditable: isDrawingMode
                                    )
                                    .aspectRatio(aspectRatio, contentMode: .fit)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Divider()
                    
                    TextField("Untitled Document", text: $document.title)
                        .font(.title2)
                        .bold()
                        .submitLabel(.done)
                    
                    // Folder/Tag Picker
                    HStack {
                        Image(systemName: "folder")
                            .foregroundStyle(.secondary)
                        Menu {
                            Button("None") {
                                document.childTag = ""
                            }
                            ForEach(appTags) { tag in
                                Button(tag.name) {
                                    document.childTag = tag.name
                                }
                            }
                        } label: {
                            HStack {
                                Text(document.childTag.isEmpty ? "Uncategorized" : document.childTag)
                                    .foregroundStyle(document.childTag.isEmpty ? .secondary : .primary)
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(UIColor.secondarySystemBackground))
                            .clipShape(Capsule())
                        }
                        Spacer()
                    }
                    
                    Group {
                        // 行事日
                        HStack {
                            Label("Event Date", systemImage: "calendar")
                                .foregroundStyle(.secondary)
                            Spacer()
                            if let date = document.eventDate {
                                Button {
                                    showEventDatePopover = true
                                } label: {
                                    Text(date.formatted(date: .numeric, time: .omitted))
                                        .foregroundStyle(.primary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color(UIColor.secondarySystemBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                                .popover(isPresented: $showEventDatePopover) {
                                    DatePicker("", selection: Binding(get: { document.eventDate ?? Date() }, set: { document.eventDate = $0 }), displayedComponents: .date)
                                        .datePickerStyle(.graphical)
                                        .padding()
                                        .frame(width: 320)
                                        .presentationCompactAdaptation(.popover)
                                        .onChange(of: document.eventDate) { _ in
                                            showEventDatePopover = false
                                        }
                                }
                                
                                Button { document.eventDate = nil } label: {
                                    Image(systemName: "xmark.circle.fill").foregroundStyle(.gray)
                                }
                            } else {
                                Button("Add") { document.eventDate = Date() }.font(.caption)
                            }
                        }
                        
                        // 提出期限
                        HStack {
                            Label("Deadline", systemImage: "clock.badge.exclamationmark")
                                .foregroundStyle(document.deadlineDate != nil ? .red : .secondary)
                            Spacer()
                            if let deadline = document.deadlineDate {
                                Button {
                                    showDeadlinePopover = true
                                } label: {
                                    Text(deadline.formatted(date: .numeric, time: .omitted))
                                        .foregroundStyle(.primary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color(UIColor.secondarySystemBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                                .popover(isPresented: $showDeadlinePopover) {
                                    DatePicker("", selection: Binding(get: { document.deadlineDate ?? Date() }, set: { document.deadlineDate = $0 }), displayedComponents: .date)
                                        .datePickerStyle(.graphical)
                                        .padding()
                                        .frame(width: 320)
                                        .presentationCompactAdaptation(.popover)
                                        .onChange(of: document.deadlineDate) { _ in
                                            showDeadlinePopover = false
                                        }
                                }
                                
                                Button { document.deadlineDate = nil } label: {
                                    Image(systemName: "xmark.circle.fill").foregroundStyle(.gray)
                                }
                            } else {
                                Button("Add") { document.deadlineDate = Date() }.font(.caption)
                            }
                        }
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            TextEditor(text: $document.notes)
                                .frame(minHeight: 120)
                                .scrollContentBackground(.hidden)
                                .background(Color(UIColor.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    
                    if !document.childTag.isEmpty {
                        HStack {
                            Image(systemName: "person")
                            Text(document.childTag)
                        }
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                    }
                }
                .padding()
            }
            .padding(.vertical)
        }
        .onAppear {
            let imageCount = document.imageData.count
            if document.drawingData.count < imageCount {
                for _ in 0..<(imageCount - document.drawingData.count) {
                    document.drawingData.append(Data())
                }
            }
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if let onClose {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                            .padding(8)
                            .background(Color(UIColor.secondarySystemBackground))
                            .clipShape(Circle())
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        isDrawingMode.toggle()
                    } label: {
                        Image(systemName: "pencil.tip.crop.circle")
                            .symbolVariant(isDrawingMode ? .fill : .none)
                            .foregroundStyle(isDrawingMode ? Color.accentColor : Color.primary)
                    }
                    
                    ShareLink(item: DocumentPDF(document: document), preview: SharePreview(document.title.isEmpty ? "Scanned Document" : document.title)) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    
                    Button {
                        Task {
                            // iOS 17以降とそれ以前で分岐
                            let store = CalendarManager.shared.eventStore
                            var granted = false
                            if #available(iOS 17.0, *) {
                               try? granted = await store.requestWriteOnlyAccessToEvents()
                            } else {
                               try? granted = await store.requestAccess(to: .event)
                            }
                            
                            if granted {
                                let event = CalendarManager.shared.createEvent(from: document)
                                self.calendarEventWrapper = IdentifiableEvent(event: event)
                            } else {
                                showCalendarError = true
                            }
                        }
                    } label: {
                        Image(systemName: "calendar.badge.plus")
                    }
                    
                    Menu {
                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                        
                        Button {
                            document.isArchived.toggle()
                        } label: {
                            Label(document.isArchived ? "Unarchive" : "Archive", 
                                  systemImage: document.isArchived ? "tray.and.arrow.up" : "archivebox")
                        }
                    } label: {
                         Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .confirmationDialog("Delete this document?", isPresented: $showDeleteAlert, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                modelContext.delete(document)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(item: $calendarEventWrapper) { wrapper in
            EventEditView(event: wrapper.event, eventStore: CalendarManager.shared.eventStore)
        }
        .alert("Calendar Access Denied", isPresented: $showCalendarError) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable access in Settings.")
        }
    }
}

// PDF転送用ヘルパー
struct DocumentPDF: Transferable {
    let document: DocumentCard
    
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .pdf) { docPDF in
            SentTransferredFile(generatePDF(for: docPDF.document))
        } importing: { _ in
            // Importはサポートしないためダミーを返す（本来は不可だがコンパイルを通すため）
            throw TransferError.importFailed
        }
    }
    
    enum TransferError: Error {
        case importFailed
    }
    
    static func generatePDF(for document: DocumentCard) -> URL {
        let pdfDocument = PDFDocument()
        for (index, data) in document.imageData.enumerated() {
            if let image = UIImage(data: data), let page = PDFPage(image: image) {
                pdfDocument.insert(page, at: index)
            }
        }
        
        // ファイル名
        let fileName = document.title.isEmpty ? "scanned_doc" : document.title
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(fileName).pdf")
        
        pdfDocument.write(to: tempURL)
        return tempURL
    }
}

struct IdentifiableEvent: Identifiable {
    let id = UUID()
    let event: EKEvent
}

class CalendarManager {
    static let shared = CalendarManager()
    let eventStore = EKEventStore()
    
    func createEvent(from document: DocumentCard) -> EKEvent {
        let event = EKEvent(eventStore: eventStore)
        event.title = document.title
        let targetDate = document.deadlineDate ?? document.eventDate ?? Date()
        event.startDate = targetDate
        event.endDate = targetDate
        event.isAllDay = true
        event.calendar = eventStore.defaultCalendarForNewEvents
        var notes = "Staqqでスキャンしたドキュメント"
        if !document.childTag.isEmpty {
            notes += "\nタグ: \(document.childTag)"
        }
        event.notes = notes
        
        if let url = URL(string: "staqq://document?id=\(document.id.uuidString)") {
            event.url = url
        }
        
        return event
    }
}

struct EventEditView: UIViewControllerRepresentable {
    let event: EKEvent
    let eventStore: EKEventStore
    
    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let controller = EKEventEditViewController()
        controller.eventStore = eventStore
        controller.event = event
        controller.editViewDelegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: EKEventEditViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    class Coordinator: NSObject, EKEventEditViewDelegate {
        var parent: EventEditView
        init(_ parent: EventEditView) { self.parent = parent }
        
        func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
            controller.dismiss(animated: true)
        }
    }
}
