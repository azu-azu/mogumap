import Vision
import UIKit

struct ReceiptResult {
    var placeName: String?
    var price: Int?
    var date: Date?
    var address: String?
    var notes: String

    func apply(
        placeName: inout String,
        priceText: inout String,
        date: inout Date,
        memo: inout String,
        address: inout String
    ) {
        if let name = self.placeName, placeName.isEmpty { placeName = name }
        if let price = self.price, priceText.isEmpty { priceText = String(price) }
        if let d = self.date { date = d }
        if let addr = self.address, address.isEmpty { address = addr }
        if !notes.isEmpty {
            memo = memo.isEmpty ? notes : memo + "\n" + notes
        }
    }
}

enum ReceiptOCRService {

    private static var dateRegexes: [NSRegularExpression] { DatePatterns.regexes }

    private static let timeRegex = try? NSRegularExpression(pattern: #"(\d{1,2}):(\d{2})"#)

    // Tier 1: 合計系キーワード（最優先。お支払より先に出るため lastMatch が正しい）
    // 注意: 小計（subtotal）は含めない
    private static let tier1TotalRegex = try? NSRegularExpression(
        pattern: #"(合計|税込|TOTAL|Total|合計金額)[^\n¥￥\d]*([¥￥]\s?[\d,]+|[\d,]+\s?円)"#
    )
    private static let tier1KeywordRegex = try? NSRegularExpression(
        pattern: #"合計|税込|TOTAL|Total|合計金額"#
    )
    // Tier 2: 支払系キーワード（Tier 1 で見つからない時だけ使う）
    // "金額" 単体は最も generic なので最後尾
    private static let tier2TotalRegex = try? NSRegularExpression(
        pattern: #"(お支払|お会計|請求額|支払金額|請求金額|金額)[^\n¥￥\d]*([¥￥]\s?[\d,]+|[\d,]+\s?円)"#
    )
    private static let tier2KeywordRegex = try? NSRegularExpression(
        pattern: #"お支払|お会計|請求額|支払金額|請求金額|金額"#
    )
    // 全金額パターン（件数カウント用）
    private static let anyPriceRegex = try? NSRegularExpression(
        pattern: #"[¥￥]\s?[\d,]+|[\d,]+\s?円"#
    )
    // 住所: 〒郵便番号 or 都道府県＋市区町村
    private static let addrRegex = try? NSRegularExpression(
        pattern: #"〒\s?\d{3}-?\d{4}|.+(都|道|府|県).+(市|区|町|村)"#
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
        // 1. Tier1（合計系）: 合計・税込・TOTAL → lastMatch（同一行 or 次行）
        // 2. Tier2（支払系）: お支払・請求額・金額 → Tier1 で見つからない時だけ
        // 3. 金額1件のみ → シンプルなレシート/チケット → そのまま使う
        // 4. 金額2件以上 かつ キーワードなし → メニュー扱い → price = nil
        let ns = text as NSString
        let textRange = NSRange(text.startIndex..., in: text)

        let priceCount = Self.anyPriceRegex.map {
            $0.numberOfMatches(in: text, range: textRange)
        } ?? 0

        // Tier 1: 合計系（同一行）
        if let regex = Self.tier1TotalRegex {
            let matches = regex.matches(in: text, range: textRange)
            if let match = matches.last, match.numberOfRanges >= 3 {
                result.price = Int(ns.substring(with: match.range(at: 2)).filter(\.isNumber))
            }
        }
        // 価格のみからなる行のインデックスを一度だけ収集（tier 1/2 で共用）
        // "価格だけの行" = ¥XXXX 単体、または XXXX円 単体（他のテキストが混在しない）
        let priceOnlyIndices = lines.indices.filter { i in
            let l = lines[i].trimmingCharacters(in: .whitespaces)
            return l.range(of: #"^[¥￥]\s?[\d,]+(内)?$"#, options: .regularExpression) != nil
                || l.range(of: #"^[\d,]+\s?円$"#, options: .regularExpression) != nil
        }

        // キーワード行の後の最初の価格のみ行を返す helper
        // 間に何行あっても対応（OCR が列単位で observation を返す場合も含む）
        func nearestPriceOnlyLine(afterKeyword keyRegex: NSRegularExpression) -> Int? {
            for (i, line) in lines.enumerated().reversed() {
                let lr = NSRange(line.startIndex..., in: line)
                guard keyRegex.firstMatch(in: line, range: lr) != nil else { continue }
                if let idx = priceOnlyIndices.first(where: { $0 > i }),
                   let m = lines[idx].range(of: #"[\d,]+"#, options: .regularExpression) {
                    return Int(String(lines[idx][m]).filter(\.isNumber))
                }
                break
            }
            return nil
        }

        // Tier 1: 合計系（分離 OCR 分割）
        if result.price == nil, let keyRegex = Self.tier1KeywordRegex {
            result.price = nearestPriceOnlyLine(afterKeyword: keyRegex)
        }
        // Tier 2: 支払系（同一行）
        if result.price == nil, let regex = Self.tier2TotalRegex {
            let matches = regex.matches(in: text, range: textRange)
            if let match = matches.last, match.numberOfRanges >= 3 {
                result.price = Int(ns.substring(with: match.range(at: 2)).filter(\.isNumber))
            }
        }
        // Tier 2: 支払系（分離 OCR 分割）
        if result.price == nil, let keyRegex = Self.tier2KeywordRegex {
            result.price = nearestPriceOnlyLine(afterKeyword: keyRegex)
        }
        if result.price == nil && priceCount == 1 {
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

        // Address: 〒郵便番号 or 都道府県＋市区町村パターン
        if let regex = Self.addrRegex {
            for (i, line) in lines.enumerated() {
                let lineRange = NSRange(line.startIndex..., in: line)
                guard regex.firstMatch(in: line, range: lineRange) != nil else { continue }
                result.address = line
                usedLines.insert(i)
                break
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
