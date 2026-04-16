import SwiftData
import SwiftUI

struct RecordDetailPreview: View {
    @Environment(\.modelContext) private var modelContext
    @State private var recordID: PersistentIdentifier?

    var body: some View {
        NavigationStack {
            if let recordID {
                RecordDetailView(recordID: recordID)
            } else {
                ProgressView()
            }
        }
        .onAppear(perform: seedData)
    }

    private func seedData() {
        let calendar = Calendar.current

        let contact = Contact(name: "张三", relation: "朋友")
        modelContext.insert(contact)

        let weddingEvent = Event(
            name: "结婚大礼",
            type: .wedding,
            date: calendar.liShuDateByAddingDays(-60)
        )
        modelContext.insert(weddingEvent)

        let primaryRecord = Record.makeMonetaryRecord(
            contact: contact,
            event: weddingEvent,
            amount: 1000,
            direction: .given,
            paymentMethod: .wechat,
            returnedAmount: 200,
            note: "记得发送感谢短信。这是一个非常慷慨的婚礼礼物。下次见面记得带伴手礼。",
            date: calendar.liShuDateByAddingDays(-60)
        )
        modelContext.insert(primaryRecord)

        let festivalEvent = Event(
            name: "春节聚会",
            type: .festival,
            date: calendar.liShuDateByAddingMonths(-3)
        )
        modelContext.insert(festivalEvent)

        let historyRecords = [
            Record.makeMonetaryRecord(
                contact: contact,
                event: festivalEvent,
                amount: 500,
                direction: .received,
                paymentMethod: .cash,
                date: calendar.liShuDateByAddingMonths(-3)
            ),
            Record.makeMonetaryRecord(
                contact: contact,
                event: weddingEvent,
                amount: 300,
                direction: .received,
                paymentMethod: .alipay,
                date: calendar.liShuDateByAddingDays(-30)
            ),
        ]
        historyRecords.forEach { modelContext.insert($0) }

        try? modelContext.save()
        recordID = primaryRecord.persistentModelID
    }
}
