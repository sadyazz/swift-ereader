import SwiftUI
import PDFKit

struct PDFReaderView: View {
    let book: Book

    var body: some View {
        PDFKitView(url: book.fileURL)
            .navigationTitle(book.title)
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct PDFKitView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.document = PDFDocument(url: url)
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context){

    }
}