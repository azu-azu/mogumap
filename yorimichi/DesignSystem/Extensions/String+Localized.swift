import Foundation

extension String {
    var localized: String {
        localized(forLanguage: LanguageProvider.shared.language.resolvedLanguageCode)
    }

    func localized(forceLanguage: String?) -> String {
        if let lang = forceLanguage {
            return localized(forLanguage: lang)
        }
        return NSLocalizedString(self, comment: "")
    }

    private func localized(forLanguage code: String) -> String {
        guard let path = Bundle.main.path(forResource: code, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return NSLocalizedString(self, comment: "")
        }
        return NSLocalizedString(self, tableName: nil, bundle: bundle, value: "", comment: "")
    }
}
