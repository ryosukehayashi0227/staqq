
import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var columnVisibility = NavigationSplitViewVisibility.detailOnly
    @State private var preferredColumn = NavigationSplitViewColumn.sidebar
    @State private var sidebarSelection: SidebarItem? = nil
    @State private var selectedDocument: DocumentCard?
    @State private var showScanner = false
    
    // SwiftDataから全ドキュメントを取得（フィルタリングはView側で行う）
    @Query private var documents: [DocumentCard]
    // フォルダタグを作成日順に取得
    @Query(sort: \AppTag.createdAt) private var appTags: [AppTag]
    
    @State private var showAddTagAlert = false
    @State private var showHelp = false
    @State private var newTagName = ""
    
    @State private var searchText = ""
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // iPad/Mac対応の3ペイン構成（今回は2ペイン：サイドバー + 詳細）
            NavigationSplitView(columnVisibility: $columnVisibility) {
                VStack(spacing: 0) {
                    // Header Area
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 12) {
                            Image(systemName: "square.grid.2x2.fill") // App Icon placeholder
                                .font(.title)
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.cyan)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: .cyan.opacity(0.3), radius: 8, x: 0, y: 4)
                            
                            Text("Staqq")
                                .font(.title)
                                .fontWeight(.bold)
                        }
                        
                        // Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)
                            
                            TextField("Search flyers & docs...", text: $searchText)
                                .submitLabel(.search)
                                .onSubmit {
                                    sidebarSelection = .all
                                }
                            
                            if !searchText.isEmpty {
                                Button {
                                    searchText = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(10)
                        .background(Color(UIColor.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .padding()
                    
                    // サイドバーのリスト表示
                    List(selection: $sidebarSelection) {
                        sidebarListContent
                    }
                    .listStyle(.sidebar)
                    .scrollContentBackground(.hidden) // デフォルトの背景を消す
                    

                }
                .navigationTitle("") // タイトル非表示
                .toolbar(.hidden, for: .navigationBar) // ナビゲーションバーを隠してカスタムヘッダーを使う
            } detail: {
                NavigationStack {
                    if let selection = sidebarSelection {
                        // 選択されたカテゴリに基づいてドキュメント一覧を表示
                        DocumentListView(filter: selection, searchText: searchText, selectedDocument: $selectedDocument)
                            .navigationDestination(item: $selectedDocument) { document in
                                // ドキュメントタップ時の詳細画面遷移
                                DocumentDetailView(document: document, onClose: nil)
                            }
                            .id(selection)
                            .toolbar {
                                ToolbarItem(placement: .topBarLeading) {
                                    if horizontalSizeClass == .regular && columnVisibility != .detailOnly {
                                        Button {
                                            withAnimation {
                                                columnVisibility = .detailOnly
                                            }
                                        } label: {
                                            Image(systemName: "sidebar.left")
                                        }
                                    }
                                }
                            }
                    } else {
                        Text("Select a category")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationSplitViewStyle(.balanced)
            .onChange(of: showScanner) { newValue in
                if !newValue {
                    sidebarSelection = .unprocessed
                }
            }
            
            // Floating Action Button (FAB)
            if selectedDocument == nil {
                Button {
                    showScanner = true
                } label: {
                Image(systemName: "camera.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .padding()
                    .background(Color.accentColor)
                    .clipShape(Circle())
                    .shadow(radius: 4, y: 2)
            }
            .padding()
            }
        }
        .sheet(isPresented: $showScanner) {
            ScannerView()
        }
        .sheet(isPresented: $showHelp) {
            HelpView()
        }
        .alert("New Folder", isPresented: $showAddTagAlert) {
            TextField("Folder Name", text: $newTagName)
                .onChange(of: newTagName) { newValue in
                    if newValue.count > 20 {
                        newTagName = String(newValue.prefix(20))
                    }
                }
            Button("Create") {
                let trimmed = newTagName.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty {
                    let tag = AppTag(name: trimmed)
                    modelContext.insert(tag)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Enter folder name")
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // showScanner = true // 自動起動はいったんコメントアウトして手動確認を優先
            }
            
            // 既存のタグをAppTagに同期
            let existingNames = Set(appTags.map { $0.name })
            let usedTags = Set(documents.map { $0.childTag }.filter { !$0.isEmpty })
            for tag in usedTags {
                if !existingNames.contains(tag) {
                    modelContext.insert(AppTag(name: tag))
                }
            }
        }
        .onOpenURL { url in
            guard url.scheme == "staqq", 
                  url.host == "document",
                  let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
                  let idString = components.queryItems?.first(where: { $0.name == "id" })?.value,
                  let id = UUID(uuidString: idString) 
            else { return }
            
            let descriptor = FetchDescriptor<DocumentCard>(predicate: #Predicate { $0.id == id })
            if let results = try? modelContext.fetch(descriptor), let doc = results.first {
                selectedDocument = doc
            }
        }
    }
    
    @ViewBuilder
    private var sidebarListContent: some View {
        // スマートフォルダ（自動分類）セクション
        Section("Smart Folders") {
            SidebarRow(title: "Inbox", icon: "tray", count: documents.filter { !$0.isArchived }.count, color: .cyan)
                .padding(.horizontal, 8)
                .background(sidebarSelection == .unprocessed ? Color.cyan.opacity(0.2) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .tag(SidebarItem.unprocessed)
            
            SidebarRow(title: "Upcoming Deadlines", icon: "clock.badge.exclamationmark", count: documents.filter { 
                !$0.isArchived && 
                $0.deadlineDate != nil && 
                $0.deadlineDate! <= Date().addingTimeInterval(3*24*60*60) 
            }.count, color: .red)
                .padding(.horizontal, 8)
                .background(sidebarSelection == .upcoming ? Color.red.opacity(0.1) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .tag(SidebarItem.upcoming)
            
            SidebarRow(title: "All Docs", icon: "doc.text", count: documents.count, color: .gray)
                .padding(.horizontal, 8)
                .background(sidebarSelection == .all ? Color.cyan.opacity(0.2) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .tag(SidebarItem.all)
            
            SidebarRow(title: "Archived", icon: "archivebox", count: documents.filter { $0.isArchived }.count, color: .gray)
                .padding(.horizontal, 8)
                .background(sidebarSelection == .archived ? Color.cyan.opacity(0.2) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .tag(SidebarItem.archived)
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        
        // ユーザー作成フォルダセクション
        Section("My Folders") {
            ForEach(appTags) { tag in
                SidebarRow(title: LocalizedStringKey(tag.name), icon: "folder", count: documents.filter { $0.childTag == tag.name }.count, color: .orange)
                    .padding(.horizontal, 8)
                    .background(sidebarSelection == .child(tag.name) ? Color.cyan.opacity(0.2) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .tag(SidebarItem.child(tag.name))
                    .contextMenu {
                        Button(role: .destructive) {
                            modelContext.delete(tag)
                        } label: {
                            Label("Delete Folder", systemImage: "trash")
                        }
                    }
            }
            
            Button {
                newTagName = ""
                showAddTagAlert = true
            } label: {
                Label("New Folder", systemImage: "plus.circle")
                    .foregroundColor(.cyan)
            }
            .padding(.leading, 8)
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        
        Button {
            showHelp = true
        } label: {
            SidebarRow(title: "Help & Support", icon: "questionmark.circle", count: 0, color: .blue)
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
}


    

