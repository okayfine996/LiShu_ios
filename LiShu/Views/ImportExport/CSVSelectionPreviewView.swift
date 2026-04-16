import SwiftUI

struct CSVSelectionPreviewItem: Identifiable {
    let id: UUID
    let isSelected: Bool
    let isSelectable: Bool
    let contactName: String
    let contextText: String
    let detailText: String
    let trailingText: String
    let statusMessage: String?
    let highlightsTrailingText: Bool
}

struct CSVSelectionPreviewConfig {
    let title: String
    let summaryText: String
    let confirmButtonTitle: String
    let footerSummaryTitle: String?
    let footerSummaryValue: String?
    let confirmIconName: String?
    let emptyText: String
    let loadingText: String
    let emptyIconName: String
    let selectAllAccessibilityID: String
    let confirmAccessibilityID: String
}

struct CSVSelectionPreviewView: View {
    let config: CSVSelectionPreviewConfig
    let items: [CSVSelectionPreviewItem]
    let isAllSelectableSelected: Bool
    let selectableItemsCount: Int
    let isProcessing: Bool
    let isConfirmEnabled: Bool
    let onToggleSelection: (UUID) -> Void
    let onSelectAll: () -> Void
    let onDeselectAll: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        CSVSelectionPreviewContainer(
            config: config,
            items: items,
            isAllSelectableSelected: isAllSelectableSelected,
            selectableItemsCount: selectableItemsCount,
            isProcessing: isProcessing,
            isConfirmEnabled: isConfirmEnabled,
            onToggleSelection: onToggleSelection,
            onSelectAll: onSelectAll,
            onDeselectAll: onDeselectAll,
            onConfirm: onConfirm
        )
        .background(DesignSystem.Colors.bgPage)
        .navigationTitle(config.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
