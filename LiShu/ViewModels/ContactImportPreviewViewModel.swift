import Foundation
import SwiftData

@MainActor
@Observable
class ContactImportPreviewViewModel {
    let sourceFileName: String
    var items: [ContactPreviewItem]
    var isImporting = false

    init(previewResult: ContactPreviewResult) {
        sourceFileName = previewResult.sourceFileName
        items = previewResult.items
    }

    var selectedItems: [ContactPreviewItem] {
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
                contactName: item.name,
                contextText: item.detailText,
                detailText: "",
                trailingText: "",
                statusMessage: item.statusMessage,
                highlightsTrailingText: false
            )
        }
    }

    var previewConfig: CSVSelectionPreviewConfig {
        CSVSelectionPreviewConfig(
            title: String(localized: "contact.csv.preview.title"),
            summaryText: String(
                format: String(localized: "contact.csv.preview.summary %lld %lld"),
                Int64(selectedCount),
                Int64(invalidItemsCount)
            ),
            confirmButtonTitle: String(
                format: String(localized: "contact.csv.preview.confirm %lld"),
                Int64(selectedCount)
            ),
            footerSummaryTitle: nil,
            footerSummaryValue: String(
                format: String(localized: "csv.selection.preview.selectedCount %lld"),
                Int64(selectedCount)
            ),
            confirmIconName: "square.and.arrow.down",
            emptyText: String(localized: "contact.csv.preview.empty"),
            loadingText: String(localized: "contact.csv.preview.loading"),
            emptyIconName: "person.crop.rectangle.stack",
            selectAllAccessibilityID: "contact.csv.preview.selectAllButton",
            confirmAccessibilityID: "contact.csv.preview.confirmButton"
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

    func performImport(container: ModelContainer) async throws -> ContactImportResult {
        guard selectedCount > 0 else {
            throw ImportError.invalidFormat
        }

        let result = try await ExportService.importContactPreviewItemsAsync(
            selectedItems,
            container: container
        )
        TelemetryDeckAnalytics.signal(TelemetryDeckAnalytics.Signal.contactXlsxImported,
                                      parameters: ["imported_count": String(result.created)])
        return result
    }
}
