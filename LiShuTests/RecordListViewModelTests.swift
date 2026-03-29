import Foundation
import Foundation
import Testing
import SwiftData
@testable import LiShu

@MainActor
struct RecordListViewModelTests {

    @Test("load with filter=all returns all 3 records")
    func testLoadAllRecords() throws {
        let db = try TestDB()
        let c1 = SampleData.contact(name: "张三")
        let c2 = SampleData.contact(name: "李四")
        let c3 = SampleData.contact(name: "王五")
        let e = SampleData.event()
        db.context.insert(c1)
        db.context.insert(c2)
        db.context.insert(c3)
        db.context.insert(e)
        let r1 = SampleData.record(contact: c1, event: e)
        let r2 = SampleData.record(contact: c2, event: e)
        let r3 = SampleData.record(contact: c3, event: e)
        db.context.insert(r1)
        db.context.insert(r2)
        db.context.insert(r3)
        try db.context.save()

        let vm = RecordListViewModel()
        vm.filter = .all
        vm.load(context: db.context)

        let grouped = vm.state.value
        #expect(grouped != nil)
        let allRecords = grouped!.values.flatMap { $0 }
        #expect(allRecords.count == 3)
    }

    @Test("load with filter=given returns only given records")
    func testLoadFilterGiven() throws {
        let db = try TestDB()
        let c1 = SampleData.contact(name: "张三")
        let c2 = SampleData.contact(name: "李四")
        let e = SampleData.event()
        db.context.insert(c1)
        db.context.insert(c2)
        db.context.insert(e)
        let rGiven = SampleData.record(contact: c1, event: e, direction: .given)
        let rReceived = SampleData.record(contact: c2, event: e, direction: .received)
        db.context.insert(rGiven)
        db.context.insert(rReceived)
        try db.context.save()

        let vm = RecordListViewModel()
        vm.filter = .given
        vm.load(context: db.context)

        let grouped = vm.state.value
        #expect(grouped != nil)
        let records = grouped!.values.flatMap { $0 }
        #expect(records.count == 1)
        #expect(records.first!.direction == .given)
    }

    @Test("load with filter=received returns only received records")
    func testLoadFilterReceived() throws {
        let db = try TestDB()
        let c1 = SampleData.contact(name: "张三")
        let c2 = SampleData.contact(name: "李四")
        let e = SampleData.event()
        db.context.insert(c1)
        db.context.insert(c2)
        db.context.insert(e)
        let rGiven = SampleData.record(contact: c1, event: e, direction: .given)
        let rReceived = SampleData.record(contact: c2, event: e, direction: .received)
        db.context.insert(rGiven)
        db.context.insert(rReceived)
        try db.context.save()

        let vm = RecordListViewModel()
        vm.filter = .received
        vm.load(context: db.context)

        let grouped = vm.state.value
        #expect(grouped != nil)
        let records = grouped!.values.flatMap { $0 }
        #expect(records.count == 1)
        #expect(records.first!.direction == .received)
    }

    @Test("searchText filters by contact name")
    func testSearchFilter() throws {
        let db = try TestDB()
        let c1 = SampleData.contact(name: "张三")
        let c2 = SampleData.contact(name: "李四")
        let e = SampleData.event()
        db.context.insert(c1)
        db.context.insert(c2)
        db.context.insert(e)
        let r1 = SampleData.record(contact: c1, event: e)
        let r2 = SampleData.record(contact: c2, event: e)
        db.context.insert(r1)
        db.context.insert(r2)
        try db.context.save()

        let vm = RecordListViewModel()
        vm.filter = .all
        vm.searchText = "张"
        vm.load(context: db.context)

        let grouped = vm.state.value
        #expect(grouped != nil)
        let records = grouped!.values.flatMap { $0 }
        #expect(records.count == 1)
        #expect(records.first!.contact?.name == "张三")
    }

    @Test("sortedMonthKeys returns newest month first")
    func testSortedMonthKeys() throws {
        let db = try TestDB()
        let cal = Calendar.current
        let c = SampleData.contact(name: "张三")
        let e = SampleData.event()
        db.context.insert(c)
        db.context.insert(e)

        var comps = cal.dateComponents([.year, .month, .day], from: Date())
        comps.month = 1
        comps.day = 15
        let jan = cal.date(from: comps)!
        comps.month = 6
        let jun = cal.date(from: comps)!
        comps.month = 3
        let mar = cal.date(from: comps)!

        let r1 = Record(contact: c, event: e, amount: 500, direction: .given, paymentMethod: .cash, returnedAmount: 0, date: jan)
        let r2 = Record(contact: c, event: e, amount: 500, direction: .given, paymentMethod: .cash, returnedAmount: 0, date: jun)
        let r3 = Record(contact: c, event: e, amount: 500, direction: .given, paymentMethod: .cash, returnedAmount: 0, date: mar)
        db.context.insert(r1)
        db.context.insert(r2)
        db.context.insert(r3)
        try db.context.save()

        let vm = RecordListViewModel()
        vm.load(context: db.context)

        let keys = vm.sortedMonthKeys
        #expect(keys.count == 3)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans")
        formatter.dateFormat = "yyyy年M月"
        let junKey = formatter.string(from: jun)
        let marKey = formatter.string(from: mar)
        let janKey = formatter.string(from: jan)
        #expect(keys[0] == junKey)
        #expect(keys[1] == marKey)
        #expect(keys[2] == janKey)
    }

    @Test("deleteRecord removes record from state")
    func testDeleteRecord() throws {
        let db = try TestDB()
        let c = SampleData.contact(name: "张三")
        let e = SampleData.event()
        db.context.insert(c)
        db.context.insert(e)
        let r = SampleData.record(contact: c, event: e)
        db.context.insert(r)
        try db.context.save()

        let vm = RecordListViewModel()
        vm.load(context: db.context)
        let before = vm.state.value!.values.flatMap { $0 }.count
        #expect(before == 1)

        vm.deleteRecord(r, context: db.context)
        let after = vm.state.value!.values.flatMap { $0 }.count
        #expect(after == 0)
    }

    @Test("deleteError starts as nil")
    func testDeleteErrorSetsProperty() throws {
        let vm = RecordListViewModel()
        #expect(vm.deleteError == nil)
    }
}
