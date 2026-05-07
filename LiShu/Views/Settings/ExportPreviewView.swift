import SwiftUI

struct ExportPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: ExportPreviewViewModel

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
        .trackScreen("export.xlsx.preview")
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
                .accessibilityIdentifier("xlsx.export.preview.backButton")
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
        "lishu_\(viewModel.recordType.rawValue)_export_\(Self.exportDateFormatter.string(from: Date())).xlsx"
    }

    private static let exportDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd_HHmmss"
        return f
    }()
}

#Preview {
    NavigationStack {
        ExportPreviewView(
            viewModel: ExportPreviewViewModel(
                previewResult: ExportPreviewResult(
                    recordType: .monetary,
                    items: [
                        ExportPreviewItem(
                            rowNumber: 2,
                            isSelected: true,
                            contactName: "张三",
                            contextText: "婚礼",
                            detailText: "2026-04-09 · 送出 · 金额",
                            trailingText: "¥800",
                            status: .ready,
                            payload: ExportPayload(rowValues: [
                                "姓名": .string("张三"),
                                "事件": .string("婚礼"),
                                "金额": .number(800.00),
                            ])
                        ),
                        ExportPreviewItem(
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
