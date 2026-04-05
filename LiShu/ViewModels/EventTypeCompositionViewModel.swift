import Foundation
import SwiftData

struct EventTypeCompositionItem: Identifiable {
    var id: EventType {
        eventType
    }

    let eventType: EventType
    let count: Int
    let percentage: Double
    let monthlyDistribution: [Int]
    /// 该事件类型下金额类记录的金额合计（与统计页事件分布口径一致：仅 monetary + 关联事件）
    let aggregateValue: Double
    let isMonetaryAggregate: Bool
}

@Observable
class EventTypeCompositionViewModel {
    var year: Int = 0
    var items: [EventTypeCompositionItem] = []
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
                    record.date >= startOfYear && record.date < endOfYear &&
                        record.recordTypeRaw == "monetary"
                },
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            let records = try context.fetch(descriptor).filter { $0.event != nil }
            computeDistribution(from: records, calendar: calendar)
            BusinessDataLogger.recordQuery(
                screen: "statistics.eventTypeComposition",
                operation: "load",
                searchText: "",
                filters: ["year": String(year), "recordType": RecordType.monetary.rawValue],
                sort: "date_desc",
                records: records
            )
        } catch {
            items = []
        }
    }

    private func computeDistribution(from records: [Record], calendar: Calendar) {
        totalCount = records.count

        var grouped: [EventType: [Record]] = [:]
        for record in records {
            guard let event = record.event else { continue }
            grouped[event.type, default: []].append(record)
        }

        items = grouped
            .map { eventType, typeRecords in
                let percentage = totalCount > 0 ? Double(typeRecords.count) / Double(totalCount) : 0

                var monthly = Array(repeating: 0, count: 12)
                for record in typeRecords {
                    let m = calendar.component(.month, from: record.date)
                    monthly[m - 1] += 1
                }

                let aggregateValue = typeRecords.reduce(0.0) { $0 + $1.monetaryAmount }

                return EventTypeCompositionItem(
                    eventType: eventType,
                    count: typeRecords.count,
                    percentage: percentage,
                    monthlyDistribution: monthly,
                    aggregateValue: aggregateValue,
                    isMonetaryAggregate: true
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
}
