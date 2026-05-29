import CoreLocation
import Foundation

enum GoogleMapsURLParser {
    static let pinpointRadius: CLLocationDistance = 100

    struct Result {
        let coordinate: CLLocationCoordinate2D
        let placeName: String?
    }

    static func isGoogleMapsURL(_ text: String) -> Bool {
        text.contains("google.com/maps") || text.contains("goo.gl/maps") || text.contains("maps.app.goo.gl")
    }

    static func isShortURL(_ text: String) -> Bool {
        text.contains("goo.gl/maps") || text.contains("maps.app.goo.gl")
    }

    static func parse(_ text: String) -> Result? {
        guard isGoogleMapsURL(text) else { return nil }

        // Pattern: /@LAT,LNG or @LAT,LNG
        if let match = text.range(of: #"@(-?\d+\.\d+),(-?\d+\.\d+)"#, options: .regularExpression) {
            let matched = String(text[match])
            let parts = matched.dropFirst().split(separator: ",")
            if parts.count >= 2,
               let lat = Double(parts[0]),
               let lng = Double(parts[1]) {
                let placeName = extractPlaceName(from: text)
                return Result(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng), placeName: placeName)
            }
        }

        // Pattern: ?q=LAT,LNG
        if let match = text.range(of: #"[?&]q=(-?\d+\.\d+),(-?\d+\.\d+)"#, options: .regularExpression) {
            let matched = String(text[match])
            let numPart = matched.split(separator: "=").last ?? ""
            let parts = numPart.split(separator: ",")
            if parts.count >= 2,
               let lat = Double(parts[0]),
               let lng = Double(parts[1]) {
                return Result(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng), placeName: nil)
            }
        }

        return nil
    }

    private static func extractPlaceName(from url: String) -> String? {
        // Pattern: /place/PLACE_NAME/@
        guard let match = url.range(of: #"/place/([^/@]+)/@"#, options: .regularExpression) else {
            return nil
        }
        let segment = String(url[match])
            .replacingOccurrences(of: "/place/", with: "")
            .replacingOccurrences(of: "/@", with: "")
            .replacingOccurrences(of: "+", with: " ")
            .removingPercentEncoding
        return segment?.isEmpty == false ? segment : nil
    }
}
