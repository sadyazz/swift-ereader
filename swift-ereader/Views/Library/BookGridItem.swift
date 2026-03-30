import SwiftUI
import PDFKit

struct BookGridItem: View {
    let book: Book

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .bottom) {
                if let coverURL = book.coverURL, let image = UIImage(contentsOfFile: coverURL.path) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(2/3, contentMode: .fill)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .aspectRatio(2/3, contentMode: .fit)
                        .overlay(
                            Image(systemName: "book.fill")
                                .font(.system(size: 40))
                                .foregroundColor(Color.gray)
                        )
                }

                if let progress = readingProgress, progress > 0 {
                    GeometryReader { geo in
                        VStack {
                            Spacer()
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 3)
                                Rectangle()
                                    .fill(Color.pink)
                                    .frame(width: geo.size.width * progress, height: 3)
                            }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }

            Text(book.title)
                .font(Font.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(height: 32, alignment: .top)
        }
    }

    private var readingProgress: Double? {
        if book.fileURL.pathExtension.lowercased() == "epub" {
            guard let json = book.epubLocator,
                  let data = json.data(using: .utf8),
                  let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let locations = dict["locations"] as? [String: Any],
                  let totalProgression = locations["totalProgression"] as? Double else {
                return nil
            }
            return totalProgression
        }
        guard let page = book.readingProgress,
              let doc = PDFDocument(url: book.fileURL),
              doc.pageCount > 1 else { return nil }
        return Double(page) / Double(doc.pageCount - 1)
    }
}
