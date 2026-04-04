import SwiftUI
import SwiftData

struct CollectionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allBooks: [Book]
    let collection: BookCollection
    @State private var showAddBooks = false

    var books: [Book] {
        allBooks.filter { collection.bookIDs.contains($0.filePath) }
    }

    var body: some View {
        Group {
            if books.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: collection.icon)
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("No books in this collection")
                        .foregroundColor(.secondary)
                    Button("Add Books") {
                        showAddBooks = true
                    }
                }
            } else {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 120))
                    ], spacing: 20) {
                        ForEach(books) { book in
                            NavigationLink(destination: readerView(for: book)) {
                                BookGridItem(book: book)
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    collection.bookIDs.removeAll { $0 == book.filePath }
                                    try? modelContext.save()
                                } label: {
                                    Label("Remove from Collection", systemImage: "minus.circle")
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(collection.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAddBooks = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddBooks) {
            AddBooksToCollectionView(collection: collection)
        }
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

struct AddBooksToCollectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allBooks: [Book]
    let collection: BookCollection

    var body: some View {
        NavigationView {
            List(allBooks) { book in
                HStack {
                    if let coverURL = book.coverURL, let image = UIImage(contentsOfFile: coverURL.path) {
                        Image(uiImage: image)
                            .resizable()
                            .frame(width: 30, height: 45)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    } else {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 30, height: 45)
                    }
                    Text(book.title)
                        .lineLimit(1)
                    Spacer()
                    if collection.bookIDs.contains(book.filePath) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.pink)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if collection.bookIDs.contains(book.filePath) {
                        collection.bookIDs.removeAll { $0 == book.filePath }
                    } else {
                        collection.bookIDs.append(book.filePath)
                    }
                    try? modelContext.save()
                }
            }
            .navigationTitle("Add Books")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
