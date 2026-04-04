import SwiftUI
import SwiftData

@main
struct swift_ereaderApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([Book.self, Bookmark.self, ReadingSession.self])
        let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.jasmina.swift-ereader")!
        let storeURL = groupURL.appendingPathComponent("library.store")
        let config = ModelConfiguration(url: storeURL)
        container = try! ModelContainer(for: schema, configurations: config)
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(container)
    }
}
