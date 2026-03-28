import SwiftUI
import ReadiumNavigator
import ReadiumShared

struct EPUBReaderView: View {
    let book: Book
    @State private var publication: Publication?
    @State private var error: String?

    var body: some View {
        Group {
            if let publication {
                EPUBView(publication: publication)
            } else if let error {
                Text("Failed to open: \(error)")
            } else {
                ProgressView("Opening...")
            }
        }
        .navigationTitle(book.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            do {
                publication = try await BookOpener.shared.open(url: book.fileURL)
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
}

struct EPUBView: UIViewControllerRepresentable {
    let publication: Publication

    func makeUIViewController(context: Context) -> EPUBNavigatorViewController {
        try! EPUBNavigatorViewController(publication: publication, initialLocation: nil)
    }

    func updateUIViewController(_ uiViewController: EPUBNavigatorViewController, context: Context) {}
}