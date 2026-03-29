import Foundation
import Testing
import SwiftData
@testable import LiShu

@MainActor
struct OCRImportViewModelTests {

    private func makeItems() -> [OCRRecordItem] {
        [
            OCRRecordItem(name: "张三", amount: 500, amountText: "500", confidence: .high),
            OCRRecordItem(name: "李四", amount: 300, amountText: "300", confidence: .medium),
            OCRRecordItem(name: "王五", amount: 200, amountText: "200", confidence: .low, warningType: .needsVerification),
        ]
    }

    @Test func testSelectedItems() {
        let vm = OCRImportViewModel()
        vm.items = makeItems()

        #expect(vm.selectedCount == 3)
        #expect(vm.isAllSelected == true)

        vm.items[1].isSelected = false
        #expect(vm.selectedCount == 2)
        #expect(vm.isAllSelected == false)
    }

    @Test func testToggleSelection() {
        let vm = OCRImportViewModel()
        vm.items = makeItems()

        let item = vm.items[0]
        #expect(item.isSelected == true)

        vm.toggleSelection(for: item)
        #expect(vm.items[0].isSelected == false)

        vm.toggleSelection(for: vm.items[0])
        #expect(vm.items[0].isSelected == true)
    }

    @Test func testSelectAllDeselectAll() {
        let vm = OCRImportViewModel()
        vm.items = makeItems()

        vm.deselectAll()
        #expect(vm.selectedCount == 0)
        #expect(vm.isAllSelected == false)

        vm.selectAll()
        #expect(vm.selectedCount == 3)
        #expect(vm.isAllSelected == true)
    }

    @Test func testToggleSelectAll() {
        let vm = OCRImportViewModel()
        vm.items = makeItems()

        vm.toggleSelectAll()
        #expect(vm.selectedCount == 0)

        vm.toggleSelectAll()
        #expect(vm.selectedCount == 3)
    }

    @Test func testDeleteSelected() {
        let vm = OCRImportViewModel()
        vm.items = makeItems()
        vm.items[1].isSelected = false

        vm.deleteSelected()
        #expect(vm.items.count == 1)
        #expect(vm.items[0].name == "李四")
    }

    @Test func testUpdateNameAndAmount() {
        let vm = OCRImportViewModel()
        vm.items = makeItems()
        let id = vm.items[0].id

        vm.updateName(for: id, newName: "赵六")
        #expect(vm.items[0].name == "赵六")

        vm.updateAmount(for: id, newAmount: "¥1,200")
        #expect(vm.items[0].amount == 1200)

        vm.updateAmount(for: id, newAmount: "invalid")
        #expect(vm.items[0].amount == 1200)
    }

    @Test func testCanImportAndPerformImport() throws {
        let db = try TestDB()
        let vm = OCRImportViewModel()
        vm.items = makeItems()

        #expect(vm.canImport == true)

        let result = vm.performImport(context: db.context)
        #expect(result == true)
        #expect(vm.importSuccess == true)

        let records = try db.context.fetch(FetchDescriptor<Record>())
        #expect(records.count == 3)

        let contacts = try db.context.fetch(FetchDescriptor<Contact>())
        #expect(contacts.count == 3)
    }

    @Test func testPerformImportDeduplicatesNewContactsByName() throws {
        let db = try TestDB()
        let vm = OCRImportViewModel()
        vm.items = [
            OCRRecordItem(name: "同名联系人", amount: 100, amountText: "100", confidence: .high),
            OCRRecordItem(name: "同名联系人", amount: 200, amountText: "200", confidence: .high),
        ]

        #expect(vm.performImport(context: db.context) == true)

        let records = try db.context.fetch(FetchDescriptor<Record>())
        #expect(records.count == 2)

        let contacts = try db.context.fetch(FetchDescriptor<Contact>())
        #expect(contacts.count == 1)
        #expect(contacts[0].name == "同名联系人")
    }

    // MARK: - Edit EventName

    @Test func testStartEditingSetsEventName() {
        let vm = OCRImportViewModel()
        let weddingName = EventType.wedding.displayName
        vm.items = [
            OCRRecordItem(name: "张三", amount: 500, amountText: "500", confidence: .high, eventName: weddingName),
        ]

        vm.startEditing(item: vm.items[0])
        #expect(vm.editEventName == weddingName)
    }

    @Test func testSaveEditingWritesBackEventName() {
        let vm = OCRImportViewModel()
        vm.items = [
            OCRRecordItem(name: "张三", amount: 500, amountText: "500", confidence: .high),
        ]

        vm.startEditing(item: vm.items[0])
        let birthdayName = EventType.birthday.displayName
        vm.editEventName = birthdayName
        vm.saveEditing()

        #expect(vm.items[0].eventName == birthdayName)
    }

    // MARK: - canImport

    @Test func testCanImportOnlyDependsOnSelection() {
        let vm = OCRImportViewModel()
        vm.items = makeItems()

        #expect(vm.canImport == true)

        vm.deselectAll()
        #expect(vm.canImport == false)

        vm.items[0].isSelected = true
        #expect(vm.canImport == true)
    }

    // MARK: - performImport creates events per record

    @Test func testPerformImportCreatesEventsPerRecord() throws {
        let db = try TestDB()
        let vm = OCRImportViewModel()

        let weddingName = EventType.wedding.displayName
        let birthdayName = EventType.birthday.displayName
        vm.items = [
            OCRRecordItem(name: "张三", amount: 500, amountText: "500", confidence: .high, eventName: weddingName),
            OCRRecordItem(name: "李四", amount: 300, amountText: "300", confidence: .high, eventName: birthdayName),
        ]

        #expect(vm.performImport(context: db.context) == true)

        let events = try db.context.fetch(FetchDescriptor<Event>())
        #expect(events.count == 2)

        let eventNames = Set(events.map(\.name))
        #expect(eventNames.contains(weddingName))
        #expect(eventNames.contains(birthdayName))

        let weddingEvent = events.first { $0.name == weddingName }
        #expect(weddingEvent?.type == .wedding)

        let birthdayEvent = events.first { $0.name == birthdayName }
        #expect(birthdayEvent?.type == .birthday)
    }
}
