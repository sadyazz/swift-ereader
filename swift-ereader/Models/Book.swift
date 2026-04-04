import Foundation
import SwiftData

@Model
class Book {
    var title: String
    var coverImage: String?
    var filePath: String
    var dateAdded: Date
    var readingProgress: Int?
    var epubLocator: String?
    var lastOpened: Date?
    var totalReadingTime: Double = 0

    init(title: String, coverImage: String?, fileURL: URL, dateAdded: Date) {
        self.title = title
        self.coverImage = coverImage
        // store path relative to Documents directory
        let docsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.path
        if fileURL.path.hasPrefix(docsPath) {
            self.filePath = String(fileURL.path.dropFirst(docsPath.count + 1))
        } else {
            self.filePath = fileURL.path
        }
        self.dateAdded = dateAdded
        self.readingProgress = nil
        self.epubLocator = nil
        self.lastOpened = nil
    }

    var fileURL: URL {
        let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docsDir.appendingPathComponent(filePath)
    }

    var coverURL: URL? {
        guard let coverImage else { return nil }
        let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docsDir.appendingPathComponent(coverImage)
    }
}
