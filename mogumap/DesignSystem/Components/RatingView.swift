import SwiftUI

struct RatingView: View {
    @Binding var rating: Int
    var maxRating = 5

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...maxRating, id: \.self) { index in
                Image(systemName: index <= rating ? "star.fill" : "star")
                    .foregroundStyle(index <= rating ? DesignTokens.Accent.primary : DesignTokens.Semantic.neutral.opacity(0.4))
                    .onTapGesture {
                        rating = index == rating ? 0 : index
                    }
            }
        }
        .font(.title3)
    }
}

struct RatingDisplayView: View {
    let rating: Int
    var maxRating = 5

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...maxRating, id: \.self) { index in
                Image(systemName: index <= rating ? "star.fill" : "star")
                    .foregroundStyle(index <= rating ? DesignTokens.Accent.primary : DesignTokens.Semantic.neutral.opacity(0.4))
            }
        }
        .font(.caption)
    }
}

#Preview {
    @Previewable @State var rating = 3
    RatingView(rating: $rating)
}
