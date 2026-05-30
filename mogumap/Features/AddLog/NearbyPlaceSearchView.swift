import SwiftUI
import MapKit

struct NearbyPlaceSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var locationService = LocationService()
    @State private var viewModel: NearbyPlaceSearchViewModel?
    @State private var didComplete = false

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    List {
                        Section {
                            ForEach(viewModel.results, id: \.self) { item in
                                NavigationLink(value: item) {
                                    PlaceRow(item: item)
                                }
                            }
                        }

                        Section {
                            NavigationLink(value: "manual") {
                                Label("nearby.manual_entry".localized, systemImage: "pencil")
                            }
                        }
                    }
                    .overlay {
                        if viewModel.isSearching && viewModel.results.isEmpty {
                            ProgressView()
                        } else if !viewModel.isSearching && viewModel.results.isEmpty {
                            ContentUnavailableView(
                                "nearby.no_results".localized,
                                systemImage: "mappin.slash",
                                description: Text("nearby.no_results_desc".localized)
                            )
                        }
                    }
                    .searchable(text: Binding(
                        get: { viewModel.searchText },
                        set: { newValue in
                            viewModel.searchText = newValue
                            viewModel.onSearchTextChanged()
                        }
                    ), prompt: "nearby.search_prompt".localized)
                } else if locationService.authorizationStatus == .denied
                            || locationService.authorizationStatus == .restricted {
                    ContentUnavailableView(
                        "nearby.location_denied".localized,
                        systemImage: "location.slash",
                        description: Text("nearby.location_denied_desc".localized)
                    )
                } else {
                    ProgressView("label.getting_location".localized)
                }
            }
            .navigationTitle("nearby.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action.close".localized) { dismiss() }
                }
            }
            .navigationDestination(for: MKMapItem.self) { item in
                AddLogView(selectedPlace: item, onComplete: { didComplete = true })
            }
            .navigationDestination(for: String.self) { _ in
                AddLogView(onComplete: { didComplete = true })
            }
            .onChange(of: didComplete) { _, completed in
                if completed { dismiss() }
            }
            .task {
                locationService.requestCurrentLocation()
            }
            .onChange(of: locationService.locationVersion) { _, _ in
                guard viewModel == nil, let location = locationService.currentLocation else { return }
                let vm = NearbyPlaceSearchViewModel(coordinate: location.coordinate)
                viewModel = vm
                Task { await vm.searchNearby() }
            }
        }
    }
}

private struct PlaceRow: View {
    let item: MKMapItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.name ?? "label.unknown".localized)
                .font(.body)
                .foregroundStyle(.primary)

            if let address = item.placemark.formattedAddress {
                Text(address)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
