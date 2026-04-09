import SwiftUI

struct CSVExportPreviewView: View {
    @Bindable var viewModel: CSVExportPreviewViewModel

    let onExportConfirmed: @MainActor (String, RecordType) async -> Void

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
            let csv = try viewModel.buildCSV()
            await onExportConfirmed(csv, viewModel.recordType)
        } catch {
            exportErrorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        CSVExportPreviewView(
            viewModel: CSVExportPreviewViewModel(
                previewResult: CSVExportPreviewResult(
                    recordType: .monetary,
                    items: [
                        CSVExportPreviewItem(
                            rowNumber: 2,
                            isSelected: true,
                            contactName: "张三",
                            contextText: "婚礼",
                            detailText: "2026-04-09 10:30 · 送出 · 金额",
                            trailingText: "¥800",
                            status: .ready,
                            payload: CSVExportPayload(csvRow: "张三,婚礼,婚礼,,送出,2026-04-09 10:30,备注,800.00,微信,0.00")
                        ),
                        CSVExportPreviewItem(
                            rowNumber: 3,
                            isSelected: false,
                            contactName: "李四",
                            contextText: String(localized: "record.context.daily"),
                            detailText: "2026-04-09 10:30 · 送出 · 金额",
                            trailingText: "¥300",
                            status: .skipped(String(localized: "csv.export.preview.invalid.missingContext")),
                            payload: nil
                        ),
                    ],
                    skipped: 1
                )
            ),
            onExportConfirmed: { _, _ in }
        )
    }
}
