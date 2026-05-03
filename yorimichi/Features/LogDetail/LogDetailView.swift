import SwiftUI

struct LogDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    let log: PlaceLog
    @State private var showDeleteConfirm = false

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(log.placeName)
                            .font(.title2)
                            .fontWeight(.bold)
                        Spacer()
                        CopyButton(text: log.placeName)
                    }

                    HStack {
                        if let category = Category(rawValue: log.category) {
                            CategoryBadge(category: category)
                        }
                        if let raw = log.impression, let imp = Impression(rawValue: raw) {
                            Text(imp.emoji)
                        }
                        if log.isFavorite {
                            Image(systemName: "heart.fill")
                                .foregroundStyle(.red)
                        }
                    }
                }
            }

            Section("Date") {
                Label {
                    Text(log.date, format: .dateTime.year().month().day().hour().minute())
                } icon: {
                    Image(systemName: "calendar")
                }
            }

            if log.rating > 0 {
                Section("Rating") {
                    RatingDisplayView(rating: log.rating)
                }
            }

            if let address = log.address, !address.isEmpty {
                Section("Address") {
                    HStack {
                        Label {
                            Text(address)
                        } icon: {
                            Image(systemName: "mappin.and.ellipse")
                        }
                        Spacer()
                        CopyButton(text: address)
                    }
                }
            }

            if !log.photos.isEmpty {
                Section("Photos") {
                    PhotoGridView(photos: log.photos)
                }
            }

            if !log.memo.isEmpty {
                Section("Thoughts (free log)") {
                    Text(log.memo)
                }
            }

            if log.hasLocation {
                Section {
                    Button {
                        showOnMap()
                    } label: {
                        Label("Show on Map", systemImage: "mappin.and.ellipse")
                    }

                    Button {
                        openInGoogleMaps()
                    } label: {
                        Label("Open in Google Maps", systemImage: "map")
                    }
                }
            }

            Section {
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Label("Delete Log", systemImage: "trash")
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(DesignTokens.Background.base.ignoresSafeArea())
        .navigationTitle("Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink("Edit") {
                    EditLogView(log: log)
                }
            }
        }
        .confirmationDialog("Delete this log?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                modelContext.delete(log)
                dismiss()
            }
        }
    }

    private func showOnMap() {
        guard let coordinate = log.coordinate else { return }
        appState.focusMap(on: coordinate)
    }

    private func openInGoogleMaps() {
        guard let coordinate = log.coordinate else { return }
        GoogleMapsLauncher.open(latitude: coordinate.latitude, longitude: coordinate.longitude, query: log.placeName)
    }
}
