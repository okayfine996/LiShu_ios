import SwiftData
import SwiftUI

@MainActor
private func makeEventListPreviewContainer() -> ModelContainer? {
    guard let container = try? ModelContainer(
        for: Contact.self, Record.self, Event.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    ) else { return nil }
    let context = container.mainContext

    let c1 = Contact(name: "张三", relation: "同事")
    let c2 = Contact(name: "李四", relation: "朋友")
    [c1, c2].forEach { context.insert($0) }

    let calendar = Calendar.current
    let e1 = Event(name: "张三的婚礼", type: .wedding, date: calendar.liShuDateByAddingDays(3), location: "北京国贸大酒店")
    let e2 = Event(name: "李四生日宴", type: .birthday, date: calendar.liShuDateByAddingDays(10), location: "上海外滩")
    let e3 = Event(name: "小明毕业典礼", type: .education, date: calendar.liShuDateByAddingDays(21), location: "广州大学")
    let e4 = Event(name: "春节聚会", type: .festival, date: calendar.liShuDateByAddingMonths(-2), location: "老家")
    let e5 = Event(name: "王五乔迁", type: .property, date: calendar.liShuDateByAddingMonths(-3), location: "深圳南山")
    [e1, e2, e3, e4, e5].forEach { context.insert($0) }

    let r1 = Record.makeMonetaryRecord(
        contact: c1,
        event: e4,
        amount: 500,
        direction: .given,
        date: calendar.liShuDateByAddingMonths(-2)
    )
    let r2 = Record.makeMonetaryRecord(
        contact: c2,
        event: e4,
        amount: 300,
        direction: .received,
        date: calendar.liShuDateByAddingMonths(-2)
    )
    let r3 = Record.makeMonetaryRecord(
        contact: c1,
        event: e5,
        amount: 1000,
        direction: .given,
        date: calendar.liShuDateByAddingMonths(-3)
    )
    [r1, r2, r3].forEach { context.insert($0) }

    return container
}

#Preview {
    Group {
        if let container = makeEventListPreviewContainer() {
            NavigationStack {
                EventListView()
            }
            .modelContainer(container)
        } else {
            Text(String(localized: "common.preview.unavailable"))
        }
    }
}
