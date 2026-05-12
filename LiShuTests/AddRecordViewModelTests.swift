//
//  AddRecordViewModelTests.swift
//  LiShuTests
//

import Foundation
@testable import LiShu
import SwiftData
import Testing

@MainActor
struct AddRecordViewModelTests {
    @Test func isValidMissingContact() throws {
        let db = try TestDB()
        let vm = AddRecordViewModel()
        vm.loadData(context: db.context)
        let event = SampleData.event()
        db.context.insert(event)

        vm.selectedContact = nil
        vm.selectedEvent = event
        vm.monetaryAmount = "500"

        #expect(vm.isValid == false)
    }

    @Test func isValidMissingEvent() throws {
        let db = try TestDB()
        let vm = AddRecordViewModel()
        vm.loadData(context: db.context)
        let contact = SampleData.contact()
        db.context.insert(contact)

        vm.selectedContact = contact
        vm.selectedEvent = nil
        vm.monetaryAmount = "500"

        #expect(vm.isValid == false)
    }

    @Test func isValidMissingDailyTag() throws {
        let db = try TestDB()
        let vm = AddRecordViewModel()
        vm.loadData(context: db.context)
        let contact = SampleData.contact()
        db.context.insert(contact)

        vm.selectedContact = contact
        vm.contextSelection = .daily
        vm.selectedDailyTag = ""
        vm.monetaryAmount = "500"

        #expect(vm.isValid == false)
    }

    @Test func isValidZeroAmount() throws {
        let db = try TestDB()
        let vm = AddRecordViewModel()
        vm.loadData(context: db.context)
        let contact = SampleData.contact()
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)

        vm.selectedContact = contact
        vm.selectedEvent = event
        vm.monetaryAmount = "0"

