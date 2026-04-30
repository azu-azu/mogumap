import SwiftUI
import SwiftData
import PhotosUI
import MapKit

struct AddLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let selectedPlace: MKMapItem?
    let onComplete: (() -> Void)?

    @State private var placeName = ""
    @State private var category: Category = .other
    @State private var date = Date()
    @State private var memo = ""
    @State private var rating = 0
    @State private var impression: Impression = .neutral
    @State private var latitude: Double?
    @State private var longitude: Double?
    @State private var address: String = ""
    @State private var locationService = LocationService()
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var photoDataList: [Data] = []
    @State private var showCamera = false

    init(selectedPlace: MKMapItem? = nil, onComplete: (() -> Void)? = nil) {
        self.selectedPlace = selectedPlace
        self.onComplete = onComplete
    }

    var body: some View {
        Form {
            Section("Place") {
                HStack {
                    TextField("Place name", text: $placeName)
                    CopyButton(text: placeName)
                }

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
                    maxSelectionCount: PhotoLoader.maxSelectionCount,
                    matching: .images
                ) {
                    Label("Select Photos", systemImage: "photo.on.rectangle.angled")
                }
                .onChange(of: selectedPhotos) { _, newItems in
                    Task { await loadPhotos(from: newItems) }
                }

                Button {
                    showCamera = true
                } label: {
                    Label("Take Photo", systemImage: "camera")
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

                HStack {
                    TextField("Address", text: $address)
                    CopyButton(text: address)
                }

                if selectedPlace == nil {
                    Button {
                        if let location = locationService.currentLocation {
                            latitude = location.coordinate.latitude
                            longitude = location.coordinate.longitude
                        }
                    } label: {
                        Label("Use Current Location", systemImage: "location")
                    }
                    .disabled(locationService.currentLocation == nil)
                }
            }

            Section("Date") {
                DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
            }

            Section("Rating") {
                RatingView(rating: $rating)
            }

            Section("Impression") {
                Picker("Impression", selection: $impression) {
                    ForEach(Impression.allCases) { imp in
                        Text("\(imp.emoji) \(imp.displayName)")
                            .tag(imp)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Thoughts (free log)") {
                TextEditor(text: $memo)
                    .frame(minHeight: 80)
            }
        }
        .scrollContentBackground(.hidden)
        .background(DesignTokens.Background.base)
        .navigationTitle("New Log")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    save()
                }
                .disabled(placeName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .task {
            if let place = selectedPlace {
                applySelectedPlace(place)
            } else {
                locationService.requestCurrentLocation()
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView { imageData in
                photoDataList.append(imageData)
            }
        }
    }

    private func loadPhotos(from items: [PhotosPickerItem]) async {
        photoDataList = await PhotoLoader.loadJPEGData(from: items)
    }

    private func applySelectedPlace(_ item: MKMapItem) {
        placeName = item.name ?? ""
        latitude = item.placemark.coordinate.latitude
        longitude = item.placemark.coordinate.longitude
        address = item.placemark.formattedAddress ?? ""
        category = Category.from(poiCategory: item.pointOfInterestCategory)
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
            rating: rating,
            impression: impression.rawValue
        )
        modelContext.insert(log)

        for (index, data) in photoDataList.enumerated() {
            let photo = PhotoAttachment(imageData: data, sortOrder: index)
            photo.placeLog = log
            modelContext.insert(photo)
        }

        if let onComplete {
            onComplete()
        } else {
            dismiss()
        }
    }
}

#Preview {
    NavigationStack {
        AddLogView()
    }
    .modelContainer(for: [PlaceLog.self, PhotoAttachment.self], inMemory: true)
}
