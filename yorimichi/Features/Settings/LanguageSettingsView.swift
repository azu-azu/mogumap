import SwiftUI

struct LanguageSettingsView: View {
    @ObservedObject private var languageProvider = LanguageProvider.shared

    var body: some View {
        List {
            Section {
                ForEach(AppLanguage.allCases) { lang in
                    Button {
                        languageProvider.language = lang
                    } label: {
                        HStack {
                            Text(lang.displayName)
                                .foregroundStyle(.primary)
                            Spacer()
                            if languageProvider.language == lang {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(DesignTokens.Accent.primary)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(DesignTokens.Background.base.ignoresSafeArea())
        .navigationTitle("settings.language.title".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        LanguageSettingsView()
    }
}
