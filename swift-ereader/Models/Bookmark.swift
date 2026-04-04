import Foundation
import SwiftData

@Model
class Bookmark {
    var bookID: String
    var title: String
    var position: String
    var dateCreated: Date

    init(bookID: String, title: String, position: String) {
        self.bookID = bookID
        self.title = title
        self.position = position
        self.dateCreated = Date()
    }
}