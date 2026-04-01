import SwiftUI
import SwiftData

struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @State private var viewModel = StatisticsViewModel()
    @State private var sheetRoute: SheetRoute?
    
    private var shouldLockProContent: Bool {
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return false
        }
        return !subscriptionManager.isPro
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loaded where !viewModel.hasData && viewModel.allRankedContacts.isEmpty:
                EmptyStateView(
                    icon: "chart.bar.fill",
                    message: String(localized: "statistics.empty")
                )
            case .loaded:
                statisticsContent
            case .error(let message):
                ErrorStateView(message: message) {
                    viewModel.loadData(context: modelContext)
                }
            }
        }
        .background(DesignSystem.Colors.bgPage)
        .navigationTitle(String(localized: "statistics.title"))
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            viewModel.loadData(context: modelContext)
        }
        .sheet(item: $sheetRoute) { route in
            if case .proMembership = route {
                NavigationStack {
                    ProMembershipView()
                }
            }
        }
    }

    // MARK: - Main Content

    private var statisticsContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: DesignSystem.Spacing.stackLoose) {
                selectorSection
                heroSection
                barChartOuterSection
                recordTypeCompositionSection
                eventDistributionSection
                NavigationLink(value: AppRoute.heatmapDetail(year: viewModel.selectedYear)) {
                    heatmapOuterSection
                }
                .buttonStyle(.plain)
                circleAnalysisSection
                rankingSection
            }
            .padding(.horizontal, DesignSystem.Spacing.pageHorizontal)
            .padding(.bottom, DesignSystem.Spacing.scrollBottom)
        }
    }

    // MARK: - Year Selector

    private var selectorSection: some View {
        HStack {
            Menu {
                ForEach(viewModel.availableYears, id: \.self) { year in
                    Button {
                        viewModel.selectYear(year, context: modelContext)
                    } label: {
                        if year == viewModel.selectedYear {
                            Label("\(year)" + String(localized: "statistics.year.suffix"), systemImage: "checkmark")
                        } else {
                            Text("\(year)" + String(localized: "statistics.year.suffix"))
                        }
                    }
                }
            } label: {
                HStack(spacing: DesignSystem.Spacing.stackTight) {
                    Text("\(viewModel.selectedYear)" + String(localized: "statistics.year.suffix"))
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

    // MARK: - Section headers（标题在卡片外，左侧图标）

    private func statisticsSectionHeader(systemImage: String, title: String) -> some View {
        statisticsSectionHeader(systemImage: systemImage, title: title) {
            EmptyView()
        }
    }

    @ViewBuilder
    private func statisticsSectionHeader(
        systemImage: String,
        title: String,
        @ViewBuilder trailing: () -> some View
    ) -> some View {
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
            trailing()
        }
    }

    /// 与环形图等大卡风格一致的「空状态」底（圈层 / 排行等无数据时）。
    @ViewBuilder
    private func statisticsEmptyStateCard(@ViewBuilder content: () -> some View) -> some View {
        content()
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, DesignSystem.Spacing.stackLoose)
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                    .stroke(DesignSystem.Colors.primary.opacity(0.05), lineWidth: 1)
            )
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.block) {
            statisticsSectionHeader(
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
            heroCard
        }
    }

    // MARK: - Hero Card

    private var heroCard: some View {
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

            heroDivider

            HStack(spacing: DesignSystem.Spacing.block) {
                heroMetricCell(
                    title: String(localized: "statistics.hero.totalIncome"),
                    value: "¥ " + viewModel.formatAmountWithComma(viewModel.totalIncome)
                )
                heroVerticalDivider
                heroMetricCell(
                    title: String(localized: "statistics.hero.totalExpense"),
                    value: "¥ " + viewModel.formatAmountWithComma(viewModel.totalExpense)
                )
                heroVerticalDivider
                heroMetricCell(
                    title: String(localized: "statistics.hero.totalExchange"),
                    value: "¥ " + viewModel.formatAmountWithComma(viewModel.totalExchangeAmount)
                )
            }
            .padding(.vertical, DesignSystem.Spacing.cardPaddingSmall)

            heroDivider

            HStack(spacing: DesignSystem.Spacing.block) {
                heroMetricCell(
                    title: String(localized: "statistics.hero.interactions"),
                    value: String(format: String(localized: "statistics.hero.interactions.value"), viewModel.totalRecordCount)
                )
                heroVerticalDivider
                heroMetricCell(
                    title: String(localized: "statistics.hero.covered"),
                    value: String(format: String(localized: "statistics.hero.covered.value"), viewModel.contactCount)
                )
                heroVerticalDivider
                heroMetricCell(
                    title: String(localized: "statistics.hero.nonFinancial"),
                    value: String(
                        format: String(localized: "statistics.hero.nonFinancial.value"),
                        viewModel.nonFinancialInteractionCount
                    )
                )
            }
            .padding(.vertical, DesignSystem.Spacing.cardPaddingSmall)

            heroDivider

            HStack(spacing: DesignSystem.Spacing.block) {
                heroStatusItem(
                    title: String(localized: "statistics.hero.relationship.close"),
                    value: viewModel.relationshipHealthSummary.close
                )
                heroStatusItem(
                    title: String(localized: "statistics.hero.relationship.stable"),
                    value: viewModel.relationshipHealthSummary.stable
                )
                heroStatusItem(
                    title: String(localized: "statistics.hero.relationship.distant"),
                    value: viewModel.relationshipHealthSummary.distant
                )
                heroStatusItem(
                    title: String(localized: "statistics.hero.relationship.needsAttention"),
                    value: viewModel.relationshipHealthSummary.needsAttention,
                    valueColor: DesignSystem.Colors.accentGold
                )
            }
            .padding(.vertical, DesignSystem.Spacing.cardPaddingSmall)
        }
        .padding(DesignSystem.Spacing.heroCardPadding)
        .background(
            ZStack {
                DesignSystem.Colors.bgSurface

                Circle()
                    .fill(DesignSystem.Colors.primary.opacity(0.08))
                    .frame(width: DesignSystem.Layout.heroDecorationDiameter, height: DesignSystem.Layout.heroDecorationDiameter)
                    .blur(radius: DesignSystem.Layout.heroDecorationBlur)
                    .offset(x: DesignSystem.Layout.heroDecorationOffset, y: -DesignSystem.Layout.heroDecorationOffset)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                .stroke(DesignSystem.Colors.primary.opacity(0.05), lineWidth: 1)
        )
    }

    private var heroDivider: some View {
        Rectangle()
            .fill(DesignSystem.Colors.separator.opacity(0.7))
            .frame(height: 1)
    }

    private var heroVerticalDivider: some View {
        Rectangle()
            .fill(DesignSystem.Colors.separator.opacity(0.8))
            .frame(width: 1, height: 36)
    }

    private func heroMetricCell(title: String, value: String) -> some View {
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

    private func heroStatusItem(
        title: String,
        value: Int,
        valueColor: Color = DesignSystem.Colors.primary
    ) -> some View {
        HStack(spacing: DesignSystem.Spacing.stackTight) {
            Text(title)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
            Text("\(value)")
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(valueColor)
        }
    }

    private var barChartOuterSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.block) {
            statisticsSectionHeader(systemImage: "chart.bar.fill", title: String(localized: "statistics.chart.trend"))
            barChartCard
        }
        .overlay {
            ProLockedOverlay(isLocked: shouldLockProContent) {
                sheetRoute = .proMembership
            }
        }
    }

    // MARK: - Bar Chart

    private var barChartCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            let bars = viewModel.chartBars
            let maxCombined = max(bars.map { $0.income + $0.expense }.max() ?? 1, 1)
            let chartHeight = DesignSystem.Layout.statisticsBarChartHeight

            if bars.isEmpty {
                Text(String(localized: "statistics.chart.noData"))
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: chartHeight)
            } else {
                HStack(alignment: .bottom, spacing: DesignSystem.Spacing.inlineTight) {
                    ForEach(Array(bars.enumerated()), id: \.offset) { index, bar in
                        if let period = viewModel.periodForBarIndex(index) {
                            NavigationLink(value: AppRoute.periodDetail(period)) {
                                barColumn(bar: bar, maxCombined: maxCombined, chartHeight: chartHeight)
                            }
                            .buttonStyle(.plain)
                        } else {
                            barColumn(bar: bar, maxCombined: maxCombined, chartHeight: chartHeight)
                        }
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.inlineTight)
            }

            HStack(spacing: DesignSystem.Spacing.stackLoose) {
                HStack(spacing: DesignSystem.Spacing.inlineTight) {
                    Circle()
                        .fill(DesignSystem.Colors.primary.opacity(0.4))
                        .frame(width: 10, height: 10)
                    Text(String(localized: "statistics.chart.income"))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
                HStack(spacing: DesignSystem.Spacing.inlineTight) {
                    Circle()
                        .fill(DesignSystem.Colors.primary)
                        .frame(width: 10, height: 10)
                    Text(String(localized: "statistics.chart.expense"))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, DesignSystem.Spacing.heroCardPadding)
        }
        .padding(DesignSystem.Spacing.cardPadding)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                .stroke(DesignSystem.Colors.primary.opacity(0.05), lineWidth: 1)
        )
    }

    private var recordTypeCompositionSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.block) {
            statisticsSectionHeader(systemImage: "circle.lefthalf.filled", title: String(localized: "statistics.recordTypeComposition"))
            NavigationLink(value: AppRoute.recordTypeComposition(year: viewModel.selectedYear)) {
                recordTypeCompositionCard
            }
            .buttonStyle(.plain)
        }
    }

    private var eventDistributionSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.block) {
            statisticsSectionHeader(systemImage: "calendar.badge.clock", title: String(localized: "statistics.eventDistribution"))
            NavigationLink(value: AppRoute.eventTypeComposition(year: viewModel.selectedYear)) {
                eventDistributionCard
            }
            .buttonStyle(.plain)
        }
        .overlay {
            ProLockedOverlay(isLocked: shouldLockProContent) {
                sheetRoute = .proMembership
            }
        }
    }

    private func barColumn(bar: (label: String, income: Double, expense: Double), maxCombined: Double, chartHeight: CGFloat) -> some View {
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

    // MARK: - Event Distribution & Record Type (shared donut card)

    private var eventDistributionCard: some View {
        DonutDistributionCard(
            title: String(localized: "statistics.eventDistribution"),
            showsTitleHeader: false,
            emptyMessage: String(localized: "statistics.overview.noEventData"),
            isEmpty: viewModel.eventTypeDistribution.isEmpty,
            ringSegments: eventDonutRingSegments,
            centerTopLabel: String(localized: "statistics.eventDistribution.largest"),
            centerMainText: viewModel.eventTypeDistribution.first.map { viewModel.eventTypeName(for: $0.type) } ?? "",
            centerMainUsesLargeValueStyle: false,
            donutNavigationRoute: nil
        ) {
            ForEach(Array(viewModel.eventTypeDistribution.prefix(4).enumerated()), id: \.offset) { index, item in
                donutDistributionListRow(
                    swatchColor: DesignSystem.Colors.primary.opacity(donutOpacity(for: index)),
                    title: viewModel.eventTypeName(for: item.type),
                    percentage: item.percentage,
                    showsChevron: false
                )
            }
        }
    }

    private var eventDonutRingSegments: [DonutRingSegment] {
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

    private func donutOpacity(for index: Int) -> Double {
        switch index {
        case 0: return 1.0
        case 1: return 0.6
        case 2: return 0.3
        default: return 0.1
        }
    }

    // MARK: - Heatmap

    private var heatmapOuterSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.block) {
            statisticsSectionHeader(systemImage: "square.grid.3x3.fill", title: String(localized: "statistics.heatmap.title")) {
                Text(String(localized: "statistics.heatmap.subtitle"))
                    .font(DesignSystem.Typography.small)
                    .italic()
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
            heatmapCard
        }
    }

    private var heatmapCard: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.block) {
            HStack(spacing: DesignSystem.Spacing.dense) {
                ForEach(0..<12, id: \.self) { month in
                    VStack(spacing: DesignSystem.Spacing.dense) {
                        ForEach(0..<4, id: \.self) { week in
                            RoundedRectangle(cornerRadius: DesignSystem.Radius.chartBar)
                                .fill(DesignSystem.Colors.primary.opacity(
                                    viewModel.heatmapOpacity(viewModel.heatmapGrid[month][week])
                                ))
                                .aspectRatio(1, contentMode: .fit)
                        }
                    }
                }
            }

            HStack(spacing: DesignSystem.Spacing.dense) {
                ForEach(0..<12, id: \.self) { m in
                    Text("\(m + 1)")
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }

            heatmapLegendRow
        }
        .padding(DesignSystem.Spacing.cardPadding)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                .stroke(DesignSystem.Colors.primary.opacity(0.05), lineWidth: 1)
        )
    }

    private var heatmapLegendRow: some View {
        HStack(spacing: DesignSystem.Spacing.inlineTight) {
            HStack(spacing: DesignSystem.Spacing.dense) {
                ForEach(Array([0.12, 0.45, 0.8].enumerated()), id: \.offset) { _, opacity in
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.chartBar)
                        .fill(DesignSystem.Colors.primary.opacity(opacity))
                        .frame(
                            width: DesignSystem.Layout.heatmapLegendSwatchWidth,
                            height: DesignSystem.Layout.heatmapLegendSwatchHeight
                        )
                }
            }
            Text(String(localized: "statistics.heatmap.legend"))
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
        }
    }

    private var recordTypeCompositionCard: some View {
        DonutDistributionCard(
            title: String(localized: "statistics.recordTypeComposition"),
            showsTitleHeader: false,
            emptyMessage: String(localized: "statistics.overview.noEventData"),
            isEmpty: viewModel.recordTypeDistribution.isEmpty,
            ringSegments: recordTypeDonutRingSegments,
            centerTopLabel: String(localized: "recordTypeComposition.yearTotal"),
            centerMainText: "\(viewModel.totalRecordCount)",
            centerMainUsesLargeValueStyle: true
        ) {
            ForEach(Array(viewModel.recordTypeDistribution.enumerated()), id: \.offset) { index, item in
                donutDistributionListRow(
                    swatchColor: recordTypeColor(for: index),
                    title: item.type.displayName,
                    percentage: item.percentage,
                    showsChevron: false
                )
            }
        }
    }

    private var recordTypeDonutRingSegments: [DonutRingSegment] {
        let items = viewModel.recordTypeDistribution
        var segments: [DonutRingSegment] = []
        var current: CGFloat = 0
        for (index, item) in items.enumerated() {
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

    @ViewBuilder
    private func donutDistributionListRow(
        swatchColor: Color,
        title: String,
        percentage: Double,
        showsChevron: Bool
    ) -> some View {
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

    private func recordTypeColor(for index: Int) -> Color {
        switch index {
        case 0: return DesignSystem.Colors.primary
        case 1: return DesignSystem.Colors.primary.opacity(0.55)
        case 2: return DesignSystem.Colors.textTertiary.opacity(0.5)
        default: return DesignSystem.Colors.textPrimary.opacity(0.7)
        }
    }

    // MARK: - Circle Analysis

    private var circleAnalysisSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.block) {
            statisticsSectionHeader(systemImage: "circle.hexagongrid.fill", title: String(localized: "statistics.circleAnalysis"))

            if viewModel.circleAnalysisItems.isEmpty {
                statisticsEmptyStateCard {
                    Text(String(localized: "statistics.overview.noEventData"))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignSystem.Spacing.block) {
                        ForEach(viewModel.circleAnalysisItems) { item in
                            NavigationLink(value: AppRoute.circleDetail(item.circle, year: viewModel.selectedYear)) {
                                circleAnalysisCard(item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private func circleAnalysisCard(_ item: CircleAnalysisItem) -> some View {
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

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.chartBar)
                        .fill(DesignSystem.Colors.primary.opacity(0.1))
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: DesignSystem.Radius.chartBar)
                        .fill(DesignSystem.Colors.primary)
                        .frame(width: geo.size.width * item.ratio, height: 4)
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
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                .stroke(DesignSystem.Colors.primary.opacity(0.05), lineWidth: 1)
        )
    }

    // MARK: - Ranking（往来深交榜）

    private var rankingSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.block) {
            statisticsSectionHeader(systemImage: "trophy.fill", title: String(localized: "statistics.ranking.deepBondTitle")) {
                if !viewModel.topContacts.isEmpty {
                    Text(String(localized: "statistics.ranking.topBadge"))
                        .font(DesignSystem.Typography.small)
                        .fontWeight(.medium)
                        .tracking(0.6)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }

            if viewModel.topContacts.isEmpty {
                statisticsEmptyStateCard {
                    Text(String(localized: "statistics.overview.noRankingData"))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.topContacts.enumerated()), id: \.element.id) { index, item in
                        VStack(spacing: 0) {
                            deepBondRankingRow(rank: index + 1, item: item)
                            if index < viewModel.topContacts.count - 1 {
                                rankingDividerLine
                            }
                        }
                    }
                }
                .background(DesignSystem.Colors.bgSurface)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                        .stroke(DesignSystem.Colors.primary.opacity(0.05), lineWidth: 1)
                )
            }
        }
    }

    private var rankingDividerLine: some View {
        Rectangle()
            .fill(DesignSystem.Colors.separator.opacity(0.55))
            .frame(height: 1)
    }

    private func deepBondRankingRow(rank: Int, item: ContactRankingItem) -> some View {
        let netPositive = item.netValue >= 0
        let netColor = netPositive ? DesignSystem.Colors.primary : DesignSystem.Colors.textPrimary
        let rankCircleFill = rank == 1
            ? DesignSystem.Colors.primary.opacity(0.12)
            : DesignSystem.Colors.bgTag

        return NavigationLink(value: AppRoute.contactDetail(item.contact.persistentModelID)) {
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

                    Text(String(format: String(localized: "statistics.ranking.deepInteractionLine"), item.recordCount))
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

// MARK: - Preview

private func makeStatisticsPreviewContainer() -> ModelContainer? {
    guard let container = try? ModelContainer(
        for: Contact.self, Record.self, Event.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    ) else { return nil }
    let ctx = container.mainContext
    let cal = Calendar.current
    let thisYear = cal.component(.year, from: .now)

    let c1 = Contact(name: "王志刚", relation: "伯父", circle: 1)
    let c2 = Contact(name: "李美玲", relation: "表姐", circle: 2)
    let c3 = Contact(name: "张三", relation: "大学同学", circle: 3)
    [c1, c2, c3].forEach { ctx.insert($0) }

    let e1 = Event(name: "结婚喜宴", type: .wedding, date: cal.date(from: DateComponents(year: thisYear, month: 1, day: 15))!)
    let e2 = Event(name: "添丁满月", type: .birth, date: cal.date(from: DateComponents(year: thisYear, month: 2, day: 10))!)
    let e3 = Event(name: "生日祝寿", type: .birthday, date: cal.date(from: DateComponents(year: thisYear, month: 5, day: 20))!)
    let e4 = Event(name: "乔迁新居", type: .property, date: cal.date(from: DateComponents(year: thisYear, month: 8, day: 5))!)
    [e1, e2, e3, e4].forEach { ctx.insert($0) }

    let records: [Record] = [
        Record(contact: c1, event: e1, amount: 30000, direction: .received, paymentMethod: .wechat, date: cal.date(from: DateComponents(year: thisYear, month: 1, day: 15))!),
        Record(contact: c1, event: e2, amount: 5000, direction: .given, paymentMethod: .cash, date: cal.date(from: DateComponents(year: thisYear, month: 2, day: 10))!),
        Record(contact: c2, event: e1, amount: 28000, direction: .received, paymentMethod: .alipay, date: cal.date(from: DateComponents(year: thisYear, month: 1, day: 16))!),
        Record(contact: c2, event: e3, amount: 12000, direction: .received, paymentMethod: .cash, date: cal.date(from: DateComponents(year: thisYear, month: 5, day: 20))!),
        Record(contact: c3, event: e1, amount: 20000, direction: .given, paymentMethod: .wechat, date: cal.date(from: DateComponents(year: thisYear, month: 1, day: 15))!),
        Record(contact: c3, event: e3, amount: 8000, direction: .given, paymentMethod: .cash, date: cal.date(from: DateComponents(year: thisYear, month: 5, day: 20))!),
        Record(contact: c1, event: e4, amount: 5000, direction: .received, paymentMethod: .wechat, date: cal.date(from: DateComponents(year: thisYear, month: 8, day: 5))!),
        Record(contact: c3, event: e4, amount: 3000, direction: .given, paymentMethod: .alipay, date: cal.date(from: DateComponents(year: thisYear, month: 8, day: 5))!),
    ]
    records.forEach { ctx.insert($0) }

    return container
}

#Preview {
    Group {
        if let container = makeStatisticsPreviewContainer() {
            NavigationStack {
                StatisticsView()
            }
            .environment(SubscriptionManager.shared)
            .modelContainer(container)
        } else {
            Text("Preview unavailable")
        }
    }
}
