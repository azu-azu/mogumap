import SwiftUI

struct PlaceAnnotationView: View {
    let log: PlaceLog

    var body: some View {
        let cat = Category(rawValue: log.category) ?? .other
        let imp = log.impression.flatMap(Impression.init(rawValue:))

        VStack(spacing: 0) {
            VStack(spacing: DesignTokens.Spacing.xs / 2) {
                Image(systemName: cat.icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)

                Text(log.placeName)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .frame(maxWidth: 72)
            }
            .padding(.horizontal, DesignTokens.Spacing.sm)
            .padding(.vertical, DesignTokens.Spacing.md / 2)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(DesignTokens.Accent.primary)
            )
            .overlay(alignment: .topTrailing) {
                if let imp {
                    Text(imp.emoji)
                        .font(.system(size: 10))
                        .offset(x: 6, y: -6)
                }
            }

            Image(systemName: "triangle.fill")
                .font(.system(size: 10))
                .foregroundStyle(DesignTokens.Accent.primary)
                .rotationEffect(.degrees(180))
                .offset(y: -2)
        }
    }
}
