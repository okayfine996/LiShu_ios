import SwiftUI

struct CSVSelectionPreviewContainer: View {
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
                CSVSelectionPreviewEmptyState(config: config)
            } else {
                CSVSelectionPreviewContentSection(
                    config: config,
                    items: items,
                    isProcessing: isProcessing,
                    onToggleSelection: onToggleSelection
                )
            }

            CSVSelectionPreviewBottomBar(
                config: config,
                isConfirmEnabled: isConfirmEnabled,
                onConfirm: onConfirm
            )
        }
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
                CSVSelectionPreviewLoadingOverlay(text: config.loadingText)
                    .accessibilityIdentifier("csv.selection.preview.loadingOverlay")
            }
        }
    }
}

private struct CSVSelectionPreviewContentSection: View {
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
                        CSVSelectionPreviewRow(item: item, isProcessing: isProcessing) {
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

private struct CSVSelectionPreviewRow: View {
    let item: CSVSelectionPreviewItem
    let isProcessing: Bool
    let onTap: () -> Void

    var body: some View {
        Group {
            if item.isSelectable {
                Button(action: onTap) {
                    CSVSelectionPreviewRowContent(item: item)
                }
                .buttonStyle(.plain)
                .disabled(isProcessing)
            } else {
                CSVSelectionPreviewRowContent(item: item)
            }
        }
    }
}

private struct CSVSelectionPreviewRowContent: View {
    let item: CSVSelectionPreviewItem

    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.block) {
            CSVSelectionPreviewSelectionIndicator(item: item)

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
                        .foregroundStyle(
                            item.isSelectable
                                ? DesignSystem.Colors.textSecondary
                                : DesignSystem.Colors.destructive
                        )
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

private struct CSVSelectionPreviewSelectionIndicator: View {
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

private struct CSVSelectionPreviewBottomBar: View {
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

private struct CSVSelectionPreviewEmptyState: View {
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

private struct CSVSelectionPreviewLoadingOverlay: View {
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
