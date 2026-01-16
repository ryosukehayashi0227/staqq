
import SwiftUI
import SwiftData

struct DocumentListView: View {
    @Query private var documents: [DocumentCard]
    @Binding var selectedDocument: DocumentCard?
    
    init(filter: SidebarItem, selectedDocument: Binding<DocumentCard?>) {
        _selectedDocument = selectedDocument
        
        let predicate: Predicate<DocumentCard>
        switch filter {
        case .all:
            predicate = #Predicate<DocumentCard> { _ in true }
        case .unprocessed:
            predicate = #Predicate<DocumentCard> { !$0.isArchived }
        case .archived:
            predicate = #Predicate<DocumentCard> { $0.isArchived }
        case .child(let name):
            predicate = #Predicate<DocumentCard> { $0.childTag == name }
        }
        
        _documents = Query(filter: predicate, sort: \.createdAt, order: .reverse)
    }
    
    var body: some View {
        List(selection: $selectedDocument) {
            ForEach(documents) { document in
                NavigationLink(value: document) {
                    DocumentRow(document: document)
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .navigationTitle("ドキュメント")
        .background(Color(UIColor.systemGroupedBackground))
    }
}

struct DocumentRow: View {
    let document: DocumentCard
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 上部：画像エリア
            ZStack(alignment: .topLeading) {
                if let firstData = document.imageData.first, let uiImage = UIImage(data: firstData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 180)
                        .clipped()
                } else {
                    // プレースホルダー
                    Rectangle()
                        .fill(Color(UIColor.secondarySystemBackground))
                        .frame(height: 180)
                        .overlay {
                            Image(systemName: "doc.text.image")
                                .font(.largeTitle)
                                .foregroundStyle(.tertiary)
                        }
                }
                
                // オーバーレイタグ（子供の名前）
                if !document.childTag.isEmpty {
                    Text(document.childTag)
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .padding(12)
                }
                
                // 右上：タイプ（チラシなど）- 将来的にAI判定
                Text("FLYER")
                    .font(.caption2)
                    .fontWeight(.heavy)
                    .tracking(1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white)
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .topTrailing)
            }
            .frame(height: 180)
            .background(Color(UIColor.secondarySystemBackground))
            
            // 下部：情報エリア
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    // スキャン日時（相対時間）
                    Text("Scanned \(document.createdAt.formatted(.relative(presentation: .named)))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                }
                
                // タイトル
                Text(document.title.isEmpty ? "名称未設定" : document.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                
                // 日付情報
                if let date = document.eventDate {
                    Label {
                        Text(date.formatted(date: .abbreviated, time: .shortened))
                    } icon: {
                        Image(systemName: "calendar")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                
                // アクション行
                HStack {
                    // 期限が近い場合などの警告
                    if let deadline = document.deadlineDate {
                        Label("期限: \(deadline.formatted(date: .numeric, time: .omitted))", systemImage: "clock.badge.exclamationmark")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.red)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(Color.red.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    
                    Spacer()
                    
                    Text("View Details")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.accentColor)
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundStyle(Color.accentColor)
                }
                .padding(.top, 4)
            }
            .padding(16)
            .background(Color(UIColor.systemBackground))
        }
        .clipShape(RoundedRectangle(cornerRadius: 20)) // 角丸を大きく
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 5) // 柔らかい影
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
