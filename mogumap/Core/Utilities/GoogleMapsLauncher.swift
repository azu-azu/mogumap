import UIKit

@MainActor
enum GoogleMapsLauncher {
    private static let defaultZoom = 17

    static func open(latitude: Double, longitude: Double, query: String? = nil) {
        let coordString = "\(latitude),\(longitude)"
        let zoom = defaultZoom

        if let query, let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            tryOpen(
                appURL: "comgooglemaps://?q=\(encoded)&center=\(coordString)&zoom=\(zoom)",
                webURL: "https://www.google.com/maps/search/\(encoded)/@\(coordString),\(zoom)z"
            )
        } else {
            tryOpen(
                appURL: "comgooglemaps://?center=\(coordString)&zoom=\(zoom)",
                webURL: "https://www.google.com/maps/@\(coordString),\(zoom)z"
            )
        }
    }

    static func openCurrentLocation() {
        tryOpen(
            appURL: "comgooglemaps://?center=current&zoom=\(defaultZoom)",
            webURL: "https://www.google.com/maps"
        )
    }

    private static func tryOpen(appURL: String, webURL: String) {
        if let url = URL(string: appURL), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else if let url = URL(string: webURL) {
            UIApplication.shared.open(url)
        }
    }
}
