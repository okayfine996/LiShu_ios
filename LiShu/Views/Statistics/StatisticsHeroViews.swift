import SwiftUI

struct StatisticsHeroSection: View {
    let viewModel: StatisticsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.block) {
            StatisticsSectionHeader(
                systemImage: "square.grid.2x2.fill",
                title: String(localized: "statistics.hero.overviewTitle")
            ) {
                if let yoyText = viewModel.formatYearOverYearChange() {
                    Text(yoyText)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.primary)
                        .padding(.horizontal, DesignSystem.Spacing.block)
                        .padding(.vertical, DesignSystem.Spacing.dense)
                        .background(DesignSystem.Colors.bgTag)
                        .clipShape(Capsule())
                }
            }
            HeroStatisticsCard(viewModel: viewModel)
        }
    }
}

struct HeroStatisticsCard: View {
    let viewModel: StatisticsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(String(localized: "statistics.hero.netBalance"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .padding(.bottom, DesignSystem.Spacing.dense)

            Text("¥ " + viewModel.formatAmountWithComma(viewModel.netValue))
                .font(DesignSystem.Typography.title1)
                .fontWeight(.bold)
                .foregroundStyle(DesignSystem.Colors.primary)
                .padding(.bottom, DesignSystem.Spacing.stackLoose)

            StatisticsDivider()

            HStack(spacing: DesignSystem.Spacing.block) {
                HeroMetricCell(
                    title: String(localized: "statistics.hero.totalIncome"),
                    value: "¥ " + viewModel.formatAmountWithComma(viewModel.totalIncome)
                )
                StatisticsVerticalDivider()
                HeroMetricCell(
                    title: String(localized: "statistics.hero.totalExpense"),
                    value: "¥ " + viewModel.formatAmountWithComma(viewModel.totalExpense)
                )
                StatisticsVerticalDivider()
                HeroMetricCell(
                    title: String(localized: "statistics.hero.totalExchange"),
                    value: "¥ " + viewModel.formatAmountWithComma(viewModel.totalExchangeAmount)
                )
            }
            .padding(.vertical, DesignSystem.Spacing.cardPaddingSmall)

            StatisticsDivider()

            HStack(spacing: DesignSystem.Spacing.block) {
                HeroMetricCell(
                    title: String(localized: "statistics.hero.interactions"),
                    value: String(
                        format: String(localized: "statistics.hero.interactions.value"),
                        viewModel.totalRecordCount
                    )
                )
                StatisticsVerticalDivider()
                HeroMetricCell(
                    title: String(localized: "statistics.hero.covered"),
                    value: String(
                        format: String(localized: "statistics.hero.covered.value"),
                        viewModel.contactCount
                    )
                )
                StatisticsVerticalDivider()
                HeroMetricCell(
                    title: String(localized: "statistics.hero.nonFinancial"),
                    value: String(
                        format: String(localized: "statistics.hero.nonFinancial.value"),
                        viewModel.nonFinancialInteractionCount
                    )
                )
            }
            .padding(.vertical, DesignSystem.Spacing.cardPaddingSmall)

            StatisticsDivider()

            HStack(spacing: DesignSystem.Spacing.block) {
                HeroStatusItem(
                    title: String(localized: "statistics.hero.relationship.close"),
                    value: viewModel.relationshipHealthSummary.close
                )
                HeroStatusItem(
                    title: String(localized: "statistics.hero.relationship.stable"),
                    value: viewModel.relationshipHealthSummary.stable
                )
                HeroStatusItem(
                    title: String(localized: "statistics.hero.relationship.distant"),
                    value: viewModel.relationshipHealthSummary.distant
                )
                HeroStatusItem(
                    title: String(localized: "statistics.hero.relationship.needsAttention"),
                    value: viewModel.relationshipHealthSummary.needsAttention,
                    valueColor: DesignSystem.Colors.accentGold
                )
            }
            .padding(.vertical, DesignSystem.Spacing.cardPaddingSmall)
        }
        .padding(DesignSystem.Spacing.heroCardPadding)
        .background {
            ZStack {
                DesignSystem.Colors.bgSurface

                Circle()
                    .fill(DesignSystem.Colors.primary.opacity(0.08))
                    .frame(
                        width: DesignSystem.Layout.heroDecorationDiameter,
                        height: DesignSystem.Layout.heroDecorationDiameter
                    )
                    .blur(radius: DesignSystem.Layout.heroDecorationBlur)
                    .offset(
                        x: DesignSystem.Layout.heroDecorationOffset,
                        y: -DesignSystem.Layout.heroDecorationOffset
                    )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        .overlay {
            RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                .stroke(DesignSystem.Colors.primary.opacity(0.05), lineWidth: 1)
        }
    }
}

struct HeroMetricCell: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.stackTight) {
            Text(title)
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
            Text(value)
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct HeroStatusItem: View {
    let title: String
    let value: Int
    let valueColor: Color

    init(title: String, value: Int, valueColor: Color = DesignSystem.Colors.primary) {
        self.title = title
        self.value = value
        self.valueColor = valueColor
    }

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.stackTight) {
            Text(title)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
            Text("\(value)")
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(valueColor)
        }
    }
}
