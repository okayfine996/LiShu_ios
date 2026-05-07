import Foundation

@MainActor
@Observable
class ExportPreviewViewModel {
    let recordType: RecordType
    var items: [ExportPreviewItem]
    var exportError: String?
    var isExporting = false

    init(previewResult: ExportPreviewResult) {
        recordType = previewResult.recordType
        items = previewResult.items
    }

    var selectedItems: [ExportPreviewItem] {
        items.filter { $0.isSelected && $0.isExportable }
    }

    var selectedCount: Int {
        selectedItems.count
    }

    var selectableItemsCount: Int {
        items.filter(\.isExportable).count
    }

    var invalidItemsCount: Int {
        items.count - selectableItemsCount
    }

    var isAllSelectableSelected: Bool {
        selectableItemsCount > 0 && selectedCount == selectableItemsCount
    }

    var hasSelectedItems: Bool {
        selectedCount > 0
    }

    var isProcessing: Bool {
        isExporting
    }

    var canExport: Bool {
        hasSelectedItems && !isExporting
    }

    var previewItems: [CSVSelectionPreviewItem] {
        items.map { item in
            CSVSelectionPreviewItem(
                id: item.id,
                isSelected: item.isSelected,
                isSelectable: item.isExportable,
                contactName: item.contactName,
                contextText: item.contextText,
                detailText: item.detailText,
                trailingText: item.trailingText,
                statusMessage: item.statusMessage,
                highlightsTrailingText: recordType == .monetary
            )
        }
    }

    var previewConfig: CSVSelectionPreviewConfig {
        CSVSelectionPreviewConfig(
            title: String(localized: "csv.export.preview.title"),
            summaryText: String(
                format: String(localized: "csv.export.preview.summary %lld %lld"),
                Int64(selectedCount),
                Int64(invalidItemsCount)
            ),
            confirmButtonTitle: String(
                format: String(localized: "csv.export.preview.confirm %lld"),
                Int64(selectedCount)
            ),
            footerSummaryTitle: nil,
            footerSummaryValue: String(
                format: String(localized: "csv.selection.preview.selectedCount %lld"),
                Int64(selectedCount)
            ),
            confirmIconName: "square.and.arrow.up",
            emptyText: String(localized: "csv.export.preview.empty"),
            loadingText: String(localized: "csv.export.preview.loading"),
            emptyIconName: "square.and.arrow.up",
            selectAllAccessibilityID: "csv.export.preview.selectAllButton",
            confirmAccessibilityID: "csv.export.preview.confirmButton"
        )
    }

    func toggleSelection(id: UUID) {
        guard !isExporting else { return }
        guard let index = items.firstIndex(where: { $0.id == id }), items[index].isExportable else { return }
        items[index].isSelected.toggle()
    }

    func selectAll() {
        guard !isExporting else { return }
        for index in items.indices where items[index].isExportable {
            items[index].isSelected = true
        }
    }

    func deselectAll() {
        guard !isExporting else { return }
        for index in items.indices where items[index].isExportable {
            items[index].isSelected = false
        }
    }

    func exportToTemporaryFile(fileName: String) async throws -> URL {
        guard hasSelectedItems else {
            throw ImportError.invalidFormat
        }
        let url = try await ExportService.exportPreviewItemsToTemporaryFileAsync(
            items,
            recordType: recordType,
            fileName: fileName
        )
        TelemetryDeckAnalytics.signal(TelemetryDeckAnalytics.Signal.xlsxExported,
                                      parameters: ["record_type": recordType.rawValue, "exported_count": String(selectedCount)])
        return url
    }
}
