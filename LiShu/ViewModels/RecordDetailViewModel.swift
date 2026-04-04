import Foundation
import SwiftData

@Observable
class RecordDetailViewModel {
    var record: Record?
    var isShowingReturnSheet: Bool = false
    var returnedAmountText: String = ""
    var isShowingDeleteAlert: Bool = false

    func load(id: PersistentIdentifier, context: ModelContext) {
        record = context.model(for: id) as? Record
    }

    var formattedAmount: String {
        guard let record else { return "¥0" }
        return "¥" + String(format: "%.0f", record.monetaryAmount)
    }

    var formattedReturnAmount: String {
        guard let record else { return "¥0" }
        return "¥" + String(format: "%.0f", record.resolvedReturnedAmount)
    }

    var formattedDate: String {
        guard let record else { return "" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: record.date)
    }

    var directionLabel: String {
        guard let record else { return "" }
        switch (record.recordType, record.direction) {
        case (.monetary, .given): return String(localized: "record.direction.monetary.given")
        case (.monetary, .received): return String(localized: "record.direction.monetary.received")
        case (.gift, .given): return String(localized: "record.direction.gift.given")
        case (.gift, .received): return String(localized: "record.direction.gift.received")
        case (.favor, .given): return String(localized: "record.direction.favor.given")
        case (.favor, .received): return String(localized: "record.direction.favor.received")
        case (.banquet, .given): return String(localized: "record.direction.banquet.given")
        case (.banquet, .received): return String(localized: "record.direction.banquet.received")
        }
    }

    var paymentMethodName: String {
        guard let record else { return "" }
        switch record.resolvedPaymentMethod {
        case .cash: return String(localized: "payment.cash")
        case .wechat: return String(localized: "payment.wechat")
        case .alipay: return String(localized: "payment.alipay")
        }
    }

    // MARK: - Contact History

    /// All records from the same contact, sorted by date descending
    var contactRecords: [Record] {
        guard let record, let contact = record.contact else { return [] }
        return (contact.records ?? []).sorted { $0.date > $1.date }
    }

    /// Number of records with this contact
    var contactRecordCount: Int {
        contactRecords.count
    }

    /// Net amount with this contact (received - given), monetary only
    var contactNetAmount: Double {
        contactRecords.filter { $0.recordType == .monetary }.reduce(0) { total, rec in
            rec.direction == .received ? total + rec.monetaryAmount : total - rec.monetaryAmount
        }
    }

    var shouldShowReturnButton: Bool {
        guard let record else { return false }
        return record.isMonetary
    }

    // MARK: - Actions

    func saveReturn(context: ModelContext) -> Bool {
        guard let record else { return false }
        guard let returnValue = Double(returnedAmountText), returnValue > 0 else { return false }

        guard var monetary = record.monetaryData else { return false }
        monetary.returnedAmount += returnValue
        record.applyTypeData(.monetary(monetary))

        do {
            try context.save()
            returnedAmountText = ""
            return true
        } catch {
            return false
        }
    }

    func deleteRecord(context: ModelContext) -> Bool {
        guard let record else { return false }
        context.delete(record)
        do {
            try context.save()
            return true
        } catch {
            return false
        }
    }
}
