import UIKit
import PDFKit

class CoverExtractor {
    static func extractPDFCover( from url: URL) -> UIImage? {
        guard let document = PDFDocument(url: url),
            let page = document.page(at: 0) else {
                return nil
            }
            let bounds = page.bounds(for: .mediaBox)
            let renderer = UIGraphicsImageRenderer(size: bounds.size)
            let image = renderer.image { ctx in
                UIColor.white.setFill()
                ctx.fill(bounds)
                ctx.cgContext.translateBy(x: 0, y: bounds.height)
                ctx.cgContext.scaleBy(x: 1, y: -1)
                page.draw(with: .mediaBox, to: ctx.cgContext)
                }
                return image
    }
}