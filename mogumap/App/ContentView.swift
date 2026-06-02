import SwiftUI

// MARK: - LanguageReloadWrapper
// ContentView からアプリ言語監視の依存を切り離す。
// タブ切り替えアニメーション中に root-level の invalidation が混ざらないようにする。
private struct LanguageReloadWrapper<Content: View>: View {
    @ObservedObject private var languageProvider = LanguageProvider.shared
    let content: () -> Content

    var body: some View {
        content()
            .id(languageProvider.language)
    }
}

// MARK: - ContentView

struct ContentView: View {
    @State private var appState = AppState()

    var body: some View {
        LanguageReloadWrapper {
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
            .fontDesign(.rounded)
        }
        .environment(appState)
        .task {
            appState.locationService.requestCurrentLocation()
        }
        .overlay(alignment: .top) {
            GeometryReader { geo in
                StatusBarView(safeAreaTop: geo.safeAreaInsets.top)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
        .statusBarHidden(true)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [PlaceLog.self, PhotoAttachment.self], inMemory: true)
}
