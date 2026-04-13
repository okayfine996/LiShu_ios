import Foundation
@testable import LiShu
import SwiftData
import Testing

@MainActor
struct EventHostModeNormalizerTests {
    @Test func upgradesEventWhenItHasAtLeastTwoReceivedMonetaryRecords() throws {
        let db = try TestDB()
        let event = SampleData.event(name: "旧婚礼", hostMode: .guest)
        let contactA = SampleData.contact(name: "张三")
        let contactB = SampleData.contact(name: "李四")
        db.context.insert(event)
        db.context.insert(contactA)
        db.context.insert(contactB)
        db.context.insert(SampleData.record(contact: contactA, event: event, amount: 1000, direction: .received))
        db.context.insert(SampleData.record(contact: contactB, event: event, amount: 800, direction: .received))
        try db.context.save()

        let updatedCount = try EventHostModeNormalizer.normalizeEvents(context: db.context)

        #expect(updatedCount == 1)
        #expect(event.hostMode == .host)
    }

    @Test func keepsGuestEventWhenThresholdIsNotMet() throws {
        let db = try TestDB()
        let event = SampleData.event(name: "单笔收礼", hostMode: .guest)
        let contact = SampleData.contact()
        db.context.insert(event)
        db.context.insert(contact)
        db.context.insert(SampleData.record(contact: contact, event: event, amount: 1000, direction: .received))
        try db.context.save()

        let updatedCount = try EventHostModeNormalizer.normalizeEvents(context: db.context)

        #expect(updatedCount == 0)
        #expect(event.hostMode == .guest)
    }

    @Test func ignoresNonMonetaryOrGivenRecords() throws {
        let db = try TestDB()
        let event = SampleData.event(name: "普通事件", hostMode: .guest)
        let contact = SampleData.contact()
        db.context.insert(event)
        db.context.insert(contact)
        db.context.insert(SampleData.record(contact: contact, event: event, amount: 1000, direction: .given))
        db.context.insert(SampleData.recordGift(contact: contact, event: event, direction: .received))
        try db.context.save()

        let updatedCount = try EventHostModeNormalizer.normalizeEvents(context: db.context)

        #expect(updatedCount == 0)
        #expect(event.hostMode == .guest)
    }

    @Test func upgradesMixedEventWhenReceivedMonetaryThresholdIsMet() throws {
        let db = try TestDB()
        let event = SampleData.event(name: "混合旧事件", hostMode: .guest)
        let contact = SampleData.contact()
        db.context.insert(event)
        db.context.insert(contact)
        db.context.insert(SampleData.record(contact: contact, event: event, amount: 1000, direction: .received))
        db.context.insert(SampleData.record(contact: contact, event: event, amount: 800, direction: .received))
        db.context.insert(SampleData.recordGift(contact: contact, event: event, direction: .received))
        db.context.insert(SampleData.record(contact: contact, event: event, amount: 200, direction: .given))
        try db.context.save()

        let updatedCount = try EventHostModeNormalizer.normalizeEvents(context: db.context)

        #expect(updatedCount == 1)
        #expect(event.hostMode == .host)
    }

    @Test func doesNotDowngradeExistingHostEvent() throws {
        let db = try TestDB()
        let event = SampleData.event(name: "我的婚礼", hostMode: .host)
        let contact = SampleData.contact()
        db.context.insert(event)
        db.context.insert(contact)
        db.context.insert(SampleData.record(contact: contact, event: event, amount: 500, direction: .given))
        try db.context.save()

        let updatedCount = try EventHostModeNormalizer.normalizeEvents(context: db.context)

        #expect(updatedCount == 0)
        #expect(event.hostMode == .host)
    }

    @Test func isIdempotentAcrossRepeatedRuns() throws {
        let db = try TestDB()
        let event = SampleData.event(name: "旧礼簿", hostMode: .guest)
        let contactA = SampleData.contact(name: "张三")
        let contactB = SampleData.contact(name: "李四")
        db.context.insert(event)
        db.context.insert(contactA)
        db.context.insert(contactB)
        db.context.insert(SampleData.record(contact: contactA, event: event, amount: 1000, direction: .received))
        db.context.insert(SampleData.record(contact: contactB, event: event, amount: 800, direction: .received))
        try db.context.save()

        let firstRunUpdated = try EventHostModeNormalizer.normalizeEvents(context: db.context)
        let secondRunUpdated = try EventHostModeNormalizer.normalizeEvents(context: db.context)

        #expect(firstRunUpdated == 1)
        #expect(secondRunUpdated == 0)
        #expect(event.hostMode == .host)
    }
}
