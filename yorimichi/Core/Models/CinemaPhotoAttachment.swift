import Foundation
import SwiftData

@Model
final class CinemaPhotoAttachment {
    var id: UUID

    @Attribute(.externalStorage)
    var imageData: Data

    var sortOrder: Int
    var isTicketStub: Bool
    var createdAt: Date
    var cinemaLog: CinemaLog?

    init(imageData: Data, sortOrder: Int = 0, isTicketStub: Bool = false) {
        self.id = UUID()
        self.imageData = imageData
        self.sortOrder = sortOrder
        self.isTicketStub = isTicketStub
        self.createdAt = Date()
    }
}
