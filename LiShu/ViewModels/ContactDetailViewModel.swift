import Foundation
import SwiftData

struct TypeCountItem: Identifiable {
    let type: RecordType
    let count: Int
    var id: String {
        type.rawValue
    }
}

@Observable
class ContactDetailViewModel {
    var contact: Contact?
    var isLoading: Bool = true
    var isShowingDeleteAlert: Bool = false

    /// Sorted records for the contact, newest first
    var sortedRecords: [Record] {
        guard let contact else { return [] }
        return (contact.records ?? []).sorted { $0.date > $1.date }
    }

    /// Past year interaction count
    var pastYearInteractionCount: Int {
        guard let contact else { return 0 }
        let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: .now) ?? .now
        return (contact.records ?? []).filter { $0.date >= oneYearAgo }.count
    }

    /// Breakdown of record counts by type (non-zero only)
    var typeCounts: [TypeCountItem] {
        guard let contact else { return [] }
        let records = contact.records ?? []
        var counts: [RecordType: Int] = [:]
        for record in records {
            counts[record.recordType, default: 0] += 1
        }
        return counts.map { TypeCountItem(type: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    /// Format date for timeline display (e.g. "2025.02")
    func timelineDateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM"
        return formatter.string(from: date)
    }

    /// Load the contact by its persistent identifier
    func load(id: PersistentIdentifier, context: ModelContext) {
        isLoading = true
        contact = context.model(for: id) as? Contact
        isLoading = false
    }

    /// Reload the contact data (e.g. after adding a record or editing)
    func reload(context: ModelContext) {
        guard let contact else { return }
        self.contact = context.model(for: contact.persistentModelID) as? Contact
    }

    /// Delete the current contact. Returns true if successful.
    func deleteContact(context: ModelContext) -> Bool {
        guard let contact else { return false }
        NotificationManager.shared.cancelBirthdayReminder(contact: contact)
        context.delete(contact)
        do {
            try context.save()
            return true
        } catch {
            return false
        }
    }

    // MARK: - Card 2: Relationship Insight

    /// 年度互动活跃度：过去一年有记录的月份数 / 12
    var yearlyActivityRate: Double {
        guard let contact else { return 0 }
        let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: .now) ?? .now
        let recentRecords = (contact.records ?? []).filter { $0.date >= oneYearAgo }
        let cal = Calendar.current
        let months = Set(recentRecords.map { cal.component(.month, from: $0.date) * 100 + cal.component(.year, from: $0.date) })
        return min(Double(months.count) / 12.0, 1.0)
    }

    /// 互惠平衡指数：给出/收到的比例接近 1:1 越好
    enum BalanceLevel: String {
        case excellent, good, fair, poor
    }

    var balanceLevel: BalanceLevel {
        guard let contact else { return .fair }
        let records = contact.records ?? []
        let givenCount = records.filter { $0.direction == .given }.count
        let receivedCount = records.filter { $0.direction == .received }.count
        let total = givenCount + receivedCount
        guard total > 0 else { return .fair }
        let ratio = Double(min(givenCount, receivedCount)) / Double(max(givenCount, receivedCount))
        if ratio >= 0.7 { return .excellent }
        if ratio >= 0.4 { return .good }
        if ratio >= 0.2 { return .fair }
        return .poor
    }

    func balanceLevelText(_ level: BalanceLevel) -> String {
        switch level {
        case .excellent: return String(localized: "contact.detail.balance.excellent")
        case .good: return String(localized: "contact.detail.balance.good")
        case .fair: return String(localized: "contact.detail.balance.fair")
        case .poor: return String(localized: "contact.detail.balance.poor")
        }
    }

    func balanceDescription(_ level: BalanceLevel) -> String {
        switch level {
        case .excellent: return String(localized: "contact.detail.balance.excellent.desc")
        case .good: return String(localized: "contact.detail.balance.good.desc")
        case .fair: return String(localized: "contact.detail.balance.fair.desc")
        case .poor: return String(localized: "contact.detail.balance.poor.desc")
        }
    }

    func circleLabel(_ level: Int) -> String {
        let name = circleText(level)
        return String(localized: "contact.detail.circlePrefix") + " \(level) " + String(localized: "contact.detail.circleSuffix") + " · " +
            name
    }

    // MARK: - Formatted Values

    func formatAmount(_ amount: Double) -> String {
        "¥" + String(format: "%.0f", amount)
    }

    func formatNetValue(_ value: Double) -> String {
        let prefix = value >= 0 ? "+" : ""
        return prefix + "¥" + String(format: "%.0f", value)
    }

    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy'年'M'月'd'日'"
        return formatter.string(from: date)
    }

    func circleText(_ level: Int) -> String {
        switch level {
        case 1: return String(localized: "contact.filter.family")
        case 2: return String(localized: "contact.filter.relative")
        case 3: return String(localized: "contact.filter.social")
        default: return String(localized: "contact.filter.other")
        }
    }
}
