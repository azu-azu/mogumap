import SwiftUI
import SwiftData
import PhotosUI

struct AddLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var placeName = ""
    @State private var category: Category = .other
    @State private var date = Date()
    @State private var memo = ""
    @State private var rating = 0
    @State private var latitude: Double?
    @State private var longitude: Double?
    @State private var address: String = ""
    @State private var locationManager = LocationManager()
    @State private var isFetchingLocation = false
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var photoDataList: [Data] = []

    var body: some View {
        NavigationStack {
            Form {
                Section("Place") {
                    TextField("Place name", text: $placeName)

                    Picker("Category", selection: $category) {
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
                        Label("Select Photos", systemImage: "photo.on.rectangle.angled")
                    }
                    .onChange(of: selectedPhotos) { _, newItems in
                        Task { await loadPhotos(from: newItems) }
                    }

                    if !photoDataList.isEmpty {
                        ScrollView(.horizontal) {
                            HStack(spacing: 8) {
                                ForEach(photoDataList.indices, id: \.self) { index in
                                    if let uiImage = UIImage(data: photoDataList[index]) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 80, height: 80)
                                            .clipped()
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                            }
                        }
                    }
                }

                Section("Location") {
                    if let lat = latitude, let lng = longitude {
                        Label(
                            String(format: "%.4f, %.4f", lat, lng),
                            systemImage: "location.fill"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    TextField("Address", text: $address)

                    Button {
                        fetchCurrentLocation()
                    } label: {
                        Label(
                            isFetchingLocation ? "Fetching..." : "Use Current Location",
                            systemImage: "location"
                        )
                    }
                    .disabled(isFetchingLocation)
                }

                Section("Date") {
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }

                Section("Rating") {
                    RatingView(rating: $rating)
                }

                Section("Memo") {
                    TextEditor(text: $memo)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("New Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(placeName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
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
        photoDataList = dataList
    }

    private func fetchCurrentLocation() {
        isFetchingLocation = true
        locationManager.requestPermission()
        locationManager.requestCurrentLocation()

        Task {
            for _ in 0..<20 {
                try? await Task.sleep(for: .milliseconds(500))
                if let location = locationManager.currentLocation {
                    latitude = location.coordinate.latitude
                    longitude = location.coordinate.longitude
                    isFetchingLocation = false
                    return
                }
            }
            isFetchingLocation = false
        }
    }

    private func save() {
        let log = PlaceLog(
            date: date,
            placeName: placeName.trimmingCharacters(in: .whitespaces),
            category: category.rawValue,
            latitude: latitude,
            longitude: longitude,
            address: address.isEmpty ? nil : address,
            memo: memo,
            rating: rating
        )
        modelContext.insert(log)

        for (index, data) in photoDataList.enumerated() {
            let photo = PhotoAttachment(imageData: data, sortOrder: index)
            photo.placeLog = log
            modelContext.insert(photo)
        }

        dismiss()
    }
}

#Preview {
    AddLogView()
        .modelContainer(for: [PlaceLog.self, PhotoAttachment.self], inMemory: true)
}
