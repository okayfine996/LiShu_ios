import Foundation
@testable import LiShu
import SwiftData
import Testing

@MainActor
struct TestDB {
    let container: ModelContainer
    let context: ModelContext

    init() throws {
        let schema = Schema([Contact.self, Record.self, Event.self, RecordPhoto.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        context = container.mainContext
    }
}

@MainActor
struct SampleData {
    static func contact(name: String = "张三", relation: String = "朋友", category: String = "社会", circle: Int = 3) -> Contact {
        Contact(name: name, relation: relation, category: category, circle: circle)
    }

    static func event(name: String = "测试婚礼", type: EventType = .wedding, date: Date = .now) -> Event {
        Event(name: name, type: type, date: date, location: "北京")
    }

    static func typedRecord(
        contact: Contact,
        event: Event? = nil,
        direction: RecordDirection = .given,
        returnedAmount: Double = 0,
        note: String = "",
        date: Date = .now,
        recordType: RecordType,
        relationshipWeight: RelationshipWeight = .reciprocal,
        typeData: RecordTypeData
    ) -> Record {
        let record = Record(
            contact: contact,
            event: event,
            direction: direction,
            returnedAmount: returnedAmount,
            note: note,
            date: date,
            recordType: recordType,
            relationshipWeight: relationshipWeight
        )
        record.applyTypeData(typeData)
        return record
    }

    static func record(
        contact: Contact,
        event: Event? = nil,
        amount: Double = 500,
        direction: RecordDirection = .given,
        returnedAmount: Double = 0,
        date: Date = .now,
        relationshipWeight: RelationshipWeight = .reciprocal
    ) -> Record {
        typedRecord(
            contact: contact,
            event: event,
            direction: direction,
            returnedAmount: returnedAmount,
            date: date,
            recordType: .monetary,
            relationshipWeight: relationshipWeight,
            typeData: .monetary(MonetaryData(amount: amount, paymentMethod: PaymentMethod.cash.rawValue, returnedAmount: returnedAmount))
        )
    }

    static func recordGift(
        contact: Contact,
        event: Event? = nil,
        giftName: String = "茶叶礼盒",
        estimatedValue: Double? = 300,
        direction: RecordDirection = .given,
        date: Date = .now,
        relationshipWeight: RelationshipWeight = .reciprocal
    ) -> Record {
        typedRecord(
            contact: contact,
            event: event,
            direction: direction,
            date: date,
            recordType: .gift,
            relationshipWeight: relationshipWeight,
            typeData: .gift(GiftData(giftName: giftName, estimatedValue: estimatedValue))
        )
    }

    static func recordFavor(
        contact: Contact,
        event: Event? = nil,
        description: String = "帮忙接送长辈去医院",
        direction: RecordDirection = .given,
        date: Date = .now,
        relationshipWeight: RelationshipWeight = .reciprocal
    ) -> Record {
        typedRecord(
            contact: contact,
            event: event,
            direction: direction,
            date: date,
            recordType: .favor,
            relationshipWeight: relationshipWeight,
            typeData: .favor(FavorData(description: description))
        )
    }

    static func recordBanquet(
        contact: Contact,
        event: Event? = nil,
        location: String = "外婆家包厢，中档宴请",
        attendeeList: String = "主客外还有两位同事陪同",
        extraCostNotes: String = "席间开了两瓶酒",
        direction: RecordDirection = .given,
        date: Date = .now,
        relationshipWeight: RelationshipWeight = .reciprocal
    ) -> Record {
        typedRecord(
            contact: contact,
            event: event,
            direction: direction,
            date: date,
            recordType: .banquet,
            relationshipWeight: relationshipWeight,
            typeData: .banquet(BanquetData(location: location, attendeeList: attendeeList, extraCostNotes: extraCostNotes))
        )
    }

    static func recordPhoto(record: Record, data: Data = Data([0xFF, 0xD8, 0xFF])) -> RecordPhoto {
        RecordPhoto(record: record, imageData: data)
    }

    static func batchRecords(count: Int, contact: Contact, event: Event, baseAmount: Double = 100) -> [Record] {
        (0 ..< count).map { i in
            typedRecord(
                contact: contact,
                event: event,
                direction: i % 2 == 0 ? .given : .received,
                returnedAmount: 0,
                date: Calendar.current.date(byAdding: .day, value: -i, to: .now) ?? .now,
                recordType: .monetary,
                typeData: .monetary(MonetaryData(
                    amount: baseAmount + Double(i),
                    paymentMethod: PaymentMethod.cash.rawValue,
                    returnedAmount: 0
                ))
            )
        }
    }
}
