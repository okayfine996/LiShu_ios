import Foundation
import SwiftData

struct HeatmapInsightItem: Identifiable {
    let monthIndex: Int
    let count: Int

    var id: Int {
        monthIndex
    }
}

@Observable
final class HeatmapDetailViewModel {
    var year: Int
    var heatmapGrid: [[Int]] = Array(repeating: Array(repeating: 0, count: 4), count: 12)
    var totalInteractions: Int = 0
    var yearOverYearPercent: Double?
    var insights: [HeatmapInsightItem] = []
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
            if month >= 0, month < 12 {
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
            if m >= 0, m < 12 { monthCounts[m] += 1 }
        }
        let ranked = monthCounts.enumerated().sorted { $0.element > $1.element }
        insights = ranked.prefix(2).filter { $0.element > 0 }.map { HeatmapInsightItem(monthIndex: $0.offset, count: $0.element) }
    }
}
