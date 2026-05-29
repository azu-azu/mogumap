import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case system = "system"
    case ja = "ja"
    case en = "en"

    var id: String { rawValue }

    static let userDefaultsKey = "appLanguage"

    var displayName: String {
        switch self {
        case .system: "settings.language.system".localized(forceLanguage: nil)
        case .ja:     "日本語"
        case .en:     "English"
        }
    }

    var resolvedLanguageCode: String {
        switch self {
        case .system:
            let pref = Locale.preferredLanguages.first ?? "en"
            return pref.hasPrefix("ja") ? "ja" : "en"
        case .ja: return "ja"
        case .en: return "en"
        }
    }
}

final class LanguageProvider: ObservableObject {
    nonisolated(unsafe) static let shared = LanguageProvider()

    @Published var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: AppLanguage.userDefaultsKey)
        }
    }

    private init() {
        if let raw = UserDefaults.standard.string(forKey: AppLanguage.userDefaultsKey),
           let saved = AppLanguage(rawValue: raw) {
            self.language = saved
        } else {
            self.language = .system
        }
    }
}
