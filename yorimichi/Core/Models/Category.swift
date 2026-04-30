import MapKit

enum Category: String, CaseIterable, Identifiable, Codable {
    case cafe
    case restaurant
    case scene
    case shop
    case temple
    case museum
    case event
    case hotel
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cafe: "Cafe"
        case .restaurant: "Restaurant"
        case .scene: "Scene"
        case .shop: "Shop"
        case .temple: "Temple"
        case .museum: "Museum"
        case .event: "Event"
        case .hotel: "Hotel"
        case .other: "Other"
        }
    }

    var icon: String {
        switch self {
        case .cafe: "cup.and.saucer.fill"
        case .restaurant: "fork.knife"
        case .scene: "sun.and.horizon.fill"
        case .shop: "bag.fill"
        case .temple: "building.columns.fill"
        case .museum: "building.2.fill"
        case .event: "star.fill"
        case .hotel: "bed.double.fill"
        case .other: "mappin.circle.fill"
        }
    }

    static func from(poiCategory: MKPointOfInterestCategory?) -> Category {
        guard let poi = poiCategory else { return .other }
        switch poi {
        case .cafe, .bakery:                    return .cafe
        case .restaurant, .brewery, .winery:    return .restaurant
        case .store, .foodMarket:               return .shop
        case .museum:                           return .museum
        case .hotel:                            return .hotel
        case .park, .beach, .nationalPark:      return .scene
        case .theater, .nightlife, .stadium:    return .event
        default:                                return .other
        }
    }
}
