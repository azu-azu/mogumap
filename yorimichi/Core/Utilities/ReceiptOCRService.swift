import Vision
import UIKit

struct ReceiptResult {
    var placeName: String?
    var price: Int?
    var date: Date?
    var notes: String

    func apply(
        placeName: inout String,
        priceText: inout String,
        date: inout Date,
        memo: inout String
    ) {
        if let name = self.placeName, placeName.isEmpty { placeName = name }
        if let price = self.price, priceText.isEmpty { priceText = String(price) }
        if let d = self.date { date = d }
        if !notes.isEmpty {
            memo = memo.isEmpty ? notes : memo + "\n" + notes
        }
    }
}

enum ReceiptOCRService {

    private static let dateRegexes: [NSRegularExpression] = [
        #"(\d{4})[/.\-](\d{1,2})[/.\-](\d{1,2})"#,
        #"(\d{4})年(\d{1,2})月(\d{1,2})日"#,
    ].compactMap { try? NSRegularExpression(pattern: $0) }

    private static let timeRegex = try? NSRegularExpression(pattern: #"(\d{1,2}):(\d{2})"#)

    // 合計行: "合計", "税込合計", "TOTAL" 等のキーワード + 金額が同一行
    // 注意: 小計（subtotal）は含めない。小計 ≠ 最終合計
    private static let totalLineRegex = try? NSRegularExpression(
        pattern: #"(合計|税込|TOTAL|Total|お支払|お会計)[^\n¥￥\d]*([¥￥]\s?[\d,]+|[\d,]+\s?円)"#
    )
    // 全金額パターン（件数カウント用）
    private static let anyPriceRegex = try? NSRegularExpression(
        pattern: #"[¥￥]\s?[\d,]+|[\d,]+\s?円"#
    )

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

        // Price detection:
        // 1. 合計/TOTAL キーワード付きの行があればその金額を使う（レシートの合計額）
        // 2. キーワードなし・金額1件のみ → シンプルなレシート/チケット → そのまま使う
        // 3. キーワードなし・金額2件以上 → メニュー扱い → price = nil
        let ns = text as NSString
        let textRange = NSRange(text.startIndex..., in: text)

        let priceCount = Self.anyPriceRegex.map {
            $0.numberOfMatches(in: text, range: textRange)
        } ?? 0

        if let regex = Self.totalLineRegex,
           let match = regex.firstMatch(in: text, range: textRange),
           match.numberOfRanges >= 3 {
            let raw = ns.substring(with: match.range(at: 2))
            let digits = raw.filter(\.isNumber)
            result.price = Int(digits)
        } else if priceCount == 1 {
            if let priceMatch = text.range(of: #"[¥￥]\s?[\d,]+"#, options: .regularExpression) {
                result.price = Int(String(text[priceMatch]).filter(\.isNumber))
            } else if let priceMatch = text.range(of: #"[\d,]+\s?円"#, options: .regularExpression) {
                result.price = Int(String(text[priceMatch]).filter(\.isNumber))
            }
        }
        // priceCount >= 2 かつ合計行なし → メニュー → result.price は nil のまま

        // Date: 2026/05/09, 2026.05.09, 2026-05-09, 2026年5月9日
        for regex in Self.dateRegexes {
            guard let match = regex.firstMatch(in: text, range: textRange),
                  match.numberOfRanges >= 4,
                  let y = Int(ns.substring(with: match.range(at: 1))),
                  let m = Int(ns.substring(with: match.range(at: 2))),
                  let d = Int(ns.substring(with: match.range(at: 3))) else { continue }

            var components = DateComponents()
            components.year = y; components.month = m; components.day = d

            // Time: HH:MM
            if let timeRegex = Self.timeRegex,
               let timeMatch = timeRegex.firstMatch(in: text, range: textRange),
               timeMatch.numberOfRanges >= 3 {
                components.hour = Int(ns.substring(with: timeMatch.range(at: 1)))
                components.minute = Int(ns.substring(with: timeMatch.range(at: 2)))
            }

            result.date = Calendar.current.date(from: components)
            break
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
            let lineRange = NSRange(line.startIndex..., in: line)
            for regex in Self.dateRegexes where regex.firstMatch(in: line, range: lineRange) != nil {
                usedLines.insert(i)
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
