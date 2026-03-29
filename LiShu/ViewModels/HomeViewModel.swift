import Foundation
import SwiftData

@Observable
class HomeViewModel {
    var yearlyIncome: Double = 0
    var yearlyExpense: Double = 0
    var contactCount: Int = 0
    var recordCount: Int = 0
    var recentRecords: [Record] = []
    var upcomingEvents: [Event] = []
    var currentYear: Int = Calendar.current.component(.year, from: Date())

    func load(context: ModelContext) {
        loadYearlySummary(context: context)
        loadRecentRecords(context: context)
        loadUpcomingEvents(context: context)
    }

    private func loadYearlySummary(context: ModelContext) {
        let calendar = Calendar.current
        let year = currentYear
        guard let startOfYear = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
              let endOfYear = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1)) else {
            yearlyIncome = 0
            yearlyExpense = 0
            contactCount = 0
            recordCount = 0
            return
        }

        do {
            let descriptor = FetchDescriptor<Record>(
                predicate: #Predicate<Record> { record in
                    record.date >= startOfYear && record.date < endOfYear
                }
            )
            let records = try context.fetch(descriptor)

            yearlyIncome = records
                .filter { $0.direction == .received }
                .reduce(0.0) { $0 + $1.amount }

            yearlyExpense = records
                .filter { $0.direction == .given }
                .reduce(0.0) { $0 + $1.amount }

            let contactIDs = Set(records.compactMap { $0.contact?.persistentModelID })
            contactCount = contactIDs.count
            recordCount = records.count
        } catch {
            yearlyIncome = 0
            yearlyExpense = 0
            contactCount = 0
            recordCount = 0
        }
    }

    private func loadRecentRecords(context: ModelContext) {
        do {
            var descriptor = FetchDescriptor<Record>(
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            descriptor.fetchLimit = 5
            recentRecords = try context.fetch(descriptor)
        } catch {
            recentRecords = []
        }
    }

    private func loadUpcomingEvents(context: ModelContext) {
        do {
            let today = Calendar.current.startOfDay(for: Date())
            var descriptor = FetchDescriptor<Event>(
                predicate: #Predicate<Event> { event in
                    event.date >= today
                },
                sortBy: [SortDescriptor(\.date, order: .forward)]
            )
            descriptor.fetchLimit = 5
            upcomingEvents = try context.fetch(descriptor)
        } catch {
            upcomingEvents = []
        }
    }

    var formattedIncome: String {
        "¥" + formatNumber(yearlyIncome)
    }

    var formattedExpense: String {
        "¥" + formatNumber(yearlyExpense)
    }

    var yearBadge: String {
        "\(currentYear)" + String(localized: "home.yearBadge")
    }

    var peopleSummary: String {
        String(format: String(localized: "home.peopleTxSummary"), contactCount, recordCount)
    }

    private func formatNumber(_ value: Double) -> String {
        if value >= 10000 {
            return String(format: String(localized: "number.tenThousandsFormat"), value / 10000)
        }
        return String(format: "%.0f", value)
    }
}
