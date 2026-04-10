//
//  RecordDetailViewModelTests.swift
//  LiShuTests
//

import Foundation
@testable import LiShu
import SwiftData
import Testing

@MainActor
struct RecordDetailViewModelTests {
    @Test func saveReturnSuccess() throws {
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
        #expect(record.resolvedReturnedAmount == 200)
    }

    @Test func saveReturnZeroAmount() throws {
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

    @Test func saveReturnInvalidText() throws {
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

    @Test func saveReturnParsesThousandSeparator() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)
        let record = SampleData.record(contact: contact, event: event, amount: 5000, returnedAmount: 0)
        db.context.insert(record)
        try db.context.save()

        let vm = RecordDetailViewModel()
        vm.record = record
        vm.returnedAmountText = "1,000"

        #expect(vm.saveReturn(context: db.context) == true)
        #expect(record.resolvedReturnedAmount == 1000)
    }

    @Test func loadRecord() throws {
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

    @Test func directionLabelCoversAllRecordTypes() {
        let event = SampleData.event()
        let cases: [(Record, String)] = [
            (
                SampleData.record(contact: SampleData.contact(name: "金额送出"), event: event, direction: .given),
                String(localized: "record.direction.monetary.given")
            ),
            (
                SampleData.record(contact: SampleData.contact(name: "金额收到"), event: event, direction: .received),
                String(localized: "record.direction.monetary.received")
            ),
            (
                SampleData.recordGift(contact: SampleData.contact(name: "礼品送出"), event: event, direction: .given),
                String(localized: "record.direction.gift.given")
            ),
            (
                SampleData.recordGift(contact: SampleData.contact(name: "礼品收到"), event: event, direction: .received),
                String(localized: "record.direction.gift.received")
            ),
            (
                SampleData.recordFavor(contact: SampleData.contact(name: "帮忙送出"), event: event, direction: .given),
                String(localized: "record.direction.favor.given")
            ),
            (
                SampleData.recordFavor(contact: SampleData.contact(name: "帮忙收到"), event: event, direction: .received),
                String(localized: "record.direction.favor.received")
            ),
            (
                SampleData.recordBanquet(contact: SampleData.contact(name: "宴请送出"), event: event, direction: .given),
                String(localized: "record.direction.banquet.given")
            ),
            (
                SampleData.recordBanquet(contact: SampleData.contact(name: "宴请收到"), event: event, direction: .received),
                String(localized: "record.direction.banquet.received")
            ),
        ]

        for (record, expected) in cases {
            let vm = RecordDetailViewModel()
            vm.record = record
            #expect(vm.directionLabel == expected)
        }
    }
}
