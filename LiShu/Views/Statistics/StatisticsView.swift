import SwiftData
import SwiftUI

struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(DebugOverrideManager.self) private var debugOverrides

    @State private var viewModel = StatisticsViewModel()
    @State private var sheetRoute: SheetRoute?

    private var shouldLockProContent: Bool {
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return false
        }
        return !subscriptionManager.effectiveIsPro(overrides: debugOverrides)
    }

    var body: some View {
        StatisticsContentStateView(
            state: viewModel.state,
            hasData: viewModel.hasData,
            hasRankings: !viewModel.allRankedContacts.isEmpty,
            retry: loadData
        ) {
            StatisticsContentScrollView(
                viewModel: viewModel,
                shouldLockProContent: shouldLockProContent,
                onSelectYear: selectYear,
                onPresentProMembership: presentProMembership
            )
        }
        .background(DesignSystem.Colors.bgPage)
        .navigationTitle(String(localized: "statistics.title"))
        .navigationBarTitleDisplayMode(.large)
        .task(loadData)
        .sheet(item: $sheetRoute, content: makeSheet)
    }

    @ViewBuilder
    private func makeSheet(route: SheetRoute) -> some View {
        if case .proMembership = route {
            NavigationStack {
                ProMembershipView()
            }
        }
    }

    private func loadData() {
        viewModel.loadData(context: modelContext)
    }

    private func selectYear(_ year: Int) {
        viewModel.selectYear(year, context: modelContext)
    }

    private func presentProMembership() {
        sheetRoute = .proMembership
    }
}

struct StatisticsContentScrollView: View {
    let viewModel: StatisticsViewModel
    let shouldLockProContent: Bool
    let onSelectYear: (Int) -> Void
    let onPresentProMembership: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: DesignSystem.Spacing.stackLoose) {
                StatisticsYearSelectorSection(
                    selectedYear: viewModel.selectedYear,
                    availableYears: viewModel.availableYears,
                    onSelectYear: onSelectYear
                )
                StatisticsHeroSection(viewModel: viewModel)
                StatisticsBarChartSection(
                    viewModel: viewModel,
                    shouldLockProContent: shouldLockProContent,
                    onPresentProMembership: onPresentProMembership
                )
                StatisticsDistributionSection(
                    systemImage: "circle.lefthalf.filled",
                    title: String(localized: "statistics.recordTypeComposition"),
                    route: AppRoute.recordTypeComposition(year: viewModel.selectedYear),
                    shouldLockProContent: shouldLockProContent,
                    onPresentProMembership: onPresentProMembership
                ) {
                    RecordTypeCompositionCard(viewModel: viewModel)
                }
                StatisticsDistributionSection(
                    systemImage: "calendar.badge.clock",
                    title: String(localized: "statistics.eventDistribution"),
                    route: AppRoute.eventTypeComposition(year: viewModel.selectedYear),
                    shouldLockProContent: shouldLockProContent,
                    onPresentProMembership: onPresentProMembership
                ) {
                    EventDistributionCard(viewModel: viewModel)
                }
                CircleAnalysisSection(viewModel: viewModel)
                RankingSection(viewModel: viewModel)
            }
            .padding(.horizontal, DesignSystem.Spacing.pageHorizontal)
            .padding(.bottom, DesignSystem.Spacing.scrollBottom)
        }
    }
}

// MARK: - Preview

@MainActor
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

    let e1 = Event(name: "结婚喜宴", type: .wedding, date: cal.liShuDate(year: thisYear, month: 1, day: 15))
    let e2 = Event(name: "添丁满月", type: .birth, date: cal.liShuDate(year: thisYear, month: 2, day: 10))
    let e3 = Event(name: "生日祝寿", type: .birthday, date: cal.liShuDate(year: thisYear, month: 5, day: 20))
    let e4 = Event(name: "乔迁新居", type: .property, date: cal.liShuDate(year: thisYear, month: 8, day: 5))
    [e1, e2, e3, e4].forEach { ctx.insert($0) }

    let records: [Record] = [
        Record.makeMonetaryRecord(
            contact: c1,
            event: e1,
            amount: 30000,
            direction: .received,
            paymentMethod: .wechat,
            date: cal.liShuDate(year: thisYear, month: 1, day: 15)
        ),
        Record.makeMonetaryRecord(
            contact: c1,
            event: e2,
            amount: 5000,
            direction: .given,
            paymentMethod: .cash,
            date: cal.liShuDate(year: thisYear, month: 2, day: 10)
        ),
        Record.makeMonetaryRecord(
            contact: c2,
            event: e1,
            amount: 28000,
            direction: .received,
            paymentMethod: .alipay,
            date: cal.liShuDate(year: thisYear, month: 1, day: 16)
        ),
        Record.makeMonetaryRecord(
            contact: c2,
            event: e3,
            amount: 12000,
            direction: .received,
            paymentMethod: .cash,
            date: cal.liShuDate(year: thisYear, month: 5, day: 20)
        ),
        Record.makeMonetaryRecord(
            contact: c3,
            event: e1,
            amount: 20000,
            direction: .given,
            paymentMethod: .wechat,
            date: cal.liShuDate(year: thisYear, month: 1, day: 15)
        ),
        Record.makeMonetaryRecord(
            contact: c3,
            event: e3,
            amount: 8000,
            direction: .given,
            paymentMethod: .cash,
            date: cal.liShuDate(year: thisYear, month: 5, day: 20)
        ),
        Record.makeMonetaryRecord(
            contact: c1,
            event: e4,
            amount: 5000,
            direction: .received,
            paymentMethod: .wechat,
            date: cal.liShuDate(year: thisYear, month: 8, day: 5)
        ),
        Record.makeMonetaryRecord(
            contact: c3,
            event: e4,
            amount: 3000,
            direction: .given,
            paymentMethod: .alipay,
            date: cal.liShuDate(year: thisYear, month: 8, day: 5)
        ),
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
            Text(String(localized: "common.preview.unavailable"))
        }
    }
}
