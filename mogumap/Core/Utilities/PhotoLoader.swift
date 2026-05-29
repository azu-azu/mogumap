import PhotosUI
import SwiftUI
import UIKit

enum PhotoLoader {
    static let compressionQuality: CGFloat = 0.8
    static let maxSelectionCount = 10

    static func loadJPEGData(from items: [PhotosPickerItem]) async -> [Data] {
        var dataList: [Data] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data),
               let jpeg = uiImage.jpegData(compressionQuality: compressionQuality) {
                dataList.append(jpeg)
            }
        }
        return dataList
    }
}
