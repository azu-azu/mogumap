import SwiftUI

enum Impression: String, CaseIterable, Identifiable, Codable {
    case good
    case neutral
    case bad

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .good: "Good"
        case .neutral: "So-so"
        case .bad: "Bad"
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
        case .good: .green
        case .neutral: .orange
        case .bad: .red
        }
    }
}
