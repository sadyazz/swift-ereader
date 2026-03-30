import SwiftUI
import UniformTypeIdentifiers
import SwiftData

struct LibraryView: View{
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Book.dateAdded, order: .reverse) private var books: [Book]
    @State private var showAsList = false
    @State private var searchText = ""

    private var filteredBooks: [Book] {
        if searchText.isEmpty {
            return books
        }

        return books.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

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
                                ForEach(filteredBooks) { book in 
                                    NavigationLink(destination: readerView(for: book)) {
                                        HStack(spacing: 12) {
                                            if let coverURL = book.coverURL, let image = UIImage(contentsOfFile: coverURL.path) {
                                                Image(uiImage: image)
                                                    .resizable()
                                                    .frame(width: 40, height: 60)
                                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                            } else {
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(Color.gray.opacity(0.3))
                                                    .frame(width: 40, height: 60)
                                                    .overlay(
                                                        Image(systemName: "book.fill")
                                                            .font(.system(size: 16))
                                                            .foregroundColor(.gray)
                                                    )
                                            }
                                            Text(book.title)
                                                .font(.body)
                                                .lineLimit(1)
                                            Spacer()
                                        }
                                        .padding(.horizontal)
                                        .padding(.vertical, 8)
                                    }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            deleteBook(book)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                    Divider()
                                }
                            }
                        } else {
                            LazyVGrid(columns: [
                                GridItem(.adaptive(minimum: 120))
                            ], spacing: 20) {
                                ForEach(filteredBooks) { book in 
                                    NavigationLink(destination: readerView(for: book)) {
                                        BookGridItem(book: book)
                                    }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            deleteBook(book)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Library")
            .searchable(text: $searchText)
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
        openDocumentPicker { urls in
            DispatchQueue.main.async {
                let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let booksDir = docsDir.appendingPathComponent("Books")
                try? FileManager.default.createDirectory(at: booksDir, withIntermediateDirectories: true)

                for url in urls {
                    let destination = booksDir.appendingPathComponent(url.lastPathComponent)
                    try? FileManager.default.removeItem(at: destination)
                    do {
                        try FileManager.default.copyItem(at: url, to: destination)
                    } catch {
                        print("failed to copy file: \(error)")
                        continue
                    }

                    let book = Book(
                        title: url.deletingPathExtension().lastPathComponent,
                        coverImage: nil,
                        fileURL: destination,
                        dateAdded: Date()
                    )

                    if destination.pathExtension.lowercased() == "pdf" {
                        if let cover = CoverExtractor.extractPDFCover(from: destination) {
                            let coverPath = saveCoverImage(cover, for: book.title)
                            book.coverImage = coverPath
                        }
                    }

                    modelContext.insert(book)
                }
            }
        }
    }

    private func deleteBook(_ book: Book) {
        try? FileManager.default.removeItem(at: book.fileURL)

        if let coverURL = book.coverURL {
            try? FileManager.default.removeItem(at: coverURL)
        }

        modelContext.delete(book)
        try? modelContext.save()
    }

    private func saveCoverImage(_ image: UIImage, for title: String) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.7) else { return nil }
        let filename = title.replacingOccurrences(of: " ", with: "_") + "_cover.jpg"
        let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let coverURL = docsDir.appendingPathComponent(filename)
        try? data.write(to: coverURL)
        return filename
    }

    @ViewBuilder
    private func readerView(for book: Book) -> some View {
        if book.fileURL.pathExtension.lowercased() == "epub" {
            EPUBReaderView(book: book)
        } else {
            PDFReaderView(book: book)
        }
    }
}

#Preview {
    LibraryView()
}
