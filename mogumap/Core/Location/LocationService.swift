import CoreLocation
import Observation

@Observable
@MainActor
final class LocationService: NSObject, CLLocationManagerDelegate {
    var currentLocation: CLLocation?
    var locationVersion = 0
    private(set) var locationError: Error?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var permissionRequested = false

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    /// permission ダイアログを求めた後、ユーザーが "Ask Next Time" を選んだ状態
    var isDeclinedForNow: Bool {
        permissionRequested && authorizationStatus == .notDetermined
    }

    func requestPermission() {
        permissionRequested = true
        manager.requestWhenInUseAuthorization()
    }

    func requestCurrentLocation() {
        requestPermission()
        manager.requestLocation()
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        let location = locations.last
        Task { @MainActor in
            self.currentLocation = location
            self.locationVersion += 1
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        Task { @MainActor in
            self.locationError = error
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.requestLocation()
        }
        Task { @MainActor in
            self.authorizationStatus = status
        }
    }
}
