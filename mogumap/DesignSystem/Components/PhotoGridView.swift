import SwiftUI

struct PhotoGridView: View {
    let photos: [PhotoAttachment]
    let columns: Int

    @State private var viewingPhoto: UIImage?

    init(photos: [PhotoAttachment], columns: Int = 3) {
        self.photos = photos.sorted { $0.sortOrder < $1.sortOrder }
        self.columns = columns
    }

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: DesignTokens.Spacing.xs), count: columns)
    }

    var body: some View {
        LazyVGrid(columns: gridColumns, spacing: DesignTokens.Spacing.xs) {
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
                            ReceiptBadge()
                                .offset(x: -4, y: -4)
                        }
                    }
                    .onTapGesture {
                        viewingPhoto = uiImage
                    }
                }
            }
        }
        .fullScreenCover(isPresented: Binding(get: { viewingPhoto != nil }, set: { if !$0 { viewingPhoto = nil } })) {
            if let photo = viewingPhoto {
                PhotoViewerSheet(image: photo)
            }
        }
    }
}
