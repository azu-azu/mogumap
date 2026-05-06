import SwiftUI

struct CinemaLogRowView: View {
    let log: CinemaLog

    var body: some View {
        HStack(spacing: 12) {
            cinemaIcon

            VStack(alignment: .leading, spacing: 4) {
                Text(log.movieTitle)
                    .font(.body)
                    .fontWeight(.semibold)

                if let theater = log.theaterName, !theater.isEmpty {
                    Text(theater)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if log.rating > 0 {
                    RatingDisplayView(rating: log.rating)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                HStack(spacing: 4) {
                    if let imp = log.impressionType {
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

    private var cinemaIcon: some View {
        Image(systemName: "film.fill")
            .font(.title3)
            .foregroundStyle(.white)
            .frame(width: 36, height: 36)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(DesignTokens.Accent.primary)
            )
    }
}
