import SwiftData
import SwiftUI

/// 人情构成详情与事件分布详情共用同一套布局：环形图、图例、「详细构成」卡片与月度迷你柱图。
struct CompositionDetailView: View {
    enum Mode: Hashable {
        case recordTypes(year: Int)
        case eventTypes(year: Int)
    }

    @Environment(\.modelContext) private var modelContext
    @State private var recordVM = RecordTypeCompositionViewModel()
    @State private var eventTypeCompositionVM = EventTypeCompositionViewModel()

    let mode: Mode

    private var navigationTitle: String {
        switch mode {
        case .recordTypes:
            String(localized: "recordTypeComposition.title")
        case .eventTypes:
            String(localized: "eventTypeComposition.title")
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                switch mode {
                case .recordTypes:
                    recordTypesContent
                case .eventTypes:
                    eventTypesContent
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(DesignSystem.Colors.bgPage)
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            switch mode {
            case let .recordTypes(year):
                recordVM.load(year: year, context: modelContext)
            case let .eventTypes(year):
                eventTypeCompositionVM.load(year: year, context: modelContext)
            }
        }
    }

    // MARK: - 人情构成

    private var recordTypesContent: some View {
        Group {
            recordDonutSection
            recordDetailCardsSection
        }
    }

    private var recordDonutSection: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(DesignSystem.Colors.primary.opacity(0.1), lineWidth: 20)

                ForEach(Array(recordTypeDonutSegments.enumerated()), id: \.offset) { _, segment in
                    Circle()
                        .trim(from: segment.start, to: segment.end)
                        .stroke(
                            compositionColor(for: segment.index),
                            style: StrokeStyle(lineWidth: 20, lineCap: .butt)
                        )
                        .rotationEffect(.degrees(-90))
                }

                VStack(spacing: 4) {
                    Text(String(localized: "recordTypeComposition.yearTotal"))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                    Text("\(recordVM.totalCount)")
                        .font(DesignSystem.Typography.title1)
                        .fontWeight(.bold)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                }
            }
            .frame(width: 180, height: 180)
            .padding(.top, 8)

