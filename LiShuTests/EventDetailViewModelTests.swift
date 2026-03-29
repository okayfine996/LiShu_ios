import Foundation
import Testing
import SwiftData
@testable import LiShu

@MainActor
struct EventDetailViewModelTests {

    @Test func testTotalGivenAndReceived() throws {
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

    @Test func testRelatedContacts() throws {
        let db = try TestDB()
        let contact1 = SampleData.contact(name: "张三")
        let contact2 = SampleData.contact(name: "李四")
        let event = SampleData.event(name: "婚礼")
        db.context.insert(contact1)
        db.context.insert(contact2)
        db.context.insert(event)

        let r1 = SampleData.record(contact: contact1, event: event, amount: 500, direction: .given)
        let r2 = SampleData.record(contact: contact2, event: event, amount: 300, direction: .given)
        let r3 = SampleData.record(contact: contact1, event: event, amount: 200, direction: .received)
        db.context.insert(r1)
        db.context.insert(r2)
        db.context.insert(r3)
        try db.context.save()

        let vm = EventDetailViewModel()
        vm.load(id: event.persistentModelID, context: db.context)

        #expect(vm.relatedContacts.count == 2)
    }

    @Test func testDaysUntilEvent() throws {
        let db = try TestDB()
        let cal = Calendar.current
        let futureDate = cal.date(byAdding: .day, value: 7, to: cal.startOfDay(for: .now))!
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

        let futureEvent = SampleData.event(name: "未来", date: cal.date(byAdding: .day, value: 5, to: .now)!)
        let pastEvent = SampleData.event(name: "过去", date: cal.date(byAdding: .day, value: -5, to: .now)!)
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

    @Test func testDeleteEventWithoutRecords() throws {
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
        cal.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        let date = cal.date(from: DateComponents(year: 2026, month: 3, day: 15))!
        let event = SampleData.event(name: "测试", date: date)
        db.context.insert(event)
        try db.context.save()

        let vm = EventDetailViewModel()
        vm.load(id: event.persistentModelID, context: db.context)

        #expect(vm.formattedDate.contains("2026"))
        #expect(vm.formattedDate.contains("3"))
        #expect(vm.formattedDate.contains("15"))
    }
}
