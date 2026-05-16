import Foundation

struct PasteResult {
    var placeName: String?
    var address: String?
    var price: Int?
    var date: Date?
    var notes: String
}

enum PlaceInfoParser {

    private static let addrRegex = try? NSRegularExpression(
        pattern: #"〒\s?\d{3}-?\d{4}|.+(都|道|府|県).+(市|区|町|村)"#
    )
    private static let dateRegexes: [NSRegularExpression] = [
        #"(\d{4})[/.\-](\d{1,2})[/.\-](\d{1,2})"#,
        #"(\d{4})年(\d{1,2})月(\d{1,2})日"#
    ].compactMap { try? NSRegularExpression(pattern: $0) }

    static func parse(_ text: String) -> PasteResult {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        var result = PasteResult(notes: "")
        var usedIndices: Set<Int> = []

        // Price: ¥1,900 / 1,900円
        let pricePatterns = [#"[¥￥]\s?[\d,]+"#, #"[\d,]+\s?円"#]
        for pattern in pricePatterns {
            if let match = text.range(of: pattern, options: .regularExpression) {
                let digits = String(text[match]).filter(\.isNumber)
                if let p = Int(digits), p > 0 {
                    result.price = p
                    break
                }
            }
        }

        // Date: 2026/05/09, 2026年5月9日
        let ns = text as NSString
        let textRange = NSRange(text.startIndex..., in: text)
        for regex in Self.dateRegexes {
            guard let match = regex.firstMatch(in: text, range: textRange),
                  match.numberOfRanges >= 4,
                  let y = Int(ns.substring(with: match.range(at: 1))),
                  let m = Int(ns.substring(with: match.range(at: 2))),
                  let d = Int(ns.substring(with: match.range(at: 3))) else { continue }
            var comps = DateComponents()
            comps.year = y; comps.month = m; comps.day = d
            result.date = Calendar.current.date(from: comps)
            break
        }

        // Address: line with 〒 or prefecture+city pattern
        for (i, line) in lines.enumerated() {
            guard let regex = Self.addrRegex,
                  regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) != nil
            else { continue }
            // Strip "住所: " prefix if present
            let cleaned = line.replacingOccurrences(
                of: #"^(住所|所在地)[:：\s]+"#, with: "", options: .regularExpression
            ).trimmingCharacters(in: .whitespaces)
            result.address = cleaned
            usedIndices.insert(i)
            break
        }

        // Mark price/date lines as used
        for (i, line) in lines.enumerated() {
            if result.price != nil,
               line.range(of: #"[¥￥][\d,\s]+|[\d,]+\s?円"#, options: .regularExpression) != nil {
                usedIndices.insert(i)
            }
            let lineRange = NSRange(line.startIndex..., in: line)
            for regex in Self.dateRegexes where regex.firstMatch(in: line, range: lineRange) != nil {
                usedIndices.insert(i)
            }
        }

        // PlaceName: first meaningful non-URL line not yet used
        for (i, line) in lines.enumerated() where !usedIndices.contains(i) {
            guard !isURLLike(line), line.count >= 2 else { continue }
            result.placeName = stripSiteSuffix(line)
            usedIndices.insert(i)
            break
        }

        // Notes: remaining non-URL lines
        let noteLines = lines.enumerated()
            .filter { !usedIndices.contains($0.offset) && !isURLLike($0.element) }
            .map(\.element)
        result.notes = noteLines.joined(separator: " / ")

        return result
    }

    // "店名 | サイト名" → "店名"
    private static func stripSiteSuffix(_ line: String) -> String {
        for sep in [" | ", " ｜ ", "｜"] {
            if let range = line.range(of: sep) {
                return String(line[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
            }
        }
        return line
    }

    private static func isURLLike(_ string: String) -> Bool {
        string.hasPrefix("http://") || string.hasPrefix("https://") || string.contains("www.")
    }
}
