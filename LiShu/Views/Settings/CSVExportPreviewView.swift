import SwiftUI

struct CSVExportPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: CSVExportPreviewViewModel

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
                .accessibilityIdentifier("csv.export.preview.backButton")
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
        "lishu_\(viewModel.recordType.rawValue)_export_\(dateSuffix()).csv"
    }

    private func dateSuffix() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter.string(from: Date())
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
                            detailText: "2026-04-09 · 送出 · 金额",
                            trailingText: "¥800",
                            status: .ready,
                            payload: CSVExportPayload(csvRow: "张三,婚礼,婚礼,,送出,2026-04-09,备注,800.00,微信,0.00")
                        ),
                        CSVExportPreviewItem(
                            rowNumber: 3,
                            isSelected: false,
                            contactName: "李四",
                            contextText: String(localized: "record.context.daily"),
                            detailText: "2026-04-09 · 送出 · 金额",
                            trailingText: "¥300",
                            status: .skipped(String(localized: "csv.export.preview.invalid.missingContext")),
                            payload: nil
                        ),
                    ],
                    skipped: 1
                )
            ),
            onExportConfirmed: { _ in }
        )
    }
}
