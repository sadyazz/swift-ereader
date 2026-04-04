import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            LibraryView()
                .tabItem {
                    Image(systemName: "books.vertical")
                    Text("Library")
                }

            CollectionsView()
                .tabItem {
                    Image(systemName: "folder")
                    Text("Collections")
                }

            StatsView()
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("Stats")
                }
        }
    }
}
