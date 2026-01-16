import SwiftUI

struct HelpTopic: Identifiable {
    let id = UUID()
    let title: LocalizedStringKey
    let icon: String
    let content: LocalizedStringKey
}

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    
    let topics: [HelpTopic] = [
        HelpTopic(
            title: "Scanning Documents",
            icon: "camera.viewfinder",
            content: "Tap the camera button to start scanning. You can toggle Auto/Manual capture from the top right button. Position the document within the frame to capture automatically, or use Manual mode to take photos yourself."
        ),
        HelpTopic(
            title: "Organizing with Folders",
            icon: "folder",
            content: "Create folders to organize your documents. You can assign a folder (tag) to each document from the detail view."
        ),
        HelpTopic(
            title: "Managing Deadlines",
            icon: "clock.badge.exclamationmark",
            content: "Set a deadline for your documents. You can view documents with upcoming deadlines (within 3 days) in the 'Upcoming Deadlines' list."
        ),
        HelpTopic(
            title: "Calendar Integration",
            icon: "calendar.badge.plus",
            content: "Add document deadlines to your calendar app. Tap the calendar icon in the detail view to create an event."
        ),
        HelpTopic(
            title: "Archiving",
            icon: "archivebox",
            content: "Move completed documents to the archive to keep your list clean. Archived documents can be viewed in the 'Archived' list and restored at any time."
        )
    ]
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(topics) { topic in
                        DisclosureGroup {
                            Text(topic.content)
                                .foregroundStyle(.secondary)
                                .padding(.vertical, 8)
                        } label: {
                            Label(topic.title, systemImage: topic.icon)
                                .foregroundStyle(.primary)
                                .fontWeight(.medium)
                        }
                    }
                } header: {
                    Text("How to use Staqq")
                } footer: {
                    Text("Staqq v1.0")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 20)
                }
            }
            .navigationTitle("Help & Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}
