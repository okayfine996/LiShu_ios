import Foundation
import SwiftData

@Observable
class EventDetailViewModel {
    var event: Event?
    var isShowingDeleteAlert: Bool = false
    var isShowingDeleteBlockedAlert: Bool = false

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
        guard let event else { return 0 }
        return (event.records ?? [])
            .filter { $0.direction == .received }
            .reduce(0.0) { $0 + $1.resolvedDisplayAmount }
    }

    var primaryRecord: Record? {
        guard let event else { return nil }
        return (event.records ?? [])
            .sorted { $0.date > $1.date }
            .first
    }

    var receivedRecords: [Record] {
        guard let event else { return [] }
        return (event.records ?? [])
            .filter { $0.direction == .received }
            .sorted { $0.date > $1.date }
    }

    var receivedRecordCount: Int {
        receivedRecords.count
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
        guard (event.records ?? []).isEmpty else { return false }
        NotificationManager.shared.cancelEventReminder(event: event)
        context.delete(event)
        do {
            try context.save()
            return true
        } catch {
            return false
        }
    }
}
