import SwiftUI

struct ContentView: View {
    @State private var appState = AppState()

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            NavigationStack {
                LogListView()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(AppState.Tab.home)

            NavigationStack {
                MapTabView()
            }
            .tabItem {
                Label("Map", systemImage: "map.fill")
            }
            .tag(AppState.Tab.map)

            NavigationStack {
                TimelineView()
            }
            .tabItem {
                Label("Timeline", systemImage: "clock.fill")
            }
            .tag(AppState.Tab.timeline)
        }
        .environment(appState)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [PlaceLog.self, PhotoAttachment.self], inMemory: true)
}
