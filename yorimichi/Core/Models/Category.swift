import Foundation
import MapKit

enum Category: String, CaseIterable, Identifiable, Codable {
    case cafe
    case restaurant
    case travel
    case walk
    case event
    case shop
    case temple
    case museum
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cafe: "Cafe"
        case .restaurant: "Restaurant"
        case .travel: "Travel"
        case .walk: "Walk"
        case .event: "Event"
        case .shop: "Shop"
        case .temple: "Temple"
        case .museum: "Museum"
        case .other: "Other"
        }
    }

    var icon: String {
        switch self {
        case .cafe: "cup.and.saucer.fill"
        case .restaurant: "fork.knife"
        case .travel: "airplane"
        case .walk: "figure.walk"
        case .event: "star.fill"
        case .shop: "bag.fill"
        case .temple: "building.columns.fill"
        case .museum: "building.2.fill"
        case .other: "mappin.circle.fill"
        }
    }

    static func from(poiCategory: MKPointOfInterestCategory?) -> Category {
        guard let poi = poiCategory else { return .other }
        switch poi {
        case .cafe: return .cafe
        case .restaurant: return .restaurant
        case .store: return .shop
        case .museum: return .museum
        default: return .other
        }
    }
}
