import Foundation
import SwiftData
import CoreLocation

@Model
final class PlaceLog {
    var id: UUID
    var date: Date
    var placeName: String
    var category: String
    var latitude: Double?
    var longitude: Double?
    var address: String?
    var memo: String
    var rating: Int
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
        self.rating = rating
        self.isFavorite = isFavorite
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: latitude ?? 0,
            longitude: longitude ?? 0
        )
    }

    var hasLocation: Bool {
        latitude != nil && longitude != nil
    }
}
