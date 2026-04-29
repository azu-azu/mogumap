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
        case .hotel: "Hotel"
        case .scene: "Scene"
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
        case .hotel: "bed.double.fill"
        case .scene: "sun.and.horizon.fill"
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
