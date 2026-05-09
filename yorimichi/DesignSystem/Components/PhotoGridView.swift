import SwiftUI

struct PhotoGridView: View {
    let photos: [PhotoAttachment]
    let columns: Int

    init(photos: [PhotoAttachment], columns: Int = 3) {
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
                    ZStack(alignment: .bottomTrailing) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(minHeight: 100)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        if photo.isReceipt {
                            Image(systemName: "doc.text.fill")
                                .font(.caption2)
                                .foregroundStyle(.white)
                                .padding(4)
                                .background(DesignTokens.Accent.primary)
                                .clipShape(Circle())
                                .offset(x: -4, y: -4)
                        }
                    }
                }
            }
        }
    }
}
