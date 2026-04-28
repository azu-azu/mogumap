import Foundation
import SwiftData

@Model
final class PhotoAttachment {
    var id: UUID

    @Attribute(.externalStorage)
    var imageData: Data

    var sortOrder: Int
    var createdAt: Date
    var placeLog: PlaceLog?

    init(imageData: Data, sortOrder: Int = 0) {
        self.id = UUID()
        self.imageData = imageData
        self.sortOrder = sortOrder
        self.createdAt = Date()
    }
}
