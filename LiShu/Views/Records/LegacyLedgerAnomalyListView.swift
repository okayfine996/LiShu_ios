import SwiftData
import SwiftUI

struct LegacyLedgerAnomalyListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var pendingDeleteRecord: Record?
    @State private var selectedRecordRoute: LegacyLedgerSelectedRecord?
    @Query(sort: \Record.date, order: .reverse) private var allRecords: [Record]

    let eventName: String
    let eventID: PersistentIdentifier

    private var displayedRecords: [Record] {
        allRecords.filter { EventDetailViewModel.isLegacyLedgerAnomaly($0, for: eventID) }
    }

    var body: some View {
        List {
            listRow {
                warningHeader
            }

            if displayedRecords.isEmpty {
                listRow {
                    EmptyStateView(
                        icon: "checkmark.seal",
                        message: String(localized: "event.ledger.legacyList.empty"),
                        actionTitle: nil,
                        action: nil
                    )
                    .frame(minHeight: 240)
                }
            } else {
                ForEach(displayedRecords) { record in
                    Button {
                        selectedRecordRoute = LegacyLedgerSelectedRecord(id: record.persistentModelID)
                    } label: {
                        RecordRow(record: record)
                    }
                    .buttonStyle(.plain)
                    .background(DesignSystem.Colors.bgSurface)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            pendingDeleteRecord = record
                        } label: {
                            Label(String(localized: "common.delete"), systemImage: "trash")
                        }
                    }
                    .listRowInsets(EdgeInsets(
                        top: 0,
                        leading: 16,
                        bottom: 16,
                        trailing: 16
                    ))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
        }
        .background(DesignSystem.Colors.bgPage)
        .scrollContentBackground(.hidden)
        .listStyle(.plain)
        .navigationTitle(String(localized: "event.ledger.legacyList.title"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedRecordRoute) { route in
            RecordDetailView(recordID: route.id)
        }
        .alert(
            String(localized: "record.detail.deleteConfirm"),
            isPresented: Binding(
                get: { pendingDeleteRecord != nil },
                set: { if !$0 { pendingDeleteRecord = nil } }
            )
        ) {
            Button(String(localized: "common.cancel"), role: .cancel) {
                pendingDeleteRecord = nil
            }
            Button(String(localized: "common.delete"), role: .destructive) {
                guard let pendingDeleteRecord else { return }
                deleteRecord(pendingDeleteRecord)
                self.pendingDeleteRecord = nil
            }
        }
    }

    private var warningHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(
                String(
                    format: String(localized: "event.ledger.legacyList.subtitle %@"),
                    eventName
                )
            )
            .font(DesignSystem.Typography.body)
            .foregroundStyle(DesignSystem.Colors.textPrimary)

            Text(String(localized: "event.ledger.legacyList.description"))
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
    }

    private func listRow(@ViewBuilder content: () -> some View) -> some View {
        content()
            .listRowInsets(EdgeInsets(
                top: 0,
                leading: 16,
                bottom: 16,
                trailing: 16
            ))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }

    private func deleteRecord(_ record: Record) {
        modelContext.delete(record)
        try? modelContext.save()
    }
}

private struct LegacyLedgerSelectedRecord: Identifiable, Hashable {
    let id: PersistentIdentifier
}

private struct LegacyLedgerAnomalyListPreviewContainer: View {
    let container: ModelContainer
    let eventName: String
    let eventID: PersistentIdentifier

    init() {
        container = try! ModelContainer(
            for: Schema([Contact.self, Record.self, Event.self]),
            configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
        )

        let context = container.mainContext
        let contactA = Contact(name: "张三", relation: "同事")
        let contactB = Contact(name: "李四", relation: "朋友")
        let event = Event(name: "我的婚礼礼簿", type: .wedding, hostMode: .host, date: .now, location: "北京")
        let giftRecord = Record(contact: contactA, event: event, direction: .received, date: .now, recordType: .gift)
        giftRecord.applyTypeData(.gift(GiftData(giftName: "龙井礼盒", estimatedValue: 288)))
        let givenRecord = Record.makeMonetaryRecord(
            contact: contactB,
            event: event,
            amount: 300,
            direction: .given,
            paymentMethod: .cash,
            date: Calendar.current.liShuDateByAddingDays(-1)
        )

        context.insert(contactA)
        context.insert(contactB)
        context.insert(event)
        context.insert(giftRecord)
        context.insert(givenRecord)
        try? context.save()

        eventName = event.name
        eventID = event.persistentModelID
    }

    var body: some View {
        NavigationStack {
            LegacyLedgerAnomalyListView(eventName: eventName, eventID: eventID)
        }
        .modelContainer(container)
    }
}

#Preview("Legacy Ledger Anomaly List") {
    LegacyLedgerAnomalyListPreviewContainer()
}
