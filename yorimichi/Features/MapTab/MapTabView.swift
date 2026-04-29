import SwiftUI
import SwiftData
import MapKit

struct MapTabView: View {
    @Query private var logs: [PlaceLog]
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var locationService = LocationService()
    @State private var hasSetInitialZoom = false

    private var logsWithLocation: [PlaceLog] {
        logs.filter { $0.latitude != nil && $0.longitude != nil }
    }

    var body: some View {
        Map(position: $position) {
            UserAnnotation()

            ForEach(logsWithLocation) { log in
                Annotation(log.placeName, coordinate: log.coordinate) {
                    NavigationLink(value: log) {
                        PlaceAnnotationView(log: log)
                    }
                }
            }
        }
        .navigationDestination(for: PlaceLog.self) { log in
            LogDetailView(log: log)
        }
        .task {
            locationService.requestCurrentLocation()
        }
        .onChange(of: locationService.currentLocation?.coordinate.latitude) { _, _ in
            guard !hasSetInitialZoom, let location = locationService.currentLocation else { return }
            hasSetInitialZoom = true
            position = .region(MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: 800,
                longitudinalMeters: 800
            ))
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if let location = locationService.currentLocation {
                        position = .region(MKCoordinateRegion(
                            center: location.coordinate,
                            latitudinalMeters: 800,
                            longitudinalMeters: 800
                        ))
                    }
                } label: {
                    Image(systemName: "location")
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        MapTabView()
    }
    .modelContainer(for: [PlaceLog.self, PhotoAttachment.self], inMemory: true)
}
