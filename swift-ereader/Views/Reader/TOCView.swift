import SwiftUI
import ReadiumShared

struct TOCView: View {
    let publication: Publication
    var onSelect: (ReadiumShared.Link) -> Void
    @State private var links: [ReadiumShared.Link] = []

    var body: some View {
        NavigationView {
            List(links, id: \.href) { link in
                Button {
                    onSelect(link)
                } label: {
                    Text(link.title ?? "Untitled")
                }
            }
            .navigationTitle("Table of Contents")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                if let result = try? await publication.tableOfContents().get() {
                    links = result
                }
            }
        }
    }
}
