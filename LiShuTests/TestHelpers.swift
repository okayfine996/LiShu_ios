import Foundation
import Testing
import SwiftData
@testable import LiShu

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

    static func record(contact: Contact, event: Event, amount: Double = 500, direction: RecordDirection = .given, returnedAmount: Double = 0, date: Date = .now) -> Record {
        Record(contact: contact, event: event, amount: amount, direction: direction, paymentMethod: .cash, returnedAmount: returnedAmount, date: date)
    }

    static func recordPhoto(record: Record, data: Data = Data([0xFF, 0xD8, 0xFF])) -> RecordPhoto {
        RecordPhoto(record: record, imageData: data)
    }

    static func batchRecords(count: Int, contact: Contact, event: Event, baseAmount: Double = 100) -> [Record] {
        (0..<count).map { i in
            Record(
                contact: contact,
                event: event,
                amount: baseAmount + Double(i),
                direction: i % 2 == 0 ? .given : .received,
                paymentMethod: .cash,
                returnedAmount: 0,
                date: Calendar.current.date(byAdding: .day, value: -i, to: .now) ?? .now
            )
        }
    }
}
