import Foundation
import Testing
import SwiftData
@testable import LiShu

@MainActor
struct CircleDetailViewModelTests {

    @Test("load circle with contacts computes memberCount, totalIncome, totalExpense, netValue")
    func testLoadCircleWithContacts() throws {
        let db = try TestDB()
        let c1 = SampleData.contact(name: "家人A", circle: 1)
        let c2 = SampleData.contact(name: "家人B", circle: 1)
        let e = SampleData.event()
        db.context.insert(c1)
        db.context.insert(c2)
        db.context.insert(e)

        let r1 = SampleData.record(contact: c1, event: e, amount: 1000, direction: .given)
        let r2 = SampleData.record(contact: c1, event: e, amount: 500, direction: .received)
        let r3 = SampleData.record(contact: c2, event: e, amount: 800, direction: .given)
        db.context.insert(r1)
        db.context.insert(r2)
        db.context.insert(r3)
        try db.context.save()

        let vm = CircleDetailViewModel()
        let year = Calendar.current.component(.year, from: .now)
        vm.load(circle: 1, year: year, context: db.context)

        #expect(vm.memberCount == 2)
        #expect(vm.totalIncome == 500)
        #expect(vm.totalExpense == 1800)
        #expect(vm.netValue == 500 - 1800)
        #expect(vm.totalAmount == 500 + 1800)
        if case .loaded = vm.state {} else {
            Issue.record("State should be .loaded")
        }
    }

    @Test("load empty circle returns 0 values")
    func testLoadEmptyCircle() throws {
        let db = try TestDB()
        let vm = CircleDetailViewModel()
        let year = Calendar.current.component(.year, from: .now)
        vm.load(circle: 4, year: year, context: db.context)

        #expect(vm.memberCount == 0)
        #expect(vm.totalIncome == 0)
        #expect(vm.totalExpense == 0)
        #expect(vm.netValue == 0)
        #expect(vm.totalAmount == 0)
        #expect(vm.members.isEmpty)
    }

    @Test("members sorted by absolute netValue descending")
    func testMembersSortedByAbsNetValue() throws {
        let db = try TestDB()
        let c1 = SampleData.contact(name: "小额", circle: 3)
        let c2 = SampleData.contact(name: "大额", circle: 3)
        let c3 = SampleData.contact(name: "中额", circle: 3)
        let e = SampleData.event()
        for c in [c1, c2, c3] { db.context.insert(c) }
        db.context.insert(e)

        let r1 = SampleData.record(contact: c1, event: e, amount: 100, direction: .given)
        let r2 = SampleData.record(contact: c2, event: e, amount: 1000, direction: .given)
        let r3 = SampleData.record(contact: c3, event: e, amount: 500, direction: .given)
        db.context.insert(r1)
        db.context.insert(r2)
        db.context.insert(r3)
        try db.context.save()

        let vm = CircleDetailViewModel()
        let year = Calendar.current.component(.year, from: .now)
        vm.load(circle: 3, year: year, context: db.context)

        #expect(vm.members.count == 3)
        #expect(vm.members[0].contact.name == "大额")
        #expect(vm.members[1].contact.name == "中额")
        #expect(vm.members[2].contact.name == "小额")
    }

    @Test("averageAmount and averageNetValue computed correctly")
    func testAverageAmountAndNetValue() throws {
        let db = try TestDB()
        let c1 = SampleData.contact(name: "A", circle: 2)
        let c2 = SampleData.contact(name: "B", circle: 2)
        let e = SampleData.event()
        db.context.insert(c1)
        db.context.insert(c2)
        db.context.insert(e)

        let r1 = SampleData.record(contact: c1, event: e, amount: 600, direction: .given)
        let r2 = SampleData.record(contact: c2, event: e, amount: 400, direction: .received)
        db.context.insert(r1)
        db.context.insert(r2)
        try db.context.save()

        let vm = CircleDetailViewModel()
        let year = Calendar.current.component(.year, from: .now)
        vm.load(circle: 2, year: year, context: db.context)

        #expect(vm.totalAmount == 1000)
        #expect(vm.averageAmount == 500)
        #expect(vm.netValue == 400 - 600)
        #expect(vm.averageNetValue == (400 - 600) / 2.0)
    }

    @Test("circleDisplayName returns correct names for circles 1-4")
    func testCircleDisplayName() {
        let vm = CircleDetailViewModel()

        let name1 = vm.circleDisplayName(1)
        let name2 = vm.circleDisplayName(2)
        let name3 = vm.circleDisplayName(3)
        let name4 = vm.circleDisplayName(99)

        #expect(!name1.isEmpty)
        #expect(!name2.isEmpty)
        #expect(!name3.isEmpty)
        #expect(!name4.isEmpty)
        #expect(name1 != name2)
        #expect(name2 != name3)
    }

    @Test("formatAmount formats with yen prefix")
    func testFormatAmount() {
        let vm = CircleDetailViewModel()
        let result = vm.formatAmount(5000)
        #expect(result.hasPrefix("¥"))
        #expect(result.contains("5,000") || result.contains("5000"))
    }

    @Test("formatCompactAmount uses 'w' suffix for >= 10000")
    func testFormatCompactAmount() {
        let vm = CircleDetailViewModel()

        let small = vm.formatCompactAmount(5000)
        #expect(!small.contains("w"))
        #expect(small.contains("5,000") || small.contains("5000"))

        let large = vm.formatCompactAmount(15000)
        #expect(large.contains("w"))
        #expect(large.contains("1.5"))
    }

    @Test("formatNetValue: positive gets + prefix, negative no prefix")
    func testFormatNetValue() {
        let vm = CircleDetailViewModel()

        let positive = vm.formatNetValue(1000)
        #expect(positive.hasPrefix("+"))
        #expect(positive.contains("¥"))

        let negative = vm.formatNetValue(-500)
        #expect(!negative.hasPrefix("+"))
        #expect(negative.contains("¥"))
        #expect(negative.contains("500"))
    }
}
