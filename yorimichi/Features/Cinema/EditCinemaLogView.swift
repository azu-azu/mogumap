import SwiftUI
import SwiftData
import PhotosUI

struct EditCinemaLogView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var log: CinemaLog

    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var newPhotoDataList: [Data] = []
    @State private var showCamera = false
    @State private var showThoughtsEditor = false
    @State private var showScreeningTime: Bool
    @State private var screeningStart: Date
    @State private var screeningEnd: Date
    @State private var priceText: String

    init(log: CinemaLog) {
        self.log = log
        _showScreeningTime = State(initialValue: log.screeningStartsAt != nil)
        _screeningStart = State(initialValue: log.screeningStartsAt ?? Date())
        _screeningEnd = State(initialValue: log.screeningEndsAt ?? Date())
        _priceText = State(initialValue: log.price.map(String.init) ?? "")
    }

    var body: some View {
        List {
            Section("Movie") {
                TextField("Movie title", text: $log.movieTitle)
            }

            Section("Theater") {
                TextField("Theater name", text: Binding(
                    get: { log.theaterName ?? "" },
                    set: { log.theaterName = $0.isEmpty ? nil : $0 }
                ))
                TextField("Screen", text: Binding(
                    get: { log.screenName ?? "" },
                    set: { log.screenName = $0.isEmpty ? nil : $0 }
                ))
                TextField("Seat number", text: Binding(
                    get: { log.seatNumber ?? "" },
                    set: { log.seatNumber = $0.isEmpty ? nil : $0 }
                ))
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
                    CinemaPhotoGridView(photos: log.photos)

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
                DatePicker("Watched", selection: $log.watchedDate, displayedComponents: [.date, .hourAndMinute])
            }

            Section("Screening Time") {
                Toggle("Set screening time", isOn: $showScreeningTime)

                if showScreeningTime {
                    DatePicker("Start", selection: $screeningStart, displayedComponents: [.date, .hourAndMinute])
                    DatePicker("End", selection: $screeningEnd, displayedComponents: [.date, .hourAndMinute])
                }
            }

            Section("Ticket") {
                HStack {
                    TextField("Price", text: $priceText)
                        .keyboardType(.numberPad)
                    Text("yen")
                        .foregroundStyle(.secondary)
                }
                TextField("Ticket type", text: Binding(
                    get: { log.ticketType ?? "" },
                    set: { log.ticketType = $0.isEmpty ? nil : $0 }
                ))
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

            Section("Thoughts") {
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

    private func loadPhotos(from items: [PhotosPickerItem]) async {
        newPhotoDataList = await PhotoLoader.loadJPEGData(from: items)
    }

    private func saveChanges() {
        log.screeningStartsAt = showScreeningTime ? screeningStart : nil
        log.screeningEndsAt = showScreeningTime ? screeningEnd : nil
        log.price = Int(priceText)
        log.touch()

        let startIndex = log.photos.count
        for (index, data) in newPhotoDataList.enumerated() {
            let photo = CinemaPhotoAttachment(imageData: data, sortOrder: startIndex + index)
            photo.cinemaLog = log
            modelContext.insert(photo)
        }

        dismiss()
    }
}
