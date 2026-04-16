import SwiftData
import SwiftUI

struct CircleAnalysisSection: View {
    let viewModel: StatisticsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.block) {
            StatisticsSectionHeader(
                systemImage: "circle.hexagongrid.fill",
                title: String(localized: "statistics.circleAnalysis")
            )

            if viewModel.circleAnalysisItems.isEmpty {
                StatisticsEmptyStateCard {
                    Text(String(localized: "statistics.overview.noEventData"))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignSystem.Spacing.block) {
                        ForEach(viewModel.circleAnalysisItems) { item in
                            NavigationLink(value: AppRoute.circleDetail(item.circle, year: viewModel.selectedYear)) {
                                CircleAnalysisCard(item: item, viewModel: viewModel)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}

struct CircleAnalysisCard: View {
    let item: CircleAnalysisItem
    let viewModel: StatisticsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.stackTight) {
            Text(item.name)
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Text("¥" + viewModel.formatAmountWithComma(item.amount))
                .font(DesignSystem.Typography.title3)
                .fontWeight(.bold)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            HStack {
                Text(String(localized: "statistics.circle.activity"))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                Spacer()
                Text(String(format: "%.0f%%", item.ratio * 100))
                    .font(DesignSystem.Typography.small)
                    .fontWeight(.semibold)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
            .padding(.top, DesignSystem.Spacing.inlineTight)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.chartBar)
                        .fill(DesignSystem.Colors.primary.opacity(0.1))
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: DesignSystem.Radius.chartBar)
                        .fill(DesignSystem.Colors.primary)
                        .frame(width: geometry.size.width * item.ratio, height: 4)
                }
            }
            .frame(height: 4)
            .padding(.top, DesignSystem.Spacing.dense)
        }
        .frame(width: DesignSystem.Layout.circleAnalysisCardWidth)
        .padding(DesignSystem.Spacing.cardPaddingSmall)
        .contentShape(Rectangle())
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        .overlay {
            RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                .stroke(DesignSystem.Colors.primary.opacity(0.05), lineWidth: 1)
        }
    }
}

struct RankingSection: View {
    let viewModel: StatisticsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.block) {
            StatisticsSectionHeader(
                systemImage: "trophy.fill",
                title: String(localized: "statistics.ranking.deepBondTitle")
            ) {
                if !viewModel.topContacts.isEmpty {
                    Text(String(localized: "statistics.ranking.topBadge"))
                        .font(DesignSystem.Typography.small)
                        .fontWeight(.medium)
                        .tracking(0.6)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }

            if viewModel.topContacts.isEmpty {
                StatisticsEmptyStateCard {
                    Text(String(localized: "statistics.overview.noRankingData"))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.topContacts.enumerated()), id: \.element.id) { index, item in
                        VStack(spacing: 0) {
                            RankingRow(rank: index + 1, item: item, viewModel: viewModel)
                            if index < viewModel.topContacts.count - 1 {
                                RankingDividerLine()
                            }
                        }
                    }
                }
                .background(DesignSystem.Colors.bgSurface)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
                .overlay {
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                        .stroke(DesignSystem.Colors.primary.opacity(0.05), lineWidth: 1)
                }
            }
        }
    }
}

struct RankingRow: View {
    let rank: Int
    let item: ContactRankingItem
    let viewModel: StatisticsViewModel

    private var netColor: Color {
        item.netValue >= 0 ? DesignSystem.Colors.accentGold : DesignSystem.Colors.primary
    }

    private var rankCircleFill: Color {
        rank == 1 ? DesignSystem.Colors.primary.opacity(0.12) : DesignSystem.Colors.bgTag
    }

    var body: some View {
        NavigationLink(value: AppRoute.contactDetail(item.contact.persistentModelID)) {
            HStack(alignment: .center, spacing: DesignSystem.Spacing.block) {
                Text("\(rank)")
                    .font(DesignSystem.Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .frame(width: DesignSystem.Layout.rankBadgeSize, height: DesignSystem.Layout.rankBadgeSize)
                    .background(rankCircleFill)
                    .clipShape(Circle())

                AvatarView(
                    imageData: item.contact.avatar,
                    name: item.contact.name,
                    size: DesignSystem.Layout.avatarM,
                    placeholderBackground: DesignSystem.Colors.bgTag
                )

                VStack(alignment: .leading, spacing: DesignSystem.Spacing.stackTight) {
                    Text(item.contact.name)
                        .font(DesignSystem.Typography.body)
                        .fontWeight(.bold)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    Text(
                        String(
                            format: String(localized: "statistics.ranking.deepInteractionLine"),
                            item.recordCount
                        )
                    )
                    .font(DesignSystem.Typography.caption)
                    .fontWeight(.regular)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                }

                Spacer(minLength: DesignSystem.Spacing.inlineTight)

                VStack(alignment: .trailing, spacing: DesignSystem.Spacing.stackTight) {
                    Text(viewModel.formatNetValue(item.netValue))
                        .font(DesignSystem.Typography.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(netColor)

                    Text(String(localized: "statistics.ranking.netValueAmountLabel"))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.cardPaddingSmall)
            .padding(.vertical, DesignSystem.Spacing.block)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
