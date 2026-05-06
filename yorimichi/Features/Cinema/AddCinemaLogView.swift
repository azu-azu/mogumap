import SwiftUI
import SwiftData
import PhotosUI

struct AddCinemaLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var movieTitle = ""
    @State private var theaterName = ""
    @State private var screenName = ""
    @State private var seatNumber = ""
    @State private var watchedDate = Date()
    @State private var showScreeningTime = false
    @State private var screeningStartsAt = Date()
    @State private var screeningEndsAt = Date()
    @State private var memo = ""
    @State private var rating = 0
    @State private var impression: Impression = .neutral
    @State private var latitude: Double?
    @State private var longitude: Double?
    @State private var address = ""
    @State private var priceText = ""
    @State private var ticketType = ""
    @State private var locationService = LocationService()
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var photoDataList: [Data] = []
    @State private var showCamera = false
    @State private var showThoughtsEditor = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                FormSection(title: "Movie") {
                    HStack {
                        TextField("Movie title", text: $movieTitle)
                        CopyButton(text: movieTitle)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }

                FormSection(title: "Theater") {
                    VStack(spacing: 0) {
                        TextField("Theater name", text: $theaterName)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)

                        Divider().padding(.leading, 16)

                        TextField("Screen (IMAX, Dolby, etc.)", text: $screenName)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)

                        Divider().padding(.leading, 16)

                        TextField("Seat number", text: $seatNumber)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                    }
                }

                FormSection(title: "Photos") {
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

                FormSection(title: "Location") {
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

                        TextField("Address", text: $address)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)

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

                FormSection(title: "Date") {
                    DatePicker("Watched", selection: $watchedDate, displayedComponents: [.date, .hourAndMinute])
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }

                FormSection(title: "Screening Time") {
                    VStack(spacing: 0) {
                        Toggle("Set screening time", isOn: $showScreeningTime)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)

                        if showScreeningTime {
                            Divider().padding(.leading, 16)

                            DatePicker("Start", selection: $screeningStartsAt, displayedComponents: [.date, .hourAndMinute])
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)

                            Divider().padding(.leading, 16)

                            DatePicker("End", selection: $screeningEndsAt, displayedComponents: [.date, .hourAndMinute])
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                        }
                    }
                }

                FormSection(title: "Ticket") {
                    VStack(spacing: 0) {
                        HStack {
                            TextField("Price", text: $priceText)
                                .keyboardType(.numberPad)
                            Text("yen")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)

                        Divider().padding(.leading, 16)

                        TextField("Ticket type (General, Late Show, etc.)", text: $ticketType)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                    }
                }

                FormSection(title: "Rating") {
                    RatingView(rating: $rating)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }

                FormSection(title: "Impression") {
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

                FormSection(title: "Thoughts") {
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
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .background(DesignTokens.Background.base.ignoresSafeArea())
        .navigationTitle("New Cinema Log")
        .navigationBarTitleDisplayMode(.inline)
        .keyboardCloseToolbar()
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    save()
                }
                .disabled(movieTitle.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .task {
            locationService.requestCurrentLocation()
        }
        .sheet(isPresented: $showThoughtsEditor) {
            FullTextEditorSheet(text: $memo)
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

    private func save() {
        let log = CinemaLog(
            watchedDate: watchedDate,
            movieTitle: movieTitle.trimmingCharacters(in: .whitespaces),
            screeningStartsAt: showScreeningTime ? screeningStartsAt : nil,
            screeningEndsAt: showScreeningTime ? screeningEndsAt : nil,
            theaterName: theaterName.isEmpty ? nil : theaterName,
            screenName: screenName.isEmpty ? nil : screenName,
            seatNumber: seatNumber.isEmpty ? nil : seatNumber,
            latitude: latitude,
            longitude: longitude,
            address: address.isEmpty ? nil : address,
            rating: rating,
            impression: impression.rawValue,
            memo: memo,
            price: Int(priceText),
            ticketType: ticketType.isEmpty ? nil : ticketType
        )
        modelContext.insert(log)

        for (index, data) in photoDataList.enumerated() {
            let photo = CinemaPhotoAttachment(imageData: data, sortOrder: index)
            photo.cinemaLog = log
            modelContext.insert(photo)
        }

        dismiss()
    }
}
