import SwiftUI

struct CinemaPhotoGridView: View {
    let photos: [CinemaPhotoAttachment]
    let columns: Int

    init(photos: [CinemaPhotoAttachment], columns: Int = 3) {
        self.photos = photos.sorted { $0.sortOrder < $1.sortOrder }
        self.columns = columns
    }

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 4), count: columns)
    }

    var body: some View {
        LazyVGrid(columns: gridColumns, spacing: 4) {
            ForEach(photos) { photo in
                if let uiImage = UIImage(data: photo.imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(minHeight: 100)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
}
