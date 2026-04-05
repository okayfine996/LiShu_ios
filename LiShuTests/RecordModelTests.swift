//
//  RecordModelTests.swift
//  LiShuTests
//

import Foundation
import Testing
import SwiftData
@testable import LiShu

@MainActor
struct RecordModelTests {

    @Test func testUpdateStatusOpen() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)

        let record = SampleData.record(contact: contact, event: event, amount: 500, returnedAmount: 0)
        db.context.insert(record)

        #expect(record.hasReturnedGift == false)
    }

    @Test func testUpdateStatusPartial() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)

        let record = SampleData.record(contact: contact, event: event, amount: 500, returnedAmount: 200)
        db.context.insert(record)

        #expect(record.hasReturnedGift == true)
    }

    @Test func testUpdateStatusSettled() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)

        let record = SampleData.record(contact: contact, event: event, amount: 500, returnedAmount: 500)
        db.context.insert(record)

        #expect(record.hasReturnedGift == true)
    }

    @Test func testDirectionComputedProperty() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)

        let record = SampleData.record(contact: contact, event: event)
        db.context.insert(record)

        #expect(record.direction == .given)
        record.direction = .received
        #expect(record.direction == .received)
        #expect(record.directionRaw == "received")
    }

    @Test func testPaymentMethodComputedProperty() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)

        let record = SampleData.record(contact: contact, event: event)
        db.context.insert(record)

        #expect(record.resolvedPaymentMethod == .cash)
        record.applyTypeData(.monetary(MonetaryData(amount: record.monetaryAmount, paymentMethod: PaymentMethod.wechat.rawValue, returnedAmount: record.returnedAmount)))
        #expect(record.resolvedPaymentMethod == .wechat)
    }

    @Test func testRelationshipWeightComputedProperty() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)

        let record = SampleData.record(contact: contact, event: event)
        db.context.insert(record)

        #expect(record.relationshipWeight == .reciprocal)
        record.relationshipWeight = .profound
        #expect(record.relationshipWeight == .profound)
        #expect(record.relationshipWeightRaw == "profound")
    }

    @Test func testRecordPhotoRelationship() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)

        let record = SampleData.record(contact: contact, event: event)
        db.context.insert(record)

        let photo1 = SampleData.recordPhoto(record: record, data: Data([0x01]))
        let photo2 = SampleData.recordPhoto(record: record, data: Data([0x02]))
        db.context.insert(photo1)
        db.context.insert(photo2)
        try db.context.save()

        #expect(record.photos?.count == 2)
    }

    @Test func testRecordCascadeDeleteRemovesPhotos() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)

        let record = SampleData.record(contact: contact, event: event)
        db.context.insert(record)

        let photo = SampleData.recordPhoto(record: record)
        db.context.insert(photo)
        try db.context.save()

        #expect(try db.context.fetchCount(FetchDescriptor<RecordPhoto>()) == 1)

        db.context.delete(record)
        try db.context.save()

        #expect(try db.context.fetchCount(FetchDescriptor<RecordPhoto>()) == 0)
    }

    @Test func testInitReflectsHasReturnedGiftViaUpdateStatus() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)

        let record = SampleData.record(contact: contact, event: event, amount: 500, returnedAmount: 500)
        db.context.insert(record)

        #expect(record.hasReturnedGift == true)
    }

    @Test func testBanquetResolvedDescriptionPrefersLocation() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        db.context.insert(contact)

        let record = SampleData.typedRecord(
            contact: contact,
            event: nil,
            direction: .given,
            date: .now,
            recordType: .banquet,
            typeData: .banquet(BanquetData(
                location: "兰亭包厢，商务档次",
                attendeeList: "主客与两位长辈",
                extraCostNotes: "额外带了两条烟"
            ))
        )
        db.context.insert(record)

        #expect(record.resolvedDescription == "兰亭包厢，商务档次")
        #expect(record.banquetData?.attendeeList == "主客与两位长辈")
    }

    @Test func testResolvedDisplayAmountUnknownRecordTypeRawUsesColumnWhenKVAmountZero() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)

        let record = SampleData.record(contact: contact, event: event, amount: 888, direction: .given, returnedAmount: 0)
        // 模拟迁移脏数据：无法识别的类型 raw + 实质 kv 中金额为 0，但遗留列上仍有金额
        record.recordTypeRaw = "open"
        record.amount = 888
        record.kvData = "{\"amount\":0,\"paymentMethod\":\"cash\",\"returnedAmount\":0}"
        db.context.insert(record)

        #expect(record.recordType == .monetary)
        #expect(record.resolvedDisplayAmount == 888)
    }

    @Test func testResolvedDisplayAmountMonetaryRecordTypeRawUsesColumnWhenKVAmountZero() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)

        let record = SampleData.record(contact: contact, event: event, amount: 888, direction: .given, returnedAmount: 0)
        // 轻量迁移后 recordTypeRaw 为合法 monetary，但 kv 占位 amount 0、列上仍为旧库金额
        record.recordTypeRaw = RecordType.monetary.rawValue
        record.amount = 888
        record.kvData = "{\"amount\":0,\"paymentMethod\":\"cash\",\"returnedAmount\":0}"
        db.context.insert(record)

        #expect(record.recordType == .monetary)
        #expect(record.resolvedDisplayAmount == 888)
    }

    @Test func testUserEnteredDecimalParsesCommas() {
        #expect(UserEnteredDecimal.parse("1,234.5") == 1234.5)
        #expect(UserEnteredDecimal.parse("1，000") == 1000)
        #expect(UserEnteredDecimal.parse("  500  ") == 500)
    }

    @Test func testRecordTypeStorageNormalizerTrimsWhitespace() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        db.context.insert(contact)
        let record = SampleData.record(contact: contact, amount: 100)
        record.recordTypeRaw = " monetary "
        db.context.insert(record)
        try db.context.save()

        try RecordTypeStorageNormalizer.normalizeAllRecords(context: db.context)

        #expect(record.recordTypeRaw == "monetary")
    }
}
