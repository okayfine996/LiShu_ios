//
//  EventModelTests.swift
//  LiShuTests
//

import Foundation
import Testing
import SwiftData
@testable import LiShu

@MainActor
struct EventModelTests {

    @Test func testTypeComputedProperty() throws {
        let db = try TestDB()
        let event = SampleData.event()
        db.context.insert(event)

        #expect(event.type == .wedding)
        #expect(event.typeRaw == "wedding")

        event.type = .birthday
        #expect(event.type == .birthday)
        #expect(event.typeRaw == "birthday")
    }

    @Test func testDefaultValues() throws {
        let event = Event(name: "测试", type: .other, date: .now, location: "", note: "")
        #expect(event.type == .other)
        #expect(event.location.isEmpty)
    }

    @Test func testDenyDeleteWhenRecordsExist() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event(name: "有记录的事件")
        db.context.insert(contact)
        db.context.insert(event)

        let record = SampleData.record(contact: contact, event: event)
        db.context.insert(record)
        try db.context.save()

        db.context.delete(event)

        var didThrow = false
        do {
            try db.context.save()
        } catch {
            didThrow = true
        }
        #expect(didThrow == true)
    }

    @Test func testDeleteWithoutRecordsSucceeds() throws {
        let db = try TestDB()
        let event = SampleData.event(name: "无记录事件")
        db.context.insert(event)
        try db.context.save()

        db.context.delete(event)
        try db.context.save()

        #expect(try db.context.fetchCount(FetchDescriptor<Event>()) == 0)
    }

    @Test func testInitWithType() throws {
        let event = Event(name: "婚礼", type: .wedding, date: .now, location: "北京")
        #expect(event.typeRaw == "wedding")
        #expect(event.type == .wedding)
    }
}
