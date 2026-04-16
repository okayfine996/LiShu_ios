import SwiftUI

enum CircleDetailMetricEmphasis {
    case large
    case medium
}

struct CircleDetailMetricCard: View {
    let title: String
    let value: String
    let valueColor: Color
    let emphasisStyle: CircleDetailMetricEmphasis
    var uppercaseTitle = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(titleFont)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .textCase(uppercaseTitle ? .uppercase : nil)

            Text(value)
                .font(valueFont)
                .foregroundStyle(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                .stroke(DesignSystem.Colors.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private var titleFont: Font {
        switch emphasisStyle {
        case .large:
            DesignSystem.Typography.caption
        case .medium:
            .system(size: 10, weight: .medium)
        }
    }

    private var valueFont: Font {
        switch emphasisStyle {
        case .large:
            .system(size: 32, weight: .bold)
        case .medium:
            DesignSystem.Typography.title3
        }
    }
}

struct CircleDetailIncomeExpenseCard: View {
    let incomeText: String
    let expenseText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "circle.detail.incomeExpense"))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .textCase(.uppercase)

            HStack(spacing: 4) {
                Text(incomeText)
                    .foregroundStyle(DesignSystem.Colors.primary)
                Text("/")
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                Text(expenseText)
                    .foregroundStyle(DesignSystem.Colors.primary)
            }
            .font(.system(size: 16, weight: .bold))
            .lineLimit(1)
            .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                .stroke(DesignSystem.Colors.primary.opacity(0.08), lineWidth: 1)
        )
    }
}

struct CircleDetailAverageCard: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(DesignSystem.Colors.primary)
                .textCase(.uppercase)

            Text(value)
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(minWidth: 160, alignment: .leading)
        .padding(16)
        .background(DesignSystem.Colors.primary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard)
                .stroke(DesignSystem.Colors.primary.opacity(0.15), lineWidth: 1)
        )
    }
}

struct CircleDetailMemberRow: View {
    let member: CircleMemberItem
    let formattedNetValue: String
    let isLast: Bool
    let memberCount: Int

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(imageData: member.contact.avatar, name: member.contact.name)

            VStack(alignment: .leading, spacing: 2) {
                Text(member.contact.name)
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                if !member.contact.relation.isEmpty {
                    Text(member.contact.relation)
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(formattedNetValue)
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(
                        member.netValue >= 0
                            ? DesignSystem.Colors.accentGold
                            : DesignSystem.Colors.primary
                    )

                Text(String(localized: "circle.detail.netValueLabel"))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(DesignSystem.Colors.primary)
                    .textCase(.uppercase)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        .opacity(isLast && memberCount > 3 ? 0.8 : 1.0)
    }
}
