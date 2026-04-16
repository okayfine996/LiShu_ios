import SwiftData
import SwiftUI

@MainActor
private func makeCircleDetailPreviewContainer() -> ModelContainer? {
    guard let container = try? ModelContainer(
        for: Contact.self, Record.self, Event.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    ) else {
        return nil
    }
    let context = container.mainContext

    let contacts = [
        Contact(name: "张伯伯", relation: "父亲的长兄", circle: 2),
        Contact(name: "李阿姨", relation: "母亲的表妹", circle: 2),
        Contact(name: "王小弟", relation: "堂弟", circle: 2),
        Contact(name: "陈奶奶", relation: "外祖母", circle: 2),
    ]
    contacts.forEach { context.insert($0) }

    let events = [
        Event(name: "结婚喜宴", type: .wedding, date: .now),
        Event(name: "生日祝寿", type: .birthday, date: .now),
    ]
    events.forEach { context.insert($0) }

    let records: [Record] = [
        Record.makeMonetaryRecord(contact: contacts[0], event: events[0], amount: 20000, direction: .received, paymentMethod: .wechat),
        Record.makeMonetaryRecord(contact: contacts[0], event: events[1], amount: 5000, direction: .given, paymentMethod: .cash),
        Record.makeMonetaryRecord(contact: contacts[1], event: events[0], amount: 10000, direction: .received, paymentMethod: .alipay),
        Record.makeMonetaryRecord(contact: contacts[1], event: events[1], amount: 3000, direction: .given, paymentMethod: .wechat),
        Record.makeMonetaryRecord(contact: contacts[2], event: events[0], amount: 5000, direction: .received, paymentMethod: .cash),
        Record.makeMonetaryRecord(contact: contacts[2], event: events[1], amount: 2000, direction: .given, paymentMethod: .alipay),
        Record.makeMonetaryRecord(contact: contacts[3], event: events[0], amount: 3000, direction: .received, paymentMethod: .cash),
        Record.makeMonetaryRecord(contact: contacts[3], event: events[1], amount: 2000, direction: .given, paymentMethod: .wechat),
    ]
    records.forEach { context.insert($0) }

    return container
}

struct CircleDetailPreview: View {
    var body: some View {
        Group {
            if let container = makeCircleDetailPreviewContainer() {
                NavigationStack {
                    CircleDetailView(circle: 2, year: Calendar.current.component(.year, from: .now))
                }
                .modelContainer(container)
            } else {
                Text(String(localized: "common.preview.unavailable"))
            }
        }
    }
}
