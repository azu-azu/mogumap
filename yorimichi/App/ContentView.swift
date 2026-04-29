import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                LogListView()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }

            NavigationStack {
                MapTabView()
            }
            .tabItem {
                Label("Map", systemImage: "map.fill")
            }

            NavigationStack {
                TimelineView()
            }
            .tabItem {
                Label("Timeline", systemImage: "clock.fill")
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [PlaceLog.self, PhotoAttachment.self], inMemory: true)
}
