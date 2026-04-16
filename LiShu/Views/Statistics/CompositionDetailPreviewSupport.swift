import SwiftData
import SwiftUI

@MainActor
private func makeCompositionDetailPreviewContainer() -> ModelContainer? {
    guard let container = try? ModelContainer(
        for: Contact.self, Record.self, Event.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    ) else {
        return nil
    }

    let context = container.mainContext
    let calendar = Calendar.current
    let currentYear = calendar.component(.year, from: .now)

    let contacts = [
        Contact(name: "王志刚", relation: "伯父", circle: 1),
        Contact(name: "李美玲", relation: "表姐", circle: 2),
    ]
    contacts.forEach { context.insert($0) }

    let events = [
        Event(name: "结婚喜宴", type: .wedding, date: calendar.liShuDate(year: currentYear, month: 1, day: 15)),
        Event(name: "生日聚会", type: .birthday, date: calendar.liShuDate(year: currentYear, month: 5, day: 20)),
    ]
    events.forEach { context.insert($0) }

    let records = [
        Record.makeMonetaryRecord(
            contact: contacts[0],
            event: events[0],
            amount: 3000,
            direction: .received,
            date: calendar.liShuDate(year: currentYear, month: 1, day: 15)
        ),
        Record.makeMonetaryRecord(
            contact: contacts[1],
            event: events[0],
            amount: 2000,
            direction: .given,
            date: calendar.liShuDate(year: currentYear, month: 2, day: 10)
        ),
        Record.makeMonetaryRecord(
            contact: contacts[0],
            event: events[1],
            amount: 800,
            direction: .received,
            date: calendar.liShuDate(year: currentYear, month: 5, day: 20)
        ),
    ]
    records.forEach { context.insert($0) }

    return container
}

struct CompositionRecordTypesPreview: View {
    var body: some View {
        Group {
            if let container = makeCompositionDetailPreviewContainer() {
                NavigationStack {
                    CompositionDetailView(
                        mode: .recordTypes(year: Calendar.current.component(.year, from: .now))
                    )
                }
                .modelContainer(container)
            } else {
                Text(String(localized: "common.preview.unavailable"))
            }
        }
    }
}

struct CompositionEventTypesPreview: View {
    var body: some View {
        Group {
            if let container = makeCompositionDetailPreviewContainer() {
                NavigationStack {
                    CompositionDetailView(
                        mode: .eventTypes(year: Calendar.current.component(.year, from: .now))
                    )
                }
                .modelContainer(container)
            } else {
                Text(String(localized: "common.preview.unavailable"))
            }
        }
    }
}
