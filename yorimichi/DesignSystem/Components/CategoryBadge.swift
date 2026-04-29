import SwiftUI

struct CategoryBadge: View {
    let category: Category

    var body: some View {
        Label(category.displayName, systemImage: category.icon)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(.white)
            .background(DesignTokens.Accent.primary)
            .clipShape(Capsule())
    }
}

#Preview {
    HStack {
        CategoryBadge(category: .cafe)
        CategoryBadge(category: .restaurant)
        CategoryBadge(category: .scene)
    }
}
