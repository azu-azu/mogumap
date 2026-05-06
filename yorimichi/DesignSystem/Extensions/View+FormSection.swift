import SwiftUI

struct FormSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            content()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(DesignTokens.Background.formCell)
                )
        }
    }
}
