import SwiftUI

struct LogRowView: View {
    let log: PlaceLog

    var body: some View {
        HStack(spacing: 12) {
            categoryIcon

            VStack(alignment: .leading, spacing: 4) {
                Text(log.placeName)
                    .font(.body)
                    .fontWeight(.semibold)

                HStack(spacing: 6) {
                    Text(log.date, format: .dateTime.hour().minute())
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let price = log.price {
                        Text("¥\(price)")
                            .font(.caption)
                            .fontDesign(.monospaced)
                            .foregroundStyle(.secondary)
                    }
                }

                if log.rating > 0 {
                    RatingDisplayView(rating: log.rating)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                HStack(spacing: 4) {
                    if let raw = log.impression, let imp = Impression(rawValue: raw) {
                        Text(imp.emoji)
                            .font(.callout)
                    }
                    if log.isFavorite {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }

                if let firstPhoto = log.photos.min(by: { $0.sortOrder < $1.sortOrder }),
                   let uiImage = UIImage(data: firstPhoto.imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 48, height: 48)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(DesignTokens.Background.card)
                .shadow(color: .black.opacity(0.8), radius: 6, x: 0, y: 3)
        )
    }

    private var categoryIcon: some View {
        let cat = Category(rawValue: log.category) ?? .other
        return Image(systemName: cat.icon)
            .font(.title3)
            .foregroundStyle(.white)
            .frame(width: 36, height: 36)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(DesignTokens.Accent.primary)
            )
    }
}
