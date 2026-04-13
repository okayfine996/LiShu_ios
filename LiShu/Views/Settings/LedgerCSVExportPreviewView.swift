import SwiftData
import SwiftUI

struct LedgerCSVExportPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: LedgerCSVExportPreviewViewModel

    let onExportConfirmed: @MainActor (URL) -> Void

    @State private var exportErrorMessage: String?

    var body: some View {
        CSVSelectionPreviewView(
            config: viewModel.previewConfig,
            items: viewModel.previewItems,
            isAllSelectableSelected: viewModel.isAllSelectableSelected,
            selectableItemsCount: viewModel.selectableItemsCount,
            isProcessing: viewModel.isProcessing,
            isConfirmEnabled: viewModel.canExport,
            onToggleSelection: { id in
                viewModel.toggleSelection(id: id)
            },
            onSelectAll: {
                viewModel.selectAll()
            },
            onDeselectAll: {
                viewModel.deselectAll()
            },
            onConfirm: {
                Task {
                    await handleConfirmExport()
                }
            }
        )
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    guard !viewModel.isProcessing else { return }
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.primary)
                }
                .disabled(viewModel.isProcessing)
                .accessibilityIdentifier("csv.ledger.export.preview.backButton")
            }
        }
        .alert(String(localized: "common.error"), isPresented: errorBinding) {
            Button(String(localized: "common.ok")) {
                exportErrorMessage = nil
            }
        } message: {
            if let exportErrorMessage {
                Text(exportErrorMessage)
            }
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { exportErrorMessage != nil },
            set: { if !$0 { exportErrorMessage = nil } }
        )
    }

    @MainActor
    private func handleConfirmExport() async {
        guard viewModel.canExport else { return }

        viewModel.isExporting = true
        defer { viewModel.isExporting = false }

        await Task.yield()
        try? await Task.sleep(for: .milliseconds(150))

        do {
            let fileURL = try await viewModel.exportToTemporaryFile(fileName: exportFileName)
            onExportConfirmed(fileURL)
        } catch {
            exportErrorMessage = error.localizedDescription
        }
    }

    private var exportFileName: String {
        "lishu_ledger_\(sanitizedEventName)_\(dateSuffix()).csv"
    }

    private func dateSuffix() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter.string(from: Date())
    }

    private var sanitizedEventName: String {
        let invalidCharacters = CharacterSet(charactersIn: "/:\\?%*|\"<>")
        let components = viewModel.eventName.components(separatedBy: invalidCharacters)
        let joined = components.joined(separator: "_")
        let trimmed = joined.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "event" : trimmed
    }
}

#Preview {
    LedgerCSVExportPreviewContainer()
}

private struct LedgerCSVExportPreviewContainer: View {
    private let container: ModelContainer
    private let eventID: PersistentIdentifier

    init() {
        let schema = Schema([Contact.self, Record.self, Event.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try! ModelContainer(for: schema, configurations: [configuration])

        let context = container.mainContext
        let event = Event(name: "我的婚礼", type: .wedding, hostMode: .host, date: .now, location: "北京")
        context.insert(event)
        try? context.save()
        eventID = event.persistentModelID
    }

    var body: some View {
        NavigationStack {
            LedgerCSVExportPreviewView(
                viewModel: LedgerCSVExportPreviewViewModel(
                    previewResult: LedgerCSVExportPreviewResult(
                        eventID: eventID,
                        eventName: "我的婚礼",
                        items: [
                            LedgerCSVExportPreviewItem(
                                rowNumber: 2,
                                isSelected: true,
                                contactName: "张三",
                                contextText: "我的婚礼",
                                detailText: "2026-04-09 · 收到 · 金额",
                                trailingText: "¥1,000",
                                status: .ready,
                                payload: LedgerCSVExportPayload(
                                    csvRow: "张三,2026-04-09,婚礼签到时登记,礼尚往来,1000.00,微信"
                                )
                            ),
                            LedgerCSVExportPreviewItem(
                                rowNumber: 3,
                                isSelected: false,
                                contactName: "李四",
                                contextText: "我的婚礼",
                                detailText: "2026-04-09 · 收到 · 金额",
                                trailingText: "¥800",
                                status: .skipped(String(localized: "csv.export.preview.invalid.missingContact")),
                                payload: nil
                            ),
                        ],
                        skipped: 1
                    )
                ),
                onExportConfirmed: { _ in }
            )
        }
        .modelContainer(container)
    }
}
