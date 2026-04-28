import SwiftUI
import SwiftData

struct LogListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PlaceLog.date, order: .reverse) private var logs: [PlaceLog]
    @State private var showAddLog = false

    var body: some View {
        Group {
            if logs.isEmpty {
                ContentUnavailableView(
                    "No Logs Yet",
                    systemImage: "mappin.slash",
                    description: Text("Tap + to add your first place log.")
                )
            } else {
                List {
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
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Timeline")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddLog = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .navigationDestination(for: PlaceLog.self) { log in
            LogDetailView(log: log)
        }
        .sheet(isPresented: $showAddLog) {
            AddLogView()
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

#Preview {
    NavigationStack {
        LogListView()
    }
    .modelContainer(for: [PlaceLog.self, PhotoAttachment.self], inMemory: true)
}
