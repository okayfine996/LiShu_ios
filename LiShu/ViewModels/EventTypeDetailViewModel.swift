import Foundation
import SwiftData

@Observable
class EventTypeDetailViewModel {
    var eventType: EventType = .other
    var year: Int = 0
    var records: [Record] = []
    var monthlyDistribution: [Int] = Array(repeating: 0, count: 12)

    var totalCount: Int {
        records.count
    }

    var totalExpense: Double {
        records.filter { $0.direction == .given }.reduce(0) { $0 + $1.monetaryAmount }
    }

    var totalIncome: Double {
        records.filter { $0.direction == .received }.reduce(0) { $0 + $1.monetaryAmount }
    }

    var netValue: Double {
        totalIncome - totalExpense
    }

    var peakMonth: Int {
        guard let maxIdx = monthlyDistribution.indices.max(by: { monthlyDistribution[$0] < monthlyDistribution[$1] }),
              monthlyDistribution[maxIdx] > 0 else { return -1 }
        return maxIdx
    }

    var typeName: String {
        eventType.displayName
    }

    var navigationTitle: String {
        typeName + " | " + "\(year)" + String(localized: "monthly.yearSuffix")
    }

    func load(eventType: EventType, year: Int, context: ModelContext) {
        self.eventType = eventType
        self.year = year

        let calendar = Calendar.current
        let typeRaw = eventType.rawValue
        guard let startOfYear = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
              let endOfYear = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1))
        else {
            records = []
            return
        }

        do {
            let descriptor = FetchDescriptor<Record>(
                predicate: #Predicate<Record> { record in
                    record.event?.typeRaw == typeRaw &&
                        record.date >= startOfYear && record.date < endOfYear
                },
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            records = try context.fetch(descriptor)
        } catch {
            records = []
        }

        var dist = Array(repeating: 0, count: 12)
        for record in records {
            let m = calendar.component(.month, from: record.date)
            dist[m - 1] += 1
        }
        monthlyDistribution = dist
    }

    func formatAmount(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return "¥" + (formatter.string(from: NSNumber(value: value)) ?? String(format: "%.0f", value))
    }

    func formatNetValue() -> String {
        let prefix = netValue >= 0 ? "+" : ""
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return prefix + (formatter.string(from: NSNumber(value: netValue)) ?? String(format: "%.0f", netValue))
    }
}
