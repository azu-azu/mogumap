import SwiftUI
import SwiftData

struct ExportView: View {
    @Query(sort: \PlaceLog.date, order: .reverse) private var logs: [PlaceLog]
    @State private var exportingOption: ExportService.Option?
    @State private var exportURL: URL?
    @State private var showShareSheet = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section {
                exportRow(
                    title: "export.json_photos".localized,
                    description: "export.json_photos_desc".localized,
                    icon: "archivebox",
                    option: .withPhotos
                )
                exportRow(
                    title: "export.json_only".localized,
                    description: "export.json_only_desc".localized,
                    icon: "doc.text",
                    option: .jsonOnly
                )
            } header: {
                Text(String(format: "export.header".localized, logs.count))
            } footer: {
                Text("export.footer".localized)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(DesignTokens.Background.base.ignoresSafeArea())
        .navigationTitle("nav.export".localized)
        .navigationBarTitleDisplayMode(.inline)
        .alert("export.failed".localized, isPresented: .init(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("action.ok".localized) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = exportURL {
                SaveToFilesPicker(url: url)
            }
        }
    }

    // MARK: - Private

    private func exportRow(
        title: String,
        description: String,
        icon: String,
        option: ExportService.Option
    ) -> some View {
        Button {
            runExport(option: option)
        } label: {
            HStack {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .foregroundStyle(.primary)
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: icon)
                }
                Spacer()
                if exportingOption == option {
                    ProgressView()
                }
            }
        }
        .disabled(exportingOption != nil || logs.isEmpty)
    }

    private func runExport(option: ExportService.Option) {
        exportingOption = option
        Task { @MainActor in
            defer { exportingOption = nil }
            do {
                exportURL = try ExportService.export(logs: logs, option: option)
                showShareSheet = true
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Files export picker

private struct SaveToFilesPicker: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        UIDocumentPickerViewController(forExporting: [url], asCopy: true)
    }

    func updateUIViewController(_ uvc: UIDocumentPickerViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        ExportView()
    }
    .modelContainer(for: [PlaceLog.self, PhotoAttachment.self], inMemory: true)
}
