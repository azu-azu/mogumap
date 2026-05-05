import Foundation
import SwiftData
import CoreLocation

@Model
final class PlaceLog {
    static let maxRating = 5
    var id: UUID
    var date: Date
    var placeName: String
    var category: String
    var latitude: Double?
    var longitude: Double?
    var address: String?
    var memo: String
    var rating: Int
    var impression: String?
    var isFavorite: Bool
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \PhotoAttachment.placeLog)
    var photos: [PhotoAttachment] = []

    init(
        date: Date = Date(),
        placeName: String,
        category: String = Category.other.rawValue,
        latitude: Double? = nil,
        longitude: Double? = nil,
        address: String? = nil,
        memo: String = "",
        rating: Int = 0,
        impression: String? = nil,
        isFavorite: Bool = false
    ) {
        self.id = UUID()
        self.date = date
        self.placeName = placeName
        self.category = category
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.memo = memo
        self.rating = min(max(rating, 0), Self.maxRating)
        self.impression = impression
        self.isFavorite = isFavorite
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var hasLocation: Bool {
        latitude != nil && longitude != nil
    }

    var impressionType: Impression? {
        get {
            guard let impression else { return nil }
            return Impression(rawValue: impression)
        }
        set {
            impression = newValue?.rawValue
        }
    }

    func setRating(_ value: Int) {
        rating = min(max(value, 0), Self.maxRating)
        touch()
    }

    func touch() {
        updatedAt = Date()
    }
}
