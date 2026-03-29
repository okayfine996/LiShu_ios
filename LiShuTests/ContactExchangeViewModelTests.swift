import Foundation
import Testing
import SwiftData
@testable import LiShu

@MainActor
struct ContactExchangeViewModelTests {

    @Test("load contact and records by persistentModelID")
    func testLoadContact() throws {
        let db = try TestDB()
        let contact = SampleData.contact(name: "往来人")
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)
        let r = SampleData.record(contact: contact, event: event, amount: 500, direction: .given)
        db.context.insert(r)
        try db.context.save()

        let vm = ContactExchangeViewModel()
        vm.load(contactID: contact.persistentModelID, context: db.context)

        #expect(vm.contact?.name == "往来人")
        #expect(vm.records.count == 1)
    }

    @Test("totalGiven and totalReceived compute correctly")
    func testTotalGivenAndReceived() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)

        let r1 = SampleData.record(contact: contact, event: event, amount: 1000, direction: .given)
        let r2 = SampleData.record(contact: contact, event: event, amount: 600, direction: .received)
        let r3 = SampleData.record(contact: contact, event: event, amount: 400, direction: .given)
        db.context.insert(r1)
        db.context.insert(r2)
        db.context.insert(r3)
        try db.context.save()

        let vm = ContactExchangeViewModel()
        vm.load(contactID: contact.persistentModelID, context: db.context)

        #expect(vm.totalGiven == 1400)
        #expect(vm.totalReceived == 600)
    }

    @Test("netValue and netLabel: positive=theyOwe, negative=iOwe, zero=even")
    func testNetValueAndLabel() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)

        let r1 = SampleData.record(contact: contact, event: event, amount: 500, direction: .given)
        let r2 = SampleData.record(contact: contact, event: event, amount: 500, direction: .received)
        db.context.insert(r1)
        db.context.insert(r2)
        try db.context.save()

        let vm = ContactExchangeViewModel()
        vm.load(contactID: contact.persistentModelID, context: db.context)

        #expect(vm.netValue == 0)
        #expect(!vm.netLabel.isEmpty)

        // Positive net: received > given
        let r3 = SampleData.record(contact: contact, event: event, amount: 200, direction: .received)
        db.context.insert(r3)
        try db.context.save()
        vm.load(contactID: contact.persistentModelID, context: db.context)
        #expect(vm.netValue > 0)

        // Negative net: given > received
        let r4 = SampleData.record(contact: contact, event: event, amount: 1000, direction: .given)
        db.context.insert(r4)
        try db.context.save()
        vm.load(contactID: contact.persistentModelID, context: db.context)
        #expect(vm.netValue < 0)
    }

    @Test("givenRatio: no records returns 0.5, with records returns given/(given+received)")
    func testGivenRatio() throws {
        let vm = ContactExchangeViewModel()
        #expect(vm.givenRatio == 0.5)

        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)
        let r1 = SampleData.record(contact: contact, event: event, amount: 600, direction: .given)
        let r2 = SampleData.record(contact: contact, event: event, amount: 400, direction: .received)
        db.context.insert(r1)
        db.context.insert(r2)
        try db.context.save()

        vm.load(contactID: contact.persistentModelID, context: db.context)
        #expect(vm.givenRatio == 0.6)
    }

    @Test("records sorted by date descending")
    func testRecordsSortedByDate() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)

        let cal = Calendar.current
        let date1 = cal.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        let date2 = cal.date(from: DateComponents(year: 2026, month: 6, day: 15))!
        let date3 = cal.date(from: DateComponents(year: 2025, month: 6, day: 1))!

        let r1 = SampleData.record(contact: contact, event: event, amount: 100, date: date1)
        let r2 = SampleData.record(contact: contact, event: event, amount: 200, date: date2)
        let r3 = SampleData.record(contact: contact, event: event, amount: 300, date: date3)
        db.context.insert(r1)
        db.context.insert(r2)
        db.context.insert(r3)
        try db.context.save()

        let vm = ContactExchangeViewModel()
        vm.load(contactID: contact.persistentModelID, context: db.context)

        #expect(vm.records.count == 3)
        #expect(vm.records[0].date >= vm.records[1].date)
        #expect(vm.records[1].date >= vm.records[2].date)
    }

    @Test("lastContactText returns nil when no records, non-nil with records")
    func testLastContactText() throws {
        let vm = ContactExchangeViewModel()
        #expect(vm.lastContactText == nil)

        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)

        let pastDate = Calendar.current.date(byAdding: .day, value: -5, to: .now)!
        let r = SampleData.record(contact: contact, event: event, amount: 100, date: pastDate)
        db.context.insert(r)
        try db.context.save()

        vm.load(contactID: contact.persistentModelID, context: db.context)
        #expect(vm.lastContactText != nil)
    }

    @Test("formatAmount includes yen sign and 2 decimal places")
    func testFormatAmountAndNetAmount() {
        let vm = ContactExchangeViewModel()
        let amount = vm.formatAmount(1234.56)
        #expect(amount.hasPrefix("¥"))
        #expect(amount.contains("1,234.56") || amount.contains("1234.56"))

        vm.records = []
        let net = vm.formatNetAmount()
        #expect(net.hasPrefix("+"))
    }

    @Test("load with no records for contact returns empty records")
    func testLoadContactWithNoRecords() throws {
        let db = try TestDB()
        let contact = SampleData.contact(name: "无记录人")
        db.context.insert(contact)
        try db.context.save()

        let vm = ContactExchangeViewModel()
        vm.load(contactID: contact.persistentModelID, context: db.context)

        #expect(vm.contact?.name == "无记录人")
        #expect(vm.records.isEmpty)
        #expect(vm.totalGiven == 0)
        #expect(vm.totalReceived == 0)
        #expect(vm.netValue == 0)
    }
}
