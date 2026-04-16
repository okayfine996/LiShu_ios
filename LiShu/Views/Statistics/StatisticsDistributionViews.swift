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
                .frame(width: DesignSystem.Spacing.inlineTight, height: DesignSystem.Spacing.inlineTight)
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
