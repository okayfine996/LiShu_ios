import SwiftData
import SwiftUI

struct LedgerImportPreviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: LedgerImportPreviewViewModel

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
                .accessibilityIdentifier("xlsx.ledger.import.preview.backButton")
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
    LedgerImportPreviewContainer()
}

private struct LedgerImportPreviewContainer: View {
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
            LedgerImportPreviewView(
                viewModel: LedgerImportPreviewViewModel(
                    previewResult: LedgerImportPreviewResult(
                        sourceFileName: "ledger.xlsx",
                        eventName: "我的婚礼",
                        items: [
                            LedgerImportPreviewItem(
                                rowNumber: 2,
                                isSelected: true,
                                contactName: "张三",
                                contextText: "我的婚礼",
                                detailText: "2026-04-09 · 收到 · 金额",
                                trailingText: "¥1,000",
                                status: .ready,
                                payload: LedgerImportPayload(
                                    contactName: "张三",
                                    date: .now,
                                    note: "婚礼签到时登记",
                                    relationshipWeight: .reciprocal,
                                    amount: 1000,
                                    paymentMethod: .wechat
                                )
                            ),
                            LedgerImportPreviewItem(
                                rowNumber: 3,
                                isSelected: false,
                                contactName: String(localized: "common.unknown"),
                                contextText: "我的婚礼",
                                detailText: "2026-04-09 · 收到 · 金额",
                                trailingText: "¥0",
                                status: .error(String(localized: "csv.import.preview.invalid.missingContact")),
                                payload: nil
                            ),
                        ],
                        skipped: 0,
                        errors: 1
                    ),
                    eventID: eventID
                ),
                onImportCompleted: { _ in }
            )
        }
        .modelContainer(container)
    }
}
