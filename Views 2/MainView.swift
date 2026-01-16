
import SwiftUI
import SwiftData

struct MainView: View {
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    @State private var preferredColumn = NavigationSplitViewColumn.sidebar
    @State private var sidebarSelection: SidebarItem? = .all
    @State private var selectedDocument: DocumentCard?
    @State private var showScanner = false
    
    @Query private var documents: [DocumentCard]
    
    var childTags: [String] {
        Set(documents.map { $0.childTag })
            .filter { !$0.isEmpty }
            .sorted()
    }
    
    @State private var searchText = ""
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            NavigationSplitView(columnVisibility: $columnVisibility, preferredCompactColumn: $preferredColumn) {
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
                        }
                        .padding(10)
                        .background(Color(UIColor.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .padding()
                    
                    List(selection: $sidebarSelection) {
                        Section("SMART FOLDERS") {
                            NavigationLink(value: SidebarItem.unprocessed) {
                                SidebarRow(title: "Inbox", icon: "tray", count: 5, color: .cyan)
                            }
                            NavigationLink(value: SidebarItem.all) {
                                SidebarRow(title: "All Docs", icon: "doc.text", count: 12, color: .gray)
                            }
                            NavigationLink(value: SidebarItem.archived) {
                                SidebarRow(title: "Archived", icon: "archivebox", count: 0, color: .gray)
                            }
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        
                        if !childTags.isEmpty {
                            Section("TAGS") {
                                ForEach(childTags, id: \.self) { tag in
                                    NavigationLink(value: SidebarItem.child(tag)) {
                                        HStack {
                                            Circle()
                                                .fill(Color.orange) // 色はランダムにしても良い
                                                .frame(width: 8, height: 8)
                                            Text("#\(tag)")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                        }
                                        .padding(.vertical, 4)
                                        .padding(.horizontal, 12)
                                        .background(Color(UIColor.secondarySystemBackground))
                                        .clipShape(Capsule())
                                    }
                                }
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.sidebar)
                    .scrollContentBackground(.hidden) // デフォルトの背景を消す
                    
                    // Quick Scan Button (Sidebar Bottom)
                    Button {
                        showScanner = true
                    } label: {
                        HStack {
                            Image(systemName: "viewfinder")
                            Text("Quick Scan")
                                .fontWeight(.bold)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.cyan)
                        .clipShape(Capsule())
                        .shadow(color: .cyan.opacity(0.4), radius: 8, x: 0, y: 4)
                    }
                    .padding()
                }
                .navigationTitle("") // タイトル非表示
                .toolbar(.hidden, for: .navigationBar) // ナビゲーションバーを隠してカスタムヘッダーを使う
            } content: {
                if let selection = sidebarSelection {
                    DocumentListView(filter: selection, selectedDocument: $selectedDocument)
                } else {
                    Text("カテゴリを選択してください")
                        .foregroundStyle(.secondary)
                }
            } detail: {
                if let document = selectedDocument {
                    DocumentDetailView(document: document)
                } else {
                    ContentUnavailableView("選択なし", systemImage: "doc.text")
                }
            }
            .navigationSplitViewStyle(.balanced)
            
            // Floating Action Button (FAB)
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
        .sheet(isPresented: $showScanner) {
            ScannerView()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // showScanner = true // 自動起動はいったんコメントアウトして手動確認を優先
            }
        }
    }
}

enum SidebarItem: Hashable, Identifiable {
    case all
    case unprocessed
    case archived
    case child(String)
    
    var id: String {
        switch self {
        case .all: return "all"
        case .unprocessed: return "unprocessed"
        case .archived: return "archived"
        case .child(let name): return "child_\(name)"
        }
    }
}

struct SidebarRow: View {
    let title: LocalizedStringKey
    let icon: String
    let count: Int
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(color)
                .frame(width: 24)
            
            Text(title)
                .font(.body)
                .fontWeight(.medium)
            
            Spacer()
            
            if count > 0 {
                Text("\(count)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(color == .cyan ? .cyan : .gray.opacity(0.5))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
    }
}
