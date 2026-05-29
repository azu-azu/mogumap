import SwiftUI

struct ReceiptBadge: View {
    var body: some View {
        Image(systemName: "doc.text.fill")
            .font(.caption2)
            .foregroundStyle(.white)
            .padding(4)
            .background(DesignTokens.Accent.primary)
            .clipShape(Circle())
    }
}
