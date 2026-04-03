import SwiftUI
import SwiftData

/// 人情热力详情：年度人情矩阵与高峰洞察（参考 Stitch 稿）。
struct HeatmapDetailView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel: HeatmapDetailViewModel

    init(year: Int) {
        _viewModel = State(initialValue: HeatmapDetailViewModel(year: year))
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loaded:
                mainScroll
            case .error(let message):
                ErrorStateView(message: message) {
                    viewModel.load(context: modelContext)
                }
            }
        }
        .background(DesignSystem.Colors.bgPage)
        .navigationTitle(String(localized: "heatmap.detail.title"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if case .idle = viewModel.state {
                viewModel.load(context: modelContext)
            }
        }
    }

    /// 供 LazyVGrid 使用，避免在 ViewBuilder 内写 `let`（旧版 Swift 可能无法编译）。
    private var monthMatrixGridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: DesignSystem.Spacing.block), count: 4)
    }

    private var monthMiniCellColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: DesignSystem.Spacing.dense),
            GridItem(.flexible(), spacing: DesignSystem.Spacing.dense),
        ]
    }

    private var mainScroll: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: DesignSystem.Spacing.stackLoose) {
                matrixCard
                if !viewModel.insights.isEmpty {
                    insightsSection
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.pageHorizontal)
            .padding(.bottom, DesignSystem.Spacing.scrollBottom)
        }
    }

    // MARK: - Matrix Card

    private var matrixCard: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.block) {
            HStack(spacing: DesignSystem.Spacing.inlineTight) {
                Image(systemName: "square.grid.3x3.fill")
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.primary)
                Text(String(localized: "heatmap.detail.matrixTitle"))
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
            }

            LazyVGrid(columns: monthMatrixGridColumns, spacing: DesignSystem.Spacing.block) {
                ForEach(0..<12, id: \.self) { month in
                    monthMiniGrid(month: month)
                }
            }

            HeatmapLegendRow()
                .frame(maxWidth: .infinity, alignment: .leading)

            Divider()
                .background(DesignSystem.Colors.separator.opacity(0.6))

            summaryFooter
        }
        .padding(DesignSystem.Spacing.heroCardPadding)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                .stroke(DesignSystem.Colors.primary.opacity(0.05), lineWidth: 1)
        )
    }

    private func monthMiniGrid(month: Int) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.stackTight) {
            Text(viewModel.monthName(forMonthIndex: month))
                .font(DesignSystem.Typography.small)
                .fontWeight(.medium)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            LazyVGrid(columns: monthMiniCellColumns, spacing: DesignSystem.Spacing.dense) {
                ForEach(0..<4, id: \.self) { week in
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.chartBar)
                        .fill(
                            DesignSystem.Colors.primary.opacity(
                                viewModel.heatmapOpacity(viewModel.heatmapGrid[month][week])
                            )
                        )
                        .aspectRatio(1, contentMode: .fit)
                }
            }
        }
    }

    private var summaryFooter: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.inlineTight) {
            Text(summaryAttributedLine)
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            Image(systemName: "info.circle")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
                .accessibilityHidden(true)
        }
    }

    private var summaryAttributedLine: String {
        let base = String(format: String(localized: "heatmap.detail.summaryBase"), viewModel.totalInteractions)
        guard let yoy = viewModel.yearOverYearPercent else { return base }
        if yoy >= 0 {
            return base + String(format: String(localized: "heatmap.detail.yoyUp"), yoy * 100)
        }
        return base + String(format: String(localized: "heatmap.detail.yoyDown"), abs(yoy) * 100)
    }

    // MARK: - Insights

    private var insightsSection: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.block) {
            ForEach(viewModel.insights) { item in
                insightCell(item: item)
            }
        }
    }

    private func insightCell(item: HeatmapInsightItem) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.inlineTight) {
            HStack(spacing: DesignSystem.Spacing.inlineTight) {
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.primary.opacity(0.1))
                        .frame(width: DesignSystem.Layout.rankBadgeSize + DesignSystem.Spacing.dense, height: DesignSystem.Layout.rankBadgeSize + DesignSystem.Spacing.dense)
                    Image(systemName: "sparkles")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.primary)
                }

                Text(String(format: String(localized: "heatmap.detail.insightTitle"), viewModel.monthName(forMonthIndex: item.monthIndex)))
                    .font(DesignSystem.Typography.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
            }

            Text(String(format: String(localized: "heatmap.detail.insightBody"), item.count))
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSystem.Spacing.cardPaddingSmall)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard)
                .stroke(DesignSystem.Colors.primary.opacity(0.05), lineWidth: 1)
        )
    }
}

