import SwiftData
import SwiftUI

struct LedgerExportPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: LedgerExportPreviewViewModel

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
                .accessibilityIdentifier("xlsx.ledger.export.preview.backButton")
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
        "lishu_ledger_\(sanitizedEventName)_\(Self.exportDateFormatter.string(from: Date())).xlsx"
    }

    private static let exportDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd_HHmmss"
        return f
    }()

    private var sanitizedEventName: String {
        let invalidCharacters = CharacterSet(charactersIn: "/:\\?%*|\"<>")
        let components = viewModel.eventName.components(separatedBy: invalidCharacters)
        let joined = components.joined(separator: "_")
        let trimmed = joined.trimmingCharacters(in: .whitespacesAndNewlines)
        let safe = trimmed.isEmpty ? "event" : trimmed
        return String(safe.prefix(100))
    }
}

#Preview {
    LedgerExportPreviewContainer()
}

private struct LedgerExportPreviewContainer: View {
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
            LedgerExportPreviewView(
                viewModel: LedgerExportPreviewViewModel(
                    previewResult: LedgerExportPreviewResult(
                        eventID: eventID,
                        eventName: "我的婚礼",
                        items: [
                            LedgerExportPreviewItem(
                                rowNumber: 2,
                                isSelected: true,
                                contactName: "张三",
                                contextText: "我的婚礼",
                                detailText: "2026-04-09 · 收到 · 金额",
                                trailingText: "¥1,000",
                                status: .ready,
                                payload: LedgerExportPayload(rowValues: [
                                    "联系人": .string("张三"),
                                    "日期": .string("2026-04-09"),
                                    "备注": .string("婚礼签到时登记"),
                                    "情分分量": .string("礼尚往来"),
                                    "金额": .number(1000.00),
                                    "支付方式": .string("微信"),
                                ])
                            ),
                            LedgerExportPreviewItem(
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
