import Foundation
import SwiftData

@Observable
class EventDetailViewModel {
    var event: Event?
    var isShowingDeleteAlert: Bool = false
    var deleteError: String?
    private let legacyLedgerPreviewLimit = 2

    func load(id: PersistentIdentifier, context: ModelContext) {
        event = context.model(for: id) as? Event
    }

    var totalGiven: Double {
        guard let event else { return 0 }
        return (event.records ?? [])
            .filter { $0.direction == .given }
            .reduce(0.0) { $0 + $1.resolvedDisplayAmount }
    }

    var totalReceived: Double {
        receivedRecords
            .reduce(0.0) { $0 + $1.resolvedDisplayAmount }
    }

    /// 普通事件默认是”我去参加别人的场合”，因此详情里只突出最新的一条主记录摘要。
    var primaryRecord: Record? {
        guard let event else { return nil }
        return (event.records ?? [])
            .sorted { $0.date > $1.date }
            .first
    }

    /// 普通事件详情的所有送礼记录，按时间倒序。
    var allRecords: [Record] {
        guard let event else { return [] }
        return (event.records ?? []).sorted { $0.date > $1.date }
    }

    /// 礼簿详情只展示收礼记录，避免和普通送礼记录混在同一列表里。
    var receivedRecords: [Record] {
        guard let event else { return [] }
        return (event.records ?? [])
            .filter { $0.direction == .received && $0.recordType == .monetary }
            .sorted { $0.date > $1.date }
    }

    var receivedRecordCount: Int {
        receivedRecords.count
    }

    var legacyNonLedgerRecords: [Record] {
        guard let event else { return [] }
        let eventID = event.persistentModelID
        return (event.records ?? [])
            .filter { Self.isLegacyLedgerAnomaly($0, for: eventID) }
            .sorted { $0.date > $1.date }
    }

    var hasLegacyLedgerAnomalies: Bool {
        !legacyNonLedgerRecords.isEmpty
    }

    var legacyLedgerAnomalyCount: Int {
        legacyNonLedgerRecords.count
    }

    var legacyLedgerAnomalyPreviewText: String {
        let labels = legacyNonLedgerRecords
            .prefix(legacyLedgerPreviewLimit)
            .map(legacyLedgerRecordLabel)

        guard !labels.isEmpty else { return "" }

        if legacyNonLedgerRecords.count > legacyLedgerPreviewLimit {
            return labels.joined(separator: "、") + String(
                format: String(localized: "event.ledger.legacyWarning.more %lld"),
                Int64(legacyNonLedgerRecords.count - legacyLedgerPreviewLimit)
            )
        }

        return labels.joined(separator: "、")
    }

    var largestReceivedAmount: Double {
        receivedRecords.map(\.resolvedDisplayAmount).max() ?? 0
    }

    var todayReceivedAmount: Double {
        let calendar = Calendar.current
        return receivedRecords
            .filter { calendar.isDateInToday($0.date) }
            .reduce(0.0) { $0 + $1.resolvedDisplayAmount }
    }

    var todayReceivedCount: Int {
        let calendar = Calendar.current
        return receivedRecords.filter { calendar.isDateInToday($0.date) }.count
    }

    var formattedDate: String {
        guard let event else { return "" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: event.date)
    }

    var daysUntilEvent: Int? {
        guard let event else { return nil }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let eventDay = calendar.startOfDay(for: event.date)
        return calendar.dateComponents([.day], from: today, to: eventDay).day
    }

    var isUpcoming: Bool {
        guard let event else { return false }
        return event.date >= Calendar.current.startOfDay(for: Date())
    }

    @MainActor
    func deleteEvent(context: ModelContext) -> Bool {
        guard let event else { return false }
        context.delete(event)
        do {
            try context.save()
            NotificationManager.shared.cancelRemindersForEventDeletion(event: event)
            return true
        } catch {
            deleteError = error.localizedDescription
            return false
        }
    }

    @MainActor
    func deleteRecord(_ record: Record, context: ModelContext) -> Bool {
        guard let event else { return false }
        let eventID = event.persistentModelID

        context.delete(record)
        do {
            try context.save()
            load(id: eventID, context: context)
            return true
        } catch {
            return false
        }
    }

    static func isLegacyLedgerAnomaly(_ record: Record, for eventID: PersistentIdentifier) -> Bool {
        guard record.event?.persistentModelID == eventID else { return false }
        return !(record.direction == .received && record.recordType == .monetary)
    }

    private func legacyLedgerRecordLabel(_ record: Record) -> String {
        let contactName = record.contact?.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let typeLabel: String

        switch record.recordType {
        case .monetary:
            typeLabel = record.direction == .given
                ? String(localized: "record.detail.directionSent") + record.recordType.displayName
                : String(localized: "record.detail.directionReceived") + record.recordType.displayName
        default:
            let description = record.resolvedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
            typeLabel = description.isEmpty ? record.recordType.displayName : description
        }

        if let contactName, !contactName.isEmpty {
            return contactName + " · " + typeLabel
        }

        return typeLabel
    }
}
