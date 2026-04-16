import SwiftUI

struct OCRResultTopStateSection: View {
    let lowConfidenceCount: Int
    let isAIEnhanced: Bool

    var body: some View {
        VStack(spacing: 0) {
            if lowConfidenceCount > 0 {
                OCRResultWarningBanner(lowConfidenceCount: lowConfidenceCount)
            }

            if isAIEnhanced {
                OCRResultAIEnhancedBadge()
            }
        }
    }
}

struct OCRResultEmptyState: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "doc.text.magnifyingglass")
                .font(DesignSystem.Typography.title1)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
            Text(String(localized: "ocr.result.empty"))
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
            Spacer()
        }
    }
}

struct OCRResultListSection: View {
    let items: [OCRRecordItem]
    let onEditItem: (OCRRecordItem) -> Void
    let onToggleSelection: (OCRRecordItem) -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 10) {
                ForEach(items) { item in
                    OCRResultRow(
                        item: item,
                        onEdit: { onEditItem(item) },
                        onToggleSelection: { onToggleSelection(item) }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .padding(.bottom, 80)
        }
    }
}

struct OCRResultBottomToolbar: View {
    let selectedCount: Int
    let isImporting: Bool
    let canImport: Bool
    let onDeleteTap: () -> Void
    let onImportTap: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Text(String(format: String(localized: "ocr.result.selected %lld"), Int64(selectedCount)))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Spacer()

            Button(action: onDeleteTap) {
                Text(String(localized: "ocr.delete"))
                    .font(DesignSystem.Typography.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
            }
            .accessibilityIdentifier("ocr.result.deleteButton")
            .buttonStyle(SecondaryButtonStyle())
            .disabled(selectedCount == 0)

            Button(action: onImportTap) {
                if isImporting {
                    ProgressView()
                        .tint(.white)
                        .padding(.vertical, 10)
                } else {
                    Text(String(localized: "ocr.import.confirmImport"))
                        .font(DesignSystem.Typography.caption)
                        .fontWeight(.medium)
                        .padding(.vertical, 10)
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!canImport || isImporting)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(
            DesignSystem.Colors.bgSurface
                .shadow(color: .black.opacity(0.06), radius: 8, y: -2)
                .ignoresSafeArea(.container, edges: .bottom)
        )
    }
}

struct OCRResultRetakeButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                    .font(DesignSystem.Typography.caption.weight(.semibold))
                Text(String(localized: "ocr.result.retake"))
                    .font(DesignSystem.Typography.body)
            }
            .foregroundStyle(DesignSystem.Colors.textPrimary)
        }
    }
}

struct OCRResultSelectAllButton: View {
    let isAllSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(isAllSelected ? String(localized: "ocr.result.deselectAll") : String(localized: "ocr.result.selectAll"))
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.primary)
        }
        .accessibilityIdentifier("ocr.result.selectAllButton")
    }
}

private struct OCRResultWarningBanner: View {
    let lowConfidenceCount: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.accentGold)

            Text(String(format: String(localized: "ocr.result.warningBanner %lld"), Int64(lowConfidenceCount)))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(DesignSystem.Colors.accentGold.opacity(0.12))
    }
}

private struct OCRResultAIEnhancedBadge: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "apple.intelligence")
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.primary)

            Text(String(localized: "ocr.ai.enhanced"))
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(DesignSystem.Colors.primary.opacity(0.08))
    }
}
