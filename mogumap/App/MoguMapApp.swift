import SwiftUI
import SwiftData

@main
struct MoguMapApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [PlaceLog.self, PhotoAttachment.self])
    }
}
