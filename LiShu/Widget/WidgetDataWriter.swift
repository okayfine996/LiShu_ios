import Foundation
import SwiftData
import WidgetKit

// MARK: - WidgetDataWriter

enum WidgetDataWriter {
    static func write(records: [Record], events: [Event], contacts: [Contact], now: Date = .now) {
        let snapshot = buildSnapshot(records: records, events: events, contacts: contacts, now: now)
        WidgetSnapshotStore.write(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Snapshot

    private static let shortDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "M月d日"
        return f
    }()

    static func buildSnapshot(records: [Record], events: [Event], contacts: [Contact], now: Date = .now) -> WidgetSnapshot {
        let cal = Calendar.current
        let todayStart = cal.startOfDay(for: now)

        var items: [WidgetReminderItem] = []

        // Birthday reminders
        for contact in contacts where contact.birthdayReminderEnabled {
            guard let birthday = contact.birthday else { continue }
            let nextOccurrence: Date? = if contact.birthdayIsLunar {
                if let md = LunarCalendarHelper.lunarMonthDay(from: birthday) {
                    LunarCalendarHelper.nextGregorianDate(lunarMonth: md.month, lunarDay: md.day, after: todayStart)
                } else {
                    nil
                }
            } else {
                nextGregorianOccurrence(of: birthday, after: todayStart)
            }
            guard let date = nextOccurrence, date >= todayStart else { continue }
            let days = cal.dateComponents([.day], from: todayStart, to: cal.startOfDay(for: date)).day ?? 0
            items.append(WidgetReminderItem(
                id: stableID(for: contact.persistentModelID),
                title: contact.name,
                subtitle: String(localized: "widget.reminder.birthday"),
                dateLabel: dateLabel(daysFromNow: days),
                urgencyDaysFromNow: days,
                kind: .birthday,
                deepLinkURL: deepLink(host: "contact", id: stableID(for: contact.persistentModelID)),
                eventDateLabel: shortDateFormatter.string(from: date),
                eventDate: date
            ))
        }

        // Event and pending-return reminders
        // Guest events without any given record → pendingReturn (you still need to bring a gift)
        // All other upcoming events → event
        for event in events {
            let eventStart = cal.startOfDay(for: event.date)
            guard eventStart >= todayStart else { continue }
            let days = cal.dateComponents([.day], from: todayStart, to: eventStart).day ?? 0
            let hasGivenRecord = (event.records ?? []).contains { $0.direction == .given }
            let isPendingReturn = event.hostMode == .guest && !hasGivenRecord
            let title: String = if isPendingReturn, let contact = event.primaryContact {
                String(format: String(localized: "widget.pendingReturn.title"), contact.name)
            } else {
                event.name
            }
            let eid = stableID(for: event.persistentModelID)
            items.append(WidgetReminderItem(
                id: eid,
                title: title,
                subtitle: event.type.displayName,
                dateLabel: dateLabel(daysFromNow: days),
                urgencyDaysFromNow: days,
                kind: isPendingReturn ? .pendingReturn : .event,
                deepLinkURL: isPendingReturn
                    ? giveGiftDeepLink(eventStableID: eid)
                    : deepLink(host: "event", id: eid),
                eventDateLabel: shortDateFormatter.string(from: event.date),
                eventDate: event.date
            ))
        }

        // Sort: today (0) first, then tomorrow (1), day after (2), etc.; within same day birthday before event
        items.sort { a, b in
            if a.urgencyDaysFromNow != b.urgencyDaysFromNow {
                return a.urgencyDaysFromNow < b.urgencyDaysFromNow
            }
            return kindPriority(a.kind) < kindPriority(b.kind)
        }

        // Yearly income/expense from monetary records this calendar year
        let currentYear = cal.component(.year, from: now)
        var yearlyIncome: Double = 0
        var yearlyExpense: Double = 0
        for record in records where record.recordType == .monetary {
            let year = cal.component(.year, from: record.date)
            guard year == currentYear else { continue }
            if record.direction == .received {
                yearlyIncome += record.monetaryAmount
            } else {
                yearlyExpense += record.monetaryAmount
            }
        }

        // Next hosting event (host-mode, future, nearest)
        let nextHosting: WidgetHostingEventItem? = events
            .filter { $0.hostMode == .host && cal.startOfDay(for: $0.date) >= todayStart }
            .min(by: { $0.date < $1.date })
            .map { event in
                let days = cal.dateComponents([.day], from: todayStart, to: cal.startOfDay(for: event.date)).day ?? 0
                let dateStr = shortDateFormatter.string(from: event.date)
                let dateLine = event.location.isEmpty ? dateStr : "\(dateStr) · \(event.location)"
                let eventID = event.persistentModelID
                let eventRecords = records.filter {
                    $0.event?.persistentModelID == eventID &&
                        $0.recordType == .monetary &&
                        $0.direction == .received
                }
                let giftTotal = eventRecords.reduce(0.0) { $0 + $1.monetaryAmount }
                let guests = Set(eventRecords.compactMap { $0.contact?.persistentModelID }).count
                let sid = stableID(for: event.persistentModelID)
                return WidgetHostingEventItem(
                    name: event.name,
                    typeName: event.type.displayName,
                    daysUntil: days,
                    dateLine: dateLine,
                    deepLinkURL: deepLink(host: "event", id: sid),
                    giftReceivedTotal: giftTotal > 0 ? giftTotal : nil,
                    guestCount: guests > 0 ? guests : nil,
                    eventDate: event.date,
                    addRecordURL: addRecordDeepLink(eventStableID: sid)
                )
            }

        // Stats: yearly record count, unique contacts with records this year, pending return count
        let yearlyRecords = records.filter { cal.component(.year, from: $0.date) == currentYear }
        let yearlyRecordCount = yearlyRecords.count
        let yearlyContactCount = Set(yearlyRecords.compactMap { $0.contact?.persistentModelID }).count

        let pendingReturnCount = events.filter { event in
            guard event.hostMode == .guest else { return false }
            guard cal.component(.year, from: event.date) == currentYear else { return false }
            return !(event.records ?? []).contains { $0.direction == .given }
        }.count

        return WidgetSnapshot(
            generatedAt: now,
            reminders: items,
            reminderCount: items.count,
            yearlyIncome: yearlyIncome,
            yearlyExpense: yearlyExpense,
            currentYear: currentYear,
            nextHostingEvent: nextHosting,
            yearlyRecordCount: yearlyRecordCount,
            yearlyContactCount: yearlyContactCount,
            pendingReturnCount: pendingReturnCount
        )
    }

    // MARK: - Helpers

    private static func nextGregorianOccurrence(of birthday: Date, after start: Date) -> Date? {
        let cal = Calendar.current
        let comps = cal.dateComponents([.month, .day], from: birthday)
        guard let month = comps.month, let day = comps.day else { return nil }
        let year = cal.component(.year, from: start)
        var candidate = DateComponents(year: year, month: month, day: day)
        if let date = cal.date(from: candidate), date >= start { return date }
        candidate.year = year + 1
        return cal.date(from: candidate)
    }

    private static func dateLabel(daysFromNow: Int) -> String {
        switch daysFromNow {
        case 0: String(localized: "widget.reminder.today")
        case 1: String(localized: "widget.reminder.tomorrow")
        case let d where d > 1: String(format: String(localized: "widget.reminder.daysLater"), d)
        default: String(format: String(localized: "widget.reminder.daysOverdue"), abs(daysFromNow))
        }
    }

    private static func kindPriority(_ kind: ReminderKind) -> Int {
        switch kind {
        case .birthday: 0
        case .event: 1
        case .pendingReturn: 2
        }
    }

    static func stableID(for persistentID: PersistentIdentifier) -> String {
        // PersistentIdentifier is Codable; the JSON-encoded form is deterministic and
        // contains the underlying x-coredata:// URI, so it uniquely identifies the row
        // without depending on private Mirror layout (which has changed across iOS SDKs
        // and previously collapsed every entity to the same fallback hash).
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let stableInput: String = if let data = try? encoder.encode(persistentID),
                                     let str = String(data: data, encoding: .utf8)
        {
            str
        } else {
            persistentID.entityName + (persistentID.storeIdentifier ?? "")
        }
        var hash: UInt64 = 1_469_598_103_934_665_603
        for byte in stableInput.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }
        return String(hash, radix: 16)
    }

    private static func deepLink(host: String, id: String) -> URL {
        var comps = URLComponents()
        comps.scheme = "lishu"
        comps.host = host
        comps.queryItems = [URLQueryItem(name: "id", value: id)]
        return comps.url ?? URL(fileURLWithPath: "/")
    }

    private static func addRecordDeepLink(eventStableID: String) -> URL {
        var comps = URLComponents()
        comps.scheme = "lishu"
        comps.host = "add-record"
        comps.queryItems = [URLQueryItem(name: "event", value: eventStableID)]
        return comps.url ?? URL(fileURLWithPath: "/")
    }

    private static func giveGiftDeepLink(eventStableID: String) -> URL {
        var comps = URLComponents()
        comps.scheme = "lishu"
        comps.host = "add-record"
        comps.queryItems = [
            URLQueryItem(name: "event", value: eventStableID),
            URLQueryItem(name: "direction", value: "given"),
        ]
        return comps.url ?? URL(fileURLWithPath: "/")
    }
}
