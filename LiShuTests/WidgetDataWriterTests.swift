import Foundation
@testable import LiShu
import SwiftData
import Testing

// MARK: - WidgetDataWriterTests

@Suite(.serialized)
struct WidgetDataWriterTests {
    /// Jan 1 2026 00:00 UTC+8 reference
    private static let jan1: Date = {
        var comps = DateComponents()
        comps.year = 2026; comps.month = 1; comps.day = 1
        comps.hour = 9; comps.minute = 0
        return Calendar.current.date(from: comps)!
    }()

    private func makeContact(
        name: String = "张三",
        birthday: Date? = nil,
        birthdayIsLunar: Bool = false,
        birthdayReminderEnabled: Bool = false
    ) -> Contact {
        let c = Contact(name: name)
        c.birthday = birthday
        c.birthdayIsLunar = birthdayIsLunar
        c.birthdayReminderEnabled = birthdayReminderEnabled
        return c
    }

    private func makeEvent(
        name: String = "婚礼",
        type: EventType = .wedding,
        hostMode: EventHostMode = .host,
        daysFromNow: Int,
        now: Date = WidgetDataWriterTests.jan1
    ) -> Event {
        let date = Calendar.current.date(byAdding: .day, value: daysFromNow, to: now)!
        return Event(name: name, type: type, hostMode: hostMode, date: date)
    }

    /// 1. Empty arrays → empty snapshot
    @Test func emptyInputsProduceEmptySnapshot() {
        let snapshot = WidgetDataWriter.buildSnapshot(records: [], events: [], contacts: [], now: Self.jan1)
        #expect(snapshot.reminders.isEmpty)
        #expect(snapshot.reminderCount == 0)
    }

    /// 2. Birthday today, reminder enabled → 1 birthday item
    @Test func birthdayTodayIncluded() throws {
        let now = Self.jan1
        // Birthday on Jan 1 (gregorian)
        var comps = DateComponents(); comps.year = 1990; comps.month = 1; comps.day = 1
        let bday = try #require(Calendar.current.date(from: comps))
        let contact = makeContact(name: "李四", birthday: bday, birthdayReminderEnabled: true)
        let snapshot = WidgetDataWriter.buildSnapshot(records: [], events: [], contacts: [contact], now: now)
        #expect(snapshot.reminders.count == 1)
        #expect(snapshot.reminders[0].kind == .birthday)
        #expect(snapshot.reminders[0].urgencyDaysFromNow == 0)
    }

    /// 2b. Lunar birthday today is included in the 3-day window
    @Test func lunarBirthdayTodayIncluded() throws {
        let now = Self.jan1
        let contact = makeContact(
            name: "农历今天",
            birthday: now,
            birthdayIsLunar: true,
            birthdayReminderEnabled: true
        )
        let snapshot = WidgetDataWriter.buildSnapshot(records: [], events: [], contacts: [contact], now: now)
        let item = try #require(snapshot.reminders.first)
        #expect(item.kind == .birthday)
        #expect(item.urgencyDaysFromNow == 0)
    }

    /// 3. Birthday today, reminder disabled → 0 items
    @Test func birthdayDisabledExcluded() throws {
        let now = Self.jan1
        var comps = DateComponents(); comps.year = 1990; comps.month = 1; comps.day = 1
        let bday = try #require(Calendar.current.date(from: comps))
        let contact = makeContact(birthday: bday, birthdayReminderEnabled: false)
        let snapshot = WidgetDataWriter.buildSnapshot(records: [], events: [], contacts: [contact], now: now)
        #expect(snapshot.reminders.isEmpty)
    }

    /// 4. Event 2 days out → included
    @Test func eventTwoDaysOutIncluded() {
        let event = makeEvent(daysFromNow: 2)
        let snapshot = WidgetDataWriter.buildSnapshot(records: [], events: [event], contacts: [], now: Self.jan1)
        #expect(snapshot.reminders.count == 1)
        #expect(snapshot.reminders[0].kind == .event)
        #expect(snapshot.reminders[0].urgencyDaysFromNow == 2)
    }

    /// 5. Event exactly 3 days out → included (windowEnd is inclusive)
    @Test func eventThreeDaysOutIncluded() {
        let event = makeEvent(daysFromNow: 3)
        let snapshot = WidgetDataWriter.buildSnapshot(records: [], events: [event], contacts: [], now: Self.jan1)
        #expect(snapshot.reminders.count == 1)
        #expect(snapshot.reminders[0].urgencyDaysFromNow == 3)
    }

