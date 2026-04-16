import SwiftData
import SwiftUI

@MainActor
private func makeExchangePreviewContainer() -> ModelContainer? {
    guard let container = try? ModelContainer(
        for: Contact.self, Record.self, Event.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    ) else { return nil }
    let context = container.mainContext

    let contact = Contact(name: "李小明", relation: "大学同学", category: "朋友", circle: 3)
    context.insert(contact)

    let e1 = Event(name: "张三婚礼", type: .wedding, date: .previewDate(2025, 10, 24))
    let e2 = Event(name: "春节聚会", type: .festival, date: .previewDate(2025, 10, 15))
    let e3 = Event(name: "生日礼物", type: .birthday, date: .previewDate(2025, 9, 28))
    let e4 = Event(name: "乔迁之喜", type: .property, date: .previewDate(2025, 8, 10))
    [e1, e2, e3, e4].forEach { context.insert($0) }

    let records: [Record] = [
        Record.makeMonetaryRecord(
            contact: contact,
            event: e1,
            amount: 1200,
            direction: .given,
            note: "用于UI设计外包首笔款项",
            date: .previewDate(2025, 10, 24)
        ),
        Record.makeMonetaryRecord(
            contact: contact,
            event: e2,
            amount: 2500,
            direction: .received,
            note: "已通过微信转账确认收妥",
            date: .previewDate(2025, 10, 15)
        ),
        Record.makeMonetaryRecord(
            contact: contact,
            event: e3,
            amount: 500,
            direction: .given,
            note: "送出的书籍与咖啡卡",
            date: .previewDate(2025, 9, 28)
        ),
        Record.makeMonetaryRecord(
            contact: contact,
            event: e4,
            amount: 800,
            direction: .given,
            date: .previewDate(2025, 8, 10)
        ),
        Record.makeMonetaryRecord(
            contact: contact,
            event: e2,
            amount: 1000,
            direction: .received,
            date: .previewDate(2025, 7, 1)
        ),
    ]
    records.forEach { context.insert($0) }

    return container
}

private extension Date {
    static func previewDate(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? .now
    }
}

#Preview {
    Group {
        if let container = makeExchangePreviewContainer(),
           let contacts = try? container.mainContext.fetch(FetchDescriptor<Contact>()),
           let first = contacts.first
        {
            NavigationStack {
                ContactExchangeView(contactID: first.persistentModelID)
            }
            .modelContainer(container)
        } else {
            Text(String(localized: "common.preview.unavailable"))
        }
    }
}
