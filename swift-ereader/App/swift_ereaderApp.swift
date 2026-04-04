import SwiftUI
import SwiftData

@main
struct swift_ereaderApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(for: [Book.self, Bookmark.self, ReadingSession.self])
    }
}
