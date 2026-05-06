import Foundation
import SwiftData

@Model
final class PhotoAttachment {
    var id: UUID

    @Attribute(.externalStorage)
    var imageData: Data

    var sortOrder: Int
    var isReceipt: Bool
    var createdAt: Date
    var placeLog: PlaceLog?

    init(imageData: Data, sortOrder: Int = 0, isReceipt: Bool = false) {
        self.id = UUID()
        self.imageData = imageData
        self.sortOrder = sortOrder
        self.isReceipt = isReceipt
        self.createdAt = Date()
    }
}
