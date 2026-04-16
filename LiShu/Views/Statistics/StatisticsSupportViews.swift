import SwiftUI

struct StatisticsContentStateView<Content: View>: View {
    let state: LoadingState<Bool>
    let hasData: Bool
    let hasRankings: Bool
    let retry: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        Group {
            switch state {
            case .idle, .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loaded where !hasData && !hasRankings:
                EmptyStateView(
                    icon: "chart.bar.fill",
                    message: String(localized: "statistics.empty")
                )
            case .loaded:
                content
            case let .error(message):
                ErrorStateView(message: message, retryAction: retry)
            }
        }
    }
}

struct StatisticsYearSelectorSection: View {
    let selectedYear: Int
    let availableYears: [Int]
    let onSelectYear: (Int) -> Void

    var body: some View {
        HStack {
            Menu {
                ForEach(availableYears, id: \.self) { year in
                    Button(action: { onSelectYear(year) }) {
                        if year == selectedYear {
                            Label(
                                "\(year)" + String(localized: "statistics.year.suffix"),
                                systemImage: "checkmark"
                            )
                        } else {
                            Text("\(year)" + String(localized: "statistics.year.suffix"))
                        }
                    }
                }
            } label: {
                HStack(spacing: DesignSystem.Spacing.stackTight) {
                    Text("\(selectedYear)" + String(localized: "statistics.year.suffix"))
                        .font(DesignSystem.Typography.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    Image(systemName: "chevron.down")
                        .font(DesignSystem.Typography.small)
                        .fontWeight(.semibold)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }

            Spacer()
        }
    }
}

struct StatisticsSectionHeader<Trailing: View>: View {
    let systemImage: String
    let title: String
    @ViewBuilder let trailing: Trailing

    init(
        systemImage: String,
        title: String,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.systemImage = systemImage
        self.title = title
        self.trailing = trailing()
    }

    var body: some View {
        HStack(alignment: .center, spacing: DesignSystem.Spacing.inlineTight) {
            Image(systemName: systemImage)
                .font(DesignSystem.Typography.body)
                .fontWeight(.semibold)
                .foregroundStyle(DesignSystem.Colors.primary)
                .accessibilityHidden(true)
            Text(title)
                .font(DesignSystem.Typography.body)
                .fontWeight(.semibold)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: DesignSystem.Spacing.inlineTight)
            trailing
        }
    }
}

struct StatisticsEmptyStateCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, DesignSystem.Spacing.stackLoose)
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
            .overlay {
                RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                    .stroke(DesignSystem.Colors.primary.opacity(0.05), lineWidth: 1)
            }
    }
}

struct StatisticsDivider: View {
    var body: some View {
        Rectangle()
            .fill(DesignSystem.Colors.separator.opacity(0.7))
            .frame(height: 1)
    }
}

struct StatisticsVerticalDivider: View {
    var body: some View {
        Rectangle()
            .fill(DesignSystem.Colors.separator.opacity(0.8))
            .frame(width: 1, height: 36)
    }
}

struct RankingDividerLine: View {
    var body: some View {
        Rectangle()
            .fill(DesignSystem.Colors.separator.opacity(0.55))
            .frame(height: 1)
    }
}
