//
//  RecordModelTests.swift
//  LiShuTests
//

import Foundation
import Testing
import SwiftData
@testable import LiShu

@MainActor
struct RecordModelTests {

    @Test func testUpdateStatusOpen() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)

        let record = SampleData.record(contact: contact, event: event, amount: 500, returnedAmount: 0)
        db.context.insert(record)

        record.updateStatus()
        #expect(record.status == .open)
    }

    @Test func testUpdateStatusPartial() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)

        let record = SampleData.record(contact: contact, event: event, amount: 500, returnedAmount: 200)
        db.context.insert(record)

        record.updateStatus()
        #expect(record.status == .partial)
    }

    @Test func testUpdateStatusSettled() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)

        let record = SampleData.record(contact: contact, event: event, amount: 500, returnedAmount: 500)
        db.context.insert(record)

        record.updateStatus()
        #expect(record.status == .settled)
    }

    @Test func testOutstandingAmount() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)

        let record = SampleData.record(contact: contact, event: event, amount: 500, returnedAmount: 200)
        db.context.insert(record)

        #expect(record.outstandingAmount == 300)
    }

    @Test func testDirectionComputedProperty() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)

        let record = SampleData.record(contact: contact, event: event)
        db.context.insert(record)

        #expect(record.direction == .given)
        record.direction = .received
        #expect(record.direction == .received)
        #expect(record.directionRaw == "received")
    }

    @Test func testPaymentMethodComputedProperty() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)

        let record = SampleData.record(contact: contact, event: event)
        db.context.insert(record)

        #expect(record.paymentMethod == .cash)
        record.paymentMethod = .wechat
        #expect(record.paymentMethod == .wechat)
        #expect(record.paymentMethodRaw == "wechat")
    }

    @Test func testRecordPhotoRelationship() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)

        let record = SampleData.record(contact: contact, event: event)
        db.context.insert(record)

        let photo1 = SampleData.recordPhoto(record: record, data: Data([0x01]))
        let photo2 = SampleData.recordPhoto(record: record, data: Data([0x02]))
        db.context.insert(photo1)
        db.context.insert(photo2)
        try db.context.save()

        #expect(record.photos?.count == 2)
    }

    @Test func testRecordCascadeDeleteRemovesPhotos() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)

        let record = SampleData.record(contact: contact, event: event)
        db.context.insert(record)

        let photo = SampleData.recordPhoto(record: record)
        db.context.insert(photo)
        try db.context.save()

        #expect(try db.context.fetchCount(FetchDescriptor<RecordPhoto>()) == 1)

        db.context.delete(record)
        try db.context.save()

        #expect(try db.context.fetchCount(FetchDescriptor<RecordPhoto>()) == 0)
    }

    @Test func testInitSetsStatusViaUpdateStatus() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)

        let record = Record(contact: contact, event: event, amount: 500, returnedAmount: 500)
        db.context.insert(record)

        #expect(record.status == .settled)
    }
}
