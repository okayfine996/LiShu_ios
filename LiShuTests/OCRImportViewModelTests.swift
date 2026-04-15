import Foundation
@testable import LiShu
import SwiftData
import Testing
import UIKit

@MainActor
struct OCRImportViewModelTests {
    private func makeLedgerEvent(in context: ModelContext, name: String = "我的婚礼礼簿") -> Event {
        let event = SampleData.event(name: name, hostMode: .host)
        context.insert(event)
        return event
    }

    private func makeItems() -> [OCRRecordItem] {
        [
            OCRRecordItem(name: "张三", amount: 500, amountText: "500", confidence: .high),
            OCRRecordItem(name: "李四", amount: 300, amountText: "300", confidence: .medium),
            OCRRecordItem(name: "王五", amount: 200, amountText: "200", confidence: .low, warningType: .needsVerification),
        ]
    }

    @Test func selectedItems() throws {
        let db = try TestDB()
        let event = makeLedgerEvent(in: db.context)
        let vm = OCRImportViewModel(eventID: event.persistentModelID)
        vm.items = makeItems()

        #expect(vm.selectedCount == 3)
        #expect(vm.isAllSelected == true)

        vm.items[1].isSelected = false
        #expect(vm.selectedCount == 2)
        #expect(vm.isAllSelected == false)
    }

    @Test func testToggleSelection() throws {
        let db = try TestDB()
        let event = makeLedgerEvent(in: db.context)
        let vm = OCRImportViewModel(eventID: event.persistentModelID)
        vm.items = makeItems()

        let item = vm.items[0]
        #expect(item.isSelected == true)

        vm.toggleSelection(for: item)
        #expect(vm.items[0].isSelected == false)

        vm.toggleSelection(for: vm.items[0])
        #expect(vm.items[0].isSelected == true)
    }

    @Test func selectAllDeselectAll() throws {
        let db = try TestDB()
        let event = makeLedgerEvent(in: db.context)
        let vm = OCRImportViewModel(eventID: event.persistentModelID)
        vm.items = makeItems()

        vm.deselectAll()
        #expect(vm.selectedCount == 0)
        #expect(vm.isAllSelected == false)

        vm.selectAll()
        #expect(vm.selectedCount == 3)
        #expect(vm.isAllSelected == true)
    }

    @Test func testToggleSelectAll() throws {
        let db = try TestDB()
        let event = makeLedgerEvent(in: db.context)
        let vm = OCRImportViewModel(eventID: event.persistentModelID)
        vm.items = makeItems()

        vm.toggleSelectAll()
        #expect(vm.selectedCount == 0)

        vm.toggleSelectAll()
        #expect(vm.selectedCount == 3)
    }

    @Test func testDeleteSelected() throws {
        let db = try TestDB()
        let event = makeLedgerEvent(in: db.context)
        let vm = OCRImportViewModel(eventID: event.persistentModelID)
        vm.items = makeItems()
        vm.items[1].isSelected = false

        vm.deleteSelected()
        #expect(vm.items.count == 1)
        #expect(vm.items[0].name == "李四")
    }

    @Test func updateNameAndAmount() throws {
        let db = try TestDB()
        let event = makeLedgerEvent(in: db.context)
        let vm = OCRImportViewModel(eventID: event.persistentModelID)
        vm.items = makeItems()
        let id = vm.items[0].id

        vm.updateName(for: id, newName: "赵六")
        #expect(vm.items[0].name == "赵六")

        vm.updateAmount(for: id, newAmount: "¥1,200")
        #expect(vm.items[0].amount == 1200)

        vm.updateAmount(for: id, newAmount: "invalid")
        #expect(vm.items[0].amount == 1200)
    }

    @Test func startEditingOnlySetsNameAndAmount() throws {
        let db = try TestDB()
        let event = makeLedgerEvent(in: db.context)
        let vm = OCRImportViewModel(eventID: event.persistentModelID)
        vm.items = [
            OCRRecordItem(name: "张三", amount: 500, amountText: "500", confidence: .high),
        ]

        vm.startEditing(item: vm.items[0])

        #expect(vm.editName == "张三")
        #expect(vm.editAmountText == "500")
    }

    @Test func saveEditingWritesBackNameAndAmount() throws {
        let db = try TestDB()
        let event = makeLedgerEvent(in: db.context)
        let vm = OCRImportViewModel(eventID: event.persistentModelID)
        vm.items = [
            OCRRecordItem(name: "张三", amount: 500, amountText: "500", confidence: .high),
        ]

        vm.startEditing(item: vm.items[0])
        vm.editName = "赵六"
        vm.editAmountText = "1,200"
        vm.saveEditing()

        #expect(vm.items[0].name == "赵六")
        #expect(vm.items[0].amount == 1200)
    }

