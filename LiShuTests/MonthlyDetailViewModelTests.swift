import Foundation
import Testing
import SwiftData
@testable import LiShu

@MainActor
struct MonthlyDetailViewModelTests {

    @Test func testLoadMonthlyRecords() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)

        let cal = Calendar.current
        let marchDate = cal.date(from: DateComponents(year: 2026, month: 3, day: 10))!
        let aprilDate = cal.date(from: DateComponents(year: 2026, month: 4, day: 5))!

        let r1 = Record(contact: contact, event: event, amount: 500, direction: .given, date: marchDate)
        let r2 = Record(contact: contact, event: event, amount: 300, direction: .received, date: marchDate)
        let r3 = Record(contact: contact, event: event, amount: 800, direction: .given, date: aprilDate)
        db.context.insert(r1)
        db.context.insert(r2)
        db.context.insert(r3)
        try db.context.save()

        let vm = MonthlyDetailViewModel()
        vm.load(period: .month(year: 2026, month: 3), context: db.context)

        #expect(vm.records.count == 2)
        #expect(vm.period.year == 2026)
    }

    @Test func testMonthlyIncomeAndExpense() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)

        let cal = Calendar.current
        let date = cal.date(from: DateComponents(year: 2026, month: 6, day: 15))!

        let given1 = Record(contact: contact, event: event, amount: 500, direction: .given, date: date)
        let given2 = Record(contact: contact, event: event, amount: 300, direction: .given, date: date)
        let received1 = Record(contact: contact, event: event, amount: 1000, direction: .received, date: date)
        db.context.insert(given1)
        db.context.insert(given2)
        db.context.insert(received1)
        try db.context.save()

        let vm = MonthlyDetailViewModel()
        vm.load(period: .month(year: 2026, month: 6), context: db.context)

        #expect(vm.periodExpense == 800)
        #expect(vm.periodIncome == 1000)
        #expect(vm.netAmount == 200)
    }

    @Test func testFormattedValues() {
        let vm = MonthlyDetailViewModel()
        vm.period = .month(year: 2026, month: 3)
        vm.records = []
        vm.periodIncome = 0
        vm.periodExpense = 0

        let formatted = vm.formatAmount(0)
        #expect(formatted.contains("¥"))

        let net = vm.formatNetAmount()
        #expect(net.hasPrefix("+"))
    }

    @Test func testPeriodTitle() {
        let vm = MonthlyDetailViewModel()
        vm.period = .month(year: 2026, month: 8)

        let title = vm.periodTitle
        #expect(title.contains("2026"))
        #expect(title.contains("8"))
    }

    @Test func testStatsPeriodMonthRange() {
        let month = StatsPeriod.month(year: 2026, month: 3)
        #expect(month.monthRange == 3...3)

        let quarter = StatsPeriod.quarter(year: 2026, quarter: 2)
        #expect(quarter.monthRange == 4...6)
    }

    @Test func testStatsPeriodPrevious() {
        let jan = StatsPeriod.month(year: 2026, month: 1)
        let prev = jan.previous
        if case .month(let y, let m) = prev {
            #expect(y == 2025)
            #expect(m == 12)
        } else {
            Issue.record("Expected .month")
        }

        let q1 = StatsPeriod.quarter(year: 2026, quarter: 1)
        let prevQ = q1.previous
        if case .quarter(let y, let q) = prevQ {
            #expect(y == 2025)
            #expect(q == 4)
        } else {
            Issue.record("Expected .quarter")
        }
    }

    @Test func testIncomeTrendAndExpenseTrend() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)

        let cal = Calendar.current
        let febDate = cal.date(from: DateComponents(year: 2026, month: 2, day: 15))!
        let marDate = cal.date(from: DateComponents(year: 2026, month: 3, day: 15))!

        let rFebGiven = Record(contact: contact, event: event, amount: 200, direction: .given, date: febDate)
        let rFebReceived = Record(contact: contact, event: event, amount: 100, direction: .received, date: febDate)
        let rMarGiven = Record(contact: contact, event: event, amount: 400, direction: .given, date: marDate)
        let rMarReceived = Record(contact: contact, event: event, amount: 300, direction: .received, date: marDate)
        db.context.insert(rFebGiven)
        db.context.insert(rFebReceived)
        db.context.insert(rMarGiven)
        db.context.insert(rMarReceived)
        try db.context.save()

        let vm = MonthlyDetailViewModel()
        vm.load(period: .month(year: 2026, month: 3), context: db.context)

        #expect(vm.periodExpense == 400)
        #expect(vm.periodIncome == 300)
        #expect(vm.prevExpense == 200)
        #expect(vm.prevIncome == 100)
        #expect(vm.expenseTrend == 1.0)
        #expect(vm.incomeTrend == 2.0)
    }

    @Test func testEventTypeSlices() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let weddingEvent = SampleData.event(name: "婚礼", type: .wedding)
        let birthdayEvent = SampleData.event(name: "生日", type: .birthday)
        db.context.insert(contact)
        db.context.insert(weddingEvent)
        db.context.insert(birthdayEvent)

        let date = Calendar.current.date(from: DateComponents(year: 2026, month: 5, day: 10))!
        let r1 = Record(contact: contact, event: weddingEvent, amount: 600, direction: .given, date: date)
        let r2 = Record(contact: contact, event: birthdayEvent, amount: 400, direction: .given, date: date)
        db.context.insert(r1)
        db.context.insert(r2)
        try db.context.save()

        let vm = MonthlyDetailViewModel()
        vm.load(period: .month(year: 2026, month: 5), context: db.context)

        #expect(vm.eventTypeSlices.count == 2)
        #expect(vm.eventTypeSlices[0].amount == 600)
        #expect(vm.eventTypeSlices[0].type == .wedding)
    }

    @Test func testQuarterLoad() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)

        let cal = Calendar.current
        let janDate = cal.date(from: DateComponents(year: 2026, month: 1, day: 15))!
        let marDate = cal.date(from: DateComponents(year: 2026, month: 3, day: 15))!
        let aprDate = cal.date(from: DateComponents(year: 2026, month: 4, day: 15))!

        let r1 = Record(contact: contact, event: event, amount: 100, direction: .given, date: janDate)
        let r2 = Record(contact: contact, event: event, amount: 200, direction: .given, date: marDate)
        let r3 = Record(contact: contact, event: event, amount: 300, direction: .given, date: aprDate)
        db.context.insert(r1)
        db.context.insert(r2)
        db.context.insert(r3)
        try db.context.save()

        let vm = MonthlyDetailViewModel()
        vm.load(period: .quarter(year: 2026, quarter: 1), context: db.context)

        #expect(vm.records.count == 2)
        #expect(vm.periodExpense == 300)
    }
}