    /// 5b. Event 4 days out is stored, then appears when refreshed into the 3-day window
    @Test func eventFourDaysOutStoredForFutureRefresh() throws {
        let event = makeEvent(daysFromNow: 4)
        let snapshot = WidgetDataWriter.buildSnapshot(records: [], events: [event], contacts: [], now: Self.jan1)
        #expect(snapshot.reminders.count == 1)
        #expect(snapshot.reminders[0].urgencyDaysFromNow == 4)
        #expect(snapshot.refreshed(at: Self.jan1).reminders.isEmpty)
        let tomorrow = try #require(Calendar.current.date(byAdding: .day, value: 1, to: Self.jan1))
        let refreshed = snapshot.refreshed(at: tomorrow)
        #expect(refreshed.reminders.count == 1)
        #expect(refreshed.reminders[0].urgencyDaysFromNow == 3)
    }

    /// 5c. Event 5 days out stays hidden until a later refresh brings it into range
    @Test func eventFiveDaysOutStoredForLaterRefresh() throws {
        let event = makeEvent(daysFromNow: 5)
        let snapshot = WidgetDataWriter.buildSnapshot(records: [], events: [event], contacts: [], now: Self.jan1)
        #expect(snapshot.reminders.count == 1)
        #expect(snapshot.refreshed(at: Self.jan1).reminders.isEmpty)
        let twoDaysLater = try #require(Calendar.current.date(byAdding: .day, value: 2, to: Self.jan1))
        let refreshed = snapshot.refreshed(at: twoDaysLater)
        #expect(refreshed.reminders.count == 1)
        #expect(refreshed.reminders[0].urgencyDaysFromNow == 3)
    }

    /// 6. Past event is excluded — widget only shows future reminders
    @Test func pastEventExcluded() {
        let event = makeEvent(name: "春节", daysFromNow: -10)
        let snapshot = WidgetDataWriter.buildSnapshot(records: [], events: [event], contacts: [], now: Self.jan1)
        #expect(snapshot.reminders.isEmpty)
    }

    /// 7. 10 qualifying items → all stored (no cap), reminderCount == stored count
    @Test func allRemindersStoredUnderNewPolicy() {
        var events: [Event] = []
        for i in 0..<10 {
            events.append(makeEvent(name: "事件\(i)", daysFromNow: i % 4))
        }
        let snapshot = WidgetDataWriter.buildSnapshot(records: [], events: events, contacts: [], now: Self.jan1)
        #expect(snapshot.reminders.count == snapshot.reminderCount)
        #expect(snapshot.reminders.count == 10)
    }

    /// 8. Sort: today before tomorrow before future (past events excluded)
    @Test func sortOrder() {
        let past = makeEvent(name: "过去", type: .other, daysFromNow: -3)
        let today = makeEvent(name: "今天", type: .birthday, daysFromNow: 0)
        let tomorrow = makeEvent(name: "明天", type: .wedding, daysFromNow: 1)
        let future = makeEvent(name: "后天", type: .funeral, daysFromNow: 2)
        let snapshot = WidgetDataWriter.buildSnapshot(
            records: [], events: [tomorrow, future, today, past], contacts: [], now: Self.jan1
        )
        #expect(snapshot.reminders.count == 3)
        #expect(snapshot.reminders[0].title == "今天")
        #expect(snapshot.reminders[1].title == "明天")
        #expect(snapshot.reminders[2].title == "后天")
    }

    /// 9. Deep link URL scheme is "lishu"
    @Test func deepLinkScheme() {
        let event = makeEvent(daysFromNow: 1)
        let snapshot = WidgetDataWriter.buildSnapshot(records: [], events: [event], contacts: [], now: Self.jan1)
        #expect(snapshot.reminders.first?.deepLinkURL.scheme == "lishu")
    }

    /// 10. Past host-mode event is excluded (past events are not shown)
    @Test func hostModeEventExcludedFromPendingReturn() {
        let event = makeEvent(name: "主场礼簿", type: .wedding, hostMode: .host, daysFromNow: -3)
        let snapshot = WidgetDataWriter.buildSnapshot(records: [], events: [event], contacts: [], now: Self.jan1)
        #expect(snapshot.reminders.isEmpty)
    }

    /// 11. Guest event with an existing given record is excluded from pending return
    @MainActor
    @Test func guestEventWithGivenRecordExcluded() throws {
        let db = try TestDB()
        let contact = SampleData.contact(name: "回礼测试")
        let eventDate = try #require(Calendar.current.date(byAdding: .day, value: -10, to: Self.jan1))
        let event = SampleData.event(name: "已回礼事件", hostMode: .guest, date: eventDate)
        db.context.insert(contact)
        db.context.insert(event)
        let record = SampleData.record(contact: contact, event: event, amount: 300, direction: .given)
        db.context.insert(record)
        try db.context.save()

        let records = try db.context.fetch(FetchDescriptor<Record>())
        let events = try db.context.fetch(FetchDescriptor<Event>())
        let snapshot = WidgetDataWriter.buildSnapshot(records: records, events: events, contacts: [], now: Self.jan1)
        #expect(snapshot.reminders.filter { $0.kind == .pendingReturn }.isEmpty)
    }

