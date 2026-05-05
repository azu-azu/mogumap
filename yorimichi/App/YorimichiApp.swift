import SwiftUI
import SwiftData

@main
struct YorimichiApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
                PlaceLog.self, PhotoAttachment.self,
                CinemaLog.self, CinemaPhotoAttachment.self,
            ])
    }
}
