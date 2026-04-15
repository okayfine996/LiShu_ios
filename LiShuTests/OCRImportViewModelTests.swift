import Foundation
@testable import LiShu
import SwiftData
import Testing
import UIKit

@MainActor
@Suite(.serialized)
struct OCRImportViewModelTests {
    private func makeItems() -> [OCRRecordItem] {
        [
            OCRRecordItem(name: "张三", amount: 500, amountText: "500", confidence: .high),
            OCRRecordItem(name: "李四", amount: 300, amountText: "300", confidence: .medium),
            OCRRecordItem(name: "王五", amount: 200, amountText: "200", confidence: .low, warningType: .needsVerification),
        ]
    }

    @Test func selectedItems() {
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

    @Test func selectAllDeselectAll() {
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

    @Test func updateNameAndAmount() {
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

    @Test func canImportAndPerformImport() throws {
        let db = try TestDB()
        let event = Event(name: "当前礼簿", type: .wedding, hostMode: .host, date: .now)
        db.context.insert(event)
        let vm = OCRImportViewModel(fixedEventID: event.persistentModelID)
        vm.items = makeItems()

        #expect(vm.canImport == true)

        let result = vm.performImport(context: db.context)
        #expect(result == true)
        #expect(vm.importSuccess == true)

        let records = try db.context.fetch(FetchDescriptor<Record>())
        #expect(records.count == 3)
        #expect(records.allSatisfy { $0.event?.persistentModelID == event.persistentModelID })
        #expect(records.allSatisfy { $0.direction == .received })

        let contacts = try db.context.fetch(FetchDescriptor<Contact>())
        #expect(contacts.count == 3)
    }

    @Test func performImportDeduplicatesNewContactsByName() throws {
        let db = try TestDB()
        let event = Event(name: "当前礼簿", hostMode: .host)
        db.context.insert(event)
        let vm = OCRImportViewModel(fixedEventID: event.persistentModelID)
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

    // MARK: - canImport

    @Test func canImportOnlyDependsOnSelection() {
        let vm = OCRImportViewModel()
        vm.items = makeItems()

        #expect(vm.canImport == true)

        vm.deselectAll()
        #expect(vm.canImport == false)

        vm.items[0].isSelected = true
        #expect(vm.canImport == true)
    }

    @Test func addImageCompressesLargeCameraInput() {
        let vm = OCRImportViewModel()
        vm.addImage(SampleImages.makeUIImage(width: 2600, height: 1900))

        #expect(vm.capturedImages.count == 1)
        let maxDimension = max(vm.capturedImages[0].size.width, vm.capturedImages[0].size.height)
        #expect(maxDimension <= CGFloat(ImagePipeline.Preset.ocrInputMaxPixelSize))
    }

    @Test func clearImagesReleasesCapturedImages() {
        let vm = OCRImportViewModel()
        vm.addImage(SampleImages.makeUIImage(width: 1800, height: 1400))
        vm.items = makeItems()
        vm.processingState = .loaded(vm.items)
        vm.recognitionMode = .ledgerHeuristicFallback
        vm.filteredNoiseCount = 4
        vm.layoutKind = .verticalLedger
        vm.orientationUsed = .rotatedClockwise

        vm.clearImages()

        #expect(vm.capturedImages.isEmpty)
        #expect(vm.items.isEmpty)
        #expect(vm.recognitionMode == .ocrOnlyLegacy)
        #expect(vm.filteredNoiseCount == 0)
        #expect(vm.layoutKind == .unknownLedger)
        #expect(vm.orientationUsed == .unknown)
        if case .idle = vm.processingState {
            #expect(Bool(true))
        } else {
            Issue.record("Expected processingState to return to idle after clearing OCR images")
        }
    }

    @Test func saveEditingOnlyUpdatesNameAmountAndDate() {
        let vm = OCRImportViewModel()
        let originalDate = Date.now
        let updatedDate = originalDate.addingTimeInterval(86400)
        let originalEventName = EventType.wedding.displayName
        vm.items = [
            OCRRecordItem(
                name: "张三",
                amount: 500,
                amountText: "500",
                confidence: .high,
                date: originalDate,
                eventType: .wedding,
                eventName: originalEventName
            ),
        ]

        vm.startEditing(item: vm.items[0])
        vm.editName = "李四"
        vm.editAmountText = "800"
        vm.editDate = updatedDate
        vm.saveEditing()

        #expect(vm.items[0].name == "李四")
        #expect(vm.items[0].amount == 800)
        #expect(vm.items[0].date == updatedDate)
        #expect(vm.items[0].eventName == originalEventName)
        #expect(vm.items[0].eventType == .wedding)
    }

    @Test func performImportKeepsBoundEventDateUnchanged() throws {
        let db = try TestDB()
        let eventDate = Date.now
        let event = Event(name: "当前礼簿", type: .wedding, hostMode: .host, date: eventDate)
        db.context.insert(event)
        let vm = OCRImportViewModel(fixedEventID: event.persistentModelID)
        let recordDate = eventDate.addingTimeInterval(172_800)
        vm.items = [
            OCRRecordItem(
                name: "张三",
                amount: 500,
                amountText: "500",
                confidence: .high,
                date: recordDate,
                eventType: .wedding,
                eventName: event.name
            ),
        ]

        #expect(vm.performImport(context: db.context) == true)

        let records = try db.context.fetch(FetchDescriptor<Record>())
        #expect(records.count == 1)
        #expect(records[0].date == recordDate)

        let events = try db.context.fetch(FetchDescriptor<Event>())
        #expect(events.count == 1)
        #expect(events[0].date == eventDate)
        #expect(events[0].persistentModelID == event.persistentModelID)
    }

    @Test func needsReviewCountTracksWarningsAndNonHighConfidence() {
        let vm = OCRImportViewModel()
        vm.items = makeItems()

        #expect(vm.needsReviewCount == 2)

        vm.items[1].confidence = .high
        vm.items[1].warningType = nil
        vm.items[2].confidence = .high
        vm.items[2].warningType = nil

        #expect(vm.needsReviewCount == 0)
    }

    @Test func newRecognitionStateDoesNotChangeImportResults() throws {
        let db = try TestDB()
        let event = Event(name: "当前礼簿", hostMode: .host)
        db.context.insert(event)
        let vm = OCRImportViewModel(fixedEventID: event.persistentModelID)
        vm.recognitionMode = .ledgerHeuristicFallback
        vm.filteredNoiseCount = 3
        vm.items = [
            OCRRecordItem(name: "张三", amount: 500, amountText: "500", confidence: .high, sourceMode: .ledgerHeuristicFallback),
            OCRRecordItem(
                name: "李四",
                amount: 300,
                amountText: "300",
                confidence: .medium,
                warningType: .needsVerification,
                sourceMode: .appleAIEnhanced
            ),
        ]

        #expect(vm.performImport(context: db.context) == true)

        let records = try db.context.fetch(FetchDescriptor<Record>())
        #expect(records.count == 2)
        #expect(vm.importSuccess == true)
    }
}
