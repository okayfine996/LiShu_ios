import Foundation
import SwiftData

/// Represents a flexible time range for the period detail view.
enum StatsPeriod: Hashable {
    case month(year: Int, month: Int)
    case quarter(year: Int, quarter: Int)

    var year: Int {
        switch self {
        case let .month(y, _): y
        case let .quarter(y, _): y
        }
    }

    var title: String {
        switch self {
        case let .month(y, m):
            "\(y)" + String(localized: "monthly.yearSuffix") + "\(m)" + String(localized: "monthly.monthSuffix")
        case let .quarter(y, q):
            "\(y)" + String(localized: "monthly.yearSuffix") + "Q\(q)"
        }
    }

    var monthRange: ClosedRange<Int> {
        switch self {
        case let .month(_, m):
            return m...m
        case let .quarter(_, q):
            let start = (q - 1) * 3 + 1
            return start...(start + 2)
        }
    }

    func dateRange(calendar: Calendar) -> (start: Date, end: Date)? {
        let range = monthRange
        guard let start = calendar.date(from: DateComponents(year: year, month: range.lowerBound, day: 1)),
              let end = calendar.date(from: DateComponents(year: year, month: range.upperBound + 1, day: 1))
        else {
            return nil
        }
        return (start, end)
    }

    /// The same period in the previous cycle for trend comparison.
    var previous: StatsPeriod {
        switch self {
        case let .month(y, m):
            m == 1 ? .month(year: y - 1, month: 12) : .month(year: y, month: m - 1)
        case let .quarter(y, q):
            q == 1 ? .quarter(year: y - 1, quarter: 4) : .quarter(year: y, quarter: q - 1)
        }
    }
}

struct EventTypeSlice: Identifiable {
    let id = UUID()
    let type: EventType
    let name: String
    let amount: Double
    let percentage: Double
}

@Observable
class MonthlyDetailViewModel {
    var records: [Record] = []
    var period: StatsPeriod = .month(year: 2026, month: 1)

    var periodIncome: Double = 0
    var periodExpense: Double = 0
    var prevIncome: Double = 0
    var prevExpense: Double = 0
    var eventTypeSlices: [EventTypeSlice] = []

    var netAmount: Double {
        periodIncome - periodExpense
    }

    var incomeTrend: Double? {
        guard prevIncome > 0 else { return nil }
        return (periodIncome - prevIncome) / prevIncome
    }

    var expenseTrend: Double? {
        guard prevExpense > 0 else { return nil }
        return (periodExpense - prevExpense) / prevExpense
    }

    var periodTitle: String {
        period.title
    }

    // MARK: - Formatting

    func formatAmount(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return "¥" + (formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value))
    }

    func formatNetAmount() -> String {
        let prefix = netAmount >= 0 ? "+" : ""
        return prefix + formatAmount(netAmount)
    }

    func formatTrend(_ value: Double?) -> String? {
        guard let v = value else { return nil }
        let sign = v >= 0 ? "+" : ""
        return sign + String(format: "%.1f%%", v * 100)
    }

    // MARK: - Load

    func load(period: StatsPeriod, context: ModelContext) {
        self.period = period
        let calendar = Calendar.current

        guard let range = period.dateRange(calendar: calendar) else {
            records = []
            return
        }

        let start = range.start
        let end = range.end

        do {
            let descriptor = FetchDescriptor<Record>(
                predicate: #Predicate<Record> { $0.date >= start && $0.date < end },
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            records = try context.fetch(descriptor)
        } catch {
            records = []
        }

        periodIncome = records.filter { $0.direction == .received }.reduce(0) { $0 + $1.monetaryAmount }
        periodExpense = records.filter { $0.direction == .given }.reduce(0) { $0 + $1.monetaryAmount }
        BusinessDataLogger.recordQuery(
            screen: "statistics.monthlyDetail",
            operation: "load",
            searchText: "",
            filters: [
                "period": period.title,
                "year": String(period.year),
            ],
            sort: "date_desc",
            records: records
        )

        loadPreviousPeriod(context: context, calendar: calendar)
        computeEventTypeSlices()
    }

    // MARK: - Private

    private func loadPreviousPeriod(context: ModelContext, calendar: Calendar) {
        let prev = period.previous
        guard let range = prev.dateRange(calendar: calendar) else {
            prevIncome = 0
            prevExpense = 0
            return
        }

        let start = range.start
        let end = range.end

        do {
            let descriptor = FetchDescriptor<Record>(
                predicate: #Predicate<Record> { $0.date >= start && $0.date < end }
            )
            let prevRecords = try context.fetch(descriptor)
            prevIncome = prevRecords.filter { $0.direction == .received }.reduce(0) { $0 + $1.monetaryAmount }
            prevExpense = prevRecords.filter { $0.direction == .given }.reduce(0) { $0 + $1.monetaryAmount }
        } catch {
            prevIncome = 0
            prevExpense = 0
        }
    }

    private func computeEventTypeSlices() {
        let expenseRecords = records.filter { $0.direction == .given }
        var typeAmounts: [EventType: Double] = [:]
        for record in expenseRecords {
            guard let event = record.event else { continue }
            typeAmounts[event.type, default: 0] += record.monetaryAmount
        }
        let total = max(typeAmounts.values.reduce(0, +), 1)

        eventTypeSlices = typeAmounts
            .sorted { $0.value > $1.value }
            .map { EventTypeSlice(
                type: $0.key,
                name: eventTypeName($0.key),
                amount: $0.value,
                percentage: $0.value / total
            ) }
    }

    private func eventTypeName(_ type: EventType) -> String {
        type.displayName
    }
}
