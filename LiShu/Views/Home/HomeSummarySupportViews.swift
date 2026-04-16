import SwiftUI

struct HomeFinancialSummaryCard: View {
    let snapshot: HomeDashboardSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                HomeSummaryCardTitle(
                    icon: "wallet.pass.fill",
                    title: String(localized: "home.financialAxisTitle")
                )

                Spacer()

                NavigationLink(value: AppRoute.statistics) {
                    Image(systemName: "chart.bar.fill")
                        .font(DesignSystem.Typography.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(DesignSystem.Colors.primary)
                        .frame(width: 40, height: 40)
                        .background(DesignSystem.Colors.bgIconSubtle)
                        .clipShape(Circle())
                }
                .accessibilityIdentifier("home.openStatistics")
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "home.monetaryNetTitle"))
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                HStack(alignment: .center, spacing: 10) {
                    Text(HomeDashboardFormatters.monetaryNet(snapshot))
                        .font(DesignSystem.Typography.display)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    if let yearOverYearChange = HomeDashboardFormatters.yearOverYearChange(snapshot) {
                        Text(yearOverYearChange)
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(DesignSystem.Colors.bgInput)
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
                    }
                }
            }

            Divider()
                .foregroundStyle(DesignSystem.Colors.separator)

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

            HStack {
                Text(String(localized: "home.totalExchangeAmountTitle"))
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                Spacer()

                Text(HomeDashboardFormatters.totalExchangeAmount(snapshot))
                    .font(DesignSystem.Typography.title3)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(DesignSystem.Colors.bgPage)
            .clipShape(Capsule())
        }
        .homeSummaryCardChrome()
    }
}

struct HomeRelationshipSummaryCard: View {
    let snapshot: HomeDashboardSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HomeSummaryCardTitle(
                icon: "person.3.fill",
                title: String(localized: "home.relationshipAxisTitle")
            )

            HomeSummaryHeroMetric(
                title: String(localized: "home.interactionsTitle"),
                value: "\(snapshot.recordCount)",
                unit: String(localized: "home.interactionsUnitSuffix"),
                valueColor: DesignSystem.Colors.textPrimary
            )

            Divider()
                .foregroundStyle(DesignSystem.Colors.separator)

            HStack(spacing: 12) {
                HomeRelationshipDetailMetric(
                    title: String(localized: "home.activeContactsTitle"),
                    value: "\(snapshot.contactCount)",
                    detail: HomeDashboardFormatters.coreCircleSummary(snapshot)
                )

                HomeRelationshipDetailMetric(
                    title: String(localized: "home.nonFinancialInteractionsTitle"),
                    value: "\(snapshot.nonFinancialInteractionCount)",
                    detail: HomeDashboardFormatters.nonFinancialSummary(snapshot)
                )
            }

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "sparkles")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.primary)
                    .padding(.top, 2)

                Text(String(localized: "home.relationshipInsightPlaceholder"))
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(DesignSystem.Colors.bgPage)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        }
        .homeSummaryCardChrome()
    }
}

private struct HomeSummaryCardTitle: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.primary)

            Text(title)
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.primary)
        }
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
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            HomeProgressBar(progress: ratio)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct HomeRelationshipDetailMetric: View {
    let title: String
    let value: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Text(value)
                .font(DesignSystem.Typography.title1)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Text(detail)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
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

private struct HomeSummaryHeroMetric: View {
    let title: String
    let value: String
    let unit: String?
    let valueColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(DesignSystem.Typography.display)
                    .foregroundStyle(valueColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                if let unit {
                    Text(unit)
                        .font(DesignSystem.Typography.title3)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
        }
    }
}
