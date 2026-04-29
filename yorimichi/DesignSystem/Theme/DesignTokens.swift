import SwiftUI

enum DesignTokens {

    // MARK: - Accent

    enum Accent {
        static let primary = Color(hex: "#C67B4E")
        static let pressed = Color(hex: "#B06B42")
    }

    // MARK: - Background

    enum Background {
        static let base = Color("BackgroundBase")
        static let card = Color(.systemBackground)
        static let cardSoft = Color("BackgroundCardSoft")
    }

    // MARK: - Text

    enum Text {
        static let primary = Color(hex: "#2F241D")
        static let secondary = Color(hex: "#6E6258")
    }

    // MARK: - Semantic

    enum Semantic {
        static let good = Color(hex: "#6B8E5A")
        static let neutral = Color(hex: "#9A8F84")
        static let bad = Color(hex: "#B85C4A")
    }
}
