import SwiftUI
import SwiftData

struct CollectionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BookCollection.dateCreated) private var collections: [BookCollection]
    @State private var showNewCollection = false
    @State private var newCollectionName = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(collections) { collection in
                    NavigationLink(destination: CollectionDetailView(collection: collection)) {
                        HStack(spacing: 12) {
                            Image(systemName: collection.icon)
                                .foregroundColor(.pink)
                                .frame(width: 30)
                            VStack(alignment: .leading) {
                                Text(collection.name)
                                    .font(.body)
                                Text("\(collection.bookIDs.count) books")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        modelContext.delete(collections[index])
                    }
                    try? modelContext.save()
                }
            }
            .navigationTitle("Collections")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showNewCollection = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("New Collection", isPresented: $showNewCollection) {
                TextField("Name", text: $newCollectionName)
                Button("Cancel", role: .cancel) {
                    newCollectionName = ""
                }
                Button("Create") {
                    if !newCollectionName.isEmpty {
                        let collection = BookCollection(name: newCollectionName)
                        modelContext.insert(collection)
                        try? modelContext.save()
                        newCollectionName = ""
                    }
                }
            }
            .overlay {
                if collections.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "folder")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No collections yet")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        Text("Tap + to create one")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}
