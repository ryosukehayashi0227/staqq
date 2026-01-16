
import SwiftUI

struct DocumentDetailView: View {
    let document: DocumentCard
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if document.imageData.isEmpty {
                    ContentUnavailableView {
                        Label("画像なし", systemImage: "photo.on.rectangle")
                    } description: {
                        Text("このドキュメントには画像がありません")
                    }
                    .frame(minHeight: 300)
                } else {
                    ForEach(document.imageData.indices, id: \.self) { index in
                        if let uiImage = UIImage(data: document.imageData[index]) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                                .padding(.horizontal)
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Divider()
                    
                    Text(document.title.isEmpty ? "名称未設定" : document.title)
                        .font(.title2)
                        .bold()
                    
                    HStack(spacing: 24) {
                        if let date = document.eventDate {
                             VStack(alignment: .leading) {
                                 Text("行事日")
                                     .font(.caption)
                                     .foregroundStyle(.secondary)
                                 Text(date.formatted(date: .long, time: .omitted))
                             }
                        }
                        
                        if let deadline = document.deadlineDate {
                             VStack(alignment: .leading) {
                                 Text("提出期限")
                                     .font(.caption)
                                     .foregroundStyle(.secondary)
                                 Text(deadline.formatted(date: .long, time: .omitted))
                                     .foregroundStyle(.red)
                             }
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
        .navigationTitle("詳細")
        .navigationBarTitleDisplayMode(.inline)
    }
}
