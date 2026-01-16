
import SwiftUI
import SwiftData
import ImageIO

struct DocumentListView: View {
    @Query private var documents: [DocumentCard]
    @Binding var selectedDocument: DocumentCard?
    @Environment(\.modelContext) private var modelContext
    
    // グリッドのカラム設定（幅160以上で自動調整）
    let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 300), spacing: 16)
    ]
    
    let title: LocalizedStringKey
    
    init(filter: SidebarItem, searchText: String, selectedDocument: Binding<DocumentCard?>) {
        _selectedDocument = selectedDocument
        
        // 検索テキストが空かどうかで分岐を避けるため、条件式内に組み込む
        // SwiftDataのPredicateは単一のクロージャである必要があるため、各caseで定義
        let filterPredicate: Predicate<DocumentCard>
        
        switch filter {
        case .all:
            title = "All Docs"
            filterPredicate = #Predicate<DocumentCard> { document in
                (searchText.isEmpty || document.title.contains(searchText) || document.childTag.contains(searchText) || document.notes.contains(searchText))
            }
        case .unprocessed:
            title = "Inbox"
            filterPredicate = #Predicate<DocumentCard> { document in
                !document.isArchived &&
                (searchText.isEmpty || document.title.contains(searchText) || document.childTag.contains(searchText) || document.notes.contains(searchText))
            }
        case .archived:
            title = "Archived"
            filterPredicate = #Predicate<DocumentCard> { document in
                document.isArchived &&
                (searchText.isEmpty || document.title.contains(searchText) || document.childTag.contains(searchText) || document.notes.contains(searchText))
            }
        case .upcoming:
            title = "Upcoming Deadlines"
            let threshold = Date().addingTimeInterval(3 * 24 * 60 * 60)
            let distantFuture = Date.distantFuture
            filterPredicate = #Predicate<DocumentCard> { document in
                !document.isArchived &&
                document.deadlineDate != nil &&
                (document.deadlineDate ?? distantFuture) <= threshold &&
                (searchText.isEmpty || document.title.contains(searchText) || document.childTag.contains(searchText) || document.notes.contains(searchText))
            }
        case .child(let tagName):
            title = LocalizedStringKey("#\(tagName)")
            filterPredicate = #Predicate<DocumentCard> { document in
                document.childTag == tagName &&
                (searchText.isEmpty || document.title.contains(searchText) || document.childTag.contains(searchText) || document.notes.contains(searchText))
            }
        }
        
        _documents = Query(filter: filterPredicate, sort: \.createdAt, order: .reverse)
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(documents) { document in
                    DocumentRow(document: document)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedDocument = document
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                modelContext.delete(document)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            Button {
                                document.isArchived.toggle()
                            } label: {
                                Label(document.isArchived ? "Unarchive" : "Archive", 
                                      systemImage: document.isArchived ? "tray.and.arrow.up" : "archivebox")
                            }
                        }
                }
            }
            .padding()
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle(title)
        .onAppear {
            selectedDocument = nil
        }
    }
}

struct DocumentRow: View {
    let document: DocumentCard
    @State private var thumbnailImage: UIImage?
    @State private var showArchiveAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 上部：画像エリア
            ZStack(alignment: .topLeading) {
                if let uiImage = thumbnailImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 140)
                        .clipped()
                } else {
                    // プレースホルダー または 読み込み中
                    Rectangle()
                        .fill(Color(UIColor.secondarySystemBackground))
                        .frame(height: 140)
                        .overlay {
                            if !document.imageData.isEmpty {
                                ProgressView()
                            } else {
                                Image(systemName: "doc.text.image")
                                    .font(.largeTitle)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                }
                
                // オーバーレイタグ
                if !document.childTag.isEmpty {
                    Text(document.childTag)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .lineLimit(1)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .padding(8)
                }
                
                // 右上：タイプ
                Text("FLYER")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.white)
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .topTrailing)
                
                // アーカイブ状態の表示
                if document.isArchived {
                    Color.black.opacity(0.3)
                    
                    Text("Archived")
                        .textCase(.uppercase)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.gray)
                        .clipShape(Capsule())
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
            }
            .frame(height: 140)
            .background(Color(UIColor.secondarySystemBackground))
            .task(id: document.id) {
                // 画像の非同期ロードとリサイズ
                if thumbnailImage == nil, let data = document.imageData.first {
                    thumbnailImage = await Task.detached(priority: .userInitiated) {
                        if let original = UIImage(data: data) {
                            // グリッド用にリサイズ（メモリ節約と高速化）
                            let size = CGSize(width: 300, height: 300)
                            return original.preparingThumbnail(of: size) ?? original
                        }
                        return nil
                    }.value
                }
            }
            
            // 下部：情報エリア
            VStack(alignment: .leading, spacing: 8) {
                // スキャン日時
                Text("Scanned \(document.createdAt.formatted(.relative(presentation: .named)))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                // タイトル
                Text(document.title.isEmpty ? "Untitled Document" : document.title)
                    .font(.subheadline)
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
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                
                // アクション行
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        if let deadline = document.deadlineDate {
                            Label("Due: \(deadline.formatted(date: .numeric, time: .omitted))", systemImage: "clock.badge.exclamationmark")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundStyle(.red)
                                .padding(.vertical, 2)
                                .padding(.horizontal, 6)
                                .background(Color.red.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        
                        if !document.childTag.isEmpty {
                             Text(document.childTag)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .lineLimit(1)
                                .foregroundStyle(.orange)
                                .padding(.vertical, 2)
                                .padding(.horizontal, 6)
                                .background(Color.orange.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                    
                    Spacer()
                    
                    // アーカイブボタン（直感的な操作）
                    Button {
                        showArchiveAlert = true
                    } label: {
                        Image(systemName: document.isArchived ? "tray.and.arrow.down" : "archivebox")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                            .padding(8)
                            .background(Color(UIColor.secondarySystemBackground))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .alert(document.isArchived ? "Restore to Inbox?" : "Move to Archived?", isPresented: $showArchiveAlert) {
                        Button(document.isArchived ? "Restore" : "Move") {
                             withAnimation {
                                 document.isArchived.toggle()
                             }
                        }
                        Button("Cancel", role: .cancel) { }
                    }
                }
            }
            .padding(10)
            .background(Color(UIColor.systemBackground))
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
        // 表示時に非同期でサムネイル画像を生成
        .task(id: document.id) {
            await loadThumbnail()
        }
    }
    
    private func loadThumbnail() async {
        // 画像がない場合や既にロード済みの場合はスキップ
        guard thumbnailImage == nil, let data = document.imageData.first else { return }
        
        // 重い画像処理をバックグラウンド（UserInitiated）で実行してメインスレッドをブロックしない
        if let image = await Task.detached(priority: .userInitiated, operation: { () -> UIImage? in
            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceShouldCacheImmediately: true,
                kCGImageSourceThumbnailMaxPixelSize: 600 // 横幅300pt x 2倍解像度 = 600px にダウンサンプリング
            ]
            
            // 全データをデコードせずに、サムネイル作成に必要な部分だけ読み込む
            guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
            guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
            
            return UIImage(cgImage: cgImage)
        }).value {
            // メインスレッドでUI更新（アニメーション付き）
            await MainActor.run {
                withAnimation(.easeIn(duration: 0.25)) {
                    self.thumbnailImage = image
                }
            }
        }
    }
}
