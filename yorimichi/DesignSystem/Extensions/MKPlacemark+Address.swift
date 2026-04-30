import CoreLocation

extension CLPlacemark {
    var formattedAddress: String? {
        let parts = [
            administrativeArea,
            locality,
            subLocality,
            thoroughfare,
            subThoroughfare,
        ].compactMap { $0 }

        return parts.isEmpty ? nil : parts.joined()
    }
}
