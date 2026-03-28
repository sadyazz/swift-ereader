import SwiftUI
import UniformTypeIdentifiers
struct LibraryView: View{
    @State private var books: [Book] = []
    @State private var showAsList = false

    var body: some View {
        NavigationView {
            Group {
                if(books.isEmpty) {
                    VStack(spacing: 16) {
                        Image(systemName: "books.vertical")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("Your library is empty")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Tap + to add your first book")
                        .font(Font.body)
                        .foregroundColor(Color.secondary)
                    }
                } else {
                    ScrollView {
                        if showAsList {
                            LazyVStack(spacing: 0) {
                                ForEach(books) { book in 
                                    NavigationLink(destination: PDFReaderView(book: book)) {
                                        HStack(spacing: 12) {
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color.gray.opacity(0.3))
                                                .frame(width: 40, height: 60)
                                                .overlay(
                                                    Image(systemName: "book.fill")
                                                        .font(.system(size: 16))
                                                        .foregroundColor(.gray)
                                                )
                                            Text(book.title)
                                                .font(.body)
                                                .lineLimit(1)
                                            Spacer()
                                        }
                                        .padding(.horizontal)
                                        .padding(.vertical, 8)
                                    }
                                    Divider()
                                }
                            }
                        } else {
                            LazyVGrid(columns: [
                                GridItem(.adaptive(minimum: 120))
                            ], spacing: 20) {
                                ForEach(books) { book in 
                                    NavigationLink(destination: PDFReaderView(book: book)) {
                                        BookGridItem(book: book)
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAsList.toggle() }) {
                        Image(systemName: showAsList ? "square.grid.2x2" : "list.bullet")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: addBook) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }

    private func addBook() {
        print("🟡 addBook() called")
        openDocumentPicker { urls in
            print("🟢 onPick callback with \(urls.count) URLs")
            for url in urls {
                let book = Book(
                    title: url.deletingPathExtension().lastPathComponent,
                    coverImage: nil,
                    fileURL: url,
                    dateAdded: Date()
                )
                books.append(book)
                print("📚 Added book: \(book.title), total: \(books.count)")
            }
        }
    }
}

#Preview {
    LibraryView()
}
