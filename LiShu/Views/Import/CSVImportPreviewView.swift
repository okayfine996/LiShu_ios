import SwiftData
import SwiftUI

struct CSVImportPreviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: CSVImportPreviewViewModel

    let onImportCompleted: (ImportResult) -> Void

    @State private var importErrorMessage: String?

    var body: some View {
        CSVSelectionPreviewView(
            config: viewModel.previewConfig,
            items: viewModel.previewItems,
            isAllSelectableSelected: viewModel.isAllSelectableSelected,
            selectableItemsCount: viewModel.selectableItemsCount,
            isProcessing: viewModel.isProcessing,
            isConfirmEnabled: viewModel.canImport,
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
                    await handleConfirmImport()
                }
            }
        )
        .trackScreen("import.csv.preview")
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
                .accessibilityIdentifier("csv.import.preview.backButton")
            }
        }
        .alert(String(localized: "common.error"), isPresented: importErrorBinding) {
            Button(String(localized: "common.ok")) {
                importErrorMessage = nil
            }
        } message: {
            if let importErrorMessage {
                Text(importErrorMessage)
            }
        }
    }

    private var importErrorBinding: Binding<Bool> {
        Binding(
            get: { importErrorMessage != nil },
            set: { if !$0 { importErrorMessage = nil } }
        )
    }

    @MainActor
    private func handleConfirmImport() async {
        guard viewModel.canImport else { return }

        viewModel.isImporting = true
        defer { viewModel.isImporting = false }

        await Task.yield()
        try? await Task.sleep(for: .milliseconds(150))

        do {
            let result = try await viewModel.performImport(container: modelContext.container)
            onImportCompleted(result)
        } catch {
            importErrorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        CSVImportPreviewView(
            viewModel: CSVImportPreviewViewModel(
                previewResult: CSVImportPreviewResult(
                    sourceFileName: "preview.csv",
                    items: [
                        CSVImportPreviewItem(
                            rowNumber: 2,
                            isSelected: true,
                            contactName: "张三",
                            eventName: "婚礼",
                            eventTypeName: "婚礼",
                            sceneTag: "",
                            direction: .given,
                            date: .now,
                            dateText: "2026-04-09",
                            note: "示例备注",
                            recordType: .monetary,
                            contextText: "婚礼",
                            trailingText: "¥800",
                            detailText: "2026-04-09 · 送出 · 金额",
                            status: .ready,
                            payload: CSVImportPayload(
                                contactName: "张三",
                                eventName: "婚礼",
                                eventType: .wedding,
                                sceneTag: "",
                                direction: .given,
                                date: .now,
                                note: "示例备注",
                                recordType: .monetary,
                                relationshipWeight: .reciprocal,
                                returnedAmount: 0,
                                typeData: .monetary(
                                    MonetaryData(
                                        amount: 800,
                                        paymentMethod: PaymentMethod.cash.rawValue,
                                        returnedAmount: 0
                                    )
                                )
                            )
                        ),
                        CSVImportPreviewItem(
                            rowNumber: 3,
                            isSelected: false,
                            contactName: "李四",
                            eventName: "",
                            eventTypeName: "",
                            sceneTag: "",
                            direction: .given,
                            date: .now,
                            dateText: "2026-04-09",
                            note: "",
                            recordType: .favor,
                            contextText: "",
                            trailingText: "帮忙挂号",
                            detailText: "2026-04-09 · 送出 · 帮忙",
                            status: .skipped(String(localized: "csv.import.preview.invalid.missingContext")),
                            payload: nil
                        ),
                    ],
                    skipped: 1,
                    errors: 0
                )
            ),
            onImportCompleted: { _ in }
        )
    }
    .modelContainer(for: [Contact.self, Record.self, Event.self], inMemory: true)
}
