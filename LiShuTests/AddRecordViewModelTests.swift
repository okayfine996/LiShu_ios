//
//  AddRecordViewModelTests.swift
//  LiShuTests
//

import Foundation
import Testing
import SwiftData
@testable import LiShu

@MainActor
struct AddRecordViewModelTests {

    @Test func testIsValidMissingContact() throws {
        let db = try TestDB()
        let vm = AddRecordViewModel()
        vm.loadData(context: db.context)
        let event = SampleData.event()
        db.context.insert(event)

        vm.selectedContact = nil
        vm.selectedEvent = event
        vm.amountText = "500"

        #expect(vm.isValid == false)
    }

    @Test func testIsValidMissingEvent() throws {
        let db = try TestDB()
        let vm = AddRecordViewModel()
        vm.loadData(context: db.context)
        let contact = SampleData.contact()
        db.context.insert(contact)

        vm.selectedContact = contact
        vm.selectedEvent = nil
        vm.amountText = "500"

        #expect(vm.isValid == false)
    }

    @Test func testIsValidZeroAmount() throws {
        let db = try TestDB()
        let vm = AddRecordViewModel()
        vm.loadData(context: db.context)
        let contact = SampleData.contact()
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)

        vm.selectedContact = contact
        vm.selectedEvent = event
        vm.amountText = "0"

        #expect(vm.isValid == false)
    }

    @Test func testIsValidAllSet() throws {
        let db = try TestDB()
        let vm = AddRecordViewModel()
        vm.loadData(context: db.context)
        let contact = SampleData.contact()
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)

        vm.selectedContact = contact
        vm.selectedEvent = event
        vm.amountText = "500"

        #expect(vm.isValid == true)
    }

    @Test func testFilteredContacts() throws {
        let db = try TestDB()
        let c1 = Contact(name: "张三", relation: "朋友")
        let c2 = Contact(name: "李四", relation: "同事")
        let c3 = Contact(name: "张伟", relation: "亲戚")
        db.context.insert(c1)
        db.context.insert(c2)
        db.context.insert(c3)
        try db.context.save()

        let vm = AddRecordViewModel()
        vm.loadData(context: db.context)
        vm.contactSearchText = "张"

        #expect(vm.filteredContacts.count == 2)
        #expect(vm.filteredContacts.map(\.name).sorted() == ["张三", "张伟"])
    }

    @Test func testSaveNewRecord() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)
        try db.context.save()

        let vm = AddRecordViewModel()
        vm.loadData(context: db.context)
        vm.selectedContact = contact
        vm.selectedEvent = event
        vm.amountText = "800"

        #expect(vm.save(context: db.context) == true)

        let descriptor = FetchDescriptor<Record>()
        let records = try db.context.fetch(descriptor)
        #expect(records.count == 1)
        #expect(records[0].amount == 800)
    }

    @Test func testSaveEditMode() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)
        let record = SampleData.record(contact: contact, event: event, amount: 500)
        db.context.insert(record)
        try db.context.save()

        let vm = AddRecordViewModel()
        vm.loadData(context: db.context)
        vm.configure(with: record)
        vm.amountText = "600"

        #expect(vm.save(context: db.context) == true)

        let descriptor = FetchDescriptor<Record>()
        let records = try db.context.fetch(descriptor)
        #expect(records.count == 1)
        #expect(records[0].amount == 600)
    }

    @Test func testLoadData() throws {
        let db = try TestDB()
        let c1 = Contact(name: "联系人1", relation: "朋友")
        let c2 = Contact(name: "联系人2", relation: "同事")
        let e1 = Event(name: "婚礼", type: .wedding, date: .now)
        db.context.insert(c1)
        db.context.insert(c2)
        db.context.insert(e1)
        try db.context.save()

        let vm = AddRecordViewModel()
        vm.loadData(context: db.context)

        #expect(vm.allContacts.count == 2)
        #expect(vm.allEvents.count == 1)
    }
}
