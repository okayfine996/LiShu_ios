import SwiftUI

struct RecordDetailDirectionTag: View {
    let direction: RecordDirection
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: direction == .given ? "arrow.up.right" : "arrow.down.left")
                .font(DesignSystem.Typography.small)
            Text(label)
                .font(DesignSystem.Typography.small)
        }
        .foregroundStyle(RecordDetailFormatters.directionColor(direction))
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(RecordDetailFormatters.directionColor(direction).opacity(0.12))
        .clipShape(Capsule())
    }
}

struct RecordDetailTypeTag: View {
    let recordType: RecordType

    var body: some View {
        HStack(spacing: 4) {
            Text(recordType.iconEmoji)
                .font(DesignSystem.Typography.small)
            Text(recordType.displayName)
                .font(DesignSystem.Typography.small)
        }
        .foregroundStyle(DesignSystem.Colors.textSecondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(DesignSystem.Colors.bgTag)
        .clipShape(Capsule())
    }
}

struct RecordDetailAmountCell: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 6) {
            Text(label)
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
            Text(value)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
    }
}

struct RecordDetailLabeledValueRow: View {
    let title: String
    let value: String
    var multiline: Bool = false

    var body: some View {
        LabeledContent(title) {
            Text(value)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .multilineTextAlignment(multiline ? .trailing : .leading)
        }
        .font(DesignSystem.Typography.caption)
        .foregroundStyle(DesignSystem.Colors.textSecondary)
    }
}

struct RecordDetailInfoRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.primary)
                .frame(width: 32, height: 32)
                .background(DesignSystem.Colors.bgIconSubtle)
                .clipShape(Circle())

            Text(label)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Spacer()

            Text(value)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

struct RecordDetailInfoDivider: View {
    var body: some View {
        Divider()
            .foregroundStyle(DesignSystem.Colors.separator)
            .padding(.leading, 56)
    }
}

struct RecordDetailAmountCellModel: Identifiable {
    let id = UUID()
    let label: String
    let value: String
}

enum RecordDetailFormatters {
    static func amount(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        let formatted = formatter.string(from: NSNumber(value: value)) ?? String(format: "%.0f", value)
        return "¥" + formatted
    }

    static func directionColor(_ direction: RecordDirection) -> Color {
        direction == .received ? DesignSystem.Colors.accentGold : DesignSystem.Colors.primary
    }
}
