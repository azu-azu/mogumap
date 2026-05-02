import CoreLocation
import Observation

@Observable
@MainActor
final class AppState {
    enum Tab: Int {
        case home = 0
        case map = 1
        case timeline = 2
    }

    var selectedTab = Tab.home
    var mapFocusCoordinate: CLLocationCoordinate2D?
    var mapFocusVersion = 0

    func focusMap(on coordinate: CLLocationCoordinate2D) {
        mapFocusCoordinate = coordinate
        mapFocusVersion += 1
        selectedTab = .map
    }
}
