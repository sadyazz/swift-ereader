import SwiftUI

struct LibraryView: View{
    @State private var books: [Book] = []

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
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 120))
                        ], spacing: 20) {
                            ForEach(books) { book in 
                                Text(book.title)
                                }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing){
                    Button(action: addBook) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }

    private func addBook() {
        print("add book tapped")
    }
}

#Preview {
    LibraryView()
}