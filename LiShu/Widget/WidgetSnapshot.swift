import Foundation

// MARK: - WidgetSnapshot

struct WidgetSnapshot: Codable {
    var generatedAt: Date
    var reminders: [WidgetReminderItem]
    var reminderCount: Int
    var yearlyIncome: Double
    var yearlyExpense: Double
    var currentYear: Int
    var nextHostingEvent: WidgetHostingEventItem?
    var yearlyRecordCount: Int
    var yearlyContactCount: Int
    var pendingReturnCount: Int

    /// Custom decoder so pendingReturnCount defaults to 0 when missing from old snapshots.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        generatedAt = try c.decode(Date.self, forKey: .generatedAt)
        reminders = try c.decode([WidgetReminderItem].self, forKey: .reminders)
        reminderCount = try c.decode(Int.self, forKey: .reminderCount)
        yearlyIncome = try c.decode(Double.self, forKey: .yearlyIncome)
        yearlyExpense = try c.decode(Double.self, forKey: .yearlyExpense)
        currentYear = try c.decode(Int.self, forKey: .currentYear)
        nextHostingEvent = try c.decodeIfPresent(WidgetHostingEventItem.self, forKey: .nextHostingEvent)
        yearlyRecordCount = try c.decode(Int.self, forKey: .yearlyRecordCount)
        yearlyContactCount = try c.decode(Int.self, forKey: .yearlyContactCount)
        pendingReturnCount = try c.decodeIfPresent(Int.self, forKey: .pendingReturnCount) ?? 0
    }

    init(
        generatedAt: Date, reminders: [WidgetReminderItem], reminderCount: Int,
        yearlyIncome: Double, yearlyExpense: Double, currentYear: Int,
        nextHostingEvent: WidgetHostingEventItem?,
        yearlyRecordCount: Int, yearlyContactCount: Int, pendingReturnCount: Int = 0
    ) {
        self.generatedAt = generatedAt
        self.reminders = reminders
        self.reminderCount = reminderCount
        self.yearlyIncome = yearlyIncome
        self.yearlyExpense = yearlyExpense
        self.currentYear = currentYear
        self.nextHostingEvent = nextHostingEvent
        self.yearlyRecordCount = yearlyRecordCount
        self.yearlyContactCount = yearlyContactCount
        self.pendingReturnCount = pendingReturnCount
    }

    static let empty = WidgetSnapshot(
        generatedAt: .distantPast,
        reminders: [],
        reminderCount: 0,
        yearlyIncome: 0,
        yearlyExpense: 0,
        currentYear: Calendar.current.component(.year, from: .now),
        nextHostingEvent: nil,
        yearlyRecordCount: 0,
        yearlyContactCount: 0
    )
}

// MARK: - WidgetReminderItem

struct WidgetReminderItem: Codable, Identifiable {
    var id: String
    var title: String
    var subtitle: String
    var dateLabel: String
    var urgencyDaysFromNow: Int
    var kind: ReminderKind
    var deepLinkURL: URL
    var eventDateLabel: String?
    var eventDate: Date?

    init(
        id: String, title: String, subtitle: String,
        dateLabel: String, urgencyDaysFromNow: Int,
        kind: ReminderKind, deepLinkURL: URL,
        eventDateLabel: String? = nil, eventDate: Date? = nil
    ) {
        self.id = id; self.title = title; self.subtitle = subtitle
        self.dateLabel = dateLabel; self.urgencyDaysFromNow = urgencyDaysFromNow
        self.kind = kind; self.deepLinkURL = deepLinkURL
        self.eventDateLabel = eventDateLabel; self.eventDate = eventDate
    }
}

enum ReminderKind: String, Codable {
    case birthday
    case event
    case pendingReturn

    fileprivate var sortPriority: Int {
        switch self { case .birthday: 0; case .event: 1; case .pendingReturn: 2 }
    }
}

// MARK: - WidgetHostingEventItem

struct WidgetHostingEventItem: Codable {
    var name: String
    var typeName: String
    var daysUntil: Int
    var dateLine: String
    var deepLinkURL: URL
    var giftReceivedTotal: Double?
    var guestCount: Int?
    var eventDate: Date?
    var addRecordURL: URL?

