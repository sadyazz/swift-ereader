import SwiftUI
import SwiftData
import ReadiumNavigator
import ReadiumShared

struct EPUBReaderView: View {
    @Environment(\.modelContext) private var modelContext
    let book: Book
    @State private var publication: Publication?
    @State private var navigator: EPUBNavigatorViewController?
    @State private var error: String?

    var body: some View {
        Group {
            if let publication, let navigator {
                EPUBView(navigator: navigator)
            } else if let error {
                Text("Failed to open: \(error)")
            } else {
                ProgressView("Opening...")
            }
        }
        .navigationTitle(book.title)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            if let locator = navigator?.currentLocation,
               let data = try? JSONSerialization.data(withJSONObject: locator.json),
               let json = String(data: data, encoding: .utf8) {
                book.epubLocator = json
                try? modelContext.save()
            }
        }
        .task {
            do {
                let pub = try await BookOpener.shared.open(url: book.fileURL)
                publication = pub

                // Restore saved position
                var locator: Locator? = nil
                if let json = book.epubLocator {
                    locator = try? Locator(jsonString: json)
                }

                navigator = try EPUBNavigatorViewController(
                    publication: pub,
                    initialLocation: locator
                )

                if book.coverImage == nil, let coverImage = try? await pub.cover().get() {
                    if let data = coverImage.jpegData(compressionQuality: 0.7) {
                        let filename = book.title.replacingOccurrences(of: " ", with: "_") + "_cover.jpg"
                        let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                        let coverURL = docsDir.appendingPathComponent(filename)
                        try? data.write(to: coverURL)
                        book.coverImage = filename
                    }
                }
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
}

struct EPUBView: UIViewControllerRepresentable {
    let navigator: EPUBNavigatorViewController

    func makeUIViewController(context: Context) -> EPUBNavigatorViewController {
        navigator
    }

    func updateUIViewController(_ uiViewController: EPUBNavigatorViewController, context: Context) {}
}
