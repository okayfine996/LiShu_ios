import SwiftData
import SwiftUI

struct MonthlyDetailContentView: View {
    let viewModel: MonthlyDetailViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: DesignSystem.Spacing.block) {
                MonthlySummaryCardsSection(viewModel: viewModel)
                MonthlyNetValueCard(viewModel: viewModel)

                if !viewModel.eventTypeSlices.isEmpty {
                    MonthlyDistributionCard(viewModel: viewModel)
                }

                MonthlyTransactionListSection(records: viewModel.records)
            }
            .padding(.horizontal, DesignSystem.Spacing.pageHorizontal)
            .padding(.vertical, DesignSystem.Spacing.block)
        }
    }
}

private struct MonthlySummaryCardsSection: View {
    let viewModel: MonthlyDetailViewModel

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.inlineTight) {
            MonthlySummaryCard(
                label: String(localized: "period.detail.income"),
                amount: viewModel.formatAmount(viewModel.periodIncome),
                amountColor: DesignSystem.Colors.primary,
                trend: viewModel.incomeTrend,
                trendText: viewModel.formatTrend(viewModel.incomeTrend),
                isPositiveTrendGood: true
            )

            MonthlySummaryCard(
                label: String(localized: "period.detail.expense"),
                amount: viewModel.formatAmount(viewModel.periodExpense),
                amountColor: DesignSystem.Colors.primary,
                trend: viewModel.expenseTrend,
                trendText: viewModel.formatTrend(viewModel.expenseTrend),
                isPositiveTrendGood: false
            )
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

private struct MonthlySummaryCard: View {
    let label: String
    let amount: String
    let amountColor: Color
    let trend: Double?
    let trendText: String?
    let isPositiveTrendGood: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Text(amount)
                .font(DesignSystem.Typography.title3)
                .fontWeight(.bold)
                .foregroundStyle(amountColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            if let trend, let trendText {
                MonthlyTrendView(
                    trend: trend,
                    trendText: trendText,
                    isPositiveTrendGood: isPositiveTrendGood
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(16)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
    }
}

private struct MonthlyTrendView: View {
    let trend: Double
    let trendText: String
    let isPositiveTrendGood: Bool

    private var isPositive: Bool {
        trend >= 0
    }

    private var trendColor: Color {
        isPositive == isPositiveTrendGood
            ? DesignSystem.Colors.income
            : DesignSystem.Colors.destructive
    }

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                .font(DesignSystem.Typography.small)
            Text(trendText)
                .font(DesignSystem.Typography.small)
        }
        .foregroundStyle(trendColor)
    }
}

private struct MonthlyNetValueCard: View {
    let viewModel: MonthlyDetailViewModel

    private var netColor: Color {
        viewModel.netAmount >= 0 ? DesignSystem.Colors.accentGold : DesignSystem.Colors.primary
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "period.detail.netValue"))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                Text(viewModel.formatNetAmount())
                    .font(DesignSystem.Typography.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(netColor)
            }

            Spacer()
        }
        .padding(16)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
    }
}

private struct MonthlyDistributionCard: View {
    let viewModel: MonthlyDetailViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "period.detail.distribution"))
                .font(DesignSystem.Typography.caption)
                .fontWeight(.bold)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            HStack(spacing: 24) {
                MonthlyDonutChart(slices: viewModel.eventTypeSlices)
                    .frame(width: 96, height: 96)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(viewModel.eventTypeSlices.prefix(5).enumerated()), id: \.element.id) { index, slice in
                        MonthlyDistributionLegendRow(
                            name: slice.name,
                            percentage: slice.percentage,
                            color: monthlySliceColor(at: index)
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
    }
}

private struct MonthlyDonutChart: View {
    let slices: [EventTypeSlice]

    private var segments: [(start: CGFloat, end: CGFloat, color: Color)] {
        var result: [(start: CGFloat, end: CGFloat, color: Color)] = []
        var current: CGFloat = 0

        for (index, slice) in slices.prefix(5).enumerated() {
            let portion = CGFloat(slice.percentage)
            result.append((start: current, end: current + portion, color: monthlySliceColor(at: index)))
            current += portion
        }

        return result
    }

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)

            ZStack {
                Circle()
                    .stroke(DesignSystem.Colors.bgTag, lineWidth: 12)

                ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                    Circle()
                        .trim(from: segment.start, to: segment.end)
                        .stroke(
                            segment.color,
                            style: StrokeStyle(lineWidth: 12, lineCap: .butt)
                        )
                        .rotationEffect(.degrees(-90))
                }

                Text(String(localized: "period.detail.overview"))
                    .font(DesignSystem.Typography.small)
                    .fontWeight(.bold)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
            .frame(width: size, height: size)
            .position(x: size / 2, y: size / 2)
        }
    }
}

private struct MonthlyDistributionLegendRow: View {
    let name: String
    let percentage: Double
    let color: Color

    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(name)
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Spacer()

            Text(String(format: "%.0f%%", percentage * 100))
                .font(DesignSystem.Typography.small)
                .fontWeight(.bold)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
        }
    }
}

private struct MonthlyTransactionListSection: View {
    let records: [Record]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(String(localized: "period.detail.transactions"))
                    .font(DesignSystem.Typography.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Spacer()

                Text(String(format: String(localized: "period.detail.count"), records.count))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }

            if records.isEmpty {
                EmptyStateView(
                    icon: "doc.text",
                    message: String(localized: "record.list.empty")
                )
                .frame(height: 200)
            } else {
                VStack(spacing: 10) {
                    ForEach(records) { record in
                        if let contact = record.contact, record.event != nil {
                            NavigationLink(value: AppRoute.contactExchange(contact.persistentModelID)) {
                                RecordRow(record: record)
                            }
                            .buttonStyle(.plain)
                            .background(DesignSystem.Colors.bgSurface)
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
                        }
                    }
                }
            }
        }
    }
}

private func monthlySliceColor(at index: Int) -> Color {
    let colors: [Color] = [
        DesignSystem.Colors.primary,
        DesignSystem.Colors.accentGold,
        DesignSystem.Colors.primary.opacity(0.5),
        DesignSystem.Colors.accentGold.opacity(0.5),
        DesignSystem.Colors.textTertiary,
    ]
    return colors[index % colors.count]
}
