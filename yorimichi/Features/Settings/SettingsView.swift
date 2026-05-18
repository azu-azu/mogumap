import SwiftUI

struct SettingsView: View {
    var body: some View {
        List {
            Section {
                NavigationLink {
                    LanguageSettingsView()
                } label: {
                    Label("settings.language.title".localized, systemImage: "globe")
                }

                NavigationLink {
                    ExportView()
                } label: {
                    Label("nav.export".localized, systemImage: "square.and.arrow.up")
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(DesignTokens.Background.base.ignoresSafeArea())
        .navigationTitle("settings.title".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
