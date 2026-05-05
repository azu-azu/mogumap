import Foundation
import SwiftData
import CoreLocation

@Model
final class CinemaLog {
    static let maxRating = 5
    var id: UUID
    var watchedDate: Date

    // — 映画情報 —
    var movieTitle: String
    var screeningStartsAt: Date?
    var screeningEndsAt: Date?

    // — 劇場情報 —
    var theaterName: String?
    var screenName: String?
    var seatNumber: String?
    var latitude: Double?
    var longitude: Double?
    var address: String?

    // — 鑑賞記録 —
    var rating: Int
    var impression: String?
    var memo: String
    var isFavorite: Bool

    // — チケット情報 —
    var price: Int?
    var ticketType: String?

    // — メタ —
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \CinemaPhotoAttachment.cinemaLog)
    var photos: [CinemaPhotoAttachment] = []

    init(
        watchedDate: Date = Date(),
        movieTitle: String = "",
        screeningStartsAt: Date? = nil,
        screeningEndsAt: Date? = nil,
        theaterName: String? = nil,
        screenName: String? = nil,
        seatNumber: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        address: String? = nil,
        rating: Int = 0,
        impression: String? = nil,
        memo: String = "",
        isFavorite: Bool = false,
        price: Int? = nil,
        ticketType: String? = nil
    ) {
        self.id = UUID()
        self.watchedDate = watchedDate
        self.movieTitle = movieTitle
        self.screeningStartsAt = screeningStartsAt
        self.screeningEndsAt = screeningEndsAt
        self.theaterName = theaterName
        self.screenName = screenName
        self.seatNumber = seatNumber
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.rating = min(max(rating, 0), Self.maxRating)
        self.impression = impression
        self.memo = memo
        self.isFavorite = isFavorite
        self.price = price
        self.ticketType = ticketType
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Computed

    var timelineDate: Date {
        screeningStartsAt ?? watchedDate
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

    // MARK: - Methods

    func setRating(_ value: Int) {
        rating = min(max(value, 0), Self.maxRating)
        touch()
    }

    func touch() {
        updatedAt = Date()
    }
}
