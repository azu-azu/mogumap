import SwiftUI

extension View {
    func cardBackground() -> some View {
        self.listRowBackground(
            RoundedRectangle(cornerRadius: 12)
                .fill(DesignTokens.Background.card)
        )
    }

    func formRowBackground() -> some View {
        self.listRowBackground(Color.red)
    }
}
