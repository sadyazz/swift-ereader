import SwiftUI
import SwiftData

struct BookmarksView: View {
    let bookID: String
    var onSelect: (String) -> Void
    @Query private var allBookmarks: [Bookmark]
    @Environment(\.modelContext) private var modelContext

    var bookmarks: [Bookmark] {
        allBookmarks.filter { $0.bookID == bookID }
    }

    var body: some View {
        NavigationView {
            Group {
                if bookmarks.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "bookmark")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("No bookmarks yet")
                            .foregroundColor(.secondary)
                    }
                } else {
                    List {
                        ForEach(bookmarks) { bookmark in
                            Button {
                                onSelect(bookmark.position)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(bookmark.title)
                                        .font(.body)
                                    Text(bookmark.dateCreated, style: .date)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                modelContext.delete(bookmarks[index])
                            }
                            try? modelContext.save()
                        }
                    }
                }
            }
            .navigationTitle("Bookmarks")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
