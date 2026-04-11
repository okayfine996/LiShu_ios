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
        VStack(spacing: 0) {
            if items.isEmpty {
                EmptyState(config: config)
            } else {
                ContentSection(
                    config: config,
                    items: items,
                    isProcessing: isProcessing,
                    onToggleSelection: onToggleSelection
                )
            }

            BottomBar(
                config: config,
                isConfirmEnabled: isConfirmEnabled,
                onConfirm: onConfirm
            )
        }
        .background(DesignSystem.Colors.bgPage)
        .navigationTitle(config.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(isProcessing ? .hidden : .visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if selectableItemsCount > 0 {
                    Button(
                        isAllSelectableSelected
                            ? String(localized: "contact.import.deselectAll")
                            : String(localized: "contact.import.selectAll")
                    ) {
                        if isAllSelectableSelected {
                            onDeselectAll()
                        } else {
                            onSelectAll()
                        }
                    }
                    .foregroundStyle(DesignSystem.Colors.primary)
                    .disabled(isProcessing)
                    .accessibilityIdentifier(config.selectAllAccessibilityID)
                }
            }
        }
        .overlay {
            if isProcessing {
                LoadingOverlay(text: config.loadingText)
                    .accessibilityIdentifier("csv.selection.preview.loadingOverlay")
            }
        }
    }
}

private struct ContentSection: View {
    let config: CSVSelectionPreviewConfig
    let items: [CSVSelectionPreviewItem]
    let isProcessing: Bool
    let onToggleSelection: (UUID) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text(config.summaryText)
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, DesignSystem.Spacing.pageHorizontal)
                .padding(.top, DesignSystem.Spacing.block)

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: DesignSystem.Spacing.block) {
                    ForEach(items) { item in
                        Row(item: item, isProcessing: isProcessing) {
                            onToggleSelection(item.id)
                        }
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.pageHorizontal)
                .padding(.vertical, DesignSystem.Spacing.cardPaddingSmall)
                .padding(.bottom, DesignSystem.Spacing.scrollBottom)
            }
        }
    }
}

private struct Row: View {
    let item: CSVSelectionPreviewItem
    let isProcessing: Bool
    let onTap: () -> Void

    var body: some View {
        Group {
            if item.isSelectable {
                Button(action: onTap) {
                    RowContent(item: item)
                }
                .buttonStyle(.plain)
                .disabled(isProcessing)
            } else {
                RowContent(item: item)
            }
        }
    }
}

private struct RowContent: View {
    let item: CSVSelectionPreviewItem

    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.block) {
            SelectionIndicator(item: item)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.stackTight) {
                HStack(alignment: .top, spacing: DesignSystem.Spacing.inlineTight) {
                    Text(item.contactName)
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if !item.trailingText.isEmpty {
                        Text(item.trailingText)
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(
                                item.highlightsTrailingText
                                    ? DesignSystem.Colors.primary
                                    : DesignSystem.Colors.textSecondary
                            )
                    }
                }

                Text(item.contextText)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                Text(item.detailText)
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)

                if let statusMessage = item.statusMessage {
                    Text(statusMessage)
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(item.isSelectable ? DesignSystem.Colors.textSecondary : DesignSystem.Colors.destructive)
                }
            }
        }
        .padding(DesignSystem.Spacing.cardPaddingSmall)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard)
                .stroke(
                    item.isSelectable
                        ? DesignSystem.Colors.border
                        : DesignSystem.Colors.destructive.opacity(0.25),
                    lineWidth: 1
                )
        )
        .opacity(item.isSelectable ? 1 : DesignSystem.Effects.disabledOpacity)
    }
}

private struct SelectionIndicator: View {
    let item: CSVSelectionPreviewItem

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(
                    item.isSelectable
                        ? (item.isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.border)
                        : DesignSystem.Colors.textTertiary,
                    lineWidth: 2
                )
                .frame(width: 24, height: 24)

            if item.isSelectable, item.isSelected {
                Circle()
                    .fill(DesignSystem.Colors.primary)
                    .frame(width: 24, height: 24)

                Image(systemName: "checkmark")
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textOnPrimary)
            } else if !item.isSelectable {
                Image(systemName: "xmark")
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
        }
        .padding(.top, 2)
    }
}

private struct BottomBar: View {
    let config: CSVSelectionPreviewConfig
    let isConfirmEnabled: Bool
    let onConfirm: () -> Void

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.dense) {
            Rectangle()
                .fill(DesignSystem.Colors.separator)
                .frame(height: 1)

            HStack(alignment: .center, spacing: DesignSystem.Spacing.block) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.stackTight) {
                    if let footerSummaryTitle = config.footerSummaryTitle {
                        Text(footerSummaryTitle)
                            .font(DesignSystem.Typography.small)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                            .lineLimit(1)
                    }

                    if let footerSummaryValue = config.footerSummaryValue {
                        Text(footerSummaryValue)
                            .font(DesignSystem.Typography.body)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 0)

                Button(action: onConfirm) {
                    HStack(spacing: DesignSystem.Spacing.inlineTight) {
                        if let confirmIconName = config.confirmIconName {
                            Image(systemName: confirmIconName)
                                .font(DesignSystem.Typography.caption)
                        }

                        Text(config.confirmButtonTitle)
                            .fontWeight(.medium)
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!isConfirmEnabled)
                .accessibilityIdentifier(config.confirmAccessibilityID)
                .frame(maxWidth: DesignSystem.Layout.selectionPreviewActionWidth)
            }
            .padding(.horizontal, DesignSystem.Spacing.pageHorizontal)
            .padding(.top, DesignSystem.Spacing.block)
            .padding(.bottom, DesignSystem.Spacing.pageHorizontal)
        }
        .background(DesignSystem.Colors.bgPage)
    }
}

private struct EmptyState: View {
    let config: CSVSelectionPreviewConfig

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.block) {
            Spacer()

            Image(systemName: config.emptyIconName)
                .font(DesignSystem.Typography.display)
                .foregroundStyle(DesignSystem.Colors.textTertiary)

            Text(config.emptyText)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Spacer()
        }
        .padding(.horizontal, DesignSystem.Spacing.pageHorizontal)
    }
}

private struct LoadingOverlay: View {
    let text: String

    var body: some View {
        ZStack {
            DesignSystem.Colors.bgPage.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: DesignSystem.Spacing.block) {
                ProgressView()
                    .tint(DesignSystem.Colors.primary)

                Text(text)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
            }
            .padding(DesignSystem.Spacing.cardPadding)
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        }
        .allowsHitTesting(true)
    }
}

#Preview {
    NavigationStack {
        CSVSelectionPreviewView(
            config: CSVSelectionPreviewConfig(
                title: String(localized: "csv.import.preview.title"),
                summaryText: String(format: String(localized: "csv.import.preview.summary %lld %lld"), Int64(1), Int64(1)),
                confirmButtonTitle: String(format: String(localized: "csv.import.preview.confirm %lld"), Int64(1)),
                footerSummaryTitle: nil,
                footerSummaryValue: String(format: String(localized: "csv.selection.preview.selectedCount %lld"), Int64(1)),
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
