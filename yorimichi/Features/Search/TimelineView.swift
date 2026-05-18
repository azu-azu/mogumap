import SwiftUI
import SwiftData

struct TimelineView: View {
    @Query(sort: \PlaceLog.date, order: .reverse) private var allLogs: [PlaceLog]

    @State private var searchText = ""
    @State private var selectedCategory: Category?
    @State private var minimumRating = 0
    @State private var priceOnly = false

    private var filteredLogs: [PlaceLog] {
        allLogs.filter { log in
            let matchesText = searchText.isEmpty ||
                log.placeName.localizedCaseInsensitiveContains(searchText) ||
                log.memo.localizedCaseInsensitiveContains(searchText) ||
                (log.address?.localizedCaseInsensitiveContains(searchText) ?? false)

            let matchesCategory = selectedCategory == nil ||
                log.category == selectedCategory?.rawValue

            let matchesRating = log.rating >= minimumRating

            let matchesPrice = !priceOnly || log.price != nil

            return matchesText && matchesCategory && matchesRating && matchesPrice
        }
    }

    var body: some View {
        List {
            Section {
                categoryFilter
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                ratingFilter
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                priceFilter
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            Section {
                HStack {
                    Text(String(format: "label.results".localized, filteredLogs.count))
                    Spacer()
                    if totalPrice > 0 {
                        Text("¥\(totalPrice)")
                            .fontDesign(.monospaced)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 12, leading: 20, bottom: 0, trailing: 16))

                if filteredLogs.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    ForEach(filteredLogs) { log in
                        NavigationLink(value: log) {
                            LogRowView(log: log)
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(DesignTokens.Background.base)
        .searchable(text: $searchText, prompt: "field.search".localized)
        .navigationDestination(for: PlaceLog.self) { log in
            LogDetailView(log: log)
        }
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(label: "label.all".localized, isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(Category.allCases) { cat in
                    filterChip(
                        label: cat.displayName,
                        icon: cat.icon,
                        isSelected: selectedCategory == cat
                    ) {
                        selectedCategory = selectedCategory == cat ? nil : cat
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var totalPrice: Int {
        filteredLogs.compactMap(\.price).reduce(0, +)
    }

    private var priceFilter: some View {
        Toggle("label.price_only".localized, isOn: $priceOnly)
            .font(.subheadline)
    }

    private var ratingFilter: some View {
        HStack {
            Text("label.min_rating".localized)
                .font(.subheadline)
            Spacer()
            RatingView(rating: $minimumRating)
        }
    }

    private func filterChip(
        label: String,
        icon: String? = nil,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption2)
                }
                Text(label)
                    .font(.caption)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? DesignTokens.Accent.primary : .clear)
            .foregroundStyle(isSelected ? .white : DesignTokens.Text.secondary)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(isSelected ? .clear : DesignTokens.Semantic.neutral, lineWidth: 1)
            )
        }
    }
}

#Preview {
    NavigationStack {
        TimelineView()
    }
    .modelContainer(for: [PlaceLog.self, PhotoAttachment.self], inMemory: true)
}