            recordLegendGrid
        }
        .padding(20)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                .stroke(DesignSystem.Colors.primary.opacity(0.05), lineWidth: 1)
        )
    }

    private var recordLegendGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Array(recordVM.items.enumerated()), id: \.offset) { index, item in
                HStack(spacing: 6) {
                    Circle()
                        .fill(compositionColor(for: index))
                        .frame(width: 10, height: 10)
                    Text(item.type.displayName)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    Text(String(format: "%.0f%%", item.percentage * 100))
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                    Spacer()
                }
            }
        }
    }

    private var recordDetailCardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "recordTypeComposition.detailSection"))
                .font(DesignSystem.Typography.caption)
                .fontWeight(.bold)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            ForEach(Array(recordVM.items.enumerated()), id: \.offset) { index, item in
                recordDetailCard(item: item, colorIndex: index)
            }
        }
    }

    private func recordDetailCard(item: RecordTypeCompositionItem, colorIndex: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.type.displayName)
                        .font(DesignSystem.Typography.title3)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    Text(String(format: String(localized: "recordTypeComposition.ratio"), item.percentage * 100))
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.primary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    if item.isMonetaryAggregate {
                        Text(String(localized: "recordTypeComposition.totalAmount"))
                            .font(DesignSystem.Typography.small)
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                        Text(recordVM.formatAmount(item.aggregateValue))
                            .font(DesignSystem.Typography.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                    }
                    Text(recordVM.formatCount(Double(item.count)))
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }

            miniBarChart(distribution: item.monthlyDistribution, color: compositionColor(for: colorIndex))
        }
        .padding(16)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                .stroke(DesignSystem.Colors.primary.opacity(0.05), lineWidth: 1)
        )
    }

    // MARK: - 事件分布（全部分类）

    private var eventTypesContent: some View {
        Group {
            eventTypeDonutSection
            eventTypeDetailCardsSection
        }
    }

    private var eventTypeDonutSection: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(DesignSystem.Colors.primary.opacity(0.1), lineWidth: 20)

                ForEach(Array(eventTypeDonutSegments.enumerated()), id: \.offset) { _, segment in
                    Circle()
                        .trim(from: segment.start, to: segment.end)
                        .stroke(
                            compositionColor(for: segment.index),
                            style: StrokeStyle(lineWidth: 20, lineCap: .butt)
                        )
                        .rotationEffect(.degrees(-90))
                }

                VStack(spacing: 4) {
                    Text(String(localized: "recordTypeComposition.yearTotal"))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                    Text("\(eventTypeCompositionVM.totalCount)")
                        .font(DesignSystem.Typography.title1)
                        .fontWeight(.bold)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                }
            }
            .frame(width: 180, height: 180)
            .padding(.top, 8)

            eventTypeLegendGrid
        }
        .padding(20)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                .stroke(DesignSystem.Colors.primary.opacity(0.05), lineWidth: 1)
        )
    }

    private var eventTypeLegendGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Array(eventTypeCompositionVM.items.enumerated()), id: \.offset) { index, item in
                HStack(spacing: 6) {
                    Circle()
                        .fill(compositionColor(for: index))
                        .frame(width: 10, height: 10)
                    Text(item.eventType.displayName)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    Text(String(format: "%.0f%%", item.percentage * 100))
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                    Spacer()
                }
            }
        }
    }

    private var eventTypeDetailCardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "recordTypeComposition.detailSection"))
                .font(DesignSystem.Typography.caption)
                .fontWeight(.bold)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            ForEach(Array(eventTypeCompositionVM.items.enumerated()), id: \.offset) { index, item in
                eventTypeCompositionDetailCard(item: item, colorIndex: index)
            }
        }
    }

    private func eventTypeCompositionDetailCard(item: EventTypeCompositionItem, colorIndex: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.eventType.displayName)
                        .font(DesignSystem.Typography.title3)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    Text(String(format: String(localized: "recordTypeComposition.ratio"), item.percentage * 100))
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.primary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    if item.isMonetaryAggregate {
                        Text(String(localized: "recordTypeComposition.totalAmount"))
                            .font(DesignSystem.Typography.small)
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                        Text(eventTypeCompositionVM.formatAmount(item.aggregateValue))
                            .font(DesignSystem.Typography.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                    }
                    Text(eventTypeCompositionVM.formatCount(Double(item.count)))
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }

            miniBarChart(distribution: item.monthlyDistribution, color: compositionColor(for: colorIndex))
        }
        .padding(16)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                .stroke(DesignSystem.Colors.primary.opacity(0.05), lineWidth: 1)
        )
    }

    // MARK: - Donut segments

    private struct DonutSegment {
        let start: CGFloat
        let end: CGFloat
        let index: Int
    }

    private var recordTypeDonutSegments: [DonutSegment] {
        var segments: [DonutSegment] = []
        var current: CGFloat = 0
        for (index, item) in recordVM.items.enumerated() {
            let end = current + CGFloat(item.percentage)
            segments.append(DonutSegment(start: current, end: min(end, 1.0), index: index))
            current = end
        }
        return segments
    }

    private var eventTypeDonutSegments: [DonutSegment] {
        var segments: [DonutSegment] = []
        var current: CGFloat = 0
        for (index, item) in eventTypeCompositionVM.items.enumerated() {
            let end = current + CGFloat(item.percentage)
            segments.append(DonutSegment(start: current, end: min(end, 1.0), index: index))
            current = end
        }
        return segments
    }

    // MARK: - Shared chart & colors

    private func miniBarChart(distribution: [Int], color: Color) -> some View {
        let maxCount = max(distribution.max() ?? 1, 1)
        let chartHeight: CGFloat = 60

        return HStack(alignment: .bottom, spacing: 6) {
            ForEach(0 ..< 12, id: \.self) { idx in
                let count = distribution[idx]
                VStack(spacing: 4) {
                    Spacer(minLength: 0)
                    if count > 0 {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(color.opacity(count == maxCount ? 1.0 : 0.4))
                            .frame(height: max(chartHeight * CGFloat(count) / CGFloat(maxCount), 4))
                    } else {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(DesignSystem.Colors.primary.opacity(0.08))
                            .frame(height: 4)
                    }
                    Text("\(idx + 1)")
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: chartHeight + 18)
    }

    private func compositionColor(for index: Int) -> Color {
        switch index {
        case 0: DesignSystem.Colors.primary
        case 1: DesignSystem.Colors.primary.opacity(0.55)
        case 2: DesignSystem.Colors.textTertiary.opacity(0.5)
        default: DesignSystem.Colors.textPrimary.opacity(0.7)
        }
    }
}

// MARK: - Preview

private func makeCompositionDetailPreviewContainer() -> ModelContainer? {
    guard let container = try? ModelContainer(
        for: Contact.self, Record.self, Event.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    ) else { return nil }
    let ctx = container.mainContext
    let cal = Calendar.current
    let thisYear = cal.component(.year, from: .now)

    let c1 = Contact(name: "王志刚", relation: "伯父", circle: 1)
    let c2 = Contact(name: "李美玲", relation: "表姐", circle: 2)
    [c1, c2].forEach { ctx.insert($0) }

    let e1 = Event(name: "结婚喜宴", type: .wedding, date: cal.liShuDate(year: thisYear, month: 1, day: 15))
    let e2 = Event(name: "生日聚会", type: .birthday, date: cal.liShuDate(year: thisYear, month: 5, day: 20))
    [e1, e2].forEach { ctx.insert($0) }

    let r1 = Record.makeMonetaryRecord(
        contact: c1,
        event: e1,
        amount: 3000,
        direction: .received,
        date: cal.liShuDate(year: thisYear, month: 1, day: 15)
    )
    let r2 = Record.makeMonetaryRecord(
        contact: c2,
        event: e1,
        amount: 2000,
        direction: .given,
        date: cal.liShuDate(year: thisYear, month: 2, day: 10)
    )
    let r3 = Record.makeMonetaryRecord(
        contact: c1,
        event: e2,
        amount: 800,
        direction: .received,
        date: cal.liShuDate(year: thisYear, month: 5, day: 20)
    )
    [r1, r2, r3].forEach { ctx.insert($0) }

    return container
}

#Preview("人情构成") {
    Group {
        if let container = makeCompositionDetailPreviewContainer() {
            NavigationStack {
                CompositionDetailView(mode: .recordTypes(year: Calendar.current.component(.year, from: .now)))
            }
            .modelContainer(container)
        } else {
            Text(String(localized: "common.preview.unavailable"))
        }
    }
}

#Preview("事件分布") {
    Group {
        if let container = makeCompositionDetailPreviewContainer() {
            NavigationStack {
                CompositionDetailView(mode: .eventTypes(year: Calendar.current.component(.year, from: .now)))
            }
            .modelContainer(container)
        } else {
            Text(String(localized: "common.preview.unavailable"))
        }
    }
}
