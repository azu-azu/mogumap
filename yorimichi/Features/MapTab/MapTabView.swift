import SwiftUI
import SwiftData
import MapKit

struct MapTabView: View {
    @Query private var logs: [PlaceLog]
    @State private var position: MapCameraPosition = .automatic

    private var logsWithLocation: [PlaceLog] {
        logs.filter { $0.latitude != nil && $0.longitude != nil }
    }

    var body: some View {
        Map(position: $position) {
            ForEach(logsWithLocation) { log in
                Annotation(log.placeName, coordinate: log.coordinate) {
                    NavigationLink(value: log) {
                        PlaceAnnotationView(log: log)
                    }
                }
            }
        }
        .navigationTitle("Map")
        .navigationDestination(for: PlaceLog.self) { log in
            LogDetailView(log: log)
        }
    }
}

#Preview {
    NavigationStack {
        MapTabView()
    }
    .modelContainer(for: [PlaceLog.self, PhotoAttachment.self], inMemory: true)
}
