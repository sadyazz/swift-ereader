import Foundation
import SwiftData

@Model
class BookCollection {
    var name: String
    var icon: String
    var dateCreated: Date
    var bookIDs: [String]

    init(name: String, icon: String = "folder.fill") {
        self.name = name
        self.icon = icon
        self.dateCreated = Date()
        self.bookIDs = []
    }
}
