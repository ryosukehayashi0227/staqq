import SwiftUI

enum SidebarItem: Hashable, Identifiable {
    case all
    case unprocessed
    case upcoming
    case archived
    case child(String)
    
    var id: String {
        switch self {
        case .all: return "all"
        case .unprocessed: return "unprocessed"
        case .upcoming: return "upcoming"
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
                .lineLimit(1)
                .truncationMode(.tail)
            
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
