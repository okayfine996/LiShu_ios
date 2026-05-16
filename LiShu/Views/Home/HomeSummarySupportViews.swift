import SwiftUI

struct HomeUnifiedSummaryCard: View {
    let snapshot: HomeDashboardSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // 标题行 + 统计入口
            HStack(alignment: .center) {
                Text(String(localized: "home.monetaryNetTitle"))
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                Spacer()

                NavigationLink(value: AppRoute.statistics) {
                    Image(systemName: "chart.bar.fill")
                        .font(DesignSystem.Typography.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(DesignSystem.Colors.primary)
                        .frame(width: 36, height: 36)
                        .background(DesignSystem.Colors.bgIconSubtle)
                        .clipShape(Circle())
                }
                .accessibilityIdentifier("home.openStatistics")
            }

            // 净额大数字 + 同比 badge
            HStack(alignment: .center, spacing: 10) {
                Text(HomeDashboardFormatters.monetaryNet(snapshot))
                    .font(DesignSystem.Typography.display)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer()

                if let yearOverYearChange = HomeDashboardFormatters.yearOverYearChange(snapshot) {
                    Text(yearOverYearChange)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(DesignSystem.Colors.bgInput)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
                }
            }

            // 收入 / 支出
            HStack(spacing: 12) {
                HomeFinancialDetailMetric(
                    title: String(localized: "home.income"),
                    amount: HomeDashboardFormatters.income(snapshot),
                    ratio: snapshot.incomeRatio
                )

                HomeFinancialDetailMetric(
                    title: String(localized: "home.expense"),
                    amount: HomeDashboardFormatters.expense(snapshot),
                    ratio: snapshot.expenseRatio
                )
            }

            Divider()
                .foregroundStyle(DesignSystem.Colors.separator)

            // 底部三栏统计
            HStack(spacing: 0) {
                HomeBottomStat(
                    title: String(localized: "home.summaryInteractions"),
                    value: "\(snapshot.recordCount)",
                    unit: String(localized: "home.summaryUnitRecords")
                )

                HomeBottomStat(
                    title: String(localized: "home.summaryActiveContacts"),
                    value: "\(snapshot.contactCount)",
                    unit: String(localized: "home.summaryUnitContacts")
                )

                HomeBottomStat(
                    title: String(localized: "home.summaryPendingReturns"),
                    value: "\(snapshot.pendingReturnCount)",
                    unit: String(localized: "home.summaryUnitRecords")
                )
            }
        }
        .homeSummaryCardChrome()
    }
}

private struct HomeBottomStat: View {
    let title: String
    let value: String
    let unit: String

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(DesignSystem.Typography.title1)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Text(unit)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct HomeFinancialDetailMetric: View {
    let title: String
    let amount: String
    let ratio: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Text(amount)
                .font(DesignSystem.Typography.title1)
                .foregroundStyle(title == String(localized: "home.income") ? DesignSystem.Colors.accentGold : DesignSystem.Colors
                    .textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            HomeProgressBar(progress: ratio)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct HomeProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { proxy in
            let clampedProgress = min(max(progress, 0), 1)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(DesignSystem.Colors.bgInput)

                Capsule()
                    .fill(DesignSystem.Colors.primary)
                    .frame(width: clampedProgress == 0 ? 0 : max(proxy.size.width * clampedProgress, 36))
            }
        }
        .frame(height: 8)
    }
}
