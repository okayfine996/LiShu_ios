import Foundation
import Testing
import SwiftData
@testable import LiShu

@MainActor
struct ContactDetailViewModelTests {

    @Test func testLoadContact() throws {
        let db = try TestDB()
        let contact = SampleData.contact(name: "张三")
        db.context.insert(contact)
        try db.context.save()

        let vm = ContactDetailViewModel()
        vm.load(id: contact.persistentModelID, context: db.context)

        #expect(vm.contact != nil)
        #expect(vm.contact?.name == "张三")
        #expect(vm.isLoading == false)
    }

    @Test func testSortedRecords() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)

        let cal = Calendar.current
        let oldDate = cal.date(byAdding: .day, value: -10, to: .now)!
        let newDate = cal.date(byAdding: .day, value: -1, to: .now)!

        let oldRecord = Record(contact: contact, event: event, amount: 100, direction: .given, date: oldDate)
        let newRecord = Record(contact: contact, event: event, amount: 200, direction: .given, date: newDate)
        db.context.insert(oldRecord)
        db.context.insert(newRecord)
        try db.context.save()

        let vm = ContactDetailViewModel()
        vm.load(id: contact.persistentModelID, context: db.context)

        let sorted = vm.sortedRecords
        #expect(sorted.count == 2)
        #expect(sorted[0].monetaryAmount == 200)
        #expect(sorted[1].monetaryAmount == 100)
    }

    @Test func testDeleteContact() throws {
        let db = try TestDB()
        let contact = SampleData.contact(name: "待删除")
        db.context.insert(contact)
        try db.context.save()

        let vm = ContactDetailViewModel()
        vm.load(id: contact.persistentModelID, context: db.context)

        #expect(vm.deleteContact(context: db.context) == true)

        let contacts = try db.context.fetch(FetchDescriptor<Contact>())
        #expect(contacts.isEmpty)
    }

    @Test func testFormatAmountAndNetValue() {
        let vm = ContactDetailViewModel()

        #expect(vm.formatAmount(1200) == "¥1200")
        #expect(vm.formatAmount(0) == "¥0")

        #expect(vm.formatNetValue(500) == "+¥500")
        #expect(vm.formatNetValue(-300) == "¥-300")
        #expect(vm.formatNetValue(0) == "+¥0")
    }

    @Test func testCircleText() {
        let vm = ContactDetailViewModel()

        let family = vm.circleText(1)
        let relative = vm.circleText(2)
        let social = vm.circleText(3)
        let other = vm.circleText(99)

        #expect(!family.isEmpty)
        #expect(!relative.isEmpty)
        #expect(!social.isEmpty)
        #expect(!other.isEmpty)
        #expect(family != social)
    }
}
