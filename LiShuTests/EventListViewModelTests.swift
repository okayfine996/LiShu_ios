import Foundation
@testable import LiShu
import SwiftData
import Testing

@MainActor
struct EventListViewModelTests {
    @Test("load returns events in state")
    func loadEvents() throws {
        let db = try TestDB()
        let e1 = SampleData.event(name: "婚礼1")
        let e2 = SampleData.event(name: "生日1")
        db.context.insert(e1)
        db.context.insert(e2)
        try db.context.save()

        let vm = EventListViewModel()
        vm.load(context: db.context)

        #expect(vm.state.value != nil)
        #expect(vm.state.value?.count == 2)
    }

    @Test("upcoming vs past events classified correctly")
    func upcomingVsPast() throws {
        let db = try TestDB()
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let futureDate = try #require(cal.date(byAdding: .day, value: 7, to: today))
        let pastDate = try #require(cal.date(byAdding: .day, value: -7, to: today))

        let eFuture = SampleData.event(name: "未来", date: futureDate)
        let ePast = SampleData.event(name: "过去", date: pastDate)
        db.context.insert(eFuture)
        db.context.insert(ePast)
        try db.context.save()

        let vm = EventListViewModel()
        vm.load(context: db.context)

        #expect(vm.upcomingEvents.count == 1)
        #expect(vm.upcomingEvents.first?.name == "未来")
        #expect(vm.pastEvents.count == 1)
        #expect(try #require(vm.pastEvents.first?.name == "过去"))
    }

    @Test("selectedTypeFilter filters events by type")
    func filteredByType() throws {
        let db = try TestDB()
        let e1 = SampleData.event(name: "婚礼", type: .wedding)
        let e2 = SampleData.event(name: "生日", type: .birthday)
        db.context.insert(e1)
        db.context.insert(e2)
        try db.context.save()

        let vm = EventListViewModel()
        vm.load(context: db.context)
        vm.selectedTypeFilter = .wedding

        #expect(vm.filteredUpcomingEvents.count == 1)
        #expect(vm.filteredUpcomingEvents.first?.type == .wedding)
    }

    @Test("daysUntil returns 5 for date 5 days from now")
    func testDaysUntil() throws {
        let vm = EventListViewModel()
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let future = try #require(cal.date(byAdding: .day, value: 5, to: today))
        #expect(vm.daysUntil(future) == 5)
    }

    @Test("daysUntil returns -3 for date 3 days ago")
    func daysUntilPast() throws {
        let vm = EventListViewModel()
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let past = try #require(cal.date(byAdding: .day, value: -3, to: today))
        #expect(vm.daysUntil(past) == -3)
    }

    @Test("formatEventDate returns M月d日 format")
    func testFormatEventDate() throws {
        let vm = EventListViewModel()
        let cal = Calendar.current
        var comps = DateComponents()
        comps.year = 2025
        comps.month = 3
        comps.day = 1
        let date = try #require(cal.date(from: comps))
        let formatted = vm.formatEventDate(date)
        #expect(formatted == "3月1日")
    }

    @Test("deleteEvent removes event (no records attached)")
    func testDeleteEvent() throws {
        let db = try TestDB()
        let e = SampleData.event(name: "待删除")
        db.context.insert(e)
        try db.context.save()

        let vm = EventListViewModel()
        vm.load(context: db.context)
        #expect(vm.state.value?.count == 1)

        vm.deleteEvent(e, context: db.context)
        #expect(vm.state.value?.count == 0)
    }
}
