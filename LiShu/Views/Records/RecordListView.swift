import SwiftData
import SwiftUI

struct RecordListView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel = RecordListViewModel()
    @State private var sheetRoute: SheetRoute?
    @State private var pendingSearchTask: Task<Void, Never>?
    @State private var pendingDeleteRecord: Record?
    @State private var selectedRecordRoute: SelectedRecordRoute?

    var body: some View {
        VStack(spacing: 0) {
            RecordListContentView(
                viewModel: viewModel,
                hasActiveQuery: hasActiveQuery,
                onRetry: loadRecords,
                onAddRecord: addRecord,
                onClearFilters: clearFilters,
                onSelectFilter: selectFilter(_:),
                onOpenRecord: openRecord(_:),
                onDeleteRecord: promptDelete(_:),
                onReturnGift: openReturnGift(_:),
                filterTitle: filterTitle(_:)
            )
        }
        .background(DesignSystem.Colors.bgPage)
        .navigationTitle(String(localized: "record.list.title"))
        .navigationBarTitleDisplayMode(.large)
        .trackScreen("records.list")
        .searchable(text: $viewModel.searchText, prompt: String(localized: "record.list.searchPlaceholder"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                addButtonMenu
            }
        }
        .onAppear(perform: loadRecords)
        .onChange(of: viewModel.filter) { _, _ in
            loadRecords()
        }
        .onChange(of: viewModel.searchText) { _, _ in
            scheduleSearch()
        }
        .sheet(item: $sheetRoute, content: sheetContent(for:))
        .navigationDestination(item: $selectedRecordRoute) { route in
            RecordDetailView(recordID: route.id)
        }
        .onChange(of: sheetRoute) { _, newValue in
            handleSheetChange(newValue)
        }
        .onDisappear {
            pendingSearchTask?.cancel()
        }
        .alert(String(localized: "common.error"), isPresented: deleteErrorBinding) {
            Button(String(localized: "common.ok")) {
                viewModel.deleteError = nil
            }
        } message: {
            if let message = viewModel.deleteError {
                Text(message)
            }
        }
        .alert(
            String(localized: "record.detail.deleteConfirm"),
            isPresented: pendingDeleteBinding
        ) {
            Button(String(localized: "common.cancel"), role: .cancel) {
                pendingDeleteRecord = nil
            }
            Button(String(localized: "common.delete"), role: .destructive, action: confirmDelete)
        } message: {
            Text(recordDeleteMessage)
        }
    }

    private var addButtonMenu: some View {
        Menu {
            Button(action: addRecord) {
                Label(String(localized: "home.addRecord"), systemImage: "square.and.pencil")
            }
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(DesignSystem.Colors.primary)
        }
        .accessibilityIdentifier("record.list.addButton")
    }

    private var hasActiveQuery: Bool {
        viewModel.filter != .all || !viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var deleteErrorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.deleteError != nil },
            set: { if !$0 { viewModel.deleteError = nil } }
        )
    }

    private var pendingDeleteBinding: Binding<Bool> {
        Binding(
            get: { pendingDeleteRecord != nil },
            set: { if !$0 { pendingDeleteRecord = nil } }
        )
    }

    private var recordDeleteMessage: String {
        guard let pendingDeleteRecord else { return "" }
        let photoCount = Int64(pendingDeleteRecord.photos?.count ?? 0)
        return String(
            format: String(localized: "record.list.deleteConfirmMessage"),
            photoCount
        )
    }

    private func loadRecords() {
        viewModel.load(context: modelContext)
    }

    private func scheduleSearch() {
        pendingSearchTask?.cancel()
        pendingSearchTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            loadRecords()
        }
    }

    private func addRecord() {
        let route = SheetRoute.addRecord(direction: nil, contactID: nil, eventID: nil)
        InteractionLogger.tap(
            screen: "records.list",
            target: "records.list.addRecord",
            route: route.logName,
            presentation: .sheet
        )
        sheetRoute = route
    }

    private func clearFilters() {
        withAnimation(.easeInOut(duration: 0.2)) {
            viewModel.filter = .all
            viewModel.searchText = ""
        }
        InteractionLogger.tap(screen: "records.list", target: "records.list.clearFilters")
    }

    private func selectFilter(_ filter: RecordFilter) {
        withAnimation(.easeInOut(duration: 0.2)) {
            viewModel.filter = filter
        }
        InteractionLogger.tap(
            screen: "records.list",
            target: "records.list.filter.\(filter.rawValue)"
        )
    }

    private func openRecord(_ record: Record) {
        InteractionLogger.navigation(
            screen: "records.list",
            target: "records.list.record.\(String(describing: record.persistentModelID))",
            route: AppRoute.recordDetail(record.persistentModelID).logName
        )
        selectedRecordRoute = SelectedRecordRoute(id: record.persistentModelID)
    }

    private func promptDelete(_ record: Record) {
        pendingDeleteRecord = record
    }

    private func confirmDelete() {
        guard let pendingDeleteRecord else { return }
        viewModel.deleteRecord(pendingDeleteRecord, context: modelContext)
        self.pendingDeleteRecord = nil
    }

    private func openReturnGift(_ record: Record) {
        InteractionLogger.contextMenuAction(
            screen: "records.list",
            target: "records.list.returnGift",
            action: .open,
            metadata: ["record_id": String(describing: record.persistentModelID)]
        )
        sheetRoute = .returnGift(recordID: record.persistentModelID)
    }

    private func handleSheetChange(_ newValue: SheetRoute?) {
        if let newValue {
            InteractionLogger.sheetPresentation(screen: "records.list", route: newValue.logName, isPresented: true)
        }
        if newValue == nil {
            loadRecords()
        }
    }

    @ViewBuilder
    private func sheetContent(for route: SheetRoute) -> some View {
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
                AddEventView()
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

    private func filterTitle(_ filter: RecordFilter) -> String {
        switch filter {
        case .all:
            String(localized: "record.filter.all")
        case .monetary:
            String(localized: "record.type.monetary")
        case .gift:
            String(localized: "record.type.gift")
        case .favor:
            String(localized: "record.type.favor")
        case .banquet:
            String(localized: "record.type.banquet")
        }
    }
}

private struct SelectedRecordRoute: Identifiable, Hashable {
    let id: PersistentIdentifier
}

#Preview {
    Group {
        if let container = makeRecordListPreviewContainer() {
            NavigationStack {
                RecordListView()
            }
            .modelContainer(container)
        } else {
            Text(String(localized: "common.preview.unavailable"))
        }
    }
}
