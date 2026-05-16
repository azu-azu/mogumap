import SwiftUI
import SwiftData
import PhotosUI
import UIKit
import CoreLocation
@preconcurrency import MapKit

struct EditLogView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var log: PlaceLog

    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var newPhotoDataList: [Data] = []
    @State private var showCamera = false
    @State private var showReceiptCamera = false
    @State private var showThoughtsEditor = false
    @State private var priceText: String
    @State private var newReceiptIndices: Set<Int> = []
    @State private var isProcessingOCR = false
    @State private var scanLibraryPhotos: [PhotosPickerItem] = []
    @State private var showScanLibraryPicker = false

    init(log: PlaceLog) {
        self.log = log
        _priceText = State(initialValue: log.price.map(String.init) ?? "")
    }

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

                if !log.photos.isEmpty || !newPhotoDataList.isEmpty {
                    PhotoGridView(photos: log.photos)

                    ForEach(newPhotoDataList.indices, id: \.self) { index in
                        if let uiImage = UIImage(data: newPhotoDataList[index]) {
                            ZStack(alignment: .bottomTrailing) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 100)
                                    .clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 8))

                                if newReceiptIndices.contains(index) {
                                    ReceiptBadge()
                                        .offset(x: -4, y: -4)
                                }
                            }
                        }
                    }
                }
            }

            Section("Scan") {
                Button {
                    showReceiptCamera = true
                } label: {
                    HStack {
                        Label("Scan from Camera", systemImage: "doc.text.viewfinder")
                        Spacer()
                        if isProcessingOCR {
                            ProgressView()
                        }
                    }
                }

                Button {
                    showScanLibraryPicker = true
                } label: {
                    Label("Scan from Library", systemImage: "photo.on.rectangle.angled")
                }

                Button {
                    handleClipboard()
                } label: {
                    Label("Paste Image or Text", systemImage: "doc.on.clipboard")
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

            Section("Price") {
                HStack {
                    TextField("Price", text: $priceText)
                        .keyboardType(.numberPad)
                    Text("yen")
                        .foregroundStyle(.secondary)
                }
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
        .fullScreenCover(isPresented: $showReceiptCamera) {
            CameraView { imageData in
                newReceiptIndices.insert(newPhotoDataList.count)
                newPhotoDataList.append(imageData)
                Task { await processReceiptOCR(imageData) }
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
                let startIndex = newPhotoDataList.count
                for (i, data) in dataList.enumerated() {
                    newReceiptIndices.insert(startIndex + i)
                    newPhotoDataList.append(data)
                }
                for data in dataList {
                    await processReceiptOCR(data)
                }
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

    private func handleClipboard() {
        let pb = UIPasteboard.general
        if let image = pb.image,
           let data = image.jpegData(compressionQuality: PhotoLoader.compressionQuality) {
            newReceiptIndices.insert(newPhotoDataList.count)
            newPhotoDataList.append(data)
            Task { await processReceiptOCR(data) }
        } else if let url = pb.url {
            Task { await handleGoogleMapsURL(url.absoluteString) }
        } else if let text = pb.string, !text.isEmpty {
            applyPasteResult(PlaceInfoParser.parse(text))
        }
    }

    private func applyPasteResult(_ result: PasteResult) {
        if let name = result.placeName, log.placeName.isEmpty { log.placeName = name }
        if let addr = result.address, log.address == nil { log.address = addr }
        if let price = result.price, priceText.isEmpty { priceText = String(price) }
        if let date = result.date { log.date = date }
        if !result.notes.isEmpty {
            log.memo = log.memo.isEmpty ? result.notes : log.memo + "\n" + result.notes
        }
    }

    private func handleGoogleMapsURL(_ urlString: String) async {
        var resolvedURL = urlString
        if GoogleMapsURLParser.isShortURL(urlString),
           let resolved = await URLResolver.resolveRedirect(urlString) {
            resolvedURL = resolved
        }
        guard let result = GoogleMapsURLParser.parse(resolvedURL) else { return }

        log.latitude = result.coordinate.latitude
        log.longitude = result.coordinate.longitude
        if let name = result.placeName, log.placeName.isEmpty {
            log.placeName = name
        }

        let location = CLLocation(latitude: result.coordinate.latitude, longitude: result.coordinate.longitude)
        if let placemark = try? await CLGeocoder().reverseGeocodeLocation(location).first {
            log.address = placemark.formattedAddress
        }
    }

    private func processReceiptOCR(_ imageData: Data) async {
        isProcessingOCR = true
        defer { isProcessingOCR = false }

        guard let text = await ReceiptOCRService.recognizeText(from: imageData) else { return }
        ReceiptOCRService.parse(text).apply(
            placeName: &log.placeName,
            priceText: &priceText,
            date: &log.date,
            memo: &log.memo
        )
    }

    private func loadPhotos(from items: [PhotosPickerItem]) async {
        newPhotoDataList = await PhotoLoader.loadJPEGData(from: items)
    }

    private func saveChanges() {
        log.price = Int(priceText)
        log.touch()

        let startIndex = log.photos.count
        for (index, data) in newPhotoDataList.enumerated() {
            let photo = PhotoAttachment(imageData: data, sortOrder: startIndex + index, isReceipt: newReceiptIndices.contains(index))
            photo.placeLog = log
            modelContext.insert(photo)
        }

        dismiss()
    }
}
