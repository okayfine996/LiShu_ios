import SwiftUI

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
