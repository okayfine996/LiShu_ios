//
//  HomeViewModelTests.swift
//  LiShuTests
//

import Foundation
@testable import LiShu
import SwiftData
import Testing

@MainActor
struct HomeDashboardSnapshotTests {
    @Test func buildEmptyDatabase() throws {
        let db = try TestDB()
        let snapshot = try HomeDashboardSnapshot.build(
            records: db.context.fetch(FetchDescriptor<Record>()),
            events: db.context.fetch(FetchDescriptor<Event>()),
            contacts: db.context.fetch(FetchDescriptor<Contact>())
        )

        #expect(snapshot.yearlyIncome == 0)
        #expect(snapshot.yearlyExpense == 0)
        #expect(snapshot.contactCount == 0)
        #expect(snapshot.recordCount == 0)
    }

    @Test func buildWithRecords() throws {
        let db = try TestDB()
        let calendar = Calendar.current
        let year = calendar.component(.year, from: .now)
        guard let startOfYear = calendar.date(from: DateComponents(year: year, month: 1, day: 1)) else {
            Issue.record("Could not create start of year")
            return
        }

        let contact = SampleData.contact()
        let eventGiven = SampleData.event(date: startOfYear)
        let eventReceived = SampleData.event(name: "收礼", date: startOfYear)
        db.context.insert(contact)
        db.context.insert(eventGiven)
        db.context.insert(eventReceived)

        let given = SampleData.record(contact: contact, event: eventGiven, amount: 500, direction: .given)
        let received = SampleData.record(contact: contact, event: eventReceived, amount: 800, direction: .received)
        db.context.insert(given)
        db.context.insert(received)
        try db.context.save()

        let snapshot = try HomeDashboardSnapshot.build(
            records: db.context.fetch(FetchDescriptor<Record>()),
            events: db.context.fetch(FetchDescriptor<Event>()),
            contacts: db.context.fetch(FetchDescriptor<Contact>())
        )

        #expect(snapshot.yearlyIncome == 800)
        #expect(snapshot.yearlyExpense == 500)
    }

    @Test func buildCountsActiveContactsFromCurrentYearRecords() throws {
        let db = try TestDB()
        let calendar = Calendar.current
        let year = calendar.component(.year, from: .now)
        let currentYearDate = try #require(calendar.date(from: DateComponents(year: year, month: 2, day: 1)))
        let previousYearDate = try #require(calendar.date(from: DateComponents(year: year - 1, month: 2, day: 1)))

        let contactCurrent = SampleData.contact(name: "今年联系人")
        let contactPrevious = SampleData.contact(name: "去年联系人")
        let eventCurrent = SampleData.event(date: currentYearDate)
        let eventPrevious = SampleData.event(date: previousYearDate)
        db.context.insert(contactCurrent)
        db.context.insert(contactPrevious)
        db.context.insert(eventCurrent)
        db.context.insert(eventPrevious)
        db.context.insert(
            SampleData.record(contact: contactCurrent, event: eventCurrent, amount: 500, direction: .given, date: currentYearDate)
        )
        db.context.insert(
            SampleData.record(contact: contactPrevious, event: eventPrevious, amount: 300, direction: .given, date: previousYearDate)
        )
        try db.context.save()

        let snapshot = try HomeDashboardSnapshot.build(
            records: db.context.fetch(FetchDescriptor<Record>()),
            events: db.context.fetch(FetchDescriptor<Event>()),
            contacts: db.context.fetch(FetchDescriptor<Contact>())
        )

        #expect(snapshot.contactCount == 1)
        #expect(snapshot.recordCount == 1)
    }

    @Test func testRecentRecords() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)

        for i in 0..<10 {
            let record = SampleData.record(contact: contact, event: event)
            record.date = Calendar.current.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            db.context.insert(record)
        }
        try db.context.save()

        let snapshot = try HomeDashboardSnapshot.build(
            records: db.context.fetch(FetchDescriptor<Record>()),
            events: db.context.fetch(FetchDescriptor<Event>()),
            contacts: db.context.fetch(FetchDescriptor<Contact>())
        )

        #expect(snapshot.recentRecords.count == 5)
    }

    @Test func testUpcomingEvents() throws {
        let db = try TestDB()
        let pastDate = Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date()
        let futureDate = Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date()

        let pastEvent = SampleData.event(name: "过去", date: pastDate)
        let futureEvent = SampleData.event(name: "未来", date: futureDate)
        db.context.insert(pastEvent)
        db.context.insert(futureEvent)
        try db.context.save()

        let snapshot = try HomeDashboardSnapshot.build(
            records: db.context.fetch(FetchDescriptor<Record>()),
            events: db.context.fetch(FetchDescriptor<Event>()),
            contacts: db.context.fetch(FetchDescriptor<Contact>())
        )

        #expect(snapshot.upcomingEvents.allSatisfy { $0.date >= Calendar.current.startOfDay(for: Date()) })
        #expect(snapshot.upcomingEvents.contains { $0.name == "未来" })
    }

    @Test func testHostLedgerEvents() throws {
        let db = try TestDB()
        let hostEvent = SampleData.event(name: "我的婚礼", hostMode: .host)
        let guestEvent = SampleData.event(name: "别人的婚礼", hostMode: .guest)
        db.context.insert(hostEvent)
        db.context.insert(guestEvent)
        try db.context.save()

        let snapshot = try HomeDashboardSnapshot.build(
            records: db.context.fetch(FetchDescriptor<Record>()),
            events: db.context.fetch(FetchDescriptor<Event>()),
            contacts: db.context.fetch(FetchDescriptor<Contact>())
        )

        #expect(snapshot.hostLedgerEvents.count == 1)
        #expect(snapshot.hostLedgerEvents.first?.name == "我的婚礼")
    }

    @Test func contactEditsAffectMostActiveContactName() throws {
        let db = try TestDB()
        let contact = SampleData.contact(name: "旧名字")
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)
        db.context.insert(SampleData.record(contact: contact, event: event, amount: 100, direction: .given))
        try db.context.save()

        contact.name = "新名字"
        try db.context.save()

        let snapshot = try HomeDashboardSnapshot.build(
            records: db.context.fetch(FetchDescriptor<Record>()),
            events: db.context.fetch(FetchDescriptor<Event>()),
            contacts: db.context.fetch(FetchDescriptor<Contact>())
        )

        #expect(snapshot.mostActiveContactName == "新名字")
    }
}
