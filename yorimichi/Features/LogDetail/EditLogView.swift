import SwiftUI
import SwiftData
import PhotosUI

struct EditLogView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var log: PlaceLog

    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var newPhotoDataList: [Data] = []

    var body: some View {
        Form {
            Section("Place") {
                TextField("Place name", text: $log.placeName)

                Picker("Category", selection: categoryBinding) {
                    ForEach(Category.allCases) { cat in
                        Label(cat.displayName, systemImage: cat.icon)
                            .tag(cat)
                    }
                }
            }

            Section("Photos") {
                PhotosPicker(
                    selection: $selectedPhotos,
                    maxSelectionCount: 10,
                    matching: .images
                ) {
                    Label("Add Photos", systemImage: "photo.on.rectangle.angled")
                }
                .onChange(of: selectedPhotos) { _, newItems in
                    Task { await loadPhotos(from: newItems) }
                }

                if !log.photos.isEmpty || !newPhotoDataList.isEmpty {
                    PhotoGridView(photos: log.photos)

                    ForEach(newPhotoDataList.indices, id: \.self) { index in
                        if let uiImage = UIImage(data: newPhotoDataList[index]) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 100)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }

            Section("Location") {
                TextField("Address", text: Binding(
                    get: { log.address ?? "" },
                    set: { log.address = $0.isEmpty ? nil : $0 }
                ))
            }

            Section("Date") {
                DatePicker("Date", selection: $log.date, displayedComponents: [.date, .hourAndMinute])
            }

            Section("Rating") {
                RatingView(rating: $log.rating)
            }

            Section("Memo") {
                TextEditor(text: $log.memo)
                    .frame(minHeight: 80)
            }

            Section {
                Toggle("Favorite", isOn: $log.isFavorite)
            }
        }
        .navigationTitle("Edit")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    saveChanges()
                }
            }
        }
    }

    private var categoryBinding: Binding<Category> {
        Binding(
            get: { Category(rawValue: log.category) ?? .other },
            set: { log.category = $0.rawValue }
        )
    }

    private func loadPhotos(from items: [PhotosPickerItem]) async {
        var dataList: [Data] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data),
               let jpeg = uiImage.jpegData(compressionQuality: 0.8) {
                dataList.append(jpeg)
            }
        }
        newPhotoDataList = dataList
    }

    private func saveChanges() {
        log.updatedAt = Date()

        let startIndex = log.photos.count
        for (index, data) in newPhotoDataList.enumerated() {
            let photo = PhotoAttachment(imageData: data, sortOrder: startIndex + index)
            photo.placeLog = log
            modelContext.insert(photo)
        }

        dismiss()
    }
}
