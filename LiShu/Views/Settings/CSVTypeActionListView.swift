import SwiftData
import SwiftUI

enum CSVTypeActionMode {
    case templateDownload
    case typedExport

    var title: String {
        switch self {
        case .templateDownload:
            String(localized: "settings.data.downloadTemplate")
        case .typedExport:
            String(localized: "settings.data.exportCSV")
        }
    }

    var iconName: String {
        switch self {
        case .templateDownload:
            "arrow.down.doc"
        case .typedExport:
            "square.and.arrow.up"
        }
    }

    var requiresPro: Bool {
        switch self {
        case .templateDownload:
            false
        case .typedExport:
            true
        }
    }
}

struct CSVTypeActionListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(DebugOverrideManager.self) private var debugOverrides

    @State private var shareURL: URL?
    @State private var exportError: String?
    @State private var showProSheet = false
    @State private var showExportPreview = false
    @State private var exportPreviewViewModel: CSVExportPreviewViewModel?

    let mode: CSVTypeActionMode

    private let csvTypes: [RecordType] = [.monetary, .gift, .favor, .banquet]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 8) {
                sectionHeader(mode.title)

                VStack(spacing: 0) {
                    ForEach(Array(csvTypes.enumerated()), id: \.offset) { index, recordType in
                        if index > 0 {
                            Divider()
                                .background(DesignSystem.Colors.separator)
                                .padding(.leading, 56)
                        }

                        Button {
                            handleAction(for: recordType)
                        } label: {
                            rowContent(for: recordType)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .background(DesignSystem.Colors.bgSurface)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))

                footerText
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                    .padding(.leading, 4)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .background(DesignSystem.Colors.bgPage)
        .navigationTitle(mode.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showExportPreview) {
            if let exportPreviewViewModel {
                CSVExportPreviewView(viewModel: exportPreviewViewModel) { csv, recordType in
                    await handleConfirmedExport(csv: csv, recordType: recordType)
                }
            }
        }
        .sheet(isPresented: $showProSheet) {
            NavigationStack {
                ProMembershipView()
            }
        }
        .sheet(item: Binding(
            get: { shareURL.map { CSVTypeShareableFile(id: $0.absoluteString, url: $0) } },
            set: {
                if let url = shareURL, $0 == nil {
                    try? FileManager.default.removeItem(at: url)
                }
                shareURL = $0?.url
            }
        )) { item in
            ShareSheet(url: item.url) {
                shareURL = nil
                try? FileManager.default.removeItem(at: item.url)
            }
        }
        .alert(String(localized: "common.error"), isPresented: Binding(
            get: { exportError != nil },
            set: { if !$0 { exportError = nil } }
        )) {
            Button(String(localized: "common.ok")) {
                exportError = nil
            }
        } message: {
            if let exportError {
                Text(exportError)
            }
        }
        .onChange(of: showExportPreview) { _, newValue in
            if !newValue {
                exportPreviewViewModel = nil
            }
        }
    }

    private var footerText: Text {
        switch mode {
        case .templateDownload:
            Text(String(localized: "settings.data.importHint"))
        case .typedExport:
            Text(String(localized: "settings.data.proHint"))
        }
    }

    private var effectiveProAccessEnabled: Bool {
        subscriptionManager.effectiveIsPro(overrides: debugOverrides)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(DesignSystem.Typography.small)
            .foregroundStyle(DesignSystem.Colors.textSecondary)
            .padding(.leading, 4)
    }

    private func rowContent(for recordType: RecordType) -> some View {
        HStack(spacing: 12) {
            Image(systemName: mode.iconName)
                .font(.system(size: 18))
                .foregroundStyle(DesignSystem.Colors.primary)
                .frame(width: 28, height: 28)

            Text(actionTitle(for: recordType))
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            if mode.requiresPro {
                Text("Pro")
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.accentGold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(DesignSystem.Colors.accentGold.opacity(0.15))
                    .clipShape(Capsule())
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(DesignSystem.Colors.textTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func actionTitle(for recordType: RecordType) -> String {
        switch mode {
        case .templateDownload:
            String(format: String(localized: "settings.data.templateType %@"), recordType.displayName)
        case .typedExport:
            String(format: String(localized: "settings.data.exportType %@"), recordType.displayName)
        }
    }

    private func handleAction(for recordType: RecordType) {
        switch mode {
        case .templateDownload:
            downloadTemplate(for: recordType)
        case .typedExport:
            exportCSV(for: recordType)
        }
    }

    private func exportCSV(for recordType: RecordType) {
        guard effectiveProAccessEnabled else {
            showProSheet = true
            return
        }

        do {
            let preview = try ExportService.previewExportCSV(context: modelContext, recordType: recordType)
            exportPreviewViewModel = CSVExportPreviewViewModel(previewResult: preview)
            showExportPreview = true
        } catch {
            exportError = error.localizedDescription
        }
    }

    @MainActor
    private func handleConfirmedExport(csv: String, recordType: RecordType) async {
        do {
            let tempDir = FileManager.default.temporaryDirectory
            let fileName = "lishu_\(recordType.rawValue)_export_\(dateSuffix()).csv"
            guard let data = csv.data(using: .utf8) else {
                exportError = String(localized: "settings.data.export_encoding_failed")
                return
            }
            let fileURL = tempDir.appendingPathComponent(fileName)
            try data.write(to: fileURL)
            showExportPreview = false
            shareURL = fileURL
        } catch {
            exportError = error.localizedDescription
        }
    }

    private func downloadTemplate(for recordType: RecordType) {
        do {
            let tempDir = FileManager.default.temporaryDirectory
            let fileName = "lishu_\(recordType.rawValue)_template.csv"
            guard let data = ExportService.templateCSV(for: recordType).data(using: .utf8) else {
                exportError = String(localized: "settings.data.export_encoding_failed")
                return
            }
            let fileURL = tempDir.appendingPathComponent(fileName)
            try data.write(to: fileURL)
            shareURL = fileURL
        } catch {
            exportError = error.localizedDescription
        }
    }

    private func dateSuffix() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter.string(from: Date())
    }
}

private struct CSVTypeShareableFile: Identifiable {
    let id: String
    let url: URL
}

#Preview {
    NavigationStack {
        CSVTypeActionListView(mode: .templateDownload)
            .environment(SubscriptionManager.shared)
            .environment(DebugOverrideManager())
    }
    .modelContainer(for: [Contact.self, Record.self, Event.self], inMemory: true)
}
