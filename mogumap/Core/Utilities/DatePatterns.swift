import Foundation

/// 日付パターンの共有定義。PlaceInfoParser と ReceiptOCRService で共用。
enum DatePatterns {
    static let regexes: [NSRegularExpression] = [
        #"(\d{4})[/.\-](\d{1,2})[/.\-](\d{1,2})"#,
        #"(\d{4})年(\d{1,2})月(\d{1,2})日"#,
    ].compactMap { try? NSRegularExpression(pattern: $0) }
}
