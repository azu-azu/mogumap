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
}
