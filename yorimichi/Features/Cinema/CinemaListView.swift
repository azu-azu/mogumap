import SwiftUI
import SwiftData

struct CinemaListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CinemaLog.watchedDate, order: .reverse) private var logs: [CinemaLog]
    @State private var showAdd = false

    var body: some View {
        List {
            if logs.isEmpty {
                Section {
                    ContentUnavailableView(
                        "No Cinema Logs",
                        systemImage: "film",
                        description: Text("Tap + to add your first movie.")
                    )
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }
            } else {
                ForEach(groupedByDate, id: \.key) { day, dayLogs in
                    Section {
                        Text(day)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 12, leading: 20, bottom: 0, trailing: 16))

                        ForEach(dayLogs) { log in
                            NavigationLink(value: log) {
                                CinemaLogRowView(log: log)
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
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
        .scrollContentBackground(.hidden)
        .background(DesignTokens.Background.base)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAdd = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .navigationDestination(for: CinemaLog.self) { log in
            CinemaLogDetailView(log: log)
        }
        .sheet(isPresented: $showAdd) {
            NavigationStack {
                AddCinemaLogView()
            }
        }
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long
        f.locale = Locale(identifier: "ja_JP")
        return f
    }()

    private var groupedByDate: [(key: String, value: [CinemaLog])] {
        let grouped = Dictionary(grouping: logs) { log in
            Self.dateFormatter.string(from: log.watchedDate)
        }
        return grouped.sorted { ($0.value.first?.watchedDate ?? .distantPast) > ($1.value.first?.watchedDate ?? .distantPast) }
    }
}
