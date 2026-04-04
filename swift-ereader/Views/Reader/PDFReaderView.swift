import SwiftUI
import PDFKit
import SwiftData

extension Notification.Name {
    static let goToPage = Notification.Name("goToPage")
    static let currentPageChanged = Notification.Name("currentPageChanged")
}

struct PDFReaderView: View {
    @Environment(\.modelContext) private var modelContext
    let book: Book
    @State private var showBookmarks = false
    @State private var currentPage: Int = 0

    var body: some View {
        PDFKitView(book: book)
            .navigationTitle(book.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showBookmarks = true
                    } label: {
                        Image(systemName: "book.pages")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        addPDFBookmark()
                    } label: {
                        Image(systemName: "bookmark.fill")
                    }
                }
            }
            .sheet(isPresented: $showBookmarks) {
                BookmarksView(bookID: book.filePath) { position in
                    showBookmarks = false
                    if let page = Int(position) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            NotificationCenter.default.post(
                                name: .goToPage,
                                object: nil,
                                userInfo: ["page": page]
                            )
                        }
                    }
                }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
            .onDisappear {
                try? modelContext.save()
            }
            .onReceive(NotificationCenter.default.publisher(for: .currentPageChanged)) { notif in
                if let page = notif.userInfo?["page"] as? Int {
                    currentPage = page
                }
            }
    }

    private func addPDFBookmark() {
        let bookmark = Bookmark(
            bookID: book.filePath,
            title: "Page \(currentPage + 1)",
            position: String(currentPage)
        )
        modelContext.insert(bookmark)
        try? modelContext.save()
    }
}

struct PDFKitView: UIViewRepresentable {
    let book: Book

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.document = PDFDocument(url: book.fileURL)
        context.coordinator.pdfView = pdfView

        // Restore saved page after layout completes
        if let page = book.readingProgress, page > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if let pdfPage = pdfView.document?.page(at: page) {
                    pdfView.go(to: pdfPage)
                }
            }
        }

        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.pageChanged(_:)),
            name: .PDFViewPageChanged,
            object: pdfView
        )

        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.goToPage(_:)),
            name: .goToPage,
            object: nil
        )

        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(book: book)
    }

    class Coordinator: NSObject {
        let book: Book
        weak var pdfView: PDFView?

        init(book: Book) {
            self.book = book
        }

        @objc func pageChanged(_ notification: Notification) {
            guard let pdfView = notification.object as? PDFView,
                  let currentPage = pdfView.currentPage,
                  let pageIndex = pdfView.document?.index(for: currentPage) else { return }
            book.readingProgress = pageIndex
            NotificationCenter.default.post(
                name: .currentPageChanged,
                object: nil,
                userInfo: ["page": pageIndex]
            )
        }

        @objc func goToPage(_ notification: Notification) {
            guard let page = notification.userInfo?["page"] as? Int,
                  let pdfView = pdfView,
                  let pdfPage = pdfView.document?.page(at: page) else { return }
            pdfView.go(to: pdfPage)
        }
    }
}
