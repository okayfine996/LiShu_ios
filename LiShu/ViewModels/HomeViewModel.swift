import Foundation
import SwiftData

@Observable
class HomeViewModel {
    var yearlyIncome: Double = 0
    var yearlyExpense: Double = 0
    var contactCount: Int = 0
    var recordCount: Int = 0
    var monetaryCount: Int = 0
    var giftCount: Int = 0
    var favorCount: Int = 0
    var banquetCount: Int = 0
    var recentRecords: [Record] = []
    var upcomingEvents: [Event] = []
    var upcomingFestivals: [FestivalOccurrence] = []
    var currentYear: Int = Calendar.current.component(.year, from: Date())

    func load(context: ModelContext) {
        loadYearlySummary(context: context)
        loadRecentRecords(context: context)
        loadUpcomingEvents(context: context)
        loadUpcomingFestivals(context: context)
    }

    private func loadYearlySummary(context: ModelContext) {
        let calendar = Calendar.current
        let year = currentYear
        guard let startOfYear = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
              let endOfYear = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1))
        else {
            resetSummary()
            return
        }

        do {
            let descriptor = FetchDescriptor<Record>(
                predicate: #Predicate<Record> { record in
                    record.date >= startOfYear && record.date < endOfYear
                }
            )
            let records = try context.fetch(descriptor)

            let monetaryRecords = records.filter { $0.recordType == .monetary }

            yearlyIncome = monetaryRecords
                .filter { $0.direction == .received }
                .reduce(0.0) { $0 + $1.monetaryAmount }

            yearlyExpense = monetaryRecords
                .filter { $0.direction == .given }
                .reduce(0.0) { $0 + $1.monetaryAmount }

            let contactIDs = Set(records.compactMap { $0.contact?.persistentModelID })
            contactCount = contactIDs.count
            recordCount = records.count
            monetaryCount = monetaryRecords.count
            giftCount = records.filter { $0.recordType == .gift }.count
            favorCount = records.filter { $0.recordType == .favor }.count
            banquetCount = records.filter { $0.recordType == .banquet }.count
        } catch {
            resetSummary()
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

    private func loadUpcomingFestivals(context: ModelContext) {
        upcomingFestivals = Array(FestivalService.allOccurrences(context: context).prefix(3))
    }

    var formattedIncome: String {
        "¥" + formatNumber(yearlyIncome)
    }

    var formattedExpense: String {
        "¥" + formatNumber(yearlyExpense)
    }

    var yearBadge: String {
        "\(currentYear)"
    }

    var peopleSummary: String {
        String(format: String(localized: "home.peopleTxSummary"), contactCount, recordCount)
    }

    var monetaryNetSummary: String {
        let net = yearlyIncome - yearlyExpense
        return String(
            format: String(localized: "home.monetaryNetSummary"),
            formatNetValue(net),
            formatNumber(yearlyIncome),
            formatNumber(yearlyExpense)
        )
    }

    /// 各类型统计（count > 0 的才展示）
    var typeBreakdown: [(type: RecordType, count: Int)] {
        var result: [(RecordType, Int)] = []
        if monetaryCount > 0 { result.append((.monetary, monetaryCount)) }
        if giftCount > 0 { result.append((.gift, giftCount)) }
        if favorCount > 0 { result.append((.favor, favorCount)) }
        if banquetCount > 0 { result.append((.banquet, banquetCount)) }
        return result
    }

    private func resetSummary() {
        yearlyIncome = 0
        yearlyExpense = 0
        contactCount = 0
        recordCount = 0
        monetaryCount = 0
        giftCount = 0
        favorCount = 0
        banquetCount = 0
    }

    private func formatNumber(_ value: Double) -> String {
        if value >= 10000 {
            return String(format: String(localized: "number.tenThousandsFormat"), value / 10000)
        }
        return String(format: "%.0f", value)
    }

    private func formatAmountWithComma(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? String(format: "%.0f", amount)
    }

    /// 与统计页口径一致：礼金收支净值（收 − 支），正数带「+」。
    private func formatNetValue(_ value: Double) -> String {
        let prefix = value >= 0 ? "+" : ""
        return prefix + "¥" + formatAmountWithComma(value)
    }
}
