import Foundation
@testable import LiShu
import SwiftData
import Testing

@MainActor
struct EventDetailViewModelTests {
    @Test func totalGivenAndReceived() throws {
        let db = try TestDB()
        let contact1 = SampleData.contact(name: "张三")
        let contact2 = SampleData.contact(name: "李四")
        let event = SampleData.event(name: "婚礼")
        db.context.insert(contact1)
        db.context.insert(contact2)
        db.context.insert(event)

        let r1 = SampleData.record(contact: contact1, event: event, amount: 500, direction: .given)
        let r2 = SampleData.record(contact: contact2, event: event, amount: 300, direction: .given)
        let r3 = SampleData.record(contact: contact1, event: event, amount: 1000, direction: .received)
        db.context.insert(r1)
        db.context.insert(r2)
        db.context.insert(r3)
        try db.context.save()

        let vm = EventDetailViewModel()
        vm.load(id: event.persistentModelID, context: db.context)

        #expect(vm.totalGiven == 800)
        #expect(vm.totalReceived == 1000)
    }

    @Test func primaryRecordPrefersLatestEventRecord() throws {
        let db = try TestDB()
        let contact1 = SampleData.contact(name: "张三")
        let contact2 = SampleData.contact(name: "李四")
        let event = SampleData.event(name: "婚礼")
        db.context.insert(contact1)
        db.context.insert(contact2)
        db.context.insert(event)

        let r1 = SampleData.record(
            contact: contact1,
            event: event,
            amount: 500,
            direction: .given,
            date: Calendar.current.date(byAdding: .day, value: -2, to: .now) ?? .now
        )
        let r2 = SampleData.record(
            contact: contact2,
            event: event,
            amount: 300,
            direction: .given,
            date: Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now
        )
        let r3 = SampleData.record(
            contact: contact1,
            event: event,
            amount: 200,
            direction: .received,
            date: .now
        )
        db.context.insert(r1)
        db.context.insert(r2)
        db.context.insert(r3)
        try db.context.save()

        let vm = EventDetailViewModel()
        vm.load(id: event.persistentModelID, context: db.context)

        #expect(vm.primaryRecord?.persistentModelID == r3.persistentModelID)
    }

    @Test func testDaysUntilEvent() throws {
        let db = try TestDB()
        let cal = Calendar.current
        let futureDate = try #require(cal.date(byAdding: .day, value: 7, to: cal.startOfDay(for: .now)))
        let event = SampleData.event(name: "未来事件", date: futureDate)
        db.context.insert(event)
        try db.context.save()

        let vm = EventDetailViewModel()
        vm.load(id: event.persistentModelID, context: db.context)

        #expect(vm.daysUntilEvent == 7)
    }

