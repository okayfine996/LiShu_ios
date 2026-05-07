import Foundation
import SwiftData

@MainActor
@Observable
class LedgerImportPreviewViewModel {
    let sourceFileName: String
    let eventID: PersistentIdentifier
    let eventName: String
    var items: [LedgerImportPreviewItem]
    var isImporting = false
    var importError: String?

    private let baseResult: ImportResult

    init(previewResult: LedgerImportPreviewResult, eventID: PersistentIdentifier) {
        sourceFileName = previewResult.sourceFileName
        self.eventID = eventID
        eventName = previewResult.eventName
        items = previewResult.items
        baseResult = ImportResult(imported: 0, skipped: previewResult.skipped, errors: previewResult.errors)
    }

    var selectedItems: [LedgerImportPreviewItem] {
        items.filter { $0.isSelected && $0.isImportable }
    }

    var selectedCount: Int {
        selectedItems.count
    }

    var selectableItemsCount: Int {
        items.filter(\.isImportable).count
    }

    var invalidItemsCount: Int {
        items.count - selectableItemsCount
    }

    var isAllSelectableSelected: Bool {
        selectableItemsCount > 0 && selectedCount == selectableItemsCount
    }

    var isProcessing: Bool {
        isImporting
    }

    var canImport: Bool {
        selectedCount > 0 && !isImporting
    }

    var previewItems: [CSVSelectionPreviewItem] {
        items.map { item in
            CSVSelectionPreviewItem(
                id: item.id,
                isSelected: item.isSelected,
                isSelectable: item.isImportable,
                contactName: item.contactName,
                contextText: item.contextText,
                detailText: item.detailText,
                trailingText: item.trailingText,
                statusMessage: item.statusMessage,
                highlightsTrailingText: true
            )
        }
    }

    var previewConfig: CSVSelectionPreviewConfig {
        CSVSelectionPreviewConfig(
            title: String(localized: "csv.ledger.import.preview.title"),
            summaryText: String(
                format: String(localized: "csv.ledger.import.preview.summary %lld %lld"),
                Int64(selectedCount),
                Int64(invalidItemsCount)
            ),
            confirmButtonTitle: String(
                format: String(localized: "csv.ledger.import.preview.confirm %lld"),
                Int64(selectedCount)
            ),
            footerSummaryTitle: nil,
            footerSummaryValue: String(
                format: String(localized: "csv.selection.preview.selectedCount %lld"),
                Int64(selectedCount)
            ),
            confirmIconName: "square.and.arrow.down",
            emptyText: String(localized: "csv.ledger.import.preview.empty"),
            loadingText: String(localized: "csv.ledger.import.preview.loading"),
            emptyIconName: "tray",
            selectAllAccessibilityID: "csv.ledger.import.preview.selectAllButton",
            confirmAccessibilityID: "csv.ledger.import.preview.confirmButton"
        )
    }

    func toggleSelection(id: UUID) {
        guard !isImporting else { return }
        guard let index = items.firstIndex(where: { $0.id == id }), items[index].isImportable else { return }
        items[index].isSelected.toggle()
    }

    func selectAll() {
        guard !isImporting else { return }
        for index in items.indices where items[index].isImportable {
            items[index].isSelected = true
        }
    }

    func deselectAll() {
        guard !isImporting else { return }
        for index in items.indices where items[index].isImportable {
            items[index].isSelected = false
        }
    }

    func performImport(container: ModelContainer) async throws -> ImportResult {
        guard selectedCount > 0 else {
            throw ImportError.invalidFormat
        }
        return try await ExportService.importLedgerPreviewItemsAsync(
            items,
            baseResult: baseResult,
            sourceFileName: sourceFileName,
            eventID: eventID,
            container: container
        )
    }
}
