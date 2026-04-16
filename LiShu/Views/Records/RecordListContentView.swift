import SwiftUI

struct RecordListContentView: View {
    let viewModel: RecordListViewModel
    let hasActiveQuery: Bool
    let onRetry: () -> Void
    let onAddRecord: () -> Void
    let onClearFilters: () -> Void
    let onSelectFilter: (RecordFilter) -> Void
    let onOpenRecord: (Record) -> Void
    let onDeleteRecord: (Record) -> Void
    let onReturnGift: (Record) -> Void
    let filterTitle: (RecordFilter) -> String

    var body: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case let .loaded(grouped) where grouped.isEmpty:
            if hasActiveQuery {
                RecordListFilteredEmptyView(
                    selectedFilter: viewModel.filter,
                    searchText: viewModel.searchText,
                    onClearFilters: onClearFilters,
                    onSelectFilter: onSelectFilter,
                    filterTitle: filterTitle
                )
            } else {
                EmptyStateView(
                    icon: "doc.text",
                    message: String(localized: "record.list.empty"),
                    actionTitle: String(localized: "home.addRecord"),
                    action: onAddRecord
                )
            }
        case .loaded:
            RecordListListView(
                groupedRecords: viewModel.state.value ?? [:],
                sortedMonthKeys: viewModel.sortedMonthKeys,
                selectedFilter: viewModel.filter,
                onSelectFilter: onSelectFilter,
                onOpenRecord: onOpenRecord,
                onDeleteRecord: onDeleteRecord,
                onReturnGift: onReturnGift,
                filterTitle: filterTitle
            )
        case let .error(message):
            ErrorStateView(message: message, retryAction: onRetry)
        }
    }
}
