import Foundation
@testable import LiShu
import SwiftData
import Testing

@MainActor
struct DataRelationshipTests {
    @Test func contactCascadeDeleteRemovesRecords() throws {
        let db = try TestDB()
        let contact = SampleData.contact(name: "级联删除测试")
        let event1 = SampleData.event(name: "事件1")
        let event2 = SampleData.event(name: "事件2")
        db.context.insert(contact)
        db.context.insert(event1)
        db.context.insert(event2)

        let r1 = SampleData.record(contact: contact, event: event1, amount: 500)
        let r2 = SampleData.record(contact: contact, event: event2, amount: 300)
        let r3 = SampleData.record(contact: contact, event: event1, amount: 200, direction: .received)
        db.context.insert(r1)
        db.context.insert(r2)
        db.context.insert(r3)
        try db.context.save()

        #expect(try db.context.fetchCount(FetchDescriptor<Record>()) == 3)

        db.context.delete(contact)
        try db.context.save()

        #expect(try db.context.fetchCount(FetchDescriptor<Contact>()) == 0)
        #expect(try db.context.fetchCount(FetchDescriptor<Record>()) == 0)
        #expect(try db.context.fetchCount(FetchDescriptor<Event>()) == 2)
    }

    /// 与 `Event` 的 nullify 删除规则一致：删事件后记录仍存在且 `event == nil`。
    @Test func eventDeleteNullifiesRecordEventReference() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event(name: "不可删除事件")
        db.context.insert(contact)
        db.context.insert(event)

        let record = SampleData.record(contact: contact, event: event, amount: 500)
        db.context.insert(record)
        try db.context.save()

        db.context.delete(event)
        try db.context.save()

        #expect(try db.context.fetchCount(FetchDescriptor<Event>()) == 0)
        let records = try db.context.fetch(FetchDescriptor<Record>())
        #expect(records.count == 1)
        #expect(records.first?.event == nil)
    }

    @Test func eventDeleteWithoutRecords() throws {
        let db = try TestDB()
        let event = SampleData.event(name: "可删除事件")
        db.context.insert(event)
        try db.context.save()

        db.context.delete(event)
        try db.context.save()

        #expect(try db.context.fetchCount(FetchDescriptor<Event>()) == 0)
    }

    @Test func recordPhotoRelationshipAndCascade() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)

        let record = SampleData.record(contact: contact, event: event)
        db.context.insert(record)

        let photo1 = SampleData.recordPhoto(record: record, data: Data([0x01, 0x02]))
        let photo2 = SampleData.recordPhoto(record: record, data: Data([0x03, 0x04]))
        db.context.insert(photo1)
        db.context.insert(photo2)
        try db.context.save()

        #expect(record.photos?.count == 2)
        #expect(try db.context.fetchCount(FetchDescriptor<RecordPhoto>()) == 2)

        db.context.delete(contact)
        try db.context.save()

        #expect(try db.context.fetchCount(FetchDescriptor<Record>()) == 0)
        #expect(try db.context.fetchCount(FetchDescriptor<RecordPhoto>()) == 0)
    }

    @Test func deleteAllDataFlow() throws {
        let db = try TestDB()
        let contact = SampleData.contact(name: "全删测试")
        let event = SampleData.event(name: "全删事件")
        db.context.insert(contact)
        db.context.insert(event)

        let record = SampleData.record(contact: contact, event: event, amount: 500)
        let photo = SampleData.recordPhoto(record: record)
        db.context.insert(record)
        db.context.insert(photo)
        try db.context.save()

        #expect(try db.context.fetchCount(FetchDescriptor<Contact>()) == 1)
        #expect(try db.context.fetchCount(FetchDescriptor<Event>()) == 1)
        #expect(try db.context.fetchCount(FetchDescriptor<Record>()) == 1)
        #expect(try db.context.fetchCount(FetchDescriptor<RecordPhoto>()) == 1)

        try db.context.delete(model: Record.self)
        try db.context.delete(model: Event.self)
        try db.context.delete(model: Contact.self)
        try db.context.save()

        #expect(try db.context.fetchCount(FetchDescriptor<Contact>()) == 0)
        #expect(try db.context.fetchCount(FetchDescriptor<Event>()) == 0)
        #expect(try db.context.fetchCount(FetchDescriptor<Record>()) == 0)
        #expect(try db.context.fetchCount(FetchDescriptor<RecordPhoto>()) == 0)
    }
}
