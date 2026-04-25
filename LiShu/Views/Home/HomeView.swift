import SwiftData
import SwiftUI

struct HomeView: View {
    @Query(sort: \Record.date, order: .reverse) private var records: [Record]
    @Query private var contacts: [Contact]
    @Query private var events: [Event]
    @State private var sheetRoute: SheetRoute?
    @Environment(\.guideCurrentAnchorID) private var guideAnchorID

    private var snapshot: HomeDashboardSnapshot {
        HomeDashboardSnapshot.build(records: records, events: events, contacts: contacts)
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                HomeDashboardContentView(snapshot: snapshot, sheetRoute: $sheetRoute)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 100)
            }
            .background(DesignSystem.Colors.bgPage)
            .onChange(of: guideAnchorID) { _, newID in
                guard let newID else { return }
                // Delay slightly so the layout (e.g. newly created ledger card) has settled
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation(.easeInOut(duration: 0.45)) {
                        proxy.scrollTo(newID, anchor: .center)
                    }
                }
            }
        }
        .navigationTitle(String(localized: "home.title"))
        .navigationBarTitleDisplayMode(.automatic)
        .sheet(item: $sheetRoute, content: sheetContent)
    }
}

private extension HomeView {
    @ViewBuilder
    func sheetContent(for route: SheetRoute) -> some View {
        switch route {
        case let .addRecord(direction, contactID, eventID):
            NavigationStack {
                AddRecordView(direction: direction, contactID: contactID, eventID: eventID)
            }
        case let .addLedgerReceipt(eventID):
            NavigationStack {
                AddLedgerReceiptView(eventID: eventID)
            }
        case .addContact:
            NavigationStack {
                AddContactView()
            }
        case .addEvent:
            NavigationStack {
                AddEventView(defaultHostMode: .host)
            }
        case let .editContact(contactID):
            NavigationStack {
                AddContactView(contactID: contactID)
            }
        case let .editEvent(eventID):
            NavigationStack {
                AddEventView(eventID: eventID)
            }
        case let .editRecord(recordID):
            NavigationStack {
                AddRecordView(recordID: recordID)
            }
        case let .returnGift(recordID):
            NavigationStack {
                ReturnGiftSheet(recordID: recordID)
            }
        case let .ocrImport(eventID):
            OCRImportView(eventID: eventID)
        case .proMembership:
            NavigationStack {
                ProMembershipView()
            }
        case let .smartReturnGift(eventID, contactID):
            NavigationStack {
                SmartReturnGiftView(eventID: eventID, contactID: contactID)
            }
        }
    }
}

@MainActor
private func makeHomePreviewContainer() -> ModelContainer? {
    guard let container = try? ModelContainer(
        for: Contact.self, Record.self, Event.self, RecordPhoto.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    ) else { return nil }
    DemoDataSeeding.insertSampleData(context: container.mainContext, attachDemoMedia: false)
    return container
}

#Preview {
    Group {
        if let container = makeHomePreviewContainer() {
            NavigationStack {
                HomeView()
            }
            .modelContainer(container)
            .environment(SubscriptionManager.shared)
        } else {
            Text(String(localized: "common.preview.unavailable"))
        }
    }
}
