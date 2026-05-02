import SwiftUI
import SwiftData
import PhotosUI
@preconcurrency import MapKit

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
        ScrollView {
            VStack(spacing: 20) {
                formSection("Place") {
                    VStack(spacing: 0) {
                        HStack {
                            TextField("Place name", text: $placeName)
                            CopyButton(text: placeName)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)

                        Divider().padding(.leading, 16)

                        Picker("Category", selection: $category) {
                            ForEach(Category.allCases) { cat in
                                Label(cat.displayName, systemImage: cat.icon)
                                    .tag(cat)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                }

                formSection("Photos") {
                    VStack(spacing: 0) {
                        PhotosPicker(
                            selection: $selectedPhotos,
                            maxSelectionCount: PhotoLoader.maxSelectionCount,
                            matching: .images
                        ) {
                            Label("Select Photos", systemImage: "photo.on.rectangle.angled")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .onChange(of: selectedPhotos) { _, newItems in
                            Task { await loadPhotos(from: newItems) }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)

                        Divider().padding(.leading, 16)

                        Button {
                            showCamera = true
                        } label: {
                            Label("Take Photo", systemImage: "camera")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)

                        if !photoDataList.isEmpty {
                            Divider().padding(.leading, 16)
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
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                    }
                }

                formSection("Location") {
                    VStack(spacing: 0) {
                        if let lat = latitude, let lng = longitude {
                            Label(
                                String(format: "%.4f, %.4f", lat, lng),
                                systemImage: "location.fill"
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)

                            Divider().padding(.leading, 16)
                        }

                        HStack {
                            TextField("Address or Google Maps URL", text: $address)
                            CopyButton(text: address)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .onChange(of: address) { _, newValue in
                            if GoogleMapsURLParser.isGoogleMapsURL(newValue) {
                                Task { await handleGoogleMapsURL(newValue) }
                            }
                        }

                        if selectedPlace == nil {
                            Divider().padding(.leading, 16)
                            Button {
                                if let location = locationService.currentLocation {
                                    latitude = location.coordinate.latitude
                                    longitude = location.coordinate.longitude
                                }
                            } label: {
                                Label("Use Current Location", systemImage: "location")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .disabled(locationService.currentLocation == nil)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                    }
                }

                formSection("Date") {
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }

                formSection("Rating") {
                    RatingView(rating: $rating)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }

                formSection("Impression") {
                    Picker("Impression", selection: $impression) {
                        ForEach(Impression.allCases) { imp in
                            Text("\(imp.emoji) \(imp.displayName)")
                                .tag(imp)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }

                formSection("Thoughts (free log)") {
                    TextEditor(text: $memo)
                        .frame(minHeight: 80)
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
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

    private func formSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            content()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(DesignTokens.Background.formCell)
                )
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

    private func handleGoogleMapsURL(_ urlString: String) async {
        var resolvedURL = urlString

        if GoogleMapsURLParser.isShortURL(urlString) {
            if let resolved = await URLResolver.resolveRedirect(urlString) {
                resolvedURL = resolved
            }
        }

        guard let result = GoogleMapsURLParser.parse(resolvedURL) else { return }

        latitude = result.coordinate.latitude
        longitude = result.coordinate.longitude

        if let name = result.placeName {
            placeName = name
        }

        await reverseGeocode(result.coordinate)
        await findNearbyPOI(at: result.coordinate)
    }

    private func reverseGeocode(_ coordinate: CLLocationCoordinate2D) async {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let geocoder = CLGeocoder()
        if let placemark = try? await geocoder.reverseGeocodeLocation(location).first {
            address = placemark.formattedAddress ?? ""
        }
    }

    private func findNearbyPOI(at coordinate: CLLocationCoordinate2D) async {
        let request = MKLocalPointsOfInterestRequest(center: coordinate, radius: GoogleMapsURLParser.pinpointRadius)
        let search = MKLocalSearch(request: request)
        if let response = try? await search.start(),
           let closest = response.mapItems.first {
            if placeName.isEmpty {
                placeName = closest.name ?? ""
            }
            category = Category.from(poiCategory: closest.pointOfInterestCategory)
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
