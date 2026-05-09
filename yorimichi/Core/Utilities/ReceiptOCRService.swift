import Vision
import UIKit

struct ReceiptResult {
    var placeName: String?
    var price: Int?
    var date: Date?
    var notes: String
}

enum ReceiptOCRService {

    static func recognizeText(from imageData: Data) async -> String? {
        guard let image = UIImage(data: imageData)?.cgImage else { return nil }

        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, _ in
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let text = observations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n")
                continuation.resume(returning: text.isEmpty ? nil : text)
            }
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["ja", "en"]
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: image)
            try? handler.perform([request])
        }
    }

    static func parse(_ text: String) -> ReceiptResult {
        let lines = text.components(separatedBy: .newlines).filter { !$0.isEmpty }
        var result = ReceiptResult(notes: "")
        var usedLines: Set<Int> = []

        // Price: ¥1,900 / ￥1900 / 1,900円
        if let priceMatch = text.range(of: #"[¥￥]\s?[\d,]+"#, options: .regularExpression) {
            let raw = String(text[priceMatch])
            let digits = raw.filter { $0.isNumber }
            result.price = Int(digits)
        } else if let priceMatch = text.range(of: #"[\d,]+\s?円"#, options: .regularExpression) {
            let raw = String(text[priceMatch])
            let digits = raw.filter { $0.isNumber }
            result.price = Int(digits)
        }

        // Date: 2026/05/09, 2026.05.09, 2026-05-09, 2026年5月9日
        let datePatterns = [
            #"(\d{4})[/.\-](\d{1,2})[/.\-](\d{1,2})"#,
            #"(\d{4})年(\d{1,2})月(\d{1,2})日"#,
        ]
        for pattern in datePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               match.numberOfRanges >= 4 {
                let year = Int((text as NSString).substring(with: match.range(at: 1)))
                let month = Int((text as NSString).substring(with: match.range(at: 2)))
                let day = Int((text as NSString).substring(with: match.range(at: 3)))

                if let y = year, let m = month, let d = day {
                    var components = DateComponents()
                    components.year = y
                    components.month = m
                    components.day = d

                    // Time: HH:MM
                    if let timeRegex = try? NSRegularExpression(pattern: #"(\d{1,2}):(\d{2})"#),
                       let timeMatch = timeRegex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
                       timeMatch.numberOfRanges >= 3 {
                        components.hour = Int((text as NSString).substring(with: timeMatch.range(at: 1)))
                        components.minute = Int((text as NSString).substring(with: timeMatch.range(at: 2)))
                    }

                    result.date = Calendar.current.date(from: components)
                    break
                }
            }
        }

        // PlaceName: first line (most receipts/tickets have the venue name on top)
        if let firstLine = lines.first {
            result.placeName = firstLine
            usedLines.insert(0)
        }

        // Mark lines that contain price or date as used
        for (i, line) in lines.enumerated() {
            if result.price != nil && line.range(of: #"[¥￥][\d,\s]+|[\d,]+\s?円"#, options: .regularExpression) != nil {
                usedLines.insert(i)
            }
            for pattern in datePatterns {
                if line.range(of: pattern, options: .regularExpression) != nil {
                    usedLines.insert(i)
                }
            }
        }

        // Notes: everything else
        let noteLines = lines.enumerated()
            .filter { !usedLines.contains($0.offset) }
            .map(\.element)
        result.notes = noteLines.joined(separator: " / ")

        return result
    }
}
