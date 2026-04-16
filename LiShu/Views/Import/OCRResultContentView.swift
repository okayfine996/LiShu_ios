import SwiftUI

struct OCRResultContentView: View {
    @Bindable var viewModel: OCRImportViewModel
    let pendingDeleteCount: Int
    @Binding var showDeleteConfirm: Bool
    let onRetake: () -> Void
    let onToggleSelectAll: () -> Void
    let onEditItem: (OCRRecordItem) -> Void
    let onToggleSelection: (OCRRecordItem) -> Void
    let onDeleteTap: () -> Void
    let onImportTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            OCRResultTopStateSection(
                lowConfidenceCount: viewModel.lowConfidenceCount,
                isAIEnhanced: viewModel.isAIEnhanced
            )

            Group {
                if viewModel.items.isEmpty {
                    OCRResultEmptyState()
                } else {
                    OCRResultListSection(
                        items: viewModel.items,
                        onEditItem: onEditItem,
                        onToggleSelection: onToggleSelection
                    )
                }
            }

            OCRResultBottomToolbar(
                selectedCount: viewModel.selectedCount,
                isImporting: viewModel.isImporting,
                canImport: viewModel.canImport,
                onDeleteTap: onDeleteTap,
                onImportTap: onImportTap
            )
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                OCRResultRetakeButton(action: onRetake)
            }
            ToolbarItem(placement: .topBarTrailing) {
                OCRResultSelectAllButton(
                    isAllSelected: viewModel.isAllSelected,
                    action: onToggleSelectAll
                )
            }
        }
    }
}
