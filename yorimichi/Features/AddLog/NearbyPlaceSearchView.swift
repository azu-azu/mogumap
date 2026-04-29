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
                                Label("Manual Entry", systemImage: "pencil")
                            }
                        }
                    }
                    .overlay {
                        if viewModel.isSearching && viewModel.results.isEmpty {
                            ProgressView()
                        } else if !viewModel.isSearching && viewModel.results.isEmpty {
                            ContentUnavailableView(
                                "No Places Found",
                                systemImage: "mappin.slash",
                                description: Text("Try a different search term.")
                            )
                        }
                    }
                    .searchable(text: Binding(
                        get: { viewModel.searchText },
                        set: { newValue in
                            viewModel.searchText = newValue
                            viewModel.onSearchTextChanged()
                        }
                    ), prompt: "Search nearby...")
                } else {
                    ProgressView("Getting location...")
                }
            }
            .navigationTitle("Nearby Places")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
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
            .onChange(of: locationService.currentLocation?.coordinate.latitude) { _, _ in
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
            Text(item.name ?? "Unknown")
                .font(.body)
                .foregroundStyle(.primary)

            if let address = formatAddress(item.placemark) {
                Text(address)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
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
