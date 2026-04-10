import Foundation
import SwiftData

@Observable
class HomeViewModel {
    var yearlyIncome: Double = 0
    var yearlyExpense: Double = 0
    var contactCount: Int = 0
    var recordCount: Int = 0
    var monetaryCount: Int = 0
    var nonFinancialInteractionCount: Int = 0
    var coreCircleActiveContactCount: Int = 0
    var giftCount: Int = 0
    var favorCount: Int = 0
    var banquetCount: Int = 0
    var previousYearTotalExchangeAmount: Double = 0
    var mostActiveContactName: String?
    var mostActiveContactRecordCount: Int = 0
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
              let endOfYear = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1)),
              let startOfPreviousYear = calendar.date(from: DateComponents(year: year - 1, month: 1, day: 1))
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
            let previousYearDescriptor = FetchDescriptor<Record>(
                predicate: #Predicate<Record> { record in
                    record.date >= startOfPreviousYear && record.date < startOfYear
                }
            )
            let previousYearRecords = try context.fetch(previousYearDescriptor)

            let monetaryRecords = records.filter { $0.recordType == .monetary }
            let previousYearMonetaryRecords = previousYearRecords.filter { $0.recordType == .monetary }

            yearlyIncome = monetaryRecords
                .filter { $0.direction == .received }
                .reduce(0.0) { $0 + $1.monetaryAmount }

            yearlyExpense = monetaryRecords
                .filter { $0.direction == .given }
                .reduce(0.0) { $0 + $1.monetaryAmount }

            let contactIDs = Set<PersistentIdentifier>(records.compactMap { $0.contact?.persistentModelID })
            let coreCircleContactIDs = Set<PersistentIdentifier>(records.compactMap { record in
                guard let contact = record.contact, contact.circle <= 2 else { return nil }
                return contact.persistentModelID
            })
            var interactionCountsByContact: [PersistentIdentifier: (name: String, count: Int)] = [:]
            for record in records {
                guard let contact = record.contact else { continue }
                let id = contact.persistentModelID
                var value = interactionCountsByContact[id] ?? (name: contact.name, count: 0)
                value.count += 1
                interactionCountsByContact[id] = value
            }

            contactCount = contactIDs.count
            coreCircleActiveContactCount = coreCircleContactIDs.count
            recordCount = records.count
            monetaryCount = monetaryRecords.count
            nonFinancialInteractionCount = records.filter { $0.recordType != .monetary }.count
            giftCount = records.filter { $0.recordType == .gift }.count
            favorCount = records.filter { $0.recordType == .favor }.count
            banquetCount = records.filter { $0.recordType == .banquet }.count
            previousYearTotalExchangeAmount = previousYearMonetaryRecords.reduce(0.0) { $0 + $1.monetaryAmount }
            if let mostActive = interactionCountsByContact.values.max(by: { lhs, rhs in
                if lhs.count == rhs.count {
                    return lhs.name > rhs.name
                }
                return lhs.count < rhs.count
            }) {
                mostActiveContactName = mostActive.name
                mostActiveContactRecordCount = mostActive.count
            } else {
                mostActiveContactName = nil
                mostActiveContactRecordCount = 0
            }
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

    var formattedIncome: String {
        "¥" + formatNumber(yearlyIncome)
    }

    var formattedExpense: String {
        "¥" + formatNumber(yearlyExpense)
    }

    var formattedTotalExchangeAmount: String {
        "¥" + formatAmountWithComma(totalExchangeAmount)
    }

    var yearBadge: String {
        "\(currentYear)"
    }

    var lunarYearLabel: String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .chinese)
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.dateFormat = "U年"
        return formatter.string(from: Date())
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

    var formattedMonetaryNet: String {
        formatNetValue(yearlyIncome - yearlyExpense)
    }

    var totalExchangeAmount: Double {
        yearlyIncome + yearlyExpense
    }

    var incomeRatio: Double {
        guard totalExchangeAmount > 0 else { return 0 }
        return yearlyIncome / totalExchangeAmount
    }

    var expenseRatio: Double {
        guard totalExchangeAmount > 0 else { return 0 }
        return yearlyExpense / totalExchangeAmount
    }

    var yearOverYearChangeRate: Double? {
        guard previousYearTotalExchangeAmount > 0 else { return nil }
        return (totalExchangeAmount - previousYearTotalExchangeAmount) / previousYearTotalExchangeAmount
    }

    var formattedYearOverYearChange: String? {
        guard let yearOverYearChangeRate else { return nil }
        let sign = yearOverYearChangeRate >= 0 ? "+" : "-"
        return String(
            format: String(localized: "statistics.hero.yoy"),
            sign,
            abs(yearOverYearChangeRate) * 100
        )
    }

    var coreCircleRatioPercent: Int {
        guard contactCount > 0 else { return 0 }
        return Int((Double(coreCircleActiveContactCount) / Double(contactCount) * 100).rounded())
    }

    var coreCircleSummary: String {
        String(format: String(localized: "home.coreCircleShareFormat"), coreCircleRatioPercent)
    }

    var nonFinancialSummary: String {
        String(format: String(localized: "home.nonFinancialSummaryFormat"), nonFinancialInteractionCount)
    }

    var relationshipInsight: String {
        if let mostActiveContactName, mostActiveContactRecordCount > 0 {
            return String(
                format: String(localized: "home.relationshipInsightTopContactFormat"),
                mostActiveContactName,
                mostActiveContactRecordCount
            )
        }

        return String(
            format: String(localized: "home.relationshipInsightFallbackFormat"),
            contactCount
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
        nonFinancialInteractionCount = 0
        coreCircleActiveContactCount = 0
        giftCount = 0
        favorCount = 0
        banquetCount = 0
        previousYearTotalExchangeAmount = 0
        mostActiveContactName = nil
        mostActiveContactRecordCount = 0
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
