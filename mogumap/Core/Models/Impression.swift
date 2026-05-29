import SwiftUI

enum Impression: String, CaseIterable, Identifiable, Codable {
    case good
    case neutral
    case bad

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .good:    "impression.good".localized
        case .neutral: "impression.neutral".localized
        case .bad:     "impression.bad".localized
        }
    }

    var emoji: String {
        switch self {
        case .good: "😊"
        case .neutral: "😐"
        case .bad: "😔"
        }
    }

    var color: Color {
        switch self {
        case .good: DesignTokens.Semantic.good
        case .neutral: DesignTokens.Semantic.neutral
        case .bad: DesignTokens.Semantic.bad
        }
    }
}
