import Foundation
@testable import LiShu
import SwiftData
import Testing

@MainActor
struct EventTypeDetailViewModelTests {
    @Test("load records by event type and year")
    func loadRecordsByEventType() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let weddingEvent = SampleData.event(name: "婚礼A", type: .wedding)
        let birthdayEvent = SampleData.event(name: "生日A", type: .birthday)
        db.context.insert(contact)
        db.context.insert(weddingEvent)
        db.context.insert(birthdayEvent)

        let cal = Calendar.current
        let date2026 = try #require(cal.date(from: DateComponents(year: 2026, month: 6, day: 15)))
        let date2025 = try #require(cal.date(from: DateComponents(year: 2025, month: 6, day: 15)))

        let r1 = SampleData.record(contact: contact, event: weddingEvent, amount: 1000, date: date2026)
        let r2 = SampleData.record(contact: contact, event: weddingEvent, amount: 500, date: date2026)
        let r3 = SampleData.record(contact: contact, event: birthdayEvent, amount: 300, date: date2026)
        let r4 = SampleData.record(contact: contact, event: weddingEvent, amount: 800, date: date2025)
        db.context.insert(r1)
        db.context.insert(r2)
        db.context.insert(r3)
        db.context.insert(r4)
        try db.context.save()

        let vm = EventTypeDetailViewModel()
        vm.load(eventType: .wedding, year: 2026, context: db.context)

        #expect(vm.records.count == 2)
        #expect(vm.eventType == .wedding)
        #expect(vm.year == 2026)
    }

    @Test("totalExpense and totalIncome computed from filtered records")
    func totalExpenseAndIncome() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event(type: .birthday)
        db.context.insert(contact)
        db.context.insert(event)

        let date = try #require(Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 10)))
        let r1 = SampleData.record(contact: contact, event: event, amount: 500, direction: .given, date: date)
        let r2 = SampleData.record(contact: contact, event: event, amount: 300, direction: .received, date: date)
        db.context.insert(r1)
        db.context.insert(r2)
        try db.context.save()

        let vm = EventTypeDetailViewModel()
        vm.load(eventType: .birthday, year: 2026, context: db.context)

        #expect(vm.totalExpense == 500)
        #expect(vm.totalIncome == 300)
        #expect(vm.netValue == -200)
    }

    @Test("monthlyDistribution has 12 elements with correct counts")
    func testMonthlyDistribution() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event(type: .wedding)
        db.context.insert(contact)
        db.context.insert(event)

        let cal = Calendar.current
        let jan = try #require(cal.date(from: DateComponents(year: 2026, month: 1, day: 5)))
        let mar1 = try #require(cal.date(from: DateComponents(year: 2026, month: 3, day: 10)))
        let mar2 = try #require(cal.date(from: DateComponents(year: 2026, month: 3, day: 20)))

        let r1 = SampleData.record(contact: contact, event: event, amount: 100, date: jan)
        let r2 = SampleData.record(contact: contact, event: event, amount: 200, date: mar1)
        let r3 = SampleData.record(contact: contact, event: event, amount: 300, date: mar2)
        db.context.insert(r1)
        db.context.insert(r2)
        db.context.insert(r3)
        try db.context.save()

        let vm = EventTypeDetailViewModel()
        vm.load(eventType: .wedding, year: 2026, context: db.context)

        #expect(vm.monthlyDistribution.count == 12)
        #expect(vm.monthlyDistribution[0] == 1) // January
        #expect(vm.monthlyDistribution[2] == 2) // March
        #expect(vm.monthlyDistribution[5] == 0) // June
    }

    @Test("peakMonth returns index of busiest month, -1 when empty")
    func testPeakMonth() throws {
        let vm = EventTypeDetailViewModel()
        #expect(vm.peakMonth == -1)

        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event(type: .funeral)
        db.context.insert(contact)
        db.context.insert(event)

        let cal = Calendar.current
        let jan = try #require(cal.date(from: DateComponents(year: 2026, month: 1, day: 5)))
        let jun1 = try #require(cal.date(from: DateComponents(year: 2026, month: 6, day: 10)))
        let jun2 = try #require(cal.date(from: DateComponents(year: 2026, month: 6, day: 20)))

        let r1 = SampleData.record(contact: contact, event: event, amount: 100, date: jan)
        let r2 = SampleData.record(contact: contact, event: event, amount: 200, date: jun1)
        let r3 = SampleData.record(contact: contact, event: event, amount: 300, date: jun2)
        db.context.insert(r1)
        db.context.insert(r2)
        db.context.insert(r3)
        try db.context.save()

        vm.load(eventType: .funeral, year: 2026, context: db.context)
        #expect(vm.peakMonth == 5) // June = index 5
    }

    @Test("typeName returns non-empty localized names for all event types")
    func testTypeName() {
        let vm = EventTypeDetailViewModel()
        for eventType in EventType.allCases {
            vm.eventType = eventType
            #expect(!vm.typeName.isEmpty, "typeName should not be empty for \(eventType)")
        }
    }

    @Test("navigationTitle contains typeName and year")
    func testNavigationTitle() {
        let vm = EventTypeDetailViewModel()
        vm.eventType = .wedding
        vm.year = 2026

        let title = vm.navigationTitle
        #expect(title.contains(vm.typeName))
        #expect(title.contains("2026"))
    }

    @Test("formatAmount and formatNetValue produce correct output")
    func formatAmountAndNetValue() {
        let vm = EventTypeDetailViewModel()
        let amount = vm.formatAmount(12345)
        #expect(amount.hasPrefix("¥"))
        #expect(amount.contains("12,345") || amount.contains("12345"))

        vm.records = []
        let net = vm.formatNetValue()
        #expect(net.hasPrefix("+"))
    }
}
