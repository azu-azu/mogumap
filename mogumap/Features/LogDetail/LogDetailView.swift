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

            Section("section.date".localized) {
                Label {
                    Text(log.date, format: .dateTime.year().month().day().hour().minute())
                } icon: {
                    Image(systemName: "calendar")
                }
            }

            if log.rating > 0 {
                Section("section.rating".localized) {
                    RatingDisplayView(rating: log.rating)
                }
            }

            if let price = log.price {
                Section("section.price".localized) {
                    Label("\(price) \("label.yen".localized)", systemImage: "yensign.circle")
                }
            }

            if let address = log.address, !address.isEmpty {
                Section("section.address".localized) {
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
                Section("section.photos".localized) {
                    PhotoGridView(photos: log.photos)
                }
            }

            if !log.memo.isEmpty {
                Section("section.thoughts".localized) {
                    Text(log.memo)
                }
            }

            if log.hasLocation {
                Section {
                    Button {
                        showOnMap()
                    } label: {
                        Label("action.show_map".localized, systemImage: "mappin.and.ellipse")
                    }

                    Button {
                        openInGoogleMaps()
                    } label: {
                        Label("action.open_maps".localized, systemImage: "map")
                    }
                }
            }

            Section {
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Label("action.delete_log".localized, systemImage: "trash")
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(DesignTokens.Background.base.ignoresSafeArea())
        .navigationTitle("nav.detail".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink("action.edit".localized) {
                    EditLogView(log: log)
                }
            }
        }
        .confirmationDialog("confirm.delete".localized, isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("action.delete".localized, role: .destructive) {
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
