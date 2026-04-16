import SwiftUI

#Preview {
    NavigationStack {
        CSVSelectionPreviewView(
            config: CSVSelectionPreviewConfig(
                title: String(localized: "csv.import.preview.title"),
                summaryText: String(
                    format: String(localized: "csv.import.preview.summary %lld %lld"),
                    Int64(1),
                    Int64(1)
                ),
                confirmButtonTitle: String(
                    format: String(localized: "csv.import.preview.confirm %lld"),
                    Int64(1)
                ),
                footerSummaryTitle: nil,
                footerSummaryValue: String(
                    format: String(localized: "csv.selection.preview.selectedCount %lld"),
                    Int64(1)
                ),
                confirmIconName: "square.and.arrow.down",
                emptyText: String(localized: "csv.import.preview.empty"),
                loadingText: String(localized: "csv.import.preview.loading"),
                emptyIconName: "doc.text.magnifyingglass",
                selectAllAccessibilityID: "preview.selectAllButton",
                confirmAccessibilityID: "preview.confirmButton"
            ),
            items: [
                CSVSelectionPreviewItem(
                    id: UUID(),
                    isSelected: true,
                    isSelectable: true,
                    contactName: "张三",
                    contextText: "婚礼",
                    detailText: "2026-04-09 · 送出 · 金额",
                    trailingText: "¥800",
                    statusMessage: nil,
                    highlightsTrailingText: true
                ),
                CSVSelectionPreviewItem(
                    id: UUID(),
                    isSelected: false,
                    isSelectable: false,
                    contactName: "李四",
                    contextText: String(localized: "record.context.daily"),
                    detailText: "2026-04-09 · 送出 · 礼品",
                    trailingText: "茶具",
                    statusMessage: String(localized: "csv.import.preview.invalid.missingContext"),
                    highlightsTrailingText: false
                ),
            ],
            isAllSelectableSelected: true,
            selectableItemsCount: 1,
            isProcessing: false,
            isConfirmEnabled: true,
            onToggleSelection: { _ in },
            onSelectAll: {},
            onDeselectAll: {},
            onConfirm: {}
        )
    }
}
