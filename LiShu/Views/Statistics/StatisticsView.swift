import SwiftUI
import SwiftData

struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @State private var viewModel = StatisticsViewModel()
    @State private var sheetRoute: SheetRoute?

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
            VStack(spacing: 20) {
                selectorSection
                heroCard
                barChartSection
                    .overlay {
                        ProLockedOverlay(isLocked: !subscriptionManager.isPro) {
                            sheetRoute = .proMembership
                        }
                    }
                eventDistributionCard
                    .overlay {
                        ProLockedOverlay(isLocked: !subscriptionManager.isPro) {
                            sheetRoute = .proMembership
                        }
                    }
                heatmapCard
                circleAnalysisSection
                rankingSection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
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
                HStack(spacing: 4) {
                    Text("\(viewModel.selectedYear)" + String(localized: "statistics.year.suffix"))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }

            Spacer()
        }
    }

    // MARK: - Hero Card

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(String(localized: "statistics.hero.netBalance"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(.white.opacity(0.7))
                .padding(.bottom, 4)

            Text("¥" + viewModel.formatAmountWithComma(viewModel.netValue))
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(.white)
                .padding(.bottom, 24)

            Rectangle()
                .fill(.white.opacity(0.2))
                .frame(height: 1)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "statistics.hero.totalIncome"))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(.white.opacity(0.7))
                    Text("¥" + viewModel.formatAmountWithComma(viewModel.totalIncome))
                        .font(DesignSystem.Typography.title3)
                        .foregroundStyle(.white)
                }

                Spacer()

                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "statistics.hero.totalExpense"))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(.white.opacity(0.7))
                    Text("¥" + viewModel.formatAmountWithComma(viewModel.totalExpense))
                        .font(DesignSystem.Typography.title3)
                        .foregroundStyle(.white)
                }
            }
            .padding(.top, 16)

            HStack(spacing: 6) {
                Image(systemName: "person.2")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.7))
                Text(String(format: String(localized: "statistics.hero.peopleTxSummary"), viewModel.contactCount, viewModel.totalRecordCount))
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(.top, 12)
        }
        .padding(24)
        .background(
            ZStack {
                DesignSystem.Colors.primary

                Circle()
                    .fill(.white.opacity(0.1))
                    .frame(width: 128, height: 128)
                    .blur(radius: 20)
                    .offset(x: 80, y: -80)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        .shadow(color: DesignSystem.Colors.primary.opacity(0.2), radius: 16, y: 8)
    }

    // MARK: - Bar Chart

    private var barChartSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(DesignSystem.Colors.primary)
                    .frame(width: 4, height: 16)
                Text(String(localized: "statistics.chart.trend"))
                    .font(DesignSystem.Typography.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
            }
            .padding(.bottom, 24)

            let bars = viewModel.chartBars
            let maxCombined = max(bars.map { $0.income + $0.expense }.max() ?? 1, 1)
            let chartHeight: CGFloat = 160

            if bars.isEmpty {
                Text(String(localized: "statistics.chart.noData"))
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: chartHeight)
            } else {
                HStack(alignment: .bottom, spacing: 8) {
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
                .padding(.horizontal, 8)
            }

            HStack(spacing: 24) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(DesignSystem.Colors.primary.opacity(0.4))
                        .frame(width: 10, height: 10)
                    Text(String(localized: "statistics.chart.income"))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
                HStack(spacing: 8) {
                    Circle()
                        .fill(DesignSystem.Colors.primary)
                        .frame(width: 10, height: 10)
                    Text(String(localized: "statistics.chart.expense"))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 24)
        }
        .padding(20)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                .stroke(DesignSystem.Colors.primary.opacity(0.05), lineWidth: 1)
        )
    }

    // MARK: - Event Distribution

    private func barColumn(bar: (label: String, income: Double, expense: Double), maxCombined: Double, chartHeight: CGFloat) -> some View {
        VStack(spacing: 4) {
            VStack(spacing: 2) {
                Spacer(minLength: 0)

                if bar.income > 0 {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(DesignSystem.Colors.primary.opacity(0.4))
                        .frame(height: chartHeight * bar.income / maxCombined)
                }

                if bar.expense > 0 {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(DesignSystem.Colors.primary)
                        .frame(height: chartHeight * bar.expense / maxCombined)
                }
            }
            .frame(height: chartHeight)

            Text(bar.label)
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Event Distribution

    private var eventDistributionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "statistics.eventDistribution"))
                .font(DesignSystem.Typography.caption)
                .fontWeight(.bold)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            if viewModel.eventTypeDistribution.isEmpty {
                Text(String(localized: "statistics.overview.noEventData"))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                HStack(alignment: .center, spacing: 24) {
                    if let topType = viewModel.eventTypeDistribution.first?.type {
                        NavigationLink(value: AppRoute.eventTypeDetail(topType, year: viewModel.selectedYear)) {
                            donutChart
                        }
                        .buttonStyle(.plain)
                    } else {
                        donutChart
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(viewModel.eventTypeDistribution.prefix(4).enumerated()), id: \.offset) { index, item in
                            NavigationLink(value: AppRoute.eventTypeDetail(item.type, year: viewModel.selectedYear)) {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(DesignSystem.Colors.primary.opacity(donutOpacity(for: index)))
                                        .frame(width: 8, height: 8)
                                    Text(viewModel.eventTypeName(for: item.type))
                                        .font(DesignSystem.Typography.small)
                                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                                    Spacer()
                                    Text(String(format: "%.0f%%", item.percentage * 100))
                                        .font(DesignSystem.Typography.small)
                                        .fontWeight(.medium)
                                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 10))
                                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                .stroke(DesignSystem.Colors.primary.opacity(0.05), lineWidth: 1)
        )
    }

    private var donutChart: some View {
        ZStack {
            Circle()
                .stroke(DesignSystem.Colors.primary.opacity(0.1), lineWidth: 10)

            ForEach(Array(donutSegments.enumerated()), id: \.offset) { _, segment in
                Circle()
                    .trim(from: segment.start, to: segment.end)
                    .stroke(
                        DesignSystem.Colors.primary.opacity(donutOpacity(for: segment.index)),
                        style: StrokeStyle(lineWidth: 10, lineCap: .butt)
                    )
                    .rotationEffect(.degrees(-90))
            }

            VStack(spacing: 2) {
                Text(String(localized: "statistics.eventDistribution.largest"))
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                if let topType = viewModel.eventTypeDistribution.first {
                    Text(viewModel.eventTypeName(for: topType.type))
                        .font(DesignSystem.Typography.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                }
            }
        }
        .frame(width: 140, height: 140)
    }

    private struct DonutSegment {
        let start: CGFloat
        let end: CGFloat
        let index: Int
    }

    private var donutSegments: [DonutSegment] {
        let items = Array(viewModel.eventTypeDistribution.prefix(4))
        var segments: [DonutSegment] = []
        var current: CGFloat = 0
        for (index, item) in items.enumerated() {
            let end = current + CGFloat(item.percentage)
            segments.append(DonutSegment(start: current, end: min(end, 1.0), index: index))
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

    private var heatmapCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(String(localized: "statistics.heatmap.title"))
                    .font(DesignSystem.Typography.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Spacer()
                Text(String(localized: "statistics.heatmap.subtitle"))
                    .font(.system(size: 10, weight: .medium))
                    .italic()
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }

            HStack(spacing: 6) {
                ForEach(0..<12, id: \.self) { month in
                    VStack(spacing: 6) {
                        ForEach(0..<4, id: \.self) { week in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(DesignSystem.Colors.primary.opacity(
                                    viewModel.heatmapOpacity(viewModel.heatmapGrid[month][week])
                                ))
                                .aspectRatio(1, contentMode: .fit)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                .stroke(DesignSystem.Colors.primary.opacity(0.05), lineWidth: 1)
        )
    }

    // MARK: - Circle Analysis

    private var circleAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "statistics.circleAnalysis"))
                .font(DesignSystem.Typography.caption)
                .fontWeight(.bold)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            if viewModel.circleAnalysisItems.isEmpty {
                Text(String(localized: "statistics.overview.noEventData"))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
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
        VStack(alignment: .leading, spacing: 4) {
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
            .padding(.top, 8)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(DesignSystem.Colors.primary.opacity(0.1))
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(DesignSystem.Colors.primary)
                        .frame(width: geo.size.width * item.ratio, height: 4)
                }
            }
            .frame(height: 4)
            .padding(.top, 4)
        }
        .frame(width: 140)
        .padding(16)
        .contentShape(Rectangle())
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                .stroke(DesignSystem.Colors.primary.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - Ranking

    private var rankingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(String(localized: "statistics.ranking.netValue"))
                    .font(DesignSystem.Typography.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Spacer()

                if !viewModel.topContacts.isEmpty {
                    NavigationLink(value: AppRoute.netValueRanking(year: viewModel.selectedYear)) {
                        HStack(spacing: 4) {
                            Text(String(localized: "common.viewAll"))
                                .font(DesignSystem.Typography.small)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            if viewModel.topContacts.isEmpty {
                Text(String(localized: "statistics.overview.noRankingData"))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(viewModel.topContacts.enumerated()), id: \.element.id) { index, item in
                        rankingRow(index: index + 1, item: item)
                    }
                }
            }
        }
    }

    private func rankingRow(index: Int, item: ContactRankingItem) -> some View {
        NavigationLink(value: AppRoute.contactDetail(item.contact.persistentModelID)) {
            HStack(spacing: 12) {
                Text("\(index)")
                    .font(DesignSystem.Typography.small)
                    .fontWeight(.bold)
                    .foregroundStyle(index <= 3 ? .white : DesignSystem.Colors.textTertiary)
                    .frame(width: 24, height: 24)
                    .background(index <= 3 ? DesignSystem.Colors.primary : DesignSystem.Colors.bgInput)
                    .clipShape(Circle())

                Text(String(item.contact.name.prefix(1)))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .frame(width: 48, height: 48)
                    .background(DesignSystem.Colors.bgTag)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.contact.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    Text(String(format: String(localized: "statistics.ranking.count"), item.recordCount))
                        .font(.system(size: 13))
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }

                Spacer()

                Text(viewModel.formatNetValue(item.netValue))
                    .font(DesignSystem.Typography.small)
                    .fontWeight(.medium)
                    .foregroundStyle(DesignSystem.Colors.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(DesignSystem.Colors.primary.opacity(0.1))
                    .clipShape(Capsule())
            }
            .padding(16)
            .contentShape(Rectangle())
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
            .shadow(color: DesignSystem.Colors.separator.opacity(0.2), radius: 2, y: 1)
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
