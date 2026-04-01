import SwiftUI
import SwiftData

struct RecordTypeCompositionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = RecordTypeCompositionViewModel()

    let year: Int

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                donutSection
                detailCardsSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(DesignSystem.Colors.bgPage)
        .navigationTitle(String(localized: "recordTypeComposition.title"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.load(year: year, context: modelContext)
        }
    }

    // MARK: - Donut Section

    private var donutSection: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(DesignSystem.Colors.primary.opacity(0.1), lineWidth: 20)

                ForEach(Array(compositionDonutSegments.enumerated()), id: \.offset) { _, segment in
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
                    Text("\(viewModel.totalCount)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                }
            }
            .frame(width: 180, height: 180)
            .padding(.top, 8)

            legendGrid
        }
        .padding(20)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                .stroke(DesignSystem.Colors.primary.opacity(0.05), lineWidth: 1)
        )
    }

    private var legendGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Array(viewModel.items.enumerated()), id: \.offset) { index, item in
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

    // MARK: - Detail Cards

    private var detailCardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "recordTypeComposition.detailSection"))
                .font(DesignSystem.Typography.caption)
                .fontWeight(.bold)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            ForEach(Array(viewModel.items.enumerated()), id: \.offset) { index, item in
                detailCard(item: item, colorIndex: index)
            }
        }
    }

    private func detailCard(item: RecordTypeCompositionItem, colorIndex: Int) -> some View {
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
                        Text(viewModel.formatAmount(item.aggregateValue))
                            .font(DesignSystem.Typography.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                    }
                    Text(viewModel.formatCount(Double(item.count)))
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

    private func miniBarChart(distribution: [Int], color: Color) -> some View {
        let maxCount = max(distribution.max() ?? 1, 1)
        let chartHeight: CGFloat = 60

        return HStack(alignment: .bottom, spacing: 6) {
            ForEach(0..<12, id: \.self) { idx in
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
                        .font(.system(size: 9))
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: chartHeight + 18)
    }

    // MARK: - Helpers

    private struct CompositionDonutSegment {
        let start: CGFloat
        let end: CGFloat
        let index: Int
    }

    private var compositionDonutSegments: [CompositionDonutSegment] {
        var segments: [CompositionDonutSegment] = []
        var current: CGFloat = 0
        for (index, item) in viewModel.items.enumerated() {
            let end = current + CGFloat(item.percentage)
            segments.append(CompositionDonutSegment(start: current, end: min(end, 1.0), index: index))
            current = end
        }
        return segments
    }

    private func compositionColor(for index: Int) -> Color {
        switch index {
        case 0: return DesignSystem.Colors.primary
        case 1: return DesignSystem.Colors.primary.opacity(0.55)
        case 2: return DesignSystem.Colors.textTertiary.opacity(0.5)
        default: return DesignSystem.Colors.textPrimary.opacity(0.7)
        }
    }
}

// MARK: - Preview

private func makeRecordTypeCompositionPreviewContainer() -> ModelContainer? {
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
    let c4 = Contact(name: "赵丽华", relation: "同事", circle: 2)
    [c1, c2, c3, c4].forEach { ctx.insert($0) }

    let e1 = Event(name: "结婚喜宴", type: .wedding, date: cal.date(from: DateComponents(year: thisYear, month: 1, day: 15))!)
    let e2 = Event(name: "生日祝寿", type: .birthday, date: cal.date(from: DateComponents(year: thisYear, month: 5, day: 20))!)
    let e3 = Event(name: "乔迁新居", type: .property, date: cal.date(from: DateComponents(year: thisYear, month: 8, day: 5))!)
    [e1, e2, e3].forEach { ctx.insert($0) }

    // monetary records — spread across months
    let monetaryRecords: [Record] = [
        Record(contact: c1, event: e1, amount: 3000, direction: .received, date: cal.date(from: DateComponents(year: thisYear, month: 1, day: 15))!),
        Record(contact: c2, event: e1, amount: 2000, direction: .given, date: cal.date(from: DateComponents(year: thisYear, month: 2, day: 10))!),
        Record(contact: c3, event: e2, amount: 1000, direction: .received, date: cal.date(from: DateComponents(year: thisYear, month: 5, day: 20))!),
        Record(contact: c4, event: e2, amount: 800, direction: .given, date: cal.date(from: DateComponents(year: thisYear, month: 5, day: 21))!),
        Record(contact: c1, event: e3, amount: 1500, direction: .received, date: cal.date(from: DateComponents(year: thisYear, month: 8, day: 5))!),
        Record(contact: c2, event: e3, amount: 600, direction: .given, date: cal.date(from: DateComponents(year: thisYear, month: 8, day: 6))!),
        Record(contact: c3, event: e1, amount: 500, direction: .given, date: cal.date(from: DateComponents(year: thisYear, month: 3, day: 10))!),
        Record(contact: c4, event: e1, amount: 2200, direction: .received, date: cal.date(from: DateComponents(year: thisYear, month: 1, day: 16))!),
    ]
    monetaryRecords.forEach { ctx.insert($0) }

    // gift records
    let giftRecords: [Record] = [
        Record(contact: c2, event: e2, direction: .given, date: cal.date(from: DateComponents(year: thisYear, month: 4, day: 1))!, recordType: .gift),
        Record(contact: c1, event: e1, direction: .received, date: cal.date(from: DateComponents(year: thisYear, month: 1, day: 16))!, recordType: .gift),
        Record(contact: c4, event: e3, direction: .given, date: cal.date(from: DateComponents(year: thisYear, month: 8, day: 10))!, recordType: .gift),
        Record(contact: c3, event: e2, direction: .received, date: cal.date(from: DateComponents(year: thisYear, month: 6, day: 1))!, recordType: .gift),
        Record(contact: c2, event: e3, direction: .given, date: cal.date(from: DateComponents(year: thisYear, month: 9, day: 15))!, recordType: .gift),
    ]
    giftRecords.forEach { ctx.insert($0) }

    // favor records
    let favorRecords: [Record] = [
        Record(contact: c3, event: e2, direction: .received, date: cal.date(from: DateComponents(year: thisYear, month: 6, day: 15))!, recordType: .favor),
        Record(contact: c1, event: e1, direction: .given, date: cal.date(from: DateComponents(year: thisYear, month: 2, day: 20))!, recordType: .favor),
        Record(contact: c4, event: e3, direction: .received, date: cal.date(from: DateComponents(year: thisYear, month: 7, day: 10))!, recordType: .favor),
        Record(contact: c2, event: e2, direction: .given, date: cal.date(from: DateComponents(year: thisYear, month: 10, day: 5))!, recordType: .favor),
    ]
    favorRecords.forEach { ctx.insert($0) }

    // banquet records
    let banquetRecords: [Record] = [
        Record(contact: c1, event: e1, direction: .received, date: cal.date(from: DateComponents(year: thisYear, month: 1, day: 15))!, recordType: .banquet),
        Record(contact: c3, event: e3, direction: .given, date: cal.date(from: DateComponents(year: thisYear, month: 8, day: 5))!, recordType: .banquet),
        Record(contact: c4, event: e2, direction: .received, date: cal.date(from: DateComponents(year: thisYear, month: 11, day: 20))!, recordType: .banquet),
    ]
    banquetRecords.forEach { ctx.insert($0) }

    return container
}

#Preview {
    Group {
        if let container = makeRecordTypeCompositionPreviewContainer() {
            NavigationStack {
                RecordTypeCompositionDetailView(year: Calendar.current.component(.year, from: .now))
            }
            .modelContainer(container)
        } else {
            Text("Preview unavailable")
        }
    }
}
