import Foundation
import SwiftData

struct RecordTypeCompositionItem: Identifiable {
    let id = UUID()
    let type: RecordType
    let count: Int
    let percentage: Double
    let monthlyDistribution: [Int]
    /// For monetary/gift: total amount; for favor/banquet: count
    let aggregateValue: Double
    let isMonetaryAggregate: Bool
}

@Observable
class RecordTypeCompositionViewModel {
    var year: Int = 0
    var items: [RecordTypeCompositionItem] = []
    var totalCount: Int = 0

    func load(year: Int, context: ModelContext) {
        self.year = year

        let calendar = Calendar.current
        guard let startOfYear = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
              let endOfYear = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1))
        else {
            items = []
            return
        }

        do {
            let descriptor = FetchDescriptor<Record>(
                predicate: #Predicate<Record> { record in
                    record.date >= startOfYear && record.date < endOfYear
                },
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            let records = try context.fetch(descriptor)
            computeDistribution(from: records, calendar: calendar)
        } catch {
            items = []
        }
    }

    private func computeDistribution(from records: [Record], calendar: Calendar) {
        totalCount = records.count

        var grouped: [RecordType: [Record]] = [:]
        for record in records {
            grouped[record.recordType, default: []].append(record)
        }

        items = grouped
            .map { type, typeRecords in
                let percentage = totalCount > 0 ? Double(typeRecords.count) / Double(totalCount) : 0

                var monthly = Array(repeating: 0, count: 12)
                for record in typeRecords {
                    let m = calendar.component(.month, from: record.date)
                    monthly[m - 1] += 1
                }

                let isMonetaryAggregate = (type == .monetary || type == .gift)
                let aggregateValue: Double = if isMonetaryAggregate {
                    typeRecords.reduce(0) { $0 + $1.resolvedDisplayAmount }
                } else {
                    Double(typeRecords.count)
                }

                return RecordTypeCompositionItem(
                    type: type,
                    count: typeRecords.count,
                    percentage: percentage,
                    monthlyDistribution: monthly,
                    aggregateValue: aggregateValue,
                    isMonetaryAggregate: isMonetaryAggregate
                )
            }
            .sorted { $0.count > $1.count }
    }

    func formatAmount(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return "¥" + (formatter.string(from: NSNumber(value: value)) ?? String(format: "%.0f", value))
    }

    func formatCount(_ value: Double) -> String {
        String(format: "%.0f", value) + String(localized: "recordTypeComposition.countUnit")
    }

    func recordTypeColor(for index: Int) -> (primary: Bool, opacity: Double) {
        switch index {
        case 0: (true, 1.0)
        case 1: (true, 0.55)
        case 2: (false, 0.5)
        default: (false, 0.7)
        }
    }
}
