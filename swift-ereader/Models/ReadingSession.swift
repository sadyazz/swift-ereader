import Foundation
import SwiftData

@Model
class ReadingSession {
    var bookID: String
    var date: Date
    var duration: Double

    init(bookID: String, date: Date, duration: Double) {
        self.bookID = bookID
        self.date = date
        self.duration = duration
    }
}
