//
//  HomeViewModelTests.swift
//  LiShuTests
//

import Foundation
@testable import LiShu
import SwiftData
import Testing

@MainActor
struct HomeViewModelTests {
    @Test func loadEmptyDatabase() throws {
        let db = try TestDB()
        let vm = HomeViewModel()
        vm.load(context: db.context)

        #expect(vm.yearlyIncome == 0)
        #expect(vm.yearlyExpense == 0)
        #expect(vm.contactCount == 0)
        #expect(vm.recordCount == 0)
    }

    @Test func loadWithRecords() throws {
        let db = try TestDB()
        let vm = HomeViewModel()
        let calendar = Calendar.current
        let year = vm.currentYear
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

        vm.load(context: db.context)

        #expect(vm.yearlyIncome == 800)
        #expect(vm.yearlyExpense == 500)
    }

    @Test func formattedIncomeUnder10000() {
        let vm = HomeViewModel()
        vm.yearlyIncome = 5000
        #expect(vm.formattedIncome == "¥5000")
    }

    @Test func formattedIncomeOver10000() {
        let vm = HomeViewModel()
        vm.yearlyIncome = 15000
        #expect(vm.formattedIncome == "¥1.5万")
    }

    @Test func testRecentRecords() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)

        for i in 0 ..< 10 {
            let record = SampleData.record(contact: contact, event: event)
            record.date = Calendar.current.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            db.context.insert(record)
        }
        try db.context.save()

        let vm = HomeViewModel()
        vm.load(context: db.context)

        #expect(vm.recentRecords.count == 5)
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

        let vm = HomeViewModel()
        vm.load(context: db.context)

        #expect(vm.upcomingEvents.allSatisfy { $0.date >= Calendar.current.startOfDay(for: Date()) })
        #expect(vm.upcomingEvents.contains { $0.name == "未来" })
    }

    @Test func testHostLedgerEvents() throws {
        let db = try TestDB()
        let hostEvent = SampleData.event(name: "我的婚礼", hostMode: .host)
        let guestEvent = SampleData.event(name: "别人的婚礼", hostMode: .guest)
        db.context.insert(hostEvent)
        db.context.insert(guestEvent)
        try db.context.save()

        let vm = HomeViewModel()
        vm.load(context: db.context)

        #expect(vm.hostLedgerEvents.count == 1)
        #expect(vm.hostLedgerEvents.first?.name == "我的婚礼")
    }
}