// MARK: - Preview

private func makeHeatmapDetailPreviewContainer() -> ModelContainer? {
    guard let container = try? ModelContainer(
        for: Contact.self, Record.self, Event.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    ) else { return nil }
    let ctx = container.mainContext
    let cal = Calendar.current
    let y = cal.component(.year, from: .now)

    func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
        cal.date(from: DateComponents(year: year, month: month, day: day))!
    }

    let names = ["王志刚", "李美玲", "陈悦", "赵强", "刘洋", "周敏", "吴磊", "孙丽"]
    let contacts = names.map { Contact(name: $0, relation: "预览", circle: 2) }
    contacts.forEach { ctx.insert($0) }

    let ev1 = Event(name: "春节走动", type: .other, date: day(y, 2, 1))
    let ev2 = Event(name: "同事婚礼", type: .wedding, date: day(y, 6, 15))
    ctx.insert(ev1)
    ctx.insert(ev2)

    var records: [Record] = []

    /// 每月固定落在不同「周」的日期（2 月不超过 28 日），避免预览数据挤在同一月。
    func daysSpreadInMonth(_ month: Int) -> [Int] {
        switch month {
        case 2: return [3, 8, 15, 22, 27]
        case 4, 6, 9, 11: return [2, 9, 16, 23, 29]
        default: return [2, 9, 16, 23, 30]
        }
    }

    // 上一年：每月 1 笔，同比基数分散在 12 个月
    for month in 1...12 {
        records.append(
            Record(
                contact: contacts[month % contacts.count],
                event: nil,
                amount: 700 + Double(month * 20),
                direction: .given,
                paymentMethod: .wechat,
                date: day(y - 1, month, 6 + (month % 5))
            )
        )
    }

    // 当年：每月相同笔数，日期落在不同周，热力尽量铺满且各月接近
    for month in 1...12 {
        for (i, d) in daysSpreadInMonth(month).enumerated() {
            records.append(
                Record(
                    contact: contacts[(month + i) % contacts.count],
                    event: month == 2 ? ev1 : (month == 6 ? ev2 : nil),
                    amount: Double(500 + month * 40 + i * 80),
                    direction: month % 3 == 0 ? .received : .given,
                    paymentMethod: i % 2 == 0 ? .alipay : .cash,
                    date: day(y, month, d)
                )
            )
        }
    }

    // 非金额往来：奇数月各 1 笔，仍保持按月份分散
    for month in stride(from: 1, through: 11, by: 2) {
        let r = Record(
            contact: contacts[month % contacts.count],
            event: nil,
            amount: 0,
            direction: .given,
            date: day(y, month, 11 + (month % 4)),
            recordType: .favor,
            favorDescription: String(localized: "record.type.favor")
        )
        records.append(r)
    }

    records.forEach { ctx.insert($0) }
    return container
}

#Preview {
    Group {
        if let container = makeHeatmapDetailPreviewContainer() {
            let y = Calendar.current.component(.year, from: Date())
            NavigationStack {
                HeatmapDetailView(year: y)
            }
            .modelContainer(container)
        } else {
            Text(String(localized: "common.preview.unavailable"))
        }
    }
}
