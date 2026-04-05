import SwiftData
import SwiftUI

struct MonthlyDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = MonthlyDetailViewModel()

    let period: StatsPeriod

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                summaryCards
                netValueCard
                if !viewModel.eventTypeSlices.isEmpty {
                    donutChartCard
                }
                transactionList
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(DesignSystem.Colors.bgPage)
        .navigationTitle(viewModel.periodTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.load(period: period, context: modelContext)
        }
    }

    // MARK: - Summary Cards (Income / Expense)

    private var summaryCards: some View {
        HStack(spacing: 12) {
            summaryCard(
                label: String(localized: "period.detail.income"),
                amount: viewModel.formatAmount(viewModel.periodIncome),
                amountColor: DesignSystem.Colors.primary,
                trend: viewModel.incomeTrend,
                isPositiveTrendGood: true
            )

            summaryCard(
                label: String(localized: "period.detail.expense"),
                amount: viewModel.formatAmount(viewModel.periodExpense),
                amountColor: DesignSystem.Colors.primary,
                trend: viewModel.expenseTrend,
                isPositiveTrendGood: false
            )
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private func summaryCard(
        label: String,
        amount: String,
        amountColor: Color,
        trend: Double?,
        isPositiveTrendGood: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Text(amount)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(amountColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            if let trend, let text = viewModel.formatTrend(trend) {
                let isPositive = trend >= 0
                let trendGood = isPositive == isPositiveTrendGood
                HStack(spacing: 2) {
                    Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                        .font(DesignSystem.Typography.small)
                    Text(text)
                        .font(DesignSystem.Typography.small)
                }
                .foregroundStyle(trendGood ? DesignSystem.Colors.income : DesignSystem.Colors.destructive)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(16)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
    }

    // MARK: - Net Value Card

    private var netValueCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "period.detail.netValue"))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                Text(viewModel.formatNetAmount())
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(
                        viewModel.netAmount >= 0
                            ? DesignSystem.Colors.accentGold
                            : DesignSystem.Colors.primary
                    )
            }

            Spacer()
        }
        .padding(16)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
    }

    // MARK: - Donut Chart Card

    private var donutChartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "period.detail.distribution"))
                .font(DesignSystem.Typography.caption)
                .fontWeight(.bold)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            HStack(spacing: 24) {
                donutChart
                    .frame(width: 96, height: 96)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.eventTypeSlices.prefix(5)) { slice in
                        HStack {
                            Circle()
                                .fill(sliceColor(for: slice))
                                .frame(width: 8, height: 8)
                            Text(slice.name)
                                .font(DesignSystem.Typography.small)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                            Spacer()
                            Text(String(format: "%.0f%%", slice.percentage * 100))
                                .font(DesignSystem.Typography.small)
                                .fontWeight(.bold)
                                .foregroundStyle(DesignSystem.Colors.textPrimary)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
    }

    private var donutChart: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let lineWidth: CGFloat = 12
            let center = CGPoint(x: size / 2, y: size / 2)

            ZStack {
                Circle()
                    .stroke(DesignSystem.Colors.bgTag, lineWidth: lineWidth)

                ForEach(Array(donutSegments.enumerated()), id: \.offset) { _, segment in
                    Circle()
                        .trim(from: segment.start, to: segment.end)
                        .stroke(segment.color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
                        .rotationEffect(.degrees(-90))
                }

                Text(String(localized: "period.detail.overview"))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
            .frame(width: size, height: size)
            .position(center)
        }
    }

    private var donutSegments: [(start: CGFloat, end: CGFloat, color: Color)] {
        var segments: [(start: CGFloat, end: CGFloat, color: Color)] = []
        var current: CGFloat = 0
        for (_, slice) in viewModel.eventTypeSlices.prefix(5).enumerated() {
            let portion = CGFloat(slice.percentage)
            segments.append((start: current, end: current + portion, color: sliceColor(for: slice)))
            current += portion
        }
        return segments
    }

    private func sliceColor(for slice: EventTypeSlice) -> Color {
        guard let idx = viewModel.eventTypeSlices.firstIndex(where: { $0.id == slice.id }) else {
            return DesignSystem.Colors.bgTag
        }
        let colors: [Color] = [
            DesignSystem.Colors.primary,
            DesignSystem.Colors.accentGold,
            DesignSystem.Colors.primary.opacity(0.5),
            DesignSystem.Colors.accentGold.opacity(0.5),
            DesignSystem.Colors.textTertiary,
        ]
        return colors[idx % colors.count]
    }

    // MARK: - Transaction List

    private var transactionList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(String(localized: "period.detail.transactions"))
                    .font(DesignSystem.Typography.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Spacer()

                Text(String(format: String(localized: "period.detail.count"), viewModel.records.count))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }

            if viewModel.records.isEmpty {
                EmptyStateView(
                    icon: "doc.text",
                    message: String(localized: "record.list.empty")
                )
                .frame(height: 200)
            } else {
                VStack(spacing: 10) {
                    ForEach(viewModel.records) { record in
                        if let contact = record.contact, record.event != nil {
                            NavigationLink(value: AppRoute.contactExchange(contact.persistentModelID)) {
                                RecordRow(record: record)
                            }
                            .buttonStyle(.plain)
                            .background(DesignSystem.Colors.bgSurface)
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
                        }
                    }
                }
            }
        }
    }
}

