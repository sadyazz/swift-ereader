//
//  swift_ereaderApp.swift
//  swift-ereader
//
//  Created by Jasmina on 15/2/26.
//

import SwiftUI
import SwiftData

@main
struct swift_ereaderApp: App {
    var body: some Scene {
        WindowGroup {
            LibraryView()
        }
        .modelContainer(for: [Book.self, Bookmark.self])
    }
}
