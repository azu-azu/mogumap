import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                LogListView()
            }
            .tabItem {
                Label("Timeline", systemImage: "clock.fill")
            }

            NavigationStack {
                MapTabView()
            }
            .tabItem {
                Label("Map", systemImage: "map.fill")
            }

            NavigationStack {
                SearchView()
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [PlaceLog.self, PhotoAttachment.self], inMemory: true)
}
