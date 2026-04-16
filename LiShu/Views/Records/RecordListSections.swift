import SwiftData
import SwiftUI

struct RecordListFilteredEmptyView: View {
    let selectedFilter: RecordFilter
    let searchText: String
    let onClearFilters: () -> Void
    let onSelectFilter: (RecordFilter) -> Void
    let filterTitle: (RecordFilter) -> String

    var body: some View {
        List {
            RecordListRowContainer {
                RecordListFilterChips(
                    selectedFilter: selectedFilter,
                    onSelectFilter: onSelectFilter,
                    filterTitle: filterTitle
                )
            }

            RecordListRowContainer(bottomInset: DesignSystem.Spacing.section) {
                EmptyStateView(
                    icon: "line.3.horizontal.decrease.circle",
                    message: String(localized: "record.list.empty"),
                    actionTitle: String(localized: "record.filter.all"),
                    action: onClearFilters
                )
                .frame(minHeight: 320)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(DesignSystem.Colors.bgPage)
    }
}

struct RecordListListView: View {
    let groupedRecords: [String: [Record]]
    let sortedMonthKeys: [String]
    let selectedFilter: RecordFilter
    let onSelectFilter: (RecordFilter) -> Void
    let onOpenRecord: (Record) -> Void
    let onDeleteRecord: (Record) -> Void
    let onReturnGift: (Record) -> Void
    let filterTitle: (RecordFilter) -> String

    var body: some View {
        List {
            RecordListRowContainer {
                RecordListFilterChips(
                    selectedFilter: selectedFilter,
                    onSelectFilter: onSelectFilter,
                    filterTitle: filterTitle
                )
            }

            ForEach(sortedMonthKeys, id: \.self) { monthKey in
                RecordListMonthSection(
                    monthKey: monthKey,
                    records: groupedRecords[monthKey] ?? [],
                    onOpenRecord: onOpenRecord,
                    onDeleteRecord: onDeleteRecord,
                    onReturnGift: onReturnGift
                )
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(DesignSystem.Colors.bgPage)
    }
}

private struct RecordListFilterChips: View {
    let selectedFilter: RecordFilter
    let onSelectFilter: (RecordFilter) -> Void
    let filterTitle: (RecordFilter) -> String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(RecordFilter.allCases, id: \.self) { filter in
                    let isSelected = selectedFilter == filter

                    Button {
                        onSelectFilter(filter)
                    } label: {
                        Text(filterTitle(filter))
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(isSelected ? .white : DesignSystem.Colors.textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.bgSurface
                            )
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(
                                        isSelected ? Color.clear : DesignSystem.Colors.border,
                                        lineWidth: 1
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct RecordListMonthSection: View {
    let monthKey: String
    let records: [Record]
    let onOpenRecord: (Record) -> Void
    let onDeleteRecord: (Record) -> Void
    let onReturnGift: (Record) -> Void

    var body: some View {
        Section {
            ForEach(records) { record in
                Button {
                    onOpenRecord(record)
                } label: {
                    RecordRow(record: record)
                        .background(DesignSystem.Colors.bgSurface)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("record.list.row.\(String(describing: record.persistentModelID))")
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        onDeleteRecord(record)
                    } label: {
                        Label(String(localized: "common.delete"), systemImage: "trash")
                    }
                }
                .contextMenu {
                    if record.recordType == .monetary, record.direction == .given {
                        Button {
                            onReturnGift(record)
                        } label: {
                            Label(String(localized: "record.detail.returnGift"), systemImage: "gift")
                        }
                    }
                }
                .listRowInsets(EdgeInsets(
                    top: 0,
                    leading: DesignSystem.Spacing.pageHorizontal,
                    bottom: DesignSystem.Spacing.block,
                    trailing: DesignSystem.Spacing.pageHorizontal
                ))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
        } header: {
            Text(monthKey)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .fontWeight(.semibold)
                .textCase(nil)
                .padding(.top, DesignSystem.Spacing.block)
        }
    }
}

private struct RecordListRowContainer<Content: View>: View {
    var bottomInset: CGFloat = DesignSystem.Spacing.block
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .listRowInsets(EdgeInsets(
                top: 0,
                leading: DesignSystem.Spacing.pageHorizontal,
                bottom: bottomInset,
                trailing: DesignSystem.Spacing.pageHorizontal
            ))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
}
