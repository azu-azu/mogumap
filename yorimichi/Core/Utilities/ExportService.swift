import Foundation
import ZIPFoundation

// MARK: - ExportService

enum ExportService {

    enum Option {
        /// Export logs.json + all photo JPEG files as a ZIP.
        case withPhotos
        /// Export logs.json only. Photo metadata (isReceipt, sortOrder) is still
        /// included in JSON; image files are omitted. Lighter, AI-friendly.
        case jsonOnly
    }

    // MARK: - Public API

    /// Build the export ZIP and return its URL in the temp directory.
    /// Must be called on the MainActor because it reads SwiftData model objects.
    @MainActor
    static func export(logs: [PlaceLog], option: Option) throws -> URL {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory

        // Unique work directory for this export run
        let workDir = tempDir.appendingPathComponent("yorimichi-export-\(UUID().uuidString)")
        try fm.createDirectory(at: workDir, withIntermediateDirectories: true)

        var cleanupNeeded = true
        defer {
            if cleanupNeeded {
                try? fm.removeItem(at: workDir)
            }
        }

        // Build export model + optionally write photo files
        let exportLogs: [ExportLog] = try logs.map { log in
            try buildExportLog(log: log, workDir: workDir, option: option, fm: fm)
        }

        // Encode manifest JSON
        let manifest = ExportManifest(
            exportedAt: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            logs: exportLogs
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(manifest)
        try jsonData.write(to: workDir.appendingPathComponent("logs.json"))

        // Create ZIP
        let zipURL = try createZip(from: workDir, tempDir: tempDir, fm: fm)

        cleanupNeeded = false
        try fm.removeItem(at: workDir)
        return zipURL
    }

    // MARK: - Private helpers

    private static func buildExportLog(
        log: PlaceLog,
        workDir: URL,
        option: Option,
        fm: FileManager
    ) throws -> ExportLog {
        let sortedPhotos = log.photos.sorted { $0.sortOrder < $1.sortOrder }
        var exportPhotos: [ExportPhoto] = []

        let photoDir = workDir
            .appendingPathComponent("photos")
            .appendingPathComponent(log.id.uuidString)
        if option == .withPhotos && !sortedPhotos.isEmpty {
            try fm.createDirectory(at: photoDir, withIntermediateDirectories: true)
        }

        for (index, photo) in sortedPhotos.enumerated() {
            let filename = "\(index).jpg"
            exportPhotos.append(ExportPhoto(
                filename: filename,
                isReceipt: photo.isReceipt,
                sortOrder: photo.sortOrder
            ))

            if option == .withPhotos {
                try photo.imageData.write(to: photoDir.appendingPathComponent(filename))
            }
        }

        return ExportLog(
            id: log.id.uuidString,
            date: log.date,
            placeName: log.placeName,
            category: log.category,
            address: log.address,
            latitude: log.latitude,
            longitude: log.longitude,
            memo: log.memo,
            rating: log.rating,
            impression: log.impression,
            isFavorite: log.isFavorite,
            price: log.price,
            createdAt: log.createdAt,
            updatedAt: log.updatedAt,
            photos: exportPhotos
        )
    }

    private static func createZip(from workDir: URL, tempDir: URL, fm: FileManager) throws -> URL {
        let dateTag = ISO8601DateFormatter().string(from: Date()).prefix(10) // "2026-05-18"
        let zipURL = tempDir.appendingPathComponent("yorimichi-\(dateTag).zip")

        if fm.fileExists(atPath: zipURL.path) {
            try fm.removeItem(at: zipURL)
        }

        // shouldKeepParent: false → contents sit at ZIP root, not inside a subdirectory
        try fm.zipItem(at: workDir, to: zipURL, shouldKeepParent: false)
        return zipURL
    }
}
