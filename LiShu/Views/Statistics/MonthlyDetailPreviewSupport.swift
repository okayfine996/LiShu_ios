import SwiftData
import SwiftUI

@MainActor
private func makeMonthlyDetailPreviewContainer() -> ModelContainer? {
    guard let container = try? ModelContainer(
        for: Contact.self, Record.self, Event.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    ) else { return nil }
    let context = container.mainContext

    let contactA = Contact(name: "张三", relation: "朋友", circle: 3)
    let contactB = Contact(name: "李华", relation: "同事", circle: 3)
    let contactC = Contact(name: "王芳", relation: "表姐", circle: 2)
    let contactD = Contact(name: "赵明", relation: "同学", circle: 3)
    [contactA, contactB, contactC, contactD].forEach { context.insert($0) }

    let eventA = Event(name: "张三婚礼", type: .wedding, date: .monthlyDetailPreviewDate(2026, 3, 8))
    let eventB = Event(name: "李华生日", type: .birthday, date: .monthlyDetailPreviewDate(2026, 3, 15))
    let eventC = Event(name: "王芳满月酒", type: .birth, date: .monthlyDetailPreviewDate(2026, 3, 20))
    let eventD = Event(name: "赵明乔迁", type: .property, date: .monthlyDetailPreviewDate(2026, 1, 10))
    let eventE = Event(name: "春节", type: .festival, date: .monthlyDetailPreviewDate(2026, 2, 17))
    [eventA, eventB, eventC, eventD, eventE].forEach { context.insert($0) }

    let records: [Record] = [
        Record.makeMonetaryRecord(
            contact: contactA,
            event: eventA,
            amount: 2000,
            direction: .given,
            date: .monthlyDetailPreviewDate(2026, 3, 8)
        ),
        Record.makeMonetaryRecord(
            contact: contactB,
            event: eventB,
            amount: 500,
            direction: .given,
            date: .monthlyDetailPreviewDate(2026, 3, 15)
        ),
        Record.makeMonetaryRecord(
            contact: contactC,
            event: eventC,
            amount: 800,
            direction: .received,
            date: .monthlyDetailPreviewDate(2026, 3, 20)
        ),
        Record.makeMonetaryRecord(
            contact: contactA,
            event: eventA,
            amount: 1000,
            direction: .received,
            date: .monthlyDetailPreviewDate(2026, 3, 9)
        ),
        Record.makeMonetaryRecord(
            contact: contactD,
            event: eventD,
            amount: 600,
            direction: .given,
            date: .monthlyDetailPreviewDate(2026, 1, 10)
        ),
        Record.makeMonetaryRecord(
            contact: contactB,
            event: eventE,
            amount: 1200,
            direction: .received,
            date: .monthlyDetailPreviewDate(2026, 2, 17)
        ),
        Record.makeMonetaryRecord(
            contact: contactC,
            event: eventE,
            amount: 800,
            direction: .given,
            date: .monthlyDetailPreviewDate(2026, 2, 18)
        ),
    ]
    records.forEach { context.insert($0) }

    return container
}

private extension Date {
    static func monthlyDetailPreviewDate(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? .now
    }
}

#Preview {
    Group {
        if let container = makeMonthlyDetailPreviewContainer() {
            NavigationStack {
                MonthlyDetailView(period: .month(year: 2026, month: 3))
            }
            .modelContainer(container)
        } else {
            Text(String(localized: "common.preview.unavailable"))
        }
    }
}

#Preview("Quarter") {
    Group {
        if let container = makeMonthlyDetailPreviewContainer() {
            NavigationStack {
                MonthlyDetailView(period: .quarter(year: 2026, quarter: 1))
            }
            .modelContainer(container)
        } else {
            Text(String(localized: "common.preview.unavailable"))
        }
    }
}