    /// 12. Yearly income accumulates monetary received records in current year
    @MainActor
    @Test func yearlyIncomeCalculated() throws {
        let db = try TestDB()
        let contact = SampleData.contact(name: "收入测试")
        db.context.insert(contact)
        let r1 = SampleData.record(contact: contact, amount: 600, direction: .received, date: Self.jan1)
        let r2 = SampleData.record(contact: contact, amount: 400, direction: .received, date: Self.jan1)
        db.context.insert(r1); db.context.insert(r2)
        try db.context.save()

        let records = try db.context.fetch(FetchDescriptor<Record>())
        let snapshot = WidgetDataWriter.buildSnapshot(records: records, events: [], contacts: [], now: Self.jan1)
        #expect(abs(snapshot.yearlyIncome - 1000) < 0.01)
        #expect(snapshot.yearlyExpense == 0)
    }

    /// 13. Yearly expense accumulates monetary given records in current year
    @MainActor
    @Test func yearlyExpenseCalculated() throws {
        let db = try TestDB()
        let contact = SampleData.contact(name: "支出测试")
        db.context.insert(contact)
        let r = SampleData.record(contact: contact, amount: 888, direction: .given, date: Self.jan1)
        db.context.insert(r)
        try db.context.save()

        let records = try db.context.fetch(FetchDescriptor<Record>())
        let snapshot = WidgetDataWriter.buildSnapshot(records: records, events: [], contacts: [], now: Self.jan1)
        #expect(abs(snapshot.yearlyExpense - 888) < 0.01)
        #expect(snapshot.yearlyIncome == 0)
    }

    /// 14. dateLabel for today is "今天"
    @Test func dateLabelToday() {
        let event = makeEvent(name: "今天事件", daysFromNow: 0)
        let snapshot = WidgetDataWriter.buildSnapshot(records: [], events: [event], contacts: [], now: Self.jan1)
        #expect(snapshot.reminders.first?.dateLabel == "今天")
    }

    /// 15. dateLabel for tomorrow is "明天"
    @Test func dateLabelTomorrow() {
        let event = makeEvent(name: "明天事件", daysFromNow: 1)
        let snapshot = WidgetDataWriter.buildSnapshot(records: [], events: [event], contacts: [], now: Self.jan1)
        #expect(snapshot.reminders.first?.dateLabel == "明天")
    }

    /// 16. Past events are excluded — no reminders produced for overdue events
    @Test func dateLabelOverdue() {
        let event = makeEvent(name: "逾期事件", daysFromNow: -5)
        let snapshot = WidgetDataWriter.buildSnapshot(records: [], events: [event], contacts: [], now: Self.jan1)
        #expect(snapshot.reminders.isEmpty)
    }

    /// 17. Upcoming guest event with no given record → pendingReturn item
    @MainActor
    @Test func pendingReturnGeneratedForGuestEventWithNoGivenRecord() throws {
        let db = try TestDB()
        let contact = SampleData.contact(name: "林悦")
        let event = Event(name: "林悦婚礼", type: .wedding, hostMode: .guest,
                          date: Self.jan1, primaryContact: contact)
        db.context.insert(contact)
        db.context.insert(event)
        try db.context.save()

        let events = try db.context.fetch(FetchDescriptor<Event>())
        let snapshot = WidgetDataWriter.buildSnapshot(records: [], events: events, contacts: [], now: Self.jan1)
        let item = try #require(snapshot.reminders.first { $0.kind == .pendingReturn })
        #expect(item.urgencyDaysFromNow == 0)
    }

    /// 18. Guest event with a given record → event kind, not pendingReturn
    @MainActor
    @Test func guestEventWithGivenRecordIsEventNotPendingReturn() throws {
        let db = try TestDB()
        let contact = SampleData.contact(name: "林悦")
        let event = Event(name: "林悦婚礼", type: .wedding, hostMode: .guest,
                          date: Self.jan1, primaryContact: contact)
        db.context.insert(contact)
        db.context.insert(event)
        let record = SampleData.record(contact: contact, event: event, direction: .given)
        db.context.insert(record)
        try db.context.save()

        let events = try db.context.fetch(FetchDescriptor<Event>())
        let records = try db.context.fetch(FetchDescriptor<Record>())
        let snapshot = WidgetDataWriter.buildSnapshot(records: records, events: events, contacts: [], now: Self.jan1)
        let item = try #require(snapshot.reminders.first)
        #expect(item.kind == .event)
        #expect(snapshot.reminders.filter { $0.kind == .pendingReturn }.isEmpty)
    }

