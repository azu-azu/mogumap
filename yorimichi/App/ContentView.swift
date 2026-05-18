import SwiftUI

struct ContentView: View {
    @State private var appState = AppState()
    @ObservedObject private var languageProvider = LanguageProvider.shared

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            NavigationStack {
                LogListView()
            }
            .tabItem {
                Label("nav.home".localized, systemImage: "house.fill")
            }
            .tag(AppState.Tab.home)

            NavigationStack {
                MapTabView()
            }
            .tabItem {
                Label("nav.map".localized, systemImage: "map.fill")
            }
            .tag(AppState.Tab.map)

            NavigationStack {
                TimelineView()
            }
            .tabItem {
                Label("nav.timeline".localized, systemImage: "clock.fill")
            }
            .tag(AppState.Tab.timeline)
        }
        .id(languageProvider.language)
        .environment(appState)
        .fontDesign(.rounded)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [PlaceLog.self, PhotoAttachment.self], inMemory: true)
}
