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

    init(
        title: String,
        value: Int,
        valueColor: Color = DesignSystem.Colors.primary
    ) {
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

struct StatisticsBarChartSection: View {
    let viewModel: StatisticsViewModel
    let shouldLockProContent: Bool
    let onPresentProMembership: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.block) {
            StatisticsSectionHeader(
                systemImage: "chart.bar.fill",
                title: String(localized: "statistics.chart.trend")
            )
            StatisticsBarChartCard(viewModel: viewModel)
                .overlay {
                    ProLockedOverlay(isLocked: shouldLockProContent, onTap: onPresentProMembership)
                }
        }
    }
}

struct StatisticsBarChartCard: View {
    let viewModel: StatisticsViewModel

    private var bars: [(label: String, income: Double, expense: Double)] {
        viewModel.chartBars
    }

    private var maxCombined: Double {
        max(bars.map { $0.income + $0.expense }.max() ?? 1, 1)
    }

    private var chartHeight: CGFloat {
        DesignSystem.Layout.statisticsBarChartHeight
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if bars.isEmpty {
                Text(String(localized: "statistics.chart.noData"))
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: chartHeight)
            } else {
                HStack(alignment: .bottom, spacing: DesignSystem.Spacing.inlineTight) {
                    ForEach(Array(bars.enumerated()), id: \.offset) { index, bar in
                        BarChartColumnLink(
                            route: viewModel.periodForBarIndex(index).map(AppRoute.periodDetail),
                            bar: bar,
                            maxCombined: maxCombined,
                            chartHeight: chartHeight
                        )
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.inlineTight)
            }

            ChartLegendRow()
                .frame(maxWidth: .infinity)
                .padding(.top, DesignSystem.Spacing.heroCardPadding)
        }
        .padding(DesignSystem.Spacing.cardPadding)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        .overlay {
            RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                .stroke(DesignSystem.Colors.primary.opacity(0.05), lineWidth: 1)
        }
    }
}

struct BarChartColumnLink: View {
    let route: AppRoute?
    let bar: (label: String, income: Double, expense: Double)
    let maxCombined: Double
    let chartHeight: CGFloat

    var body: some View {
        Group {
            if let route {
                NavigationLink(value: route) {
                    BarChartColumn(bar: bar, maxCombined: maxCombined, chartHeight: chartHeight)
                }
                .buttonStyle(.plain)
            } else {
                BarChartColumn(bar: bar, maxCombined: maxCombined, chartHeight: chartHeight)
            }
        }
    }
}

struct BarChartColumn: View {
    let bar: (label: String, income: Double, expense: Double)
    let maxCombined: Double
    let chartHeight: CGFloat

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.stackTight) {
            VStack(spacing: DesignSystem.Spacing.stackTight / 2) {
                Spacer(minLength: 0)

                if bar.income > 0 {
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.chartBar)
                        .fill(DesignSystem.Colors.primary.opacity(0.4))
                        .frame(height: chartHeight * bar.income / maxCombined)
                }

                if bar.expense > 0 {
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.chartBar)
                        .fill(DesignSystem.Colors.primary)
                        .frame(height: chartHeight * bar.expense / maxCombined)
                }
            }
            .frame(height: chartHeight)

            Text(bar.label)
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ChartLegendRow: View {
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.stackLoose) {
            ChartLegendItem(
                color: DesignSystem.Colors.primary.opacity(0.4),
                title: String(localized: "statistics.chart.income")
            )
            ChartLegendItem(
                color: DesignSystem.Colors.primary,
                title: String(localized: "statistics.chart.expense")
            )
        }
    }
}

struct ChartLegendItem: View {
    let color: Color
    let title: String

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.inlineTight) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(title)
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
    }
}