    /// 19. Sort within same day: birthday (0) before event (1) before pendingReturn (2)
    @MainActor
    @Test func kindPrioritySort() throws {
        let db = try TestDB()
        let now = Self.jan1
        var bdayComps = DateComponents(); bdayComps.year = 1990; bdayComps.month = 1; bdayComps.day = 1
        let bday = try #require(Calendar.current.date(from: bdayComps))
        let contact = makeContact(name: "张三", birthday: bday, birthdayReminderEnabled: true)
        let hostEvent = Event(name: "我的婚礼", type: .wedding, hostMode: .host, date: now)
        let guestEvent = Event(name: "朋友婚礼", type: .wedding, hostMode: .guest, date: now)
        db.context.insert(guestEvent)
        try db.context.save()
        let events = try db.context.fetch(FetchDescriptor<Event>())

        let snapshot = WidgetDataWriter.buildSnapshot(
            records: [], events: events + [hostEvent], contacts: [contact], now: now
        )
        #expect(snapshot.reminders.count == 3)
        #expect(snapshot.reminders[0].kind == .birthday)
        #expect(snapshot.reminders[1].kind == .event)
        #expect(snapshot.reminders[2].kind == .pendingReturn)
    }

    /// 20. yearlyRecordCount counts all records in current year
    @MainActor
    @Test func yearlyRecordCountCalculated() throws {
        let db = try TestDB()
        let contact = SampleData.contact(name: "测试")
        db.context.insert(contact)
        let r1 = SampleData.record(contact: contact, amount: 100, date: Self.jan1)
        let r2 = SampleData.record(contact: contact, amount: 200, date: Self.jan1)
        db.context.insert(r1); db.context.insert(r2)
        try db.context.save()
        let records = try db.context.fetch(FetchDescriptor<Record>())
        let snapshot = WidgetDataWriter.buildSnapshot(records: records, events: [], contacts: [], now: Self.jan1)
        #expect(snapshot.yearlyRecordCount == 2)
    }

    /// 21. yearlyContactCount counts unique contacts with records this year (not total contacts)
    @MainActor
    @Test func yearlyContactCountFromRecords() throws {
        let db = try TestDB()
        let c1 = SampleData.contact(name: "互动人A")
        let c2 = SampleData.contact(name: "互动人B")
        let c3 = SampleData.contact(name: "无互动C")
        db.context.insert(c1); db.context.insert(c2); db.context.insert(c3)
        let r1 = SampleData.record(contact: c1, date: Self.jan1)
        let r2 = SampleData.record(contact: c1, date: Self.jan1)
        let r3 = SampleData.record(contact: c2, date: Self.jan1)
        db.context.insert(r1); db.context.insert(r2); db.context.insert(r3)
        try db.context.save()
        let records = try db.context.fetch(FetchDescriptor<Record>())
        let snapshot = WidgetDataWriter.buildSnapshot(
            records: records, events: [], contacts: [c1, c2, c3], now: Self.jan1
        )
        #expect(snapshot.yearlyContactCount == 2)
    }

    /// 22. nextHostingEvent gift total sums received monetary records for that event
    @MainActor
    @Test func nextHostingEventGiftTotalCalculated() throws {
        let db = try TestDB()
        let c1 = SampleData.contact(name: "宾客1")
        let c2 = SampleData.contact(name: "宾客2")
        let event = Event(name: "我的婚礼", type: .wedding, hostMode: .host, date: Self.jan1)
        db.context.insert(c1); db.context.insert(c2); db.context.insert(event)
        let r1 = SampleData.record(contact: c1, event: event, amount: 500, direction: .received)
        let r2 = SampleData.record(contact: c2, event: event, amount: 800, direction: .received)
        let r3 = SampleData.record(contact: c1, event: event, amount: 200, direction: .given)
        db.context.insert(r1); db.context.insert(r2); db.context.insert(r3)
        try db.context.save()
        let records = try db.context.fetch(FetchDescriptor<Record>())
        let events = try db.context.fetch(FetchDescriptor<Event>())
        let snapshot = WidgetDataWriter.buildSnapshot(records: records, events: events, contacts: [], now: Self.jan1)
        let hosting = try #require(snapshot.nextHostingEvent)
        #expect(abs((hosting.giftReceivedTotal ?? 0) - 1300) < 0.01)
    }