        #expect(vm.isValid == false)
    }

    @Test func isValidAllSet() throws {
        let db = try TestDB()
        let vm = AddRecordViewModel()
        vm.loadData(context: db.context)
        let contact = SampleData.contact()
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)

        vm.selectedContact = contact
        vm.selectedEvent = event
        vm.monetaryAmount = "500"

        #expect(vm.isValid == true)
    }

    @Test func isValidDailyContextWithTag() throws {
        let db = try TestDB()
        let vm = AddRecordViewModel()
        vm.loadData(context: db.context)
        let contact = SampleData.contact()
        db.context.insert(contact)

        vm.selectedContact = contact
        vm.contextSelection = .daily
        vm.selectedDailyTag = "节日看望"
        vm.monetaryAmount = "500"

        #expect(vm.isValid == true)
    }

    @Test func testFilteredContacts() throws {
        let db = try TestDB()
        let c1 = Contact(name: "张三", relation: "朋友")
        let c2 = Contact(name: "李四", relation: "同事")
        let c3 = Contact(name: "张伟", relation: "亲戚")
        db.context.insert(c1)
        db.context.insert(c2)
        db.context.insert(c3)
        try db.context.save()

        let vm = AddRecordViewModel()
        vm.loadData(context: db.context)
        vm.contactSearchText = "张"

        #expect(vm.filteredContacts.count == 2)
        #expect(vm.filteredContacts.map(\.name).sorted() == ["张三", "张伟"])
    }

    @Test func saveNewRecord() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)
        try db.context.save()

        let vm = AddRecordViewModel()
        vm.loadData(context: db.context)
        vm.selectedContact = contact
        vm.selectedEvent = event
        vm.monetaryAmount = "800"

        #expect(vm.save(context: db.context) == true)

        let descriptor = FetchDescriptor<Record>()
        let records = try db.context.fetch(descriptor)
        #expect(records.count == 1)
        #expect(records[0].monetaryAmount == 800)
    }

    @Test func saveEditMode() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)
        let record = SampleData.record(contact: contact, event: event, amount: 500)
        db.context.insert(record)
        try db.context.save()

        let vm = AddRecordViewModel()
        vm.loadData(context: db.context)
        vm.configure(with: record)
        vm.monetaryAmount = "600"

        #expect(vm.save(context: db.context) == true)

        let descriptor = FetchDescriptor<Record>()
        let records = try db.context.fetch(descriptor)
        #expect(records.count == 1)
        #expect(records[0].monetaryAmount == 600)
    }

    @Test func saveEditModePreservesExistingDirectionWhenEventIsUnchanged() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event(hostMode: .host)
        db.context.insert(contact)
        db.context.insert(event)
        let record = SampleData.record(contact: contact, event: event, amount: 500, direction: .given)
        db.context.insert(record)
        try db.context.save()

        let vm = AddRecordViewModel()
        vm.loadData(context: db.context)
        vm.configure(with: record)
        vm.monetaryAmount = "600"

        #expect(vm.direction == .given)
        #expect(vm.save(context: db.context) == true)

        let records = try db.context.fetch(FetchDescriptor<Record>())
        #expect(records.count == 1)
        #expect(records[0].direction == .given)
        #expect(records[0].monetaryAmount == 600)
    }

    @Test func saveEditModeUsesUserSelectedDirectionForDailyRecord() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        db.context.insert(contact)

        let record = SampleData.record(contact: contact, event: nil, amount: 500, direction: .given)
        record.contextTag = "节日看望"
        db.context.insert(record)
        try db.context.save()

        let vm = AddRecordViewModel()
        vm.loadData(context: db.context)
        vm.configure(with: record)
        vm.direction = .received
        vm.monetaryAmount = "600"

        #expect(vm.save(context: db.context) == true)

        let records = try db.context.fetch(FetchDescriptor<Record>())
        #expect(records.count == 1)
        #expect(records[0].direction == .received)
        #expect(records[0].contextTag == "节日看望")
        #expect(records[0].monetaryAmount == 600)
    }

    @Test func saveBanquetRecord() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)
        try db.context.save()

        let vm = AddRecordViewModel()
        vm.loadData(context: db.context)
        vm.selectedContact = contact
        vm.selectedEvent = event
        vm.contextSelection = .event
        vm.recordType = .banquet
        vm.banquetLocation = "西贝莜面村包间，中档规格"
        vm.banquetAttendeeList = "主客外还有两位同事陪同"
        vm.banquetExtraCostNotes = "席间开了两瓶酒"

        #expect(vm.save(context: db.context) == true)

        let records = try db.context.fetch(FetchDescriptor<Record>())
        #expect(records.count == 1)
        #expect(records[0].recordType == .banquet)
        #expect(records[0].banquetData?.location == "西贝莜面村包间，中档规格")
        #expect(records[0].banquetData?.attendeeList == "主客外还有两位同事陪同")
        #expect(records[0].banquetData?.extraCostNotes == "席间开了两瓶酒")
    }

    @Test func saveDailyRecordRequiresSceneTag() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        db.context.insert(contact)
        try db.context.save()

        let vm = AddRecordViewModel()
        vm.loadData(context: db.context)
        vm.selectedContact = contact
        vm.contextSelection = .daily
        vm.selectedDailyTag = ""
        vm.monetaryAmount = "520"

        #expect(vm.save(context: db.context) == false)

        let records = try db.context.fetch(FetchDescriptor<Record>())
        #expect(records.isEmpty)
    }

    @Test func testLoadData() throws {
        let db = try TestDB()
        let c1 = Contact(name: "联系人1", relation: "朋友")
        let c2 = Contact(name: "联系人2", relation: "同事")
        let e1 = Event(name: "婚礼", type: .wedding, date: .now)
        db.context.insert(c1)
        db.context.insert(c2)
        db.context.insert(e1)
        try db.context.save()

        let vm = AddRecordViewModel()
        vm.loadData(context: db.context)

        #expect(vm.allContacts.count == 2)
        #expect(vm.allEvents.count == 1)
    }

    @Test func configureWithEventPrefillsEventAndDirection() throws {
        let db = try TestDB()
        let event = SampleData.event(hostMode: .host)
        db.context.insert(event)
        try db.context.save()

        let vm = AddRecordViewModel()
        vm.loadData(context: db.context)
        vm.configure(direction: .received, contactID: nil, eventID: event.persistentModelID, context: db.context)

        #expect(vm.selectedEvent?.persistentModelID == event.persistentModelID)
        #expect(vm.direction == .received)
        #expect(vm.contextSelection == .event)
    }

    @Test func selectingGuestEventLocksDirectionToGiven() throws {
        let db = try TestDB()
        let event = SampleData.event(hostMode: .guest)
        db.context.insert(event)
        try db.context.save()

        let vm = AddRecordViewModel()
        vm.direction = .received

        vm.selectEvent(event)

        #expect(vm.selectedEvent?.persistentModelID == event.persistentModelID)
        #expect(vm.contextSelection == .event)
        #expect(vm.direction == .given)
        #expect(vm.isDirectionLockedBySelectedEvent == true)
    }

    @Test func savingHostEventForcesReceivedDirection() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event(hostMode: .host)
        db.context.insert(contact)
        db.context.insert(event)
        try db.context.save()

        let vm = AddRecordViewModel()
        vm.loadData(context: db.context)
        vm.selectedContact = contact
        vm.selectEvent(event)
        vm.direction = .given
        vm.monetaryAmount = "666"

        #expect(vm.save(context: db.context) == true)

        let records = try db.context.fetch(FetchDescriptor<Record>())
        #expect(records.count == 1)
        #expect(records[0].direction == .received)
    }

    @Test func savingGuestEventForcesGivenDirection() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event(hostMode: .guest)
        db.context.insert(contact)
        db.context.insert(event)
        try db.context.save()

        let vm = AddRecordViewModel()
        vm.loadData(context: db.context)
        vm.selectedContact = contact
        vm.selectEvent(event)
        vm.direction = .received
        vm.monetaryAmount = "520"

        #expect(vm.save(context: db.context) == true)

        let records = try db.context.fetch(FetchDescriptor<Record>())
        #expect(records.count == 1)
        #expect(records[0].direction == .given)
    }

    @Test func ledgerReceiptViewModelPrefillsLockedReceiptContext() throws {
        let db = try TestDB()
        let event = SampleData.event(hostMode: .host)
        db.context.insert(event)
        try db.context.save()

        let vm = AddLedgerReceiptViewModel(eventID: event.persistentModelID)
        vm.load(context: db.context)

        #expect(vm.selectedEvent?.persistentModelID == event.persistentModelID)
        #expect(vm.direction == .received)
        #expect(vm.recordType == .monetary)
        #expect(vm.contextSelection == .event)
    }

    @Test func resetForContinuousEntryPreservesEventAndPaymentMethod() {
        let event = SampleData.event(hostMode: .host)
        let contact = SampleData.contact()
        let vm = AddRecordViewModel()
        vm.selectedEvent = event
        vm.selectedContact = contact
        vm.direction = .received
        vm.monetaryPaymentMethod = .wechat
        vm.monetaryAmount = "888"
        vm.note = "测试"

        vm.resetForContinuousEntry()

        #expect(vm.selectedEvent?.persistentModelID == event.persistentModelID)
        #expect(vm.selectedContact == nil)
        #expect(vm.direction == .received)
        #expect(vm.monetaryPaymentMethod == .wechat)
        #expect(vm.monetaryAmount.isEmpty)
        #expect(vm.note.isEmpty)
    }

    @Test func saveRecordCompressesNewPhotoData() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)
        try db.context.save()

        let vm = AddRecordViewModel()
        vm.loadData(context: db.context)
        vm.selectedContact = contact
        vm.selectedEvent = event
        vm.monetaryAmount = "520"
        vm.newPhotoItems = [
            NewRecordPhotoItem(id: UUID(), data: SampleImages.makePNGData(width: 2600, height: 1800)),
        ]

        #expect(vm.save(context: db.context) == true)

        let photos = try db.context.fetch(FetchDescriptor<RecordPhoto>())
        #expect(photos.count == 1)
        let dimensions = try #require(ImagePipeline.imageDimensions(from: photos[0].imageData))
        #expect(dimensions.width <= CGFloat(ImagePipeline.Preset.recordPhotoMaxPixelSize))
        #expect(dimensions.height <= CGFloat(ImagePipeline.Preset.recordPhotoMaxPixelSize))
    }

    @Test func smartReturnGiftSuggestionAppearsForGivenMonetaryEventRecord() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let historicalEvent = SampleData.event(name: "去年的婚礼")
        let currentEvent = SampleData.event(name: "今年的婚礼")
        db.context.insert(contact)
        db.context.insert(historicalEvent)
        db.context.insert(currentEvent)
        db.context.insert(
            SampleData.record(
                contact: contact,
                event: historicalEvent,
                amount: 800,
                direction: .received,
                date: Calendar.current.date(byAdding: .day, value: -240, to: .now) ?? .now
            )
        )
        try db.context.save()

        let vm = AddRecordViewModel()
        vm.loadData(context: db.context)
        vm.selectedContact = contact
        vm.selectEvent(currentEvent)

        let suggestion = try #require(vm.smartReturnGiftSuggestion)
        #expect(suggestion.contactID == contact.persistentModelID)
        #expect(suggestion.eventID == currentEvent.persistentModelID)
        #expect(suggestion.historicalRecordCount == 1)
        #expect(suggestion.standardAmount > 0)
    }

    @Test func smartReturnGiftSuggestionHidesOutsideEligibleContext() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)
        db.context.insert(
            SampleData.record(
                contact: contact,
                event: event,
                amount: 600,
                direction: .received,
                date: Calendar.current.date(byAdding: .day, value: -120, to: .now) ?? .now
            )
        )
        try db.context.save()

        let vm = AddRecordViewModel()
        vm.loadData(context: db.context)
        vm.selectedContact = contact
        vm.selectEvent(event)
        #expect(vm.smartReturnGiftSuggestion != nil)

        vm.setContextSelection(.daily)
        #expect(vm.smartReturnGiftSuggestion == nil)
    }

    @Test func applySuggestedAmountUpdatesAmountAndPaymentMethod() {
        let vm = AddRecordViewModel()

        vm.applySuggestedAmount(888, paymentMethod: .wechat)

        #expect(vm.monetaryAmount == "888")
        #expect(vm.monetaryPaymentMethod == .wechat)
    }

    @Test func smartReturnGiftSuggestionHidesWhenNoMonetaryHistory() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)
        db.context.insert(
            SampleData.recordGift(
                contact: contact,
                event: event,
                giftName: "茶叶",
                direction: .received,
                date: Calendar.current.date(byAdding: .day, value: -60, to: .now) ?? .now
            )
        )
        try db.context.save()

        let vm = AddRecordViewModel()
        vm.loadData(context: db.context)
        vm.selectedContact = contact
        vm.selectEvent(event)

        #expect(vm.smartReturnGiftSuggestion == nil)
    }
}
