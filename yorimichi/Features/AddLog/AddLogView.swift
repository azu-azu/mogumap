import SwiftUI
import SwiftData
import PhotosUI
import UIKit
@preconcurrency import MapKit

enum QuickScanMode {
    case scanCamera
    case scanLibrary
    case paste
}

struct AddLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let selectedPlace: MKMapItem?
    let quickScanMode: QuickScanMode?
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
    @State private var priceText = ""
    @State private var receiptIndices: Set<Int> = []
    @State private var showCamera = false
    @State private var showReceiptCamera = false
    @State private var showThoughtsEditor = false
    @State private var isProcessingOCR = false
    @State private var scanLibraryPhotos: [PhotosPickerItem] = []
    @State private var showScanLibraryPicker = false
    @State private var showLibraryPicker = false
    @State private var showAddOptions = false

    private static let sheetAnimationDelay: Duration = .milliseconds(600)

    init(selectedPlace: MKMapItem? = nil, quickScanMode: QuickScanMode? = nil, onComplete: (() -> Void)? = nil) {
        self.selectedPlace = selectedPlace
        self.quickScanMode = quickScanMode
        self.onComplete = onComplete
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                dateSection
                placeSection
                attachmentsSection
                priceSection
                thoughtsSection
                ratingSection
                impressionSection
                locationSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .background(DesignTokens.Background.base.ignoresSafeArea())
        .navigationTitle("New Log")
        .navigationBarTitleDisplayMode(.inline)
        .keyboardCloseToolbar()
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
            guard let mode = quickScanMode else { return }
            // Wait for sheet animation to complete before presenting another sheet/cover
            if mode != .paste {
                try? await Task.sleep(for: Self.sheetAnimationDelay)
            }
            switch mode {
            case .scanCamera:   showReceiptCamera = true
            case .scanLibrary:  showScanLibraryPicker = true
            case .paste:        handleClipboard()
            }
        }
        .onChange(of: selectedPhotos) { _, newItems in
            Task { await loadPhotos(from: newItems) }
        }
        .photosPicker(
            isPresented: $showLibraryPicker,
            selection: $selectedPhotos,
            maxSelectionCount: PhotoLoader.maxSelectionCount,
            matching: .images
        )
        .confirmationDialog("Add Attachment", isPresented: $showAddOptions) {
            Button { showCamera = true } label: {
                Label("Take Photo", systemImage: "camera")
            }
            Button { showLibraryPicker = true } label: {
                Label("Select from Library", systemImage: "photo.on.rectangle.angled")
            }
            Button { showReceiptCamera = true } label: {
                Label("Scan from Camera", systemImage: "doc.text.viewfinder")
            }
            Button { showScanLibraryPicker = true } label: {
                Label("Scan from Library", systemImage: "photo.on.rectangle.angled")
            }
            Button { handleClipboard() } label: {
                Label("Paste Image or Text", systemImage: "doc.on.clipboard")
            }
        }
        .photosPicker(
            isPresented: $showScanLibraryPicker,
            selection: $scanLibraryPhotos,
            maxSelectionCount: PhotoLoader.maxSelectionCount,
            matching: .images
        )
        .onChange(of: scanLibraryPhotos) { _, newItems in
            Task {
                let dataList = await PhotoLoader.loadJPEGData(from: newItems)
                let startIndex = photoDataList.count
                for (i, data) in dataList.enumerated() {
                    receiptIndices.insert(startIndex + i)
                    photoDataList.append(data)
                }
                for data in dataList {
                    await processReceiptOCR(data)
                }
            }
        }
        .sheet(isPresented: $showThoughtsEditor) {
            FullTextEditorSheet(text: $memo)
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView { imageData in
                photoDataList.append(imageData)
            }
        }
        .fullScreenCover(isPresented: $showReceiptCamera) {
            CameraView { imageData in
                receiptIndices.insert(photoDataList.count)
                photoDataList.append(imageData)
                Task { await processReceiptOCR(imageData) }
            }
        }
    }

    private func handleClipboard() {
        let pb = UIPasteboard.general
        if let image = pb.image,
           let data = image.jpegData(compressionQuality: PhotoLoader.compressionQuality) {
            receiptIndices.insert(photoDataList.count)
            photoDataList.append(data)
            Task { await processReceiptOCR(data) }
        } else if let url = pb.url {
            address = url.absoluteString
            Task { await handleGoogleMapsURL(url.absoluteString) }
        } else if let text = pb.string, !text.isEmpty {
            applyPasteResult(PlaceInfoParser.parse(text))
        }
    }

    private func applyPasteResult(_ result: PasteResult) {
        if let name = result.placeName, placeName.isEmpty { placeName = name }
        if let addr = result.address, address.isEmpty { address = addr }
        if let price = result.price, priceText.isEmpty { priceText = String(price) }
        if let date = result.date { self.date = date }
        if !result.notes.isEmpty {
            memo = memo.isEmpty ? result.notes : memo + "\n" + result.notes
        }
    }

    private func processReceiptOCR(_ imageData: Data) async {
        isProcessingOCR = true
        defer { isProcessingOCR = false }

        guard let text = await ReceiptOCRService.recognizeText(from: imageData) else { return }
        ReceiptOCRService.parse(text).apply(
            placeName: &placeName,
            priceText: &priceText,
            date: &date,
            memo: &memo
        )
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

    private var placeSection: some View {
        FormSection(title: "Place") {
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
                        Label(cat.displayName, systemImage: cat.icon).tag(cat)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
    }

    private var locationSection: some View {
        FormSection(title: "Location") {
            VStack(spacing: 0) {
                if let lat = latitude, let lng = longitude {
                    Label(String(format: "%.4f, %.4f", lat, lng), systemImage: "location.fill")
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
    }

    private var dateSection: some View {
        FormSection(title: "Date") {
            DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
    }

    private var priceSection: some View {
        FormSection(title: "Price") {
            HStack {
                TextField("Price", text: $priceText).keyboardType(.numberPad)
                Text("yen").foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private var thoughtsSection: some View {
        FormSection(title: "Thoughts (free log)") {
            Button {
                showThoughtsEditor = true
            } label: {
                Text(memo.isEmpty ? "Tap to write..." : memo)
                    .foregroundStyle(memo.isEmpty ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(3)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var ratingSection: some View {
        FormSection(title: "Rating") {
            RatingView(rating: $rating)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
    }

    private var impressionSection: some View {
        FormSection(title: "Impression") {
            Picker("Impression", selection: $impression) {
                ForEach(Impression.allCases) { imp in
                    Text("\(imp.emoji) \(imp.displayName)").tag(imp)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private var attachmentsSection: some View {
        FormSection(title: "Attachments") {
            VStack(spacing: 0) {
                if !photoDataList.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(photoDataList.indices, id: \.self) { index in
                                if let uiImage = UIImage(data: photoDataList[index]) {
                                    ZStack(alignment: .bottomTrailing) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 80, height: 80)
                                            .clipped()
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                        if receiptIndices.contains(index) {
                                            ReceiptBadge().offset(x: 2, y: 2)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    Divider().padding(.leading, 16)
                }
                Button {
                    showAddOptions = true
                } label: {
                    HStack {
                        Label("Add", systemImage: "plus.circle")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if isProcessingOCR { ProgressView() }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
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
            impression: impression.rawValue,
            price: Int(priceText)
        )
        modelContext.insert(log)

        for (index, data) in photoDataList.enumerated() {
            let photo = PhotoAttachment(imageData: data, sortOrder: index, isReceipt: receiptIndices.contains(index))
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
