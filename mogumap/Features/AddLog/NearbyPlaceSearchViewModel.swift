@preconcurrency import MapKit
import Observation

@Observable
@MainActor
final class NearbyPlaceSearchViewModel {
    var results: [MKMapItem] = []
    var searchText = ""
    var isSearching = false

    static let defaultRadius: CLLocationDistance = 500

    private let coordinate: CLLocationCoordinate2D
    private let radius: CLLocationDistance = defaultRadius
    private var searchTask: Task<Void, Never>?

    private static let poiCategories: [MKPointOfInterestCategory] = [
        .cafe, .restaurant, .store, .museum, .bakery, .brewery,
        .foodMarket, .nightlife, .theater, .park,
    ]

    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }

    func searchNearby() async {
        isSearching = true
        let request = MKLocalPointsOfInterestRequest(
            center: coordinate,
            radius: radius
        )
        request.pointOfInterestFilter = MKPointOfInterestFilter(
            including: Self.poiCategories
        )

        do {
            let search = MKLocalSearch(request: request)
            let response = try await search.start()
            results = response.mapItems
        } catch {
            results = []
        }
        isSearching = false
    }

    func onSearchTextChanged() {
        searchTask?.cancel()
        let query = searchText.trimmingCharacters(in: .whitespaces)
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            if query.isEmpty {
                await searchNearby()
            } else {
                await performTextSearch(query: query)
            }
        }
    }

    private func performTextSearch(query: String) async {
        isSearching = true
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: radius * 2,
            longitudinalMeters: radius * 2
        )
        request.resultTypes = .pointOfInterest
        request.pointOfInterestFilter = MKPointOfInterestFilter(
            including: Self.poiCategories
        )

        do {
            let search = MKLocalSearch(request: request)
            let response = try await search.start()
            if !Task.isCancelled {
                results = response.mapItems
            }
        } catch {
            if !Task.isCancelled {
                results = []
            }
        }
        if !Task.isCancelled {
            isSearching = false
        }
    }
}
