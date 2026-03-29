import Foundation
import Testing
import SwiftData
@testable import LiShu

@MainActor
struct AddEventViewModelTests {

    @Test func testIsValidWithEmptyName() {
        let vm = AddEventViewModel()
        vm.name = ""
        #expect(vm.isValid == false)
    }

    @Test func testIsValidWithWhitespaceName() {
        let vm = AddEventViewModel()
        vm.name = "   \n  "
        #expect(vm.isValid == false)
    }

    @Test func testIsValidWithValidName() {
        let vm = AddEventViewModel()
        vm.name = "春节聚会"
        #expect(vm.isValid == true)
    }

    @Test func testSaveNewEvent() throws {
        let db = try TestDB()
        let vm = AddEventViewModel()
        vm.name = "张三的婚礼"
        vm.eventType = .wedding
        vm.location = "北京"
        vm.note = "提前准备红包"

        #expect(vm.save(context: db.context) == true)

        let descriptor = FetchDescriptor<Event>(
            predicate: #Predicate<Event> { $0.name == "张三的婚礼" }
        )
        let events = try db.context.fetch(descriptor)
        #expect(events.count == 1)
        #expect(events[0].type == .wedding)
        #expect(events[0].location == "北京")
        #expect(events[0].note == "提前准备红包")
    }

    @Test func testSaveInvalidReturnsFalse() throws {
        let db = try TestDB()
        let vm = AddEventViewModel()
        vm.name = ""

        #expect(vm.save(context: db.context) == false)

        let events = try db.context.fetch(FetchDescriptor<Event>())
        #expect(events.isEmpty)
    }

    @Test func testConfigureWithEvent() throws {
        let db = try TestDB()
        let event = Event(name: "生日宴", type: .birthday, date: Date(timeIntervalSince1970: 1700000000), location: "上海", note: "备注")
        event.coverImage = Data([0x01, 0x02])
        db.context.insert(event)
        try db.context.save()

        let vm = AddEventViewModel()
        vm.configure(with: event)

        #expect(vm.editingEvent === event)
        #expect(vm.name == "生日宴")
        #expect(vm.eventType == .birthday)
        #expect(vm.location == "上海")
        #expect(vm.note == "备注")
        #expect(vm.coverImageData == Data([0x01, 0x02]))
    }

    @Test func testSaveEditMode() throws {
        let db = try TestDB()
        let event = Event(name: "旧名称", type: .wedding, location: "旧地点")
        db.context.insert(event)
        try db.context.save()

        let vm = AddEventViewModel()
        vm.configure(with: event)
        vm.name = "新名称"
        vm.eventType = .birthday
        vm.location = "新地点"

        #expect(vm.save(context: db.context) == true)

        let events = try db.context.fetch(FetchDescriptor<Event>())
        #expect(events.count == 1)
        #expect(events[0].name == "新名称")
        #expect(events[0].type == .birthday)
        #expect(events[0].location == "新地点")
    }
}
