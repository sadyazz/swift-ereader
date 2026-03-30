import SwiftUI
import PDFKit
import SwiftData

struct PDFReaderView: View {
    @Environment(\.modelContext) private var modelContext
    let book: Book

    var body: some View {
        PDFKitView(book: book)
            .navigationTitle(book.title)
            .navigationBarTitleDisplayMode(.inline)
            .onDisappear {
                try? modelContext.save()
            }
    }
}

struct PDFKitView: UIViewRepresentable {
    let book: Book

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.document = PDFDocument(url: book.fileURL)

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

        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(book: book)
    }

    class Coordinator: NSObject {
        let book: Book

        init(book: Book) {
            self.book = book
        }

        @objc func pageChanged(_ notification: Notification) {
            guard let pdfView = notification.object as? PDFView,
                  let currentPage = pdfView.currentPage,
                  let pageIndex = pdfView.document?.index(for: currentPage) else { return }
            book.readingProgress = pageIndex
        }
    }
}
