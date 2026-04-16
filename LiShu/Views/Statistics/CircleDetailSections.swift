import SwiftData
import SwiftUI

struct CircleDetailContentView: View {
    let viewModel: CircleDetailViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                CircleDetailProfileHeader(
                    circleIcon: viewModel.circleIcon,
                    circleName: viewModel.circleName,
                    memberCount: viewModel.memberCount,
                    closenessLevel: viewModel.closenessLevel
                )
                CircleDetailSummarySection(viewModel: viewModel)
                CircleDetailAverageSection(viewModel: viewModel)
                CircleDetailMembersSection(viewModel: viewModel)
            }
            .padding(.bottom, 24)
        }
    }
}

private struct CircleDetailProfileHeader: View {
    let circleIcon: String
    let circleName: String
    let memberCount: Int
    let closenessLevel: String

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.primary.opacity(0.1))
                    .frame(width: 112, height: 112)

                Image(systemName: circleIcon)
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(DesignSystem.Colors.primary)
            }
            .overlay(
                Circle()
                    .stroke(DesignSystem.Colors.bgSurface, lineWidth: 4)
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            )

            VStack(spacing: 8) {
                Text(circleName)
                    .font(DesignSystem.Typography.title2)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                HStack(spacing: 8) {
                    Text(String(format: String(localized: "circle.detail.memberCount"), memberCount))
                        .font(DesignSystem.Typography.small)
                        .fontWeight(.semibold)
                        .foregroundStyle(DesignSystem.Colors.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(DesignSystem.Colors.primary.opacity(0.15))
                        .clipShape(Capsule())

                    Text(closenessLevel)
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
    }
}

private struct CircleDetailSummarySection: View {
    let viewModel: CircleDetailViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(String(localized: "circle.detail.summary"))
                    .font(DesignSystem.Typography.title3)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Spacer()
            }

            VStack(spacing: 12) {
                CircleDetailMetricCard(
                    title: String(localized: "circle.detail.totalAmount"),
                    value: viewModel.formatAmount(viewModel.totalAmount),
                    valueColor: DesignSystem.Colors.primary,
                    emphasisStyle: .large
                )

                HStack(spacing: 12) {
                    CircleDetailMetricCard(
                        title: String(localized: "circle.detail.netValue"),
                        value: viewModel.formatAmount(viewModel.netValue),
                        valueColor: viewModel.netValue >= 0
                            ? DesignSystem.Colors.accentGold
                            : DesignSystem.Colors.primary,
                        emphasisStyle: .medium,
                        uppercaseTitle: true
                    )

                    CircleDetailIncomeExpenseCard(
                        incomeText: viewModel.formatCompactAmount(viewModel.totalIncome),
                        expenseText: viewModel.formatCompactAmount(viewModel.totalExpense)
                    )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

private struct CircleDetailAverageSection: View {
    let viewModel: CircleDetailViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "circle.detail.averageData"))
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    CircleDetailAverageCard(
                        label: String(localized: "circle.detail.avgAmount"),
                        value: viewModel.formatAmount(viewModel.averageAmount)
                    )
                    CircleDetailAverageCard(
                        label: String(localized: "circle.detail.avgNetValue"),
                        value: viewModel.formatAmount(viewModel.averageNetValue)
                    )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 32)
    }
}

private struct CircleDetailMembersSection: View {
    let viewModel: CircleDetailViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(String(localized: "circle.detail.memberList"))
                    .font(DesignSystem.Typography.title3)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Spacer()

                HStack(spacing: 2) {
                    Text(String(localized: "circle.detail.sortByNetValue"))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.primary)
                    Image(systemName: "arrow.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.primary)
                }
            }

            if viewModel.members.isEmpty {
                EmptyStateView(
                    icon: "person.3",
                    message: String(localized: "circle.detail.empty")
                )
                .frame(height: 200)
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(viewModel.members.enumerated()), id: \.element.id) { index, member in
                        NavigationLink(value: AppRoute.contactDetail(member.contact.persistentModelID)) {
                            CircleDetailMemberRow(
                                member: member,
                                formattedNetValue: viewModel.formatAmount(abs(member.netValue)),
                                isLast: index == viewModel.members.count - 1,
                                memberCount: viewModel.members.count
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 32)
    }
}