    @Test func canImportAndPerformImport() throws {
        let db = try TestDB()
        let event = makeLedgerEvent(in: db.context)
        let vm = OCRImportViewModel(eventID: event.persistentModelID)
        vm.items = makeItems()

        #expect(vm.canImport == true)

        let result = vm.performImport(context: db.context)
        #expect(result == true)
        #expect(vm.importSuccess == true)

        let records = try db.context.fetch(FetchDescriptor<Record>())
        #expect(records.count == 3)
        #expect(records.allSatisfy { $0.event?.persistentModelID == event.persistentModelID })
        #expect(records.allSatisfy { $0.direction == .received })
        #expect(records.allSatisfy { $0.recordType == .monetary })

        let contacts = try db.context.fetch(FetchDescriptor<Contact>())
        #expect(contacts.count == 3)
    }

    @Test func performImportDeduplicatesNewContactsByName() throws {
        let db = try TestDB()
        let event = makeLedgerEvent(in: db.context)
        let vm = OCRImportViewModel(eventID: event.persistentModelID)
        vm.items = [
            OCRRecordItem(name: "同名联系人", amount: 100, amountText: "100", confidence: .high),
            OCRRecordItem(name: "同名联系人", amount: 200, amountText: "200", confidence: .high),
        ]

        #expect(vm.performImport(context: db.context) == true)

        let records = try db.context.fetch(FetchDescriptor<Record>())
        #expect(records.count == 2)
        #expect(records.allSatisfy { $0.event?.persistentModelID == event.persistentModelID })

        let contacts = try db.context.fetch(FetchDescriptor<Contact>())
        #expect(contacts.count == 1)
        #expect(contacts[0].name == "同名联系人")
    }

    @Test func performImportRequiresBoundLedgerEvent() throws {
        let db = try TestDB()
        let guestEvent = SampleData.event(name: "朋友婚礼", hostMode: .guest)
        db.context.insert(guestEvent)

        let vm = OCRImportViewModel(eventID: guestEvent.persistentModelID)
        vm.items = makeItems()

        #expect(vm.performImport(context: db.context) == false)
        #expect(vm.importSuccess == false)

        let records = try db.context.fetch(FetchDescriptor<Record>())
        #expect(records.isEmpty)
    }

    @Test func performImportDoesNotCreateNewEvents() throws {
        let db = try TestDB()
        let event = makeLedgerEvent(in: db.context)
        let vm = OCRImportViewModel(eventID: event.persistentModelID)
        vm.items = [
            OCRRecordItem(name: "张三", amount: 500, amountText: "500", confidence: .high),
            OCRRecordItem(name: "李四", amount: 300, amountText: "300", confidence: .high),
        ]

        #expect(vm.performImport(context: db.context) == true)

        let events = try db.context.fetch(FetchDescriptor<Event>())
        #expect(events.count == 1)
        #expect(events[0].persistentModelID == event.persistentModelID)
    }

    @Test func canImportOnlyDependsOnSelection() throws {
        let db = try TestDB()
        let event = makeLedgerEvent(in: db.context)
        let vm = OCRImportViewModel(eventID: event.persistentModelID)
        vm.items = makeItems()

        #expect(vm.canImport == true)

        vm.deselectAll()
        #expect(vm.canImport == false)

        vm.items[0].isSelected = true
        #expect(vm.canImport == true)
    }

    @Test func addImageCompressesLargeCameraInput() throws {
        let db = try TestDB()
        let event = makeLedgerEvent(in: db.context)
        let vm = OCRImportViewModel(eventID: event.persistentModelID)
        vm.addImage(SampleImages.makeUIImage(width: 2600, height: 1900))

        #expect(vm.capturedImages.count == 1)
        let maxDimension = max(vm.capturedImages[0].size.width, vm.capturedImages[0].size.height)
        #expect(maxDimension <= CGFloat(ImagePipeline.Preset.ocrInputMaxPixelSize))
    }

    @Test func clearImagesReleasesCapturedImages() throws {
        let db = try TestDB()
        let event = makeLedgerEvent(in: db.context)
        let vm = OCRImportViewModel(eventID: event.persistentModelID)
        vm.addImage(SampleImages.makeUIImage(width: 1800, height: 1400))
        vm.items = makeItems()
        vm.processingState = .loaded(vm.items)

        vm.clearImages()

        #expect(vm.capturedImages.isEmpty)
        #expect(vm.items.isEmpty)
        if case .idle = vm.processingState {
            #expect(Bool(true))
        } else {
            Issue.record("Expected processingState to return to idle after clearing OCR images")
        }
    }
}
