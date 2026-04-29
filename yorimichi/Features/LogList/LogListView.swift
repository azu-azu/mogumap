import SwiftUI
import SwiftData
import MapKit

struct LogListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PlaceLog.date, order: .reverse) private var logs: [PlaceLog]
    @State private var locationService = LocationService()
    @State private var nearbyViewModel: NearbyPlaceSearchViewModel?
    @State private var selectedPlace: MKMapItem?
    @State private var showManualAdd = false

    var body: some View {
        List {
            nearbySection

            if logs.isEmpty {
                ContentUnavailableView(
                    "No Logs Yet",
                    systemImage: "mappin.slash",
                    description: Text("Tap a nearby place to add your first log.")
                )
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            } else {
                ForEach(groupedByDate, id: \.key) { day, dayLogs in
                    Section(day) {
                        ForEach(dayLogs) { log in
                            NavigationLink(value: log) {
                                LogRowView(log: log)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    modelContext.delete(log)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    log.isFavorite.toggle()
                                } label: {
                                    Label(
                                        log.isFavorite ? "Unfavorite" : "Favorite",
                                        systemImage: log.isFavorite ? "heart.slash" : "heart.fill"
                                    )
                                }
                                .tint(.pink)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Timeline")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showManualAdd = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .navigationDestination(for: PlaceLog.self) { log in
            LogDetailView(log: log)
        }
        .sheet(isPresented: Binding(
            get: { selectedPlace != nil },
            set: { if !$0 { selectedPlace = nil } }
        )) {
            if let place = selectedPlace {
                NavigationStack {
                    AddLogView(selectedPlace: place)
                }
            }
        }
        .sheet(isPresented: $showManualAdd) {
            NavigationStack {
                AddLogView()
            }
        }
        .task {
            locationService.requestCurrentLocation()
        }
        .onChange(of: locationService.currentLocation?.coordinate.latitude) { _, _ in
            guard nearbyViewModel == nil, let location = locationService.currentLocation else { return }
            let vm = NearbyPlaceSearchViewModel(coordinate: location.coordinate)
            nearbyViewModel = vm
            Task { await vm.searchNearby() }
        }
    }

    @ViewBuilder
    private var nearbySection: some View {
        Section {
            if let vm = nearbyViewModel {
                if vm.isSearching && vm.results.isEmpty {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else {
                    ForEach(vm.results.prefix(5), id: \.self) { item in
                        Button {
                            selectedPlace = item
                        } label: {
                            NearbyPlaceRow(item: item)
                        }
                    }
                }
            } else {
                HStack {
                    Spacer()
                    ProgressView("Getting location...")
                    Spacer()
                }
            }
        } header: {
            Label("Nearby", systemImage: "location.fill")
        }
    }

    private var groupedByDate: [(key: String, value: [PlaceLog])] {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "ja_JP")

        let grouped = Dictionary(grouping: logs) { log in
            formatter.string(from: log.date)
        }
        return grouped.sorted { $0.value[0].date > $1.value[0].date }
    }
}

private struct NearbyPlaceRow: View {
    let item: MKMapItem

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name ?? "Unknown")
                    .font(.body)
                    .foregroundStyle(.primary)

                if let address = formatAddress(item.placemark) {
                    Text(address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "plus.circle")
                .foregroundStyle(.tint)
        }
    }

    private func formatAddress(_ placemark: MKPlacemark) -> String? {
        let parts = [
            placemark.administrativeArea,
            placemark.locality,
            placemark.subLocality,
            placemark.thoroughfare,
            placemark.subThoroughfare,
        ].compactMap { $0 }

        return parts.isEmpty ? nil : parts.joined()
    }
}

#Preview {
    NavigationStack {
        LogListView()
    }
    .modelContainer(for: [PlaceLog.self, PhotoAttachment.self], inMemory: true)
}
