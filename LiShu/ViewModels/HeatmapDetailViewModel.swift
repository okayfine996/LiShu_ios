import Foundation
import SwiftData

struct HeatmapInsightItem: Identifiable {
    let monthIndex: Int
    let count: Int

    var id: Int { monthIndex }
}

struct HeatmapRecordRowItem: Identifiable {
    let recordID: PersistentIdentifier
    let contactName: String
    let eventTitle: String
    let dateText: String
    let amountText: String?

    var id: PersistentIdentifier { recordID }
}

/// 与热力矩阵格子一致：某月第几周（0–3）下的往来列表。
struct HeatmapWeekSectionItem: Identifiable {
    let monthIndex: Int
    let weekIndex: Int
    let records: [HeatmapRecordRowItem]

    var id: Int { monthIndex * 4 + weekIndex }
}

@Observable
final class HeatmapDetailViewModel {
    var year: Int
    var heatmapGrid: [[Int]] = Array(repeating: Array(repeating: 0, count: 4), count: 12)
    var totalInteractions: Int = 0
    var yearOverYearPercent: Double?
    var insights: [HeatmapInsightItem] = []
    /// 按周分组的往来（仅包含有记录的周，顺序为 1 月第 1 周 → … → 12 月第 4 周）
    var weekSections: [HeatmapWeekSectionItem] = []
    var state: LoadingState<Bool> = .idle

    init(year: Int) {
        self.year = year
    }

    func load(context: ModelContext) {
        state = .loading
        do {
            let allRecords = try context.fetch(FetchDescriptor<Record>())
            computeYearBounds(from: allRecords)
            computeHeatmapGrid(from: allRecords)
            totalInteractions = yearRecords(from: allRecords).count
            yearOverYearPercent = computeYoYInteractionChange(from: allRecords)
            computeInsights(from: allRecords)
            computeWeekSections(from: allRecords)
            state = .loaded(true)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func heatmapOpacity(_ count: Int) -> Double {
        if count == 0 { return 0.05 }
        let maxCount = max(Double(heatmapGrid.flatMap { $0 }.max() ?? 1), 1)
        return min(0.1 + Double(count) / maxCount * 0.7, 0.8)
    }

    func monthName(forMonthIndex monthIndex: Int) -> String {
        var c = DateComponents()
        c.year = 2000
        c.month = monthIndex + 1
        c.day = 1
        guard let date = Calendar.current.date(from: c) else { return "\(monthIndex + 1)" }
        let f = DateFormatter()
        f.locale = Locale.current
        f.setLocalizedDateFormatFromTemplate("MMMM")
        return f.string(from: date)
    }

    // MARK: - Private

    private func yearRecords(from records: [Record]) -> [Record] {
        let calendar = Calendar.current
        return records.filter { calendar.component(.year, from: $0.date) == year }
    }

    private func computeYearBounds(from records: [Record]) {
        let calendar = Calendar.current
        let years = Set(records.map { calendar.component(.year, from: $0.date) })
        let currentYear = calendar.component(.year, from: Date())
        var yearSet = years
        yearSet.insert(currentYear)
        let sorted = yearSet.sorted()
        guard let minY = sorted.first, let maxY = sorted.last else { return }
        if year < minY { year = minY }
        if year > maxY { year = maxY }
    }

    private func computeHeatmapGrid(from records: [Record]) {
        let calendar = Calendar.current
        let ys = yearRecords(from: records)
        var grid = Array(repeating: Array(repeating: 0, count: 4), count: 12)
        for record in ys {
            let month = calendar.component(.month, from: record.date) - 1
            let day = calendar.component(.day, from: record.date)
            let week = min((day - 1) / 7, 3)
            if month >= 0 && month < 12 {
                grid[month][week] += 1
            }
        }
        heatmapGrid = grid
    }

    private func computeYoYInteractionChange(from records: [Record]) -> Double? {
        let calendar = Calendar.current
        let currentCount = yearRecords(from: records).count
        let previousYear = year - 1
        let previousCount = records.filter { calendar.component(.year, from: $0.date) == previousYear }.count
        guard previousCount > 0 else { return nil }
        return Double(currentCount - previousCount) / Double(previousCount)
    }

    private func computeInsights(from records: [Record]) {
        let calendar = Calendar.current
        var monthCounts = Array(repeating: 0, count: 12)
        for record in yearRecords(from: records) {
            let m = calendar.component(.month, from: record.date) - 1
            if m >= 0 && m < 12 { monthCounts[m] += 1 }
        }
        let ranked = monthCounts.enumerated().sorted { $0.element > $1.element }
        insights = ranked.prefix(2).filter { $0.element > 0 }.map { HeatmapInsightItem(monthIndex: $0.offset, count: $0.element) }
    }

    private func computeWeekSections(from records: [Record]) {
        var sections: [HeatmapWeekSectionItem] = []
        for m in 0..<12 {
            for w in 0..<4 {
                let inWeek = recordsInWeek(year: year, month: m, week: w, from: records)
                guard !inWeek.isEmpty else { continue }
                let rows = inWeek
                    .sorted { $0.date > $1.date }
                    .map { makeRow($0) }
                sections.append(HeatmapWeekSectionItem(monthIndex: m, weekIndex: w, records: rows))
            }
        }
        weekSections = sections
    }

    private func recordsInWeek(year: Int, month: Int, week: Int, from records: [Record]) -> [Record] {
        let calendar = Calendar.current
        var comps = DateComponents(year: year, month: month + 1, day: 1)
        guard let startOfMonth = calendar.date(from: comps) else { return [] }
        guard let range = calendar.range(of: .day, in: .month, for: startOfMonth) else { return [] }
        let dayStart = week * 7 + 1
        let dayEnd = min((week + 1) * 7, range.count)
        return yearRecords(from: records).filter { r in
            let m = calendar.component(.month, from: r.date) - 1
            let d = calendar.component(.day, from: r.date)
            return m == month && d >= dayStart && d <= dayEnd
        }
    }

    private func makeRow(_ record: Record) -> HeatmapRecordRowItem {
        let contactName = record.contact?.name ?? String(localized: "heatmap.detail.unknownContact")
        let eventTitle = record.event?.name ?? record.contextTag
        let dateText = Self.shortDateFormatter.string(from: record.date)
        let amountText: String?
        if record.recordType == .monetary {
            let amount = record.monetaryAmount
            if let s = Self.amountFormatter.string(from: NSNumber(value: amount)) {
                amountText = "¥" + s
            } else {
                amountText = "¥" + String(format: "%.0f", amount)
            }
        } else {
            amountText = nil
        }
        return HeatmapRecordRowItem(
            recordID: record.persistentModelID,
            contactName: contactName,
            eventTitle: eventTitle.isEmpty ? String(localized: "heatmap.detail.noEventTitle") : eventTitle,
            dateText: dateText,
            amountText: amountText
        )
    }

    private static let shortDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MM-dd"
        return f
    }()

    private static let amountFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f
    }()
}
