import Foundation
import SwiftData

// MARK: - Supporting Types

struct ContactRankingItem: Identifiable {
    let contact: Contact
    let recordCount: Int
    let income: Double
    let expense: Double
    let lastRecordDate: Date?

    var id: PersistentIdentifier {
        contact.persistentModelID
    }

    var netValue: Double {
        income - expense
    }

    var totalAmount: Double {
        income + expense
    }
}

struct CircleAnalysisItem: Identifiable {
    let id = UUID()
    let circle: Int
    let name: String
    let amount: Double
    let ratio: Double
}

@Observable
class StatisticsViewModel {
    struct RelationshipHealthSummary {
        var close: Int = 0
        var stable: Int = 0
        var distant: Int = 0
        var needsAttention: Int = 0
    }

    var selectedYear: Int = Calendar.current.component(.year, from: Date())
    var availableYears: [Int] = []
    var totalIncome: Double = 0
    var totalExpense: Double = 0
    var netValue: Double = 0
    var monthlyData: [(month: Int, income: Double, expense: Double)] = []
    var eventTypeDistribution: [(type: EventType, amount: Double, percentage: Double)] = []
    var topContacts: [ContactRankingItem] = []
    var allRankedContacts: [ContactRankingItem] = []
    var circleAnalysisItems: [CircleAnalysisItem] = []
    var heatmapGrid: [[Int]] = Array(repeating: Array(repeating: 0, count: 4), count: 12)
    var nonFinancialInteractionCount: Int = 0
    var recordTypeDistribution: [(type: RecordType, count: Int, percentage: Double)] = []
    var yearOverYearChangeRate: Double?
    var relationshipHealthSummary = RelationshipHealthSummary()
    var state: LoadingState<Bool> = .idle

    var chartBars: [(label: String, income: Double, expense: Double)] {
        monthlyData.map { ("\($0.month)" + String(localized: "statistics.month"), $0.income, $0.expense) }
    }

    func periodForBarIndex(_ index: Int) -> StatsPeriod? {
        guard index < monthlyData.count else { return nil }
        return .month(year: selectedYear, month: monthlyData[index].month)
    }

