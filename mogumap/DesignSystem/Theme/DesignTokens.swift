import SwiftUI

enum DesignTokens {

    // MARK: - Spacing

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
    }

    // MARK: - Accent

    enum Accent {
        static let primary = Color(hex: "#C67B4E")
    }

    // MARK: - Background

    enum Background {
        static let base = Color("BackgroundBase")
        static let card = Color("BackgroundCard")
        static let formCell = Color("BackgroundFormCell")
    }

    // MARK: - Text

    enum Text {
        static let secondary = Color("TextSecondary")
    }

    // MARK: - Semantic

    enum Semantic {
        static let good = Color(hex: "#6B8E5A")
        static let neutral = Color(hex: "#9A8F84")
        static let bad = Color(hex: "#B85C4A")
    }
}
