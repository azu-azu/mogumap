import MapKit

enum Category: String, CaseIterable, Identifiable, Codable {
    case cafe
    case restaurant
    case bar
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cafe:       "category.cafe".localized
        case .restaurant: "category.restaurant".localized
        case .bar:        "category.bar".localized
        case .other:      "category.other".localized
        }
    }

    var icon: String {
        switch self {
        case .cafe:       "cup.and.saucer.fill"
        case .restaurant: "fork.knife"
        case .bar:        "wineglass.fill"
        case .other:      "mappin.circle.fill"
        }
    }

    static func from(poiCategory: MKPointOfInterestCategory?) -> Category {
        guard let poi = poiCategory else { return .other }
        switch poi {
        case .cafe, .bakery:                            return .cafe
        case .restaurant, .brewery, .winery:            return .restaurant
        case .nightlife:                                return .bar
        default:                                        return .other
        }
    }
}