    func loadData(context: ModelContext) {
        state = .loading
        do {
            let allRecords = try context.fetch(FetchDescriptor<Record>())
            computeAvailableYears(from: allRecords)
            computeYearlyStats(from: allRecords)
            computeMonthlyData(from: allRecords)
            computeEventTypeDistribution(from: allRecords)
            computeContactRanking(from: allRecords)
            computeCircleAnalysis(from: allRecords)
            computeHeatmapGrid(from: allRecords)
            computeRecordTypeDistribution(from: allRecords)
            computeYearOverYearChange(from: allRecords)
            computeRelationshipHealthSummary()
            state = .loaded(true)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func selectYear(_ year: Int, context: ModelContext) {
        selectedYear = year
        loadData(context: context)
    }

    var hasData: Bool {
        totalIncome > 0 || totalExpense > 0 || nonFinancialInteractionCount > 0
    }

    var totalRecordCount: Int {
        allRankedContacts.reduce(0) { $0 + $1.recordCount }
    }

    var contactCount: Int {
        allRankedContacts.count
    }

    var totalExchangeAmount: Double {
        totalIncome + totalExpense
    }

    // MARK: - Ranking sorted lists

    func contactsSortedByMost() -> [ContactRankingItem] {
        allRankedContacts.sorted { $0.recordCount > $1.recordCount }
    }

    func contactsSortedByIncome() -> [ContactRankingItem] {
        allRankedContacts.sorted { $0.income > $1.income }
    }

    func contactsSortedByExpense() -> [ContactRankingItem] {
        allRankedContacts.sorted { $0.expense > $1.expense }
    }

    // MARK: - Display helpers

    func circleDisplayName(_ circle: Int) -> String {
        switch circle {
        case 1: String(localized: "statistics.circle.family")
        case 2: String(localized: "statistics.circle.close")
        case 3: String(localized: "statistics.circle.social")
        default: String(localized: "statistics.circle.other")
        }
    }

    func heatmapOpacity(_ count: Int) -> Double {
        if count == 0 { return 0.05 }
        let maxCount = max(Double(heatmapGrid.flatMap(\.self).max() ?? 1), 1)
        return min(0.1 + Double(count) / maxCount * 0.7, 0.8)
    }

    // MARK: - Private computations

    private func computeAvailableYears(from records: [Record]) {
        let calendar = Calendar.current
        let years = Set(records.map { calendar.component(.year, from: $0.date) })
        let currentYear = calendar.component(.year, from: Date())
        var yearSet = years
        yearSet.insert(currentYear)
        availableYears = yearSet.sorted()
        if !availableYears.contains(selectedYear) {
            selectedYear = availableYears.last ?? currentYear
        }
    }

    private func computeYearlyStats(from records: [Record]) {
        let calendar = Calendar.current
        let yearRecords = records.filter {
            calendar.component(.year, from: $0.date) == selectedYear
        }
        let monetaryRecords = yearRecords.filter { $0.recordType == .monetary }
        totalIncome = monetaryRecords
            .filter { $0.direction == .received }
            .reduce(0.0) { $0 + $1.monetaryAmount }
        totalExpense = monetaryRecords
            .filter { $0.direction == .given }
            .reduce(0.0) { $0 + $1.monetaryAmount }
        netValue = totalIncome - totalExpense
        nonFinancialInteractionCount = yearRecords.filter { $0.recordType != .monetary }.count
    }

    private func computeMonthlyData(from records: [Record]) {
        let calendar = Calendar.current
        let yearRecords = records.filter {
            calendar.component(.year, from: $0.date) == selectedYear && $0.recordType == .monetary
        }
        var monthly: [(month: Int, income: Double, expense: Double)] = []
        for month in 1 ... 12 {
            let monthRecords = yearRecords.filter {
                calendar.component(.month, from: $0.date) == month
            }
            let income = monthRecords
                .filter { $0.direction == .received }
                .reduce(0.0) { $0 + $1.monetaryAmount }
            let expense = monthRecords
                .filter { $0.direction == .given }
                .reduce(0.0) { $0 + $1.monetaryAmount }
            monthly.append((month: month, income: income, expense: expense))
        }
        monthlyData = monthly
    }

    private func computeEventTypeDistribution(from records: [Record]) {
        let calendar = Calendar.current
        let yearRecords = records.filter {
            calendar.component(.year, from: $0.date) == selectedYear &&
                $0.recordType == .monetary &&
                $0.event != nil
        }
        var typeAmounts: [EventType: Double] = [:]
        for record in yearRecords {
            guard let event = record.event else { continue }
            typeAmounts[event.type, default: 0] += record.monetaryAmount
        }
        let totalAmount = typeAmounts.values.reduce(0, +)
        eventTypeDistribution = typeAmounts
            .map { (type: $0.key, amount: $0.value, percentage: totalAmount > 0 ? $0.value / totalAmount : 0) }
            .sorted { $0.amount > $1.amount }
    }

    private func computeContactRanking(from records: [Record]) {
        let calendar = Calendar.current
        let yearRecords = records.filter {
            calendar.component(.year, from: $0.date) == selectedYear
        }
        var contactStats: [PersistentIdentifier: (contact: Contact, recordCount: Int, income: Double, expense: Double, lastDate: Date?)] =
            [:]
        for record in yearRecords {
            guard let contact = record.contact else { continue }
            let cid = contact.persistentModelID
            var stats = contactStats[cid] ?? (contact: contact, recordCount: 0, income: 0, expense: 0, lastDate: nil)
            stats.recordCount += 1
            if record.recordType == .monetary {
                if record.direction == .received {
                    stats.income += record.monetaryAmount
                } else {
                    stats.expense += record.monetaryAmount
                }
            }
            if stats.lastDate.map({ record.date > $0 }) ?? true {
                stats.lastDate = record.date
            }
            contactStats[cid] = stats
        }
        allRankedContacts = contactStats.values
            .map { ContactRankingItem(
                contact: $0.contact,
                recordCount: $0.recordCount,
                income: $0.income,
                expense: $0.expense,
                lastRecordDate: $0.lastDate
            ) }
            .sorted { abs($0.netValue) > abs($1.netValue) }
        topContacts = Array(allRankedContacts.prefix(5))
    }

    private func computeCircleAnalysis(from records: [Record]) {
        let calendar = Calendar.current
        let yearRecords = records.filter {
            calendar.component(.year, from: $0.date) == selectedYear && $0.recordType == .monetary
        }
        var circleAmounts: [Int: Double] = [:]
        for record in yearRecords {
            guard let contact = record.contact else { continue }
            circleAmounts[contact.circle, default: 0] += record.monetaryAmount
        }
        let maxAmount = max(circleAmounts.values.max() ?? 1, 1)
        circleAnalysisItems = circleAmounts
            .sorted { $0.key < $1.key }
            .map { CircleAnalysisItem(circle: $0.key, name: circleDisplayName($0.key), amount: $0.value, ratio: $0.value / maxAmount) }
    }

    /// Heatmap 统计所有记录类型（含非金额），作为"人情活跃度"展示，与 recordCount 一致。
    /// 月度柱状图等金额图表仅统计 monetary，两者设计意图不同。
    private func computeHeatmapGrid(from records: [Record]) {
        let calendar = Calendar.current
        let yearRecords = records.filter {
            calendar.component(.year, from: $0.date) == selectedYear
        }
        var grid = Array(repeating: Array(repeating: 0, count: 4), count: 12)
        for record in yearRecords {
            let month = calendar.component(.month, from: record.date) - 1
            let day = calendar.component(.day, from: record.date)
            let week = min((day - 1) / 7, 3)
            if month >= 0, month < 12 {
                grid[month][week] += 1
            }
        }
        heatmapGrid = grid
    }

    private func computeRecordTypeDistribution(from records: [Record]) {
        let calendar = Calendar.current
        let yearRecords = records.filter {
            calendar.component(.year, from: $0.date) == selectedYear
        }
        var typeCounts: [RecordType: Int] = [:]
        for record in yearRecords {
            typeCounts[record.recordType, default: 0] += 1
        }
        let total = typeCounts.values.reduce(0, +)
        recordTypeDistribution = typeCounts
            .map { (type: $0.key, count: $0.value, percentage: total > 0 ? Double($0.value) / Double(total) : 0) }
            .sorted { $0.count > $1.count }
    }

    private func computeYearOverYearChange(from records: [Record]) {
        let calendar = Calendar.current
        let currentTotal = records
            .filter {
                calendar.component(.year, from: $0.date) == selectedYear &&
                    $0.recordType == .monetary
            }
            .reduce(0.0) { $0 + $1.monetaryAmount }

        let previousYear = selectedYear - 1
        let previousTotal = records
            .filter {
                calendar.component(.year, from: $0.date) == previousYear &&
                    $0.recordType == .monetary
            }
            .reduce(0.0) { $0 + $1.monetaryAmount }

        guard previousTotal > 0 else {
            yearOverYearChangeRate = nil
            return
        }
        yearOverYearChangeRate = (currentTotal - previousTotal) / previousTotal
    }

    private func computeRelationshipHealthSummary() {
        let today = Date()
        var summary = RelationshipHealthSummary()
        let calendar = Calendar.current

        for item in allRankedContacts {
            guard let lastDate = item.lastRecordDate else { continue }
            let days = calendar.dateComponents([.day], from: lastDate, to: today).day ?? 0
            switch days {
            case ...90:
                summary.close += 1
            case 91 ... 180:
                summary.stable += 1
            case 181 ... 365:
                summary.distant += 1
            default:
                summary.needsAttention += 1
            }
        }
        relationshipHealthSummary = summary
    }

    // MARK: - Formatting helpers

    func formatAmount(_ amount: Double) -> String {
        if abs(amount) >= 10000 {
            return String(format: "%.1fW", amount / 10000)
        }
        return String(format: "%.0f", amount)
    }

    func formatAmountWithComma(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? String(format: "%.0f", amount)
    }

    func formatNetValue(_ value: Double) -> String {
        let prefix = value >= 0 ? "+" : ""
        return prefix + "¥" + formatAmountWithComma(value)
    }

    func formatPercentageValue(_ value: Double) -> String {
        String(format: "%.0f%%", value * 100)
    }

    func formatYearOverYearChange() -> String? {
        guard let yearOverYearChangeRate else { return nil }
        let sign = yearOverYearChangeRate >= 0 ? "+" : "-"
        return String(format: String(localized: "statistics.hero.yoy"), sign, abs(yearOverYearChangeRate) * 100)
    }

    func eventTypeIconName(for type: EventType) -> String {
        type.iconName
    }

    func eventTypeName(for type: EventType) -> String {
        type.displayName
    }
}