private func makePreviewContainer() -> ModelContainer? {
    guard let container = try? ModelContainer(
        for: Contact.self, Record.self, Event.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    ) else { return nil }
    let ctx = container.mainContext

    let c1 = Contact(name: "张三", relation: "朋友", circle: 3)
    let c2 = Contact(name: "李华", relation: "同事", circle: 3)
    let c3 = Contact(name: "王芳", relation: "表姐", circle: 2)
    let c4 = Contact(name: "赵明", relation: "同学", circle: 3)
    [c1, c2, c3, c4].forEach { ctx.insert($0) }

    let e1 = Event(name: "张三婚礼", type: .wedding, date: .makeDate(2026, 3, 8))
    let e2 = Event(name: "李华生日", type: .birthday, date: .makeDate(2026, 3, 15))
    let e3 = Event(name: "王芳满月酒", type: .birth, date: .makeDate(2026, 3, 20))
    let e4 = Event(name: "赵明乔迁", type: .property, date: .makeDate(2026, 1, 10))
    let e5 = Event(name: "春节", type: .festival, date: .makeDate(2026, 2, 17))
    [e1, e2, e3, e4, e5].forEach { ctx.insert($0) }

    let records: [Record] = [
        Record.makeMonetaryRecord(contact: c1, event: e1, amount: 2000, direction: .given, date: .makeDate(2026, 3, 8)),
        Record.makeMonetaryRecord(contact: c2, event: e2, amount: 500, direction: .given, date: .makeDate(2026, 3, 15)),
        Record.makeMonetaryRecord(contact: c3, event: e3, amount: 800, direction: .received, date: .makeDate(2026, 3, 20)),
        Record.makeMonetaryRecord(contact: c1, event: e1, amount: 1000, direction: .received, date: .makeDate(2026, 3, 9)),
        Record.makeMonetaryRecord(contact: c4, event: e4, amount: 600, direction: .given, date: .makeDate(2026, 1, 10)),
        Record.makeMonetaryRecord(contact: c2, event: e5, amount: 1200, direction: .received, date: .makeDate(2026, 2, 17)),
        Record.makeMonetaryRecord(contact: c3, event: e5, amount: 800, direction: .given, date: .makeDate(2026, 2, 18)),
    ]
    records.forEach { ctx.insert($0) }

    return container
}

private extension Date {
    static func makeDate(_ y: Int, _ m: Int, _ d: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: y, month: m, day: d)) ?? .now
    }
}

#Preview {
    Group {
        if let container = makePreviewContainer() {
            NavigationStack {
                MonthlyDetailView(period: .month(year: 2026, month: 3))
            }
            .modelContainer(container)
        } else {
            Text(String(localized: "common.preview.unavailable"))
        }
    }
}

#Preview("Quarter") {
    Group {
        if let container = makePreviewContainer() {
            NavigationStack {
                MonthlyDetailView(period: .quarter(year: 2026, quarter: 1))
            }
            .modelContainer(container)
        } else {
            Text(String(localized: "common.preview.unavailable"))
        }
    }
}
