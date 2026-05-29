import SwiftUI
import SwiftData
import MapKit

struct MapTabView: View {
    @Environment(AppState.self) private var appState
    @Query private var logs: [PlaceLog]
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var locationService = LocationService()
    private static let zoomRadius: CLLocationDistance = 800
    @State private var hasSetInitialZoom = false

    private var logsWithLocation: [PlaceLog] {
        logs.filter { $0.latitude != nil && $0.longitude != nil }
    }

    var body: some View {
        Map(position: $position) {
            UserAnnotation()

            ForEach(logsWithLocation) { log in
                if let coordinate = log.coordinate {
                    Annotation(log.placeName, coordinate: coordinate) {
                        NavigationLink(value: log) {
                            PlaceAnnotationView(log: log)
                        }
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
        .onChange(of: appState.mapFocusVersion) { _, _ in
            guard let coord = appState.mapFocusCoordinate else { return }
            hasSetInitialZoom = true
            zoomTo(coord)
            appState.mapFocusCoordinate = nil
        }
        .onChange(of: locationService.locationVersion) { _, _ in
            guard !hasSetInitialZoom, let location = locationService.currentLocation else { return }
            hasSetInitialZoom = true
            zoomTo(location.coordinate)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    GoogleMapsLauncher.openCurrentLocation()
                } label: {
                    Image(systemName: "map")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if let location = locationService.currentLocation {
                        zoomTo(location.coordinate)
                    }
                } label: {
                    Image(systemName: "location")
                }
            }
        }
    }

    private func zoomTo(_ coordinate: CLLocationCoordinate2D) {
        position = .region(MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: Self.zoomRadius,
            longitudinalMeters: Self.zoomRadius
        ))
    }
}

#Preview {
    NavigationStack {
        MapTabView()
    }
    .environment(AppState())
    .modelContainer(for: [PlaceLog.self, PhotoAttachment.self], inMemory: true)
}
