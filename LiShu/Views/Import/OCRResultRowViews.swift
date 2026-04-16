import SwiftUI

struct OCRResultRow: View {
    let item: OCRRecordItem
    let onEdit: () -> Void
    let onToggleSelection: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            OCRResultCheckboxButton(isSelected: item.isSelected, action: onToggleSelection)
            OCRResultNameAndStatus(item: item)
            Spacer()
            OCRResultAmountStatus(item: item)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
        .contentShape(Rectangle())
        .onTapGesture(perform: onEdit)
    }
}

private struct OCRResultCheckboxButton: View {
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .strokeBorder(
                        isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.border,
                        lineWidth: 2
                    )
                    .frame(width: 26, height: 26)

                if isSelected {
                    Circle()
                        .fill(DesignSystem.Colors.primary)
                        .frame(width: 26, height: 26)

                    Image(systemName: "checkmark")
                        .font(DesignSystem.Typography.small.weight(.bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

private struct OCRResultNameAndStatus: View {
    let item: OCRRecordItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.name)
                .font(DesignSystem.Typography.body)
                .fontWeight(.semibold)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            OCRResultConfidenceLabel(item: item)
        }
    }
}

private struct OCRResultConfidenceLabel: View {
    let item: OCRRecordItem

    var body: some View {
        switch item.confidence {
        case .high:
            Text(String(localized: "ocr.result.confidenceHigh"))
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
        case .medium, .low:
            HStack(spacing: 2) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.accentGold)
                Text(warningText)
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.accentGold)
            }
        }
    }

    private var warningText: String {
        switch item.warningType {
        case .needsVerification:
            String(localized: "ocr.result.needsVerification")
        case .suspiciousAmount:
            String(localized: "ocr.result.suspiciousAmount")
        case nil:
            String(localized: "ocr.result.needsVerification")
        }
    }
}

private struct OCRResultAmountStatus: View {
    let item: OCRRecordItem

    var body: some View {
        HStack(spacing: 8) {
            Text(OCRResultFormatters.amount(item.amount))
                .font(DesignSystem.Typography.body)
                .fontWeight(.semibold)
                .foregroundStyle(amountColor)

            confidenceIcon
        }
    }

    private var amountColor: Color {
        switch item.confidence {
        case .high:
            DesignSystem.Colors.primary
        case .medium:
            DesignSystem.Colors.accentGold
        case .low:
            DesignSystem.Colors.textSecondary
        }
    }

    @ViewBuilder
    private var confidenceIcon: some View {
        switch item.confidence {
        case .high:
            Image(systemName: "checkmark.circle.fill")
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.primary)
        case .medium:
            Image(systemName: "exclamationmark.circle.fill")
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.accentGold)
        case .low:
            Image(systemName: "questionmark.circle.fill")
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
        }
    }
}

enum OCRResultFormatters {
    static func amount(_ amount: Double) -> String {
        if amount == Double(Int(amount)) {
            return "¥\(Int(amount))"
        }
        return "¥\(String(format: "%.2f", amount))"
    }
}
