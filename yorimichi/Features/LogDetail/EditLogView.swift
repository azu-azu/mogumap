import SwiftUI
import SwiftData
import PhotosUI

struct EditLogView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var log: PlaceLog

    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var newPhotoDataList: [Data] = []
    @State private var showCamera = false
    @State private var showThoughtsEditor = false

    var body: some View {
        List {
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
                    maxSelectionCount: PhotoLoader.maxSelectionCount,
                    matching: .images
                ) {
                    Label("Add Photos", systemImage: "photo.on.rectangle.angled")
                }
                .onChange(of: selectedPhotos) { _, newItems in
                    Task { await loadPhotos(from: newItems) }
                }

                Button {
                    showCamera = true
                } label: {
                    Label("Take Photo", systemImage: "camera")
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

            Section("Impression") {
                Picker("Impression", selection: impressionBinding) {
                    ForEach(Impression.allCases) { imp in
                        Text("\(imp.emoji) \(imp.displayName)")
                            .tag(imp)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Thoughts (free log)") {
                Button {
                    showThoughtsEditor = true
                } label: {
                    Text(log.memo.isEmpty ? "Tap to write..." : log.memo)
                        .foregroundStyle(log.memo.isEmpty ? .secondary : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(3)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            Section {
                Toggle("Favorite", isOn: $log.isFavorite)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(DesignTokens.Background.base.ignoresSafeArea())
        .navigationTitle("Edit")
        .navigationBarTitleDisplayMode(.inline)
        .keyboardCloseToolbar()
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    saveChanges()
                }
            }
        }
        .sheet(isPresented: $showThoughtsEditor) {
            FullTextEditorSheet(text: $log.memo)
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView { imageData in
                newPhotoDataList.append(imageData)
            }
        }
    }

    private var impressionBinding: Binding<Impression> {
        Binding(
            get: { log.impression.flatMap(Impression.init(rawValue:)) ?? .neutral },
            set: { log.impression = $0.rawValue }
        )
    }

    private var categoryBinding: Binding<Category> {
        Binding(
            get: { Category(rawValue: log.category) ?? .other },
            set: { log.category = $0.rawValue }
        )
    }

    private func loadPhotos(from items: [PhotosPickerItem]) async {
        newPhotoDataList = await PhotoLoader.loadJPEGData(from: items)
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
