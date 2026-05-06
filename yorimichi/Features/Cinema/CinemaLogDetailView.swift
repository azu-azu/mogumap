import SwiftUI

struct CinemaLogDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    let log: CinemaLog
    @State private var showDeleteConfirm = false

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(log.movieTitle)
                            .font(.title2)
                            .fontWeight(.bold)
                        Spacer()
                        CopyButton(text: log.movieTitle)
                    }

                    HStack {
                        if let theater = log.theaterName {
                            Text(theater)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        if let imp = log.impressionType {
                            Text(imp.emoji)
                        }
                        if log.isFavorite {
                            Image(systemName: "heart.fill")
                                .foregroundStyle(.red)
                        }
                    }
                }
            }

            if log.screenName != nil || log.seatNumber != nil {
                Section("Screening") {
                    if let screen = log.screenName {
                        Label(screen, systemImage: "tv")
                    }
                    if let seat = log.seatNumber {
                        Label(seat, systemImage: "chair.lounge")
                    }
                    if let start = log.screeningStartsAt {
                        Label {
                            Text(start, format: .dateTime.hour().minute())
                            if let end = log.screeningEndsAt {
                                Text(" - ")
                                Text(end, format: .dateTime.hour().minute())
                            }
                        } icon: {
                            Image(systemName: "clock")
                        }
                    }
                }
            }

            Section("Date") {
                Label {
                    Text(log.watchedDate, format: .dateTime.year().month().day().hour().minute())
                } icon: {
                    Image(systemName: "calendar")
                }
            }

            if log.price != nil || !(log.ticketType?.isEmpty ?? true) {
                Section("Ticket") {
                    if let price = log.price {
                        Label("\(price) yen", systemImage: "yensign.circle")
                    }
                    if let type = log.ticketType, !type.isEmpty {
                        Label(type, systemImage: "ticket")
                    }
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
                    CinemaPhotoGridView(photos: log.photos)
                }
            }

            if !log.memo.isEmpty {
                Section("Thoughts") {
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
                    EditCinemaLogView(log: log)
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
        GoogleMapsLauncher.open(latitude: coordinate.latitude, longitude: coordinate.longitude, query: log.theaterName ?? log.movieTitle)
    }
}
