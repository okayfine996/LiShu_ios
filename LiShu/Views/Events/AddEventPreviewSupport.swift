import SwiftData
import SwiftUI

#Preview("新建 - 宾客模式") {
    AddEventPreviewWrapper(defaultHostMode: .guest)
}

#Preview("新建 - 主场模式") {
    AddEventPreviewWrapper(defaultHostMode: .host)
}

#Preview("编辑已有活动") {
    AddEventEditPreviewWrapper()
}

// MARK: - Preview Wrappers

private struct AddEventPreviewWrapper: View {
    let defaultHostMode: EventHostMode

    private let container: ModelContainer? = {
        guard let c = try? ModelContainer(
            for: Contact.self, Record.self, Event.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        ) else { return nil }
        AddEventPreviewData.insertContacts(into: c.mainContext)
        return c
    }()

    var body: some View {
        if let container {
            NavigationStack {
                AddEventView(defaultHostMode: defaultHostMode)
            }
            .modelContainer(container)
        } else {
            Text(String(localized: "common.preview.unavailable"))
        }
    }
}

private struct AddEventEditPreviewWrapper: View {
    private let container: ModelContainer?
    private let eventID: PersistentIdentifier?

    init() {
        guard let c = try? ModelContainer(
            for: Contact.self, Record.self, Event.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        ) else {
            container = nil
            eventID = nil
            return
        }
        let contacts = AddEventPreviewData.insertContacts(into: c.mainContext)
        let event = Event(
            name: "张伟婚礼",
            type: .wedding,
            hostMode: .guest,
            date: Calendar.current.date(byAdding: .day, value: 30, to: .now) ?? .now,
            location: "北京香格里拉大酒店",
            note: "记得带红包",
            primaryContact: contacts.first
        )
        c.mainContext.insert(event)
        try? c.mainContext.save()
        container = c
        eventID = event.persistentModelID
    }

    var body: some View {
        if let container, let eventID {
            NavigationStack {
                AddEventView(eventID: eventID)
            }
            .modelContainer(container)
        } else {
            Text(String(localized: "common.preview.unavailable"))
        }
    }
}

// MARK: - Seed Data

enum AddEventPreviewData {
    @discardableResult
    static func insertContacts(into context: ModelContext) -> [Contact] {
        let contacts = [
            Contact(name: "张伟", relation: "配偶", category: "家人", circle: 1),
            Contact(name: "李娜", relation: "母亲", category: "家人", circle: 1),
            Contact(name: "王强", relation: "好友", category: "社交", circle: 3),
            Contact(name: "赵丽", relation: "同事", category: "社交", circle: 3),
            Contact(name: "陈明", relation: "表兄弟", category: "亲属", circle: 2),
            Contact(name: "周婷", relation: "同学", category: "社交", circle: 3),
        ]
        for contact in contacts {
            context.insert(contact)
        }
        try? context.save()
        return contacts
    }
}
