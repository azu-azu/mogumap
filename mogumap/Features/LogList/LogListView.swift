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
    @State private var showScanOptions = false
    @State private var quickScanMode: QuickScanMode?
    @State private var showQuickAdd = false
    @State private var showSettings = false

    var body: some View {
        List {
            let locationDenied = locationService.authorizationStatus == .denied
                || locationService.authorizationStatus == .restricted
                || locationService.isDeclinedForNow

            if locationDenied {
                Section {
                    Button("action.open_settings".localized) {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.caption)
                }
            } else {
                nearbySection
            }

            let displayedGroups = locationDenied ? allGroupedByDate : nearbyGroupedByDate
            if !locationDenied && locationService.currentLocation != nil && displayedGroups.isEmpty {
                Section {
                    ContentUnavailableView(
                        "empty.nearby_title".localized,
                        systemImage: "mappin.slash",
                        description: Text("empty.nearby_desc".localized)
                    )
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }
            } else {
                ForEach(displayedGroups, id: \.key) { day, dayLogs in
                    Section {
                        Text(day)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 12, leading: 20, bottom: 0, trailing: 16))

                        ForEach(dayLogs) { log in
                            NavigationLink(value: log) {
                                LogRowView(log: log)
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    modelContext.delete(log)
                                } label: {
                                    Label("action.delete".localized, systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    log.isFavorite.toggle()
                                } label: {
                                    Label(
                                        log.isFavorite ? "label.unfavorite".localized : "label.favorite".localized,
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
        .scrollContentBackground(.hidden)
        .background(DesignTokens.Background.base)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 4) {
                    Button {
                        showScanOptions = true
                    } label: {
                        Image(systemName: "doc.text.viewfinder")
                    }
                    Button {
                        showManualAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
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
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView()
            }
        }
        .confirmationDialog("section.scan".localized, isPresented: $showScanOptions) {
            Button("action.scan_camera".localized) {
                quickScanMode = .scanCamera
                showQuickAdd = true
            }
            Button("action.scan_library".localized) {
                quickScanMode = .scanLibrary
                showQuickAdd = true
            }
            Button("action.paste".localized) {
                quickScanMode = .paste
                showQuickAdd = true
            }
        }
        .sheet(isPresented: $showQuickAdd, onDismiss: { quickScanMode = nil }) {
            NavigationStack {
                AddLogView(quickScanMode: quickScanMode)
            }
        }
        .task {
            locationService.requestCurrentLocation()
        }
        .onChange(of: locationService.locationVersion) { _, _ in
            guard nearbyViewModel == nil, let location = locationService.currentLocation else { return }
            let vm = NearbyPlaceSearchViewModel(coordinate: location.coordinate)
            nearbyViewModel = vm
            Task { await vm.searchNearby() }
        }
    }

    @ViewBuilder
    private var nearbySection: some View {
        Section("section.nearby".localized) {
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
                        .buttonStyle(.plain)
                    }
                }
            } else if locationService.authorizationStatus == .denied
                          || locationService.authorizationStatus == .restricted
                          || locationService.isDeclinedForNow {
                VStack(alignment: .leading, spacing: 4) {
                    Text("nearby.location_denied".localized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("action.open_settings".localized) {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.caption)
                }
            } else {
                HStack {
                    Spacer()
                    ProgressView("label.getting_location".localized)
                    Spacer()
                }
            }
        }
    }

    private var nearbyLogs: [PlaceLog] {
        guard let current = locationService.currentLocation else { return [] }
        return logs.filter { log in
            guard let coord = log.coordinate else { return false }
            let logLocation = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
            return logLocation.distance(from: current) <= NearbyPlaceSearchViewModel.defaultRadius
        }
    }

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .long
        f.locale = Locale(identifier: LanguageProvider.shared.language.resolvedLanguageCode)
        return f
    }

    private var nearbyGroupedByDate: [(key: String, value: [PlaceLog])] {
        groupedByDate(nearbyLogs)
    }

    private var allGroupedByDate: [(key: String, value: [PlaceLog])] {
        groupedByDate(logs)
    }

    private func groupedByDate(_ source: [PlaceLog]) -> [(key: String, value: [PlaceLog])] {
        let grouped = Dictionary(grouping: source) { log in
            dateFormatter.string(from: log.date)
        }
        return grouped.sorted { ($0.value.first?.date ?? .distantPast) > ($1.value.first?.date ?? .distantPast) }
    }
}

private struct NearbyPlaceRow: View {
    let item: MKMapItem

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name ?? "Unknown")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                if let address = item.placemark.formattedAddress {
                    Text(address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "plus.circle.fill")
                .font(.title3)
                .foregroundStyle(DesignTokens.Accent.primary)
        }
    }
}

#Preview {
    NavigationStack {
        LogListView()
    }
    .modelContainer(for: [PlaceLog.self, PhotoAttachment.self], inMemory: true)
}
