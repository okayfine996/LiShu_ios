//
//  ContactModelTests.swift
//  LiShuTests
//

import Foundation
@testable import LiShu
import SwiftData
import Testing

@MainActor
struct ContactModelTests {
    @Test func defaultValues() throws {
        let db = try TestDB()
        let contact = Contact(name: "测试")
        db.context.insert(contact)

        #expect(contact.circle == 4)
        #expect(contact.phone.isEmpty)
        #expect(contact.records?.isEmpty != false)
    }

    @Test func testNetValue() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event1 = SampleData.event(name: "婚礼1")
        let event2 = SampleData.event(name: "婚礼2")
        db.context.insert(contact)
        db.context.insert(event1)
        db.context.insert(event2)

        let given = SampleData.record(contact: contact, event: event1, amount: 500, direction: .given, returnedAmount: 100)
        let received = SampleData.record(contact: contact, event: event2, amount: 800, direction: .received, returnedAmount: 200)
        db.context.insert(given)
        db.context.insert(received)

        try db.context.save()

        let receivedNet: Double = 800 - 200
        let givenNet: Double = 500 - 100
        #expect(contact.netValue == receivedNet - givenNet)
    }

    @Test func cascadeDeleteRemovesRecords() throws {
        let db = try TestDB()
        let contact = SampleData.contact(name: "待删除")
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)

        let r1 = SampleData.record(contact: contact, event: event, amount: 500)
        let r2 = SampleData.record(contact: contact, event: event, amount: 300)
        db.context.insert(r1)
        db.context.insert(r2)
        try db.context.save()

        #expect(try db.context.fetchCount(FetchDescriptor<Record>()) == 2)

        db.context.delete(contact)
        try db.context.save()

        #expect(try db.context.fetchCount(FetchDescriptor<Contact>()) == 0)
        #expect(try db.context.fetchCount(FetchDescriptor<Record>()) == 0)
    }

    @Test func totalGivenAndReceived() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event1 = SampleData.event(name: "婚礼1")
        let event2 = SampleData.event(name: "婚礼2")
        db.context.insert(contact)
        db.context.insert(event1)
        db.context.insert(event2)

        let given1 = SampleData.record(contact: contact, event: event1, amount: 500, direction: .given)
        let given2 = SampleData.record(contact: contact, event: event2, amount: 300, direction: .given)
        let received1 = SampleData.record(contact: contact, event: event1, amount: 1000, direction: .received)
        db.context.insert(given1)
        db.context.insert(given2)
        db.context.insert(received1)

        try db.context.save()

        #expect(contact.totalGiven == 800)
        #expect(contact.totalReceived == 1000)
        #expect(contact.totalReturned == 0)
    }
}
