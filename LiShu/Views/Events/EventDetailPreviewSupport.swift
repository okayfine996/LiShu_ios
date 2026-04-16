import SwiftData
import SwiftUI

struct EventDetailPreview: View {
    @Environment(\.modelContext) private var modelContext
    @State private var eventID: PersistentIdentifier?

    let hostMode: EventHostMode
    var includeLegacyAnomalies = false

    var body: some View {
        NavigationStack {
            if let eventID {
                EventDetailView(eventID: eventID)
            } else {
                ProgressView()
            }
        }
        .onAppear(perform: seedData)
    }

    private func seedData() {
        let calendar = Calendar.current
        let contacts = [
            Contact(name: "张三", relation: "同事"),
            Contact(name: "李四", relation: "朋友"),
            Contact(name: "王五", relation: "亲戚"),
        ]
        contacts.forEach(modelContext.insert)

        let event = Event(
            name: hostMode == .host ? "我的婚礼礼簿" : "张三的婚礼",
            type: .wedding,
            hostMode: hostMode,
            date: calendar.liShuDateByAddingDays(3),
            location: "北京国贸大酒店",
            note: "提前一天到达，需要帮忙布置场地。记得带红包和礼物。"
        )
        modelContext.insert(event)

        let records = [
            Record.makeMonetaryRecord(
                contact: contacts[0],
                event: event,
                amount: 1000,
                direction: hostMode == .host ? .received : .given,
                paymentMethod: .wechat,
                date: calendar.liShuDateByAddingDays(-5)
            ),
            Record.makeMonetaryRecord(
                contact: contacts[1],
                event: event,
                amount: 500,
                direction: .received,
                paymentMethod: .cash,
                date: calendar.liShuDateByAddingDays(-3)
            ),
            Record.makeMonetaryRecord(
                contact: contacts[2],
                event: event,
                amount: 800,
                direction: hostMode == .host ? .received : .given,
                paymentMethod: .alipay,
                date: calendar.liShuDateByAddingDays(-1)
            ),
        ]
        records.forEach(modelContext.insert)

        if includeLegacyAnomalies, hostMode == .host {
            let legacyGift = makeGiftRecord(
                contact: contacts[0],
                event: event,
                giftName: "龙井礼盒",
                direction: .received,
                date: calendar.liShuDateByAddingDays(-2)
            )
            let legacyGiven = Record.makeMonetaryRecord(
                contact: contacts[1],
                event: event,
                amount: 300,
                direction: .given,
                paymentMethod: .cash,
                date: calendar.liShuDateByAddingDays(-4)
            )
            modelContext.insert(legacyGift)
            modelContext.insert(legacyGiven)
        }

        try? modelContext.save()
        eventID = event.persistentModelID
    }

    private func makeGiftRecord(
        contact: Contact,
        event: Event,
        giftName: String,
        direction: RecordDirection,
        date: Date
    ) -> Record {
        let record = Record(
            contact: contact,
            event: event,
            direction: direction,
            date: date,
            recordType: .gift,
            relationshipWeight: .reciprocal
        )
        record.applyTypeData(.gift(GiftData(giftName: giftName, estimatedValue: 288)))
        return record
    }
}

#Preview("Standard Event") {
    EventDetailPreview(hostMode: .guest)
        .modelContainer(for: [Contact.self, Record.self, Event.self], inMemory: true)
}

#Preview("Host Ledger") {
    EventDetailPreview(hostMode: .host)
        .modelContainer(for: [Contact.self, Record.self, Event.self], inMemory: true)
}

#Preview("Host Ledger Legacy Warning") {
    EventDetailPreview(hostMode: .host, includeLegacyAnomalies: true)
        .modelContainer(for: [Contact.self, Record.self, Event.self], inMemory: true)
}
