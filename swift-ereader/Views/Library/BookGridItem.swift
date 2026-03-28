import SwiftUI

struct BookGridItem: View {
    let book: Book

    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .aspectRatio(2/3, contentMode: .fit)
                .overlay(
                    Image(systemName: "book.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Color.gray)
                )

            Text(book.title)
                .font(Font.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(height: 32, alignment: .top)
        }
    }
}