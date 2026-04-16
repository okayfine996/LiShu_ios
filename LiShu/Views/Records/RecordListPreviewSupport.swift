import SwiftData
import SwiftUI

@MainActor
func makeRecordListPreviewContainer() -> ModelContainer? {
    guard let container = try? ModelContainer(
        for: Contact.self, Record.self, Event.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    ) else {
        return nil
    }
    let context = container.mainContext

    let contacts = [
        Contact(name: "李梅", relation: "同事"),
        Contact(name: "陈伟", relation: "朋友"),
        Contact(name: "张伟", relation: "亲戚"),
        Contact(name: "王芳", relation: "朋友"),
        Contact(name: "刘锦", relation: "同事"),
    ]
    contacts.forEach { context.insert($0) }

    let calendar = Calendar.current
    let events = [
        Event(name: "结婚随礼", type: .wedding, date: calendar.liShuDateByAddingDays(-6)),
        Event(name: "满月酒", type: .birth, date: calendar.liShuDateByAddingDays(-10)),
        Event(name: "聚餐", type: .other, date: calendar.liShuDateByAddingDays(-15)),
        Event(name: "乔迁之喜", type: .property, date: calendar.liShuDateByAddingMonths(-1)),
        Event(name: "升职庆祝", type: .other, date: calendar.liShuDateByAddingMonths(-1)),
    ]
    events.forEach { context.insert($0) }

    let records = [
        Record.makeMonetaryRecord(
            contact: contacts[0],
            event: events[0],
            amount: 2000,
            direction: .given,
            paymentMethod: .wechat,
            date: calendar.liShuDateByAddingDays(-6)
        ),
        Record.makeMonetaryRecord(
            contact: contacts[1],
            event: events[1],
            amount: 800,
            direction: .received,
            paymentMethod: .cash,
            returnedAmount: 800,
            date: calendar.liShuDateByAddingDays(-10)
        ),
        Record.makeMonetaryRecord(
            contact: contacts[2],
            event: events[2],
            amount: 500,
            direction: .given,
            paymentMethod: .alipay,
            returnedAmount: 500,
            date: calendar.liShuDateByAddingDays(-15)
        ),
        Record.makeMonetaryRecord(
            contact: contacts[3],
            event: events[3],
            amount: 1200,
            direction: .given,
            paymentMethod: .wechat,
            date: calendar.liShuDateByAddingMonths(-1)
        ),
        Record.makeMonetaryRecord(
            contact: contacts[4],
            event: events[4],
            amount: 600,
            direction: .received,
            paymentMethod: .cash,
            returnedAmount: 600,
            date: calendar.liShuDateByAddingMonths(-1)
        ),
    ]
    records.forEach { context.insert($0) }

    return container
}
