import Foundation

// MARK: - Export manifest

struct ExportManifest: Codable {
    let version: Int
    let exportedAt: Date
    let appVersion: String
    let logCount: Int
    let logs: [ExportLog]

    init(exportedAt: Date, appVersion: String, logs: [ExportLog]) {
        self.version = 1
        self.exportedAt = exportedAt
        self.appVersion = appVersion
        self.logCount = logs.count
        self.logs = logs
    }
}

// MARK: - Export log (mirrors PlaceLog fields)

struct ExportLog: Codable {
    let id: String
    let date: Date
    let placeName: String
    let category: String
    let address: String?
    let latitude: Double?
    let longitude: Double?
    let memo: String
    let rating: Int
    let impression: String?
    let isFavorite: Bool
    let price: Int?
    let createdAt: Date
    let updatedAt: Date
    let photos: [ExportPhoto]
}

// MARK: - Export photo metadata

/// Photo metadata embedded in JSON.
/// isReceipt and sortOrder are stored here — not inferred from filename —
/// so that restore logic doesn't need to parse filenames.
struct ExportPhoto: Codable {
    /// Relative path from the log's photo directory: "0.jpg", "1.jpg", …
    /// Always present in the JSON even when exporting without photo files,
    /// so a later full export produces consistent filenames.
    let filename: String
    let isReceipt: Bool
    let sortOrder: Int
}
