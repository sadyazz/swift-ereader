import Foundation
import SwiftData

@Model
class Book {
    var title: String
    var coverImage: String?
    var filePath: String
    var dateAdded: Date

    init(title: String, coverImage: String?, fileURL: URL, dateAdded: Date) {
        self.title = title
        self.coverImage = coverImage
        self.filePath = fileURL.path
        self.dateAdded = dateAdded
    }

    var fileURL: URL {
        URL(fileURLWithPath: filePath)
    }
}