import Foundation

struct Book: Identifiable {
    let id = UUID()
    var title: String
    var coverImage: String?
    var fileURL: URL
    var dateAdded: Date
}