    @Test func testIsUpcoming() throws {
        let db = try TestDB()
        let cal = Calendar.current

        let futureEvent = try SampleData.event(name: "未来", date: #require(cal.date(byAdding: .day, value: 5, to: .now)))
        let pastEvent = try SampleData.event(name: "过去", date: #require(cal.date(byAdding: .day, value: -5, to: .now)))
        db.context.insert(futureEvent)
        db.context.insert(pastEvent)
        try db.context.save()

        let vm1 = EventDetailViewModel()
        vm1.load(id: futureEvent.persistentModelID, context: db.context)
        #expect(vm1.isUpcoming == true)

        let vm2 = EventDetailViewModel()
        vm2.load(id: pastEvent.persistentModelID, context: db.context)
        #expect(vm2.isUpcoming == false)
    }

    @Test func deleteEventWithoutRecords() throws {
        let db = try TestDB()
        let event = SampleData.event(name: "无记录事件")
        db.context.insert(event)
        try db.context.save()

        let vm = EventDetailViewModel()
        vm.load(id: event.persistentModelID, context: db.context)

        #expect(vm.deleteEvent(context: db.context) == true)

        let events = try db.context.fetch(FetchDescriptor<Event>())
        #expect(events.isEmpty)
    }

    @Test func testFormattedDate() throws {
        let db = try TestDB()
        var cal = Calendar.current
        cal.timeZone = try #require(TimeZone(identifier: "Asia/Shanghai"))
        let date = try #require(cal.date(from: DateComponents(year: 2026, month: 3, day: 15)))
        let event = SampleData.event(name: "测试", date: date)
        db.context.insert(event)
        try db.context.save()

        let vm = EventDetailViewModel()
        vm.load(id: event.persistentModelID, context: db.context)

        #expect(vm.formattedDate.contains("2026"))
        #expect(vm.formattedDate.contains("3"))
        #expect(vm.formattedDate.contains("15"))
    }

    @Test func hostLedgerSummaryMetrics() throws {
        let db = try TestDB()
        let contact1 = SampleData.contact(name: "张三")
        let contact2 = SampleData.contact(name: "李四")
        let event = SampleData.event(name: "我的婚礼", hostMode: .host)
        db.context.insert(contact1)
        db.context.insert(contact2)
        db.context.insert(event)

        let todayFirst = SampleData.record(contact: contact1, event: event, amount: 1000, direction: .received)
        let todaySecond = SampleData.record(contact: contact2, event: event, amount: 1500, direction: .received)
        let oldGiven = SampleData.record(
            contact: contact1,
            event: event,
            amount: 600,
            direction: .given,
            date: Calendar.current.date(byAdding: .day, value: -3, to: .now) ?? .now
        )
        db.context.insert(todayFirst)
        db.context.insert(todaySecond)
        db.context.insert(oldGiven)
        try db.context.save()

        let vm = EventDetailViewModel()
        vm.load(id: event.persistentModelID, context: db.context)

        #expect(vm.receivedRecordCount == 2)
        #expect(vm.largestReceivedAmount == 1500)
        #expect(vm.todayReceivedCount == 2)
        #expect(vm.todayReceivedAmount == 2500)
    }

    @Test func hostLedgerSummaryMetricsIgnoreNonMonetaryReceivedRecords() throws {
        let db = try TestDB()
        let contact = SampleData.contact(name: "张三")
        let event = SampleData.event(name: "我的婚礼", hostMode: .host)
        db.context.insert(contact)
        db.context.insert(event)

        db.context.insert(SampleData.record(contact: contact, event: event, amount: 1200, direction: .received))
        db.context.insert(SampleData.recordGift(contact: contact, event: event, estimatedValue: 8888, direction: .received))
        db.context.insert(SampleData.recordFavor(contact: contact, event: event, direction: .received))
        try db.context.save()

        let vm = EventDetailViewModel()
        vm.load(id: event.persistentModelID, context: db.context)

        #expect(vm.receivedRecordCount == 1)
        #expect(vm.totalReceived == 1200)
        #expect(vm.largestReceivedAmount == 1200)
        #expect(vm.todayReceivedAmount == 1200)
    }

    @Test func hostLedgerFlagsLegacyAnomalies() throws {
        let db = try TestDB()
        let contact = SampleData.contact(name: "张三")
        let event = SampleData.event(name: "我的婚礼", hostMode: .host)
        db.context.insert(contact)
        db.context.insert(event)

        db.context.insert(SampleData.record(contact: contact, event: event, amount: 1200, direction: .received))
        db.context.insert(SampleData.record(contact: contact, event: event, amount: 800, direction: .received))
        db.context.insert(SampleData.recordGift(contact: contact, event: event, direction: .received))
        db.context.insert(SampleData.record(contact: contact, event: event, amount: 300, direction: .given))
        try db.context.save()

        let vm = EventDetailViewModel()
        vm.load(id: event.persistentModelID, context: db.context)

        #expect(vm.hasLegacyLedgerAnomalies == true)
        #expect(vm.legacyLedgerAnomalyCount == 2)
        #expect(vm.receivedRecordCount == 2)
    }

    @Test func pureHostLedgerDoesNotFlagLegacyAnomalies() throws {
        let db = try TestDB()
        let contact = SampleData.contact(name: "张三")
        let event = SampleData.event(name: "我的婚礼", hostMode: .host)
        db.context.insert(contact)
        db.context.insert(event)

        db.context.insert(SampleData.record(contact: contact, event: event, amount: 1200, direction: .received))
        db.context.insert(SampleData.record(contact: contact, event: event, amount: 800, direction: .received))
        try db.context.save()

        let vm = EventDetailViewModel()
        vm.load(id: event.persistentModelID, context: db.context)

        #expect(vm.hasLegacyLedgerAnomalies == false)
        #expect(vm.legacyLedgerAnomalyCount == 0)
    }
}