    init(
        name: String, typeName: String, daysUntil: Int,
        dateLine: String, deepLinkURL: URL,
        giftReceivedTotal: Double? = nil, guestCount: Int? = nil,
        eventDate: Date? = nil, addRecordURL: URL? = nil
    ) {
        self.name = name; self.typeName = typeName; self.daysUntil = daysUntil
        self.dateLine = dateLine; self.deepLinkURL = deepLinkURL
        self.giftReceivedTotal = giftReceivedTotal; self.guestCount = guestCount
        self.eventDate = eventDate; self.addRecordURL = addRecordURL
    }
}

// MARK: - WidgetSnapshot refresh

extension WidgetSnapshot {
    /// Recomputes date labels and filters past/out-of-window items using `now`.
    /// Called in `getTimeline()` so labels stay accurate even when the app hasn't been opened.
    func refreshed(at now: Date) -> WidgetSnapshot {
        let cal = Calendar.current
        let todayStart = cal.startOfDay(for: now)
        let windowEnd = cal.date(byAdding: .day, value: 3, to: todayStart) ?? now

        let updated: [WidgetReminderItem] = reminders
            .compactMap { item -> WidgetReminderItem? in
                guard let itemDate = item.eventDate else { return item }
                let itemStart = cal.startOfDay(for: itemDate)
                guard itemStart >= todayStart, itemStart <= windowEnd else { return nil }
                let days = cal.dateComponents([.day], from: todayStart, to: itemStart).day ?? 0
                return WidgetReminderItem(
                    id: item.id, title: item.title, subtitle: item.subtitle,
                    dateLabel: WidgetSnapshot.dateLabel(daysFromNow: days),
                    urgencyDaysFromNow: days,
                    kind: item.kind, deepLinkURL: item.deepLinkURL,
                    eventDateLabel: item.eventDateLabel, eventDate: item.eventDate
                )
            }
            .sorted {
                if $0.urgencyDaysFromNow != $1.urgencyDaysFromNow {
                    return $0.urgencyDaysFromNow < $1.urgencyDaysFromNow
                }
                return $0.kind.sortPriority < $1.kind.sortPriority
            }

        let updatedHosting: WidgetHostingEventItem? = nextHostingEvent.flatMap { event in
            guard let eventDate = event.eventDate else { return event }
            let eventStart = cal.startOfDay(for: eventDate)
            guard eventStart >= todayStart else { return nil }
            let days = cal.dateComponents([.day], from: todayStart, to: eventStart).day ?? 0
            return WidgetHostingEventItem(
                name: event.name, typeName: event.typeName,
                daysUntil: days, dateLine: event.dateLine,
                deepLinkURL: event.deepLinkURL,
                giftReceivedTotal: event.giftReceivedTotal,
                guestCount: event.guestCount, eventDate: event.eventDate,
                addRecordURL: event.addRecordURL
            )
        }

        return WidgetSnapshot(
            generatedAt: now,
            reminders: updated,
            reminderCount: updated.count,
            yearlyIncome: yearlyIncome,
            yearlyExpense: yearlyExpense,
            currentYear: currentYear,
            nextHostingEvent: updatedHosting,
            yearlyRecordCount: yearlyRecordCount,
            yearlyContactCount: yearlyContactCount,
            pendingReturnCount: pendingReturnCount
        )
    }

    static func dateLabel(daysFromNow: Int) -> String {
        switch daysFromNow {
        case 0: String(localized: "widget.reminder.today")
        case 1: String(localized: "widget.reminder.tomorrow")
        case let d where d > 1: String(format: String(localized: "widget.reminder.daysLater"), d)
        default: String(format: String(localized: "widget.reminder.daysOverdue"), abs(daysFromNow))
        }
    }
}

// MARK: - WidgetSnapshotStore

enum WidgetSnapshotStore {
    static let appGroupID = "group.com.finefine.LiShu"
    static let snapshotKey = "widget.snapshot.v2"

    static func write(_ snapshot: WidgetSnapshot) {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = try? JSONEncoder().encode(snapshot)
        else { return }
        defaults.set(data, forKey: snapshotKey)
    }

    static func read() -> WidgetSnapshot {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: snapshotKey),
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
        else { return .empty }
        return snapshot
    }
}