    /// 23. nextHostingEvent guest count = unique guests who gave received records
    @MainActor
    @Test func nextHostingEventGuestCountCalculated() throws {
        let db = try TestDB()
        let c1 = SampleData.contact(name: "宾客1")
        let c2 = SampleData.contact(name: "宾客2")
        let event = Event(name: "我的婚礼", type: .wedding, hostMode: .host, date: Self.jan1)
        db.context.insert(c1); db.context.insert(c2); db.context.insert(event)
        let r1 = SampleData.record(contact: c1, event: event, amount: 500, direction: .received)
        let r2 = SampleData.record(contact: c1, event: event, amount: 100, direction: .received)
        let r3 = SampleData.record(contact: c2, event: event, amount: 300, direction: .received)
        db.context.insert(r1); db.context.insert(r2); db.context.insert(r3)
        try db.context.save()
        let records = try db.context.fetch(FetchDescriptor<Record>())
        let events = try db.context.fetch(FetchDescriptor<Event>())
        let snapshot = WidgetDataWriter.buildSnapshot(records: records, events: events, contacts: [], now: Self.jan1)
        let hosting = try #require(snapshot.nextHostingEvent)
        #expect(hosting.guestCount == 2)
    }

    /// 24. nextHostingEvent selects the nearest future host event
    @Test func nextHostingEventIsNearestFuture() throws {
        let near = try Event(name: "近期主办", type: .wedding, hostMode: .host,
                             date: #require(Calendar.current.date(byAdding: .day, value: 3, to: Self.jan1)))
        let far = try Event(name: "远期主办", type: .birthday, hostMode: .host,
                            date: #require(Calendar.current.date(byAdding: .day, value: 30, to: Self.jan1)))
        let snapshot = WidgetDataWriter.buildSnapshot(records: [], events: [far, near], contacts: [], now: Self.jan1)
        #expect(snapshot.nextHostingEvent?.name == "近期主办")
    }

    /// 25. nextHostingEvent is nil when no future host events exist
    @Test func nextHostingEventNilWhenNoneExist() throws {
        let past = try Event(name: "过去主办", type: .wedding, hostMode: .host,
                             date: #require(Calendar.current.date(byAdding: .day, value: -5, to: Self.jan1)))
        let snapshot = WidgetDataWriter.buildSnapshot(records: [], events: [past], contacts: [], now: Self.jan1)
        #expect(snapshot.nextHostingEvent == nil)
    }

    /// 26. pendingReturnCount counts future/today guest events with no given records
    @MainActor
    @Test func pendingReturnCountForFutureGuestEvents() throws {
        let db = try TestDB()
        let contact = SampleData.contact(name: "林悦")
        let guestNoGift = Event(name: "林悦婚礼", type: .wedding, hostMode: .guest, date: Self.jan1)
        let guestWithGift = Event(name: "同学满月", type: .birthday, hostMode: .guest, date: Self.jan1)
        let hostEvent = Event(name: "我的婚礼", type: .wedding, hostMode: .host, date: Self.jan1)
        db.context.insert(contact)
        db.context.insert(guestNoGift)
        db.context.insert(guestWithGift)
        db.context.insert(hostEvent)
        let gift = SampleData.record(contact: contact, event: guestWithGift, direction: .given)
        db.context.insert(gift)
        try db.context.save()
        let events = try db.context.fetch(FetchDescriptor<Event>())
        let records = try db.context.fetch(FetchDescriptor<Record>())
        let snapshot = WidgetDataWriter.buildSnapshot(records: records, events: events, contacts: [], now: Self.jan1)
        // Only guestNoGift qualifies: guest + today/future + no given record
        #expect(snapshot.pendingReturnCount == 1)
    }

    /// 27. pendingReturnCount excludes past guest events (even if in the current year)
    @Test func pendingReturnCountExcludesPastEvents() throws {
        let yesterday = try #require(Calendar.current.date(byAdding: .day, value: -1, to: Self.jan1))
        let lastYear = try #require(Calendar.current.date(byAdding: .year, value: -1, to: Self.jan1))
        let pastThisYear = Event(name: "昨天婚礼", type: .wedding, hostMode: .guest, date: yesterday)
        let pastLastYear = Event(name: "去年婚礼", type: .wedding, hostMode: .guest, date: lastYear)
        let snapshot = WidgetDataWriter.buildSnapshot(records: [], events: [pastThisYear, pastLastYear], contacts: [], now: Self.jan1)
        #expect(snapshot.pendingReturnCount == 0)
    }

    /// 28. eventDateLabel is populated for birthday reminders in the 3-day window
    @Test func eventDateLabelPopulatedForBirthday() throws {
        let now = Self.jan1 // Jan 1
        var comps = DateComponents(); comps.year = 1990; comps.month = 1; comps.day = 1
        let bday = try #require(Calendar.current.date(from: comps))
        let contact = makeContact(name: "王五", birthday: bday, birthdayReminderEnabled: true)
        let snapshot = WidgetDataWriter.buildSnapshot(records: [], events: [], contacts: [contact], now: now)
        let item = try #require(snapshot.reminders.first)
        #expect(item.eventDateLabel == "1月1日")
    }

    /// 29. eventDateLabel is populated for event reminders in the 3-day window
    @Test func eventDateLabelPopulatedForEvent() throws {
        let event = makeEvent(name: "同学婚礼", daysFromNow: 1, now: Self.jan1)
        let snapshot = WidgetDataWriter.buildSnapshot(records: [], events: [event], contacts: [], now: Self.jan1)
        let item = try #require(snapshot.reminders.first)
        #expect(item.eventDateLabel == "1月2日")
    }

    /// 30. pendingReturn reminder title = "回礼 · {contact.name}" when primaryContact is set
    @MainActor
    @Test func pendingReturnTitleUsesContactName() throws {
        let db = try TestDB()
        let contact = SampleData.contact(name: "林悦")
        let event = Event(name: "林悦婚礼", type: .wedding, hostMode: .guest,
                          date: Self.jan1, primaryContact: contact)
        db.context.insert(contact)
        db.context.insert(event)
        try db.context.save()
        let events = try db.context.fetch(FetchDescriptor<Event>())
        let snapshot = WidgetDataWriter.buildSnapshot(records: [], events: events, contacts: [], now: Self.jan1)
        let item = try #require(snapshot.reminders.first { $0.kind == .pendingReturn })
        #expect(item.title.contains("林悦"))
    }

    /// 31. pendingReturn reminder title falls back to event name when no primaryContact
    @MainActor
    @Test func pendingReturnTitleFallsBackToEventName() throws {
        let db = try TestDB()
        let event = Event(name: "朋友婚礼", type: .wedding, hostMode: .guest, date: Self.jan1)
        db.context.insert(event)
        try db.context.save()
        let events = try db.context.fetch(FetchDescriptor<Event>())
        let snapshot = WidgetDataWriter.buildSnapshot(records: [], events: events, contacts: [], now: Self.jan1)
        let item = try #require(snapshot.reminders.first { $0.kind == .pendingReturn })
        #expect(item.title == "朋友婚礼")
    }

    /// 32. host event within 3-day window is NOT included in pendingReturnCount
    @Test func hostEventExcludedFromPendingReturnCount() {
        let event = makeEvent(name: "我的婚礼", hostMode: .host, daysFromNow: 0)
        let snapshot = WidgetDataWriter.buildSnapshot(records: [], events: [event], contacts: [], now: Self.jan1)
        #expect(snapshot.pendingReturnCount == 0)
    }

    /// 33. nextHostingEvent.daysUntil == 0 when the event is today (used by countdown widgets)
    @Test func nextHostingEventTodayHasDaysUntilZero() {
        let event = makeEvent(name: "今天的婚礼", hostMode: .host, daysFromNow: 0)
        let snapshot = WidgetDataWriter.buildSnapshot(records: [], events: [event], contacts: [], now: Self.jan1)
        #expect(snapshot.nextHostingEvent != nil)
        #expect(snapshot.nextHostingEvent?.daysUntil == 0)
    }

    /// 34. nextHostingEvent.dateLine includes location when non-empty
    @Test func nextHostingEventDateLineIncludesLocation() {
        let event = makeEvent(name: "婚礼", hostMode: .host, daysFromNow: 7)
        event.location = "上海静安瑞吉"
        let snapshot = WidgetDataWriter.buildSnapshot(records: [], events: [event], contacts: [], now: Self.jan1)
        let dateLine = snapshot.nextHostingEvent?.dateLine ?? ""
        #expect(dateLine.contains("上海静安瑞吉"))
        #expect(dateLine.contains("·"))
    }

    /// 35. nextHostingEvent.dateLine omits separator when location is empty
    @Test func nextHostingEventDateLineWithoutLocation() {
        let event = makeEvent(name: "婚礼", hostMode: .host, daysFromNow: 7)
        event.location = ""
        let snapshot = WidgetDataWriter.buildSnapshot(records: [], events: [event], contacts: [], now: Self.jan1)
        let dateLine = snapshot.nextHostingEvent?.dateLine ?? ""
        #expect(!dateLine.contains("·"))
        #expect(dateLine.contains("月"))
    }

    /// 36. Birthday exactly 3 days out → included (windowEnd is inclusive for birthdays)
    @Test func birthdayThreeDaysOutIncluded() throws {
        let now = Self.jan1 // Jan 1 2026
        var comps = DateComponents(); comps.year = 1990; comps.month = 1; comps.day = 4
        let bday = try #require(Calendar.current.date(from: comps))
        let contact = makeContact(name: "三天生日", birthday: bday, birthdayReminderEnabled: true)
        let snapshot = WidgetDataWriter.buildSnapshot(records: [], events: [], contacts: [contact], now: now)
        #expect(snapshot.reminders.count == 1)
        #expect(snapshot.reminders[0].kind == .birthday)
        #expect(snapshot.reminders[0].urgencyDaysFromNow == 3)
    }

    /// 36b. Birthday beyond 3 days is stored so timeline refresh can reveal it later
    @Test func birthdayFiveDaysOutStoredForFutureRefresh() throws {
        let now = Self.jan1 // Jan 1 2026
        var comps = DateComponents(); comps.year = 1990; comps.month = 1; comps.day = 6
        let bday = try #require(Calendar.current.date(from: comps))
        let contact = makeContact(name: "五天生日", birthday: bday, birthdayReminderEnabled: true)
        let snapshot = WidgetDataWriter.buildSnapshot(records: [], events: [], contacts: [contact], now: now)
        #expect(snapshot.reminders.count == 1)
        #expect(snapshot.refreshed(at: now).reminders.isEmpty)
        let twoDaysLater = try #require(Calendar.current.date(byAdding: .day, value: 2, to: now))
        let refreshed = snapshot.refreshed(at: twoDaysLater)
        #expect(refreshed.reminders.count == 1)
        #expect(refreshed.reminders[0].kind == .birthday)
        #expect(refreshed.reminders[0].urgencyDaysFromNow == 3)
    }

    /// 37. dateLabel for 2 days from now uses the "N天后" format (daysLater branch)
    @Test func dateLabelDaysLater() {
        let event = makeEvent(name: "后天事件", daysFromNow: 2)
        let snapshot = WidgetDataWriter.buildSnapshot(records: [], events: [event], contacts: [], now: Self.jan1)
        let label = snapshot.reminders.first?.dateLabel ?? ""
        #expect(label.contains("2") && label.hasSuffix("后"))
    }

    /// 38. Non-monetary records (gift/favor/banquet) do not contribute to yearlyIncome or yearlyExpense
    @MainActor
    @Test func nonMonetaryRecordsExcludedFromYearlyIncome() throws {
        let db = try TestDB()
        let contact = SampleData.contact(name: "礼品测试")
        db.context.insert(contact)
        let gift = SampleData.recordGift(contact: contact, date: Self.jan1)
        let favor = SampleData.recordFavor(contact: contact, date: Self.jan1)
        let banquet = SampleData.recordBanquet(contact: contact, date: Self.jan1)
        db.context.insert(gift); db.context.insert(favor); db.context.insert(banquet)
        try db.context.save()

        let records = try db.context.fetch(FetchDescriptor<Record>())
        let snapshot = WidgetDataWriter.buildSnapshot(records: records, events: [], contacts: [], now: Self.jan1)
        #expect(snapshot.yearlyIncome == 0)
        #expect(snapshot.yearlyExpense == 0)
    }

    /// 41. Prior-year monetary records do not count toward yearlyIncome / yearlyExpense
    @MainActor
    @Test func priorYearIncomeExcludedFromYearly() throws {
        let db = try TestDB()
        let contact = SampleData.contact(name: "去年测试")
        db.context.insert(contact)
        let lastYear = try #require(Calendar.current.date(byAdding: .year, value: -1, to: Self.jan1))
        let r = SampleData.record(contact: contact, amount: 2000, direction: .received, date: lastYear)
        db.context.insert(r)
        try db.context.save()
        let records = try db.context.fetch(FetchDescriptor<Record>())
        let snapshot = WidgetDataWriter.buildSnapshot(records: records, events: [], contacts: [], now: Self.jan1)
        #expect(snapshot.yearlyIncome == 0)
        #expect(snapshot.yearlyRecordCount == 0)
    }

    /// 42. Prior-year records do not count toward yearlyRecordCount
    @MainActor
    @Test func priorYearRecordsExcludedFromYearlyCount() throws {
        let db = try TestDB()
        let contact = SampleData.contact(name: "去年计数测试")
        db.context.insert(contact)
        let lastYear = try #require(Calendar.current.date(byAdding: .year, value: -1, to: Self.jan1))
        let old = SampleData.record(contact: contact, amount: 300, date: lastYear)
        let current = SampleData.record(contact: contact, amount: 300, date: Self.jan1)
        db.context.insert(old); db.context.insert(current)
        try db.context.save()
        let records = try db.context.fetch(FetchDescriptor<Record>())
        let snapshot = WidgetDataWriter.buildSnapshot(records: records, events: [], contacts: [], now: Self.jan1)
        #expect(snapshot.yearlyRecordCount == 1)
    }

    /// 43. nextHostingEvent is nil when only guest events exist
    @Test func nextHostingEventNilWithOnlyGuestEvents() {
        let event = makeEvent(name: "朋友婚礼", hostMode: .guest, daysFromNow: 3)
        let snapshot = WidgetDataWriter.buildSnapshot(records: [], events: [event], contacts: [], now: Self.jan1)
        #expect(snapshot.nextHostingEvent == nil)
    }

    /// 44. nextHostingEvent.addRecordURL uses lishu://add-record?event=<stableID>
    @MainActor
    @Test func nextHostingEventAddRecordURLHasCorrectFormat() throws {
        let db = try TestDB()
        let event = Event(name: "我的婚礼", type: .wedding, hostMode: .host, date: Self.jan1)
        db.context.insert(event)
        try db.context.save()
        let events = try db.context.fetch(FetchDescriptor<Event>())
        let snapshot = WidgetDataWriter.buildSnapshot(records: [], events: events, contacts: [], now: Self.jan1)
        let hosting = try #require(snapshot.nextHostingEvent)
        let addURL = try #require(hosting.addRecordURL)
        let comps = try #require(URLComponents(url: addURL, resolvingAgainstBaseURL: false))
        #expect(comps.scheme == "lishu")
        #expect(comps.host == "add-record")
        let eventParam = try #require(comps.queryItems?.first(where: { $0.name == "event" })?.value)
        #expect(DeepLink.from(addURL) == .addRecordForEvent(stableID: eventParam))
    }

    /// 45. pendingReturn reminder deepLinkURL uses lishu://add-record?event=<stableID>&direction=given
    @MainActor
    @Test func pendingReturnDeepLinkUsesGiveGiftURL() throws {
        let db = try TestDB()
        let event = Event(name: "朋友婚礼", type: .wedding, hostMode: .guest, date: Self.jan1)
        db.context.insert(event)
        try db.context.save()
        let events = try db.context.fetch(FetchDescriptor<Event>())
        let snapshot = WidgetDataWriter.buildSnapshot(records: [], events: events, contacts: [], now: Self.jan1)
        let item = try #require(snapshot.reminders.first(where: { $0.kind == .pendingReturn }))
        let comps = try #require(URLComponents(url: item.deepLinkURL, resolvingAgainstBaseURL: false))
        #expect(comps.scheme == "lishu")
        #expect(comps.host == "add-record")
        let direction = comps.queryItems?.first(where: { $0.name == "direction" })?.value
        #expect(direction == "given")
        let eventParam = try #require(comps.queryItems?.first(where: { $0.name == "event" })?.value)
        #expect(DeepLink.from(item.deepLinkURL) == .giveGiftForEvent(stableID: eventParam))
    }

    /// 46. stableID(for:) must be unique per saved event in the same store.
    /// Regression: if the underlying PersistentIdentifier shape changes (e.g. iOS bumps),
    /// the Mirror-based reflection used to silently fall back to entityName+storeIdentifier,
    /// which collapses every Event to the same stableID and makes widget deep links route
    /// to the wrong entity.
    @MainActor
    @Test func stableIDIsUniquePerEvent() throws {
        let db = try TestDB()
        let e1 = Event(name: "事件A", type: .wedding, hostMode: .host, date: Self.jan1)
        let e2 = Event(name: "事件B", type: .birthday, hostMode: .host, date: Self.jan1)
        let e3 = Event(name: "事件C", type: .other, hostMode: .guest, date: Self.jan1)
        db.context.insert(e1); db.context.insert(e2); db.context.insert(e3)
        try db.context.save()
        let events = try db.context.fetch(FetchDescriptor<Event>())
        #expect(events.count == 3)
        let sids = events.map { WidgetDataWriter.stableID(for: $0.persistentModelID) }
        #expect(Set(sids).count == 3, "stableIDs must be distinct, got: \(sids)")
    }

    /// 47. nextHostingEvent cover image is written to the App Group file path.
    @Test func nextHostingEventCoverImagePathIsWritten() throws {
        let event = makeEvent(name: "带封面主办", hostMode: .host, daysFromNow: 2)
        event.coverImage = SampleImages.makePNGData(width: 64, height: 64)

        let snapshot = WidgetDataWriter.buildSnapshot(records: [], events: [event], contacts: [], now: Self.jan1)
        let path = try #require(snapshot.nextHostingEvent?.coverImagePath)

        #expect(!path.isEmpty)
        #expect(FileManager.default.fileExists(atPath: path))
    }
}
