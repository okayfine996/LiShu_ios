import SwiftData
import SwiftUI

struct StatisticsDistributionSection<Content: View>: View {
    let systemImage: String
    let title: String
    let route: AppRoute
    let shouldLockProContent: Bool
    let onPresentProMembership: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.block) {
            StatisticsSectionHeader(systemImage: systemImage, title: title)
            NavigationLink(value: route) {
                content
                    .overlay {
                        ProLockedOverlay(isLocked: shouldLockProContent, onTap: onPresentProMembership)
                    }
            }
            .buttonStyle(.plain)
        }
    }
}

struct EventDistributionCard: View {
    let viewModel: StatisticsViewModel

    private var ringSegments: [DonutRingSegment] {
        let items = Array(viewModel.eventTypeDistribution.prefix(4))
        var segments: [DonutRingSegment] = []
        var current: CGFloat = 0

        for (index, item) in items.enumerated() {
            let end = current + CGFloat(item.percentage)
            segments.append(
                DonutRingSegment(
                    start: current,
                    end: min(end, 1.0),
                    color: DesignSystem.Colors.primary.opacity(donutOpacity(for: index))
                )
            )
            current = end
        }

        return segments
    }

    var body: some View {
        DonutDistributionCard(
            title: String(localized: "statistics.eventDistribution"),
            showsTitleHeader: false,
            emptyMessage: String(localized: "statistics.overview.noEventData"),
            isEmpty: viewModel.eventTypeDistribution.isEmpty,
            ringSegments: ringSegments,
            centerTopLabel: String(localized: "statistics.eventDistribution.largest"),
            centerMainText: viewModel.eventTypeDistribution.first.map { viewModel.eventTypeName(for: $0.type) } ?? "",
            centerMainUsesLargeValueStyle: false,
            donutNavigationRoute: nil
        ) {
            ForEach(Array(viewModel.eventTypeDistribution.prefix(4).enumerated()), id: \.offset) { index, item in
                DonutDistributionListRow(
                    swatchColor: DesignSystem.Colors.primary.opacity(donutOpacity(for: index)),
                    title: viewModel.eventTypeName(for: item.type),
                    percentage: item.percentage,
                    showsChevron: false
                )
            }
        }
    }

    private func donutOpacity(for index: Int) -> Double {
        switch index {
        case 0: 1.0
        case 1: 0.6
        case 2: 0.3
        default: 0.1
        }
    }
}

struct RecordTypeCompositionCard: View {
    let viewModel: StatisticsViewModel

    private var ringSegments: [DonutRingSegment] {
        var segments: [DonutRingSegment] = []
        var current: CGFloat = 0

        for (index, item) in viewModel.recordTypeDistribution.enumerated() {
            let end = current + CGFloat(item.percentage)
            segments.append(
                DonutRingSegment(
                    start: current,
                    end: min(end, 1.0),
                    color: recordTypeColor(for: index)
                )
            )
            current = end
        }

        return segments
    }

    var body: some View {
        DonutDistributionCard(
            title: String(localized: "statistics.recordTypeComposition"),
            showsTitleHeader: false,
            emptyMessage: String(localized: "statistics.overview.noEventData"),
            isEmpty: viewModel.recordTypeDistribution.isEmpty,
            ringSegments: ringSegments,
            centerTopLabel: String(localized: "recordTypeComposition.yearTotal"),
            centerMainText: "\(viewModel.totalRecordCount)",
            centerMainUsesLargeValueStyle: true
        ) {
            ForEach(Array(viewModel.recordTypeDistribution.enumerated()), id: \.offset) { index, item in
                DonutDistributionListRow(
                    swatchColor: recordTypeColor(for: index),
                    title: item.type.displayName,
                    percentage: item.percentage,
                    showsChevron: false
                )
            }
        }
    }

    private func recordTypeColor(for index: Int) -> Color {
        switch index {
        case 0: DesignSystem.Colors.primary
        case 1: DesignSystem.Colors.primary.opacity(0.55)
        case 2: DesignSystem.Colors.textTertiary.opacity(0.5)
        default: DesignSystem.Colors.textPrimary.opacity(0.7)
        }
    }
}

struct DonutDistributionListRow: View {
    let swatchColor: Color
    let title: String
    let percentage: Double
    let showsChevron: Bool

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.dense) {
            Circle()
                .fill(swatchColor)
                .frame(
                    width: DesignSystem.Spacing.inlineTight,
                    height: DesignSystem.Spacing.inlineTight
                )
            Text(title)
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
            Spacer()
            Text(String(format: "%.0f%%", percentage * 100))
                .font(DesignSystem.Typography.small)
                .fontWeight(.medium)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
        }
        .contentShape(Rectangle())
    }
}

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
                    .frame(
                        width: DesignSystem.Layout.rankBadgeSize,
                        height: DesignSystem.Layout.rankBadgeSize
                    )
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
