import SwiftUI

struct LogRowView: View {
    let log: PlaceLog

    var body: some View {
        HStack(spacing: 12) {
            categoryIcon

            VStack(alignment: .leading, spacing: 4) {
                Text(log.placeName)
                    .font(.body)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    Text(log.date, format: .dateTime.hour().minute())
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let category = Category(rawValue: log.category) {
                        CategoryBadge(category: category)
                    }
                }

                if log.rating > 0 {
                    RatingDisplayView(rating: log.rating)
                }
            }

            Spacer()

            if let raw = log.impression, let imp = Impression(rawValue: raw) {
                Text(imp.emoji)
                    .font(.body)
            }

            if let firstPhoto = log.photos.sorted(by: { $0.sortOrder < $1.sortOrder }).first,
               let uiImage = UIImage(data: firstPhoto.imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            if log.isFavorite {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.red)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }

    private var categoryIcon: some View {
        let cat = Category(rawValue: log.category) ?? .other
        return Image(systemName: cat.icon)
            .font(.title3)
            .foregroundStyle(.tint)
            .frame(width: 32, height: 32)
    }
}
