//
//  RecordDetailViewModelTests.swift
//  LiShuTests
//

import Foundation
import Testing
import SwiftData
@testable import LiShu

@MainActor
struct RecordDetailViewModelTests {

    @Test func testSaveReturnSuccess() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)
        let record = SampleData.record(contact: contact, event: event, amount: 500, returnedAmount: 0)
        db.context.insert(record)
        try db.context.save()

        let vm = RecordDetailViewModel()
        vm.record = record
        vm.returnedAmountText = "200"

        #expect(vm.saveReturn(context: db.context) == true)
        #expect(record.returnedAmount == 200)
    }

    @Test func testSaveReturnZeroAmount() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)
        let record = SampleData.record(contact: contact, event: event)
        db.context.insert(record)
        try db.context.save()

        let vm = RecordDetailViewModel()
        vm.record = record
        vm.returnedAmountText = "0"

        #expect(vm.saveReturn(context: db.context) == false)
    }

    @Test func testSaveReturnInvalidText() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)
        let record = SampleData.record(contact: contact, event: event)
        db.context.insert(record)
        try db.context.save()

        let vm = RecordDetailViewModel()
        vm.record = record
        vm.returnedAmountText = "abc"

        #expect(vm.saveReturn(context: db.context) == false)
    }

    @Test func testDeleteRecord() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)
        let record = SampleData.record(contact: contact, event: event)
        db.context.insert(record)
        try db.context.save()

        let vm = RecordDetailViewModel()
        vm.record = record

        #expect(vm.deleteRecord(context: db.context) == true)

        let descriptor = FetchDescriptor<Record>()
        let records = try db.context.fetch(descriptor)
        #expect(records.isEmpty)
    }

    @Test func testFormattedAmount() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)
        let record = SampleData.record(contact: contact, event: event, amount: 1000)
        db.context.insert(record)

        let vm = RecordDetailViewModel()
        vm.record = record

        #expect(vm.formattedAmount == "¥1000")
    }

    @Test func testLoadRecord() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)
        let record = SampleData.record(contact: contact, event: event)
        db.context.insert(record)
        try db.context.save()

        let vm = RecordDetailViewModel()
        vm.load(id: record.persistentModelID, context: db.context)

        #expect(vm.record != nil)
        #expect(vm.record?.monetaryAmount == 500)
    }
}
