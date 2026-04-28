import SwiftUI

struct LogDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let log: PlaceLog
    @State private var showDeleteConfirm = false

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(log.placeName)
                        .font(.title2)
                        .fontWeight(.bold)

                    HStack {
                        if let category = Category(rawValue: log.category) {
                            CategoryBadge(category: category)
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
                    Label {
                        Text(address)
                    } icon: {
                        Image(systemName: "mappin.and.ellipse")
                    }
                }
            }

            if !log.photos.isEmpty {
                Section("Photos") {
                    PhotoGridView(photos: log.photos)
                }
            }

            if !log.memo.isEmpty {
                Section("Memo") {
                    Text(log.memo)
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
        .navigationTitle("Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink("Edit") {
                    EditLogView(log: log)
                }
            }
        }
        .confirmationDialog("Delete this log?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                modelContext.delete(log)
                dismiss()
            }
        }
    }
}
