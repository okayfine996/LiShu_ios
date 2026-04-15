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
            recordsContent
        }
        .background(DesignSystem.Colors.bgPage)
        .navigationTitle(String(localized: "record.list.title"))
        .navigationBarTitleDisplayMode(.large)
        .trackScreen("records.list")
        .searchable(text: $viewModel.searchText, prompt: String(localized: "record.list.searchPlaceholder"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        InteractionLogger.tap(
                            screen: "records.list",
                            target: "records.list.addRecord",
                            route: SheetRoute.addRecord(direction: nil, contactID: nil, eventID: nil).logName,
                            presentation: .sheet
                        )
                        sheetRoute = .addRecord(direction: nil, contactID: nil, eventID: nil)
                    } label: {
                        Label(String(localized: "home.addRecord"), systemImage: "square.and.pencil")
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.primary)
                }
                .accessibilityIdentifier("record.list.addButton")
            }
        }
        .onAppear {
            viewModel.load(context: modelContext)
        }
        .onChange(of: viewModel.filter) { _, _ in
            viewModel.load(context: modelContext)
        }
        .onChange(of: viewModel.searchText) { _, _ in
            pendingSearchTask?.cancel()
            pendingSearchTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(300))
                guard !Task.isCancelled else { return }
                viewModel.load(context: modelContext)
            }
        }
        .sheet(item: $sheetRoute) { route in
            sheetContent(for: route)
        }
        .navigationDestination(item: $selectedRecordRoute) { route in
            RecordDetailView(recordID: route.id)
        }
        .onChange(of: sheetRoute) { _, newValue in
            if let newValue {
                InteractionLogger.sheetPresentation(screen: "records.list", route: newValue.logName, isPresented: true)
            }
            if newValue == nil {
                viewModel.load(context: modelContext)
            }
        }
        .onDisappear {
            pendingSearchTask?.cancel()
        }
        .alert(String(localized: "common.error"), isPresented: Binding(
            get: { viewModel.deleteError != nil },
            set: { if !$0 { viewModel.deleteError = nil } }
        )) {
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
                viewModel.deleteRecord(pendingDeleteRecord, context: modelContext)
                self.pendingDeleteRecord = nil
            }
        } message: {
            Text(recordDeleteMessage)
        }
    }

    // MARK: - Records Content

    @ViewBuilder
    private var recordsContent: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case let .loaded(grouped) where grouped.isEmpty:
            if hasActiveQuery {
                filteredEmptyContent
            } else {
                EmptyStateView(
                    icon: "doc.text",
                    message: String(localized: "record.list.empty"),
                    actionTitle: String(localized: "home.addRecord"),
                    action: {
                        InteractionLogger.tap(
                            screen: "records.list",
                            target: "records.list.empty.addRecord",
                            route: SheetRoute.addRecord(direction: nil, contactID: nil, eventID: nil).logName,
                            presentation: .sheet
                        )
                        sheetRoute = .addRecord(direction: nil, contactID: nil, eventID: nil)
                    }
                )
            }
        case .loaded:
            recordsList
        case let .error(message):
            ErrorStateView(message: message) {
                viewModel.load(context: modelContext)
            }
        }
    }

    private var hasActiveQuery: Bool {
        viewModel.filter != .all || !viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var filteredEmptyContent: some View {
        List {
            listRow {
                filterChips
            }

            listRow(bottomInset: DesignSystem.Spacing.section) {
                EmptyStateView(
                    icon: "line.3.horizontal.decrease.circle",
                    message: String(localized: "record.list.empty"),
                    actionTitle: String(localized: "record.filter.all"),
                    action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.filter = .all
                            viewModel.searchText = ""
                        }
                        InteractionLogger.tap(screen: "records.list", target: "records.list.clearFilters")
                    }
                )
                .frame(minHeight: 320)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(DesignSystem.Colors.bgPage)
    }

    private var recordsList: some View {
        List {
            listRow {
                filterChips
            }

            ForEach(viewModel.sortedMonthKeys, id: \.self) { monthKey in
                monthSection(monthKey)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(DesignSystem.Colors.bgPage)
    }

    // MARK: - Filter Chips

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(RecordFilter.allCases, id: \.self) { filter in
                    let isSelected = viewModel.filter == filter
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.filter = filter
                        }
                        InteractionLogger.tap(
                            screen: "records.list",
                            target: "records.list.filter.\(filter.rawValue)"
                        )
                    } label: {
                        Text(filterTitle(filter))
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(isSelected ? .white : DesignSystem.Colors.textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.bgSurface)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(
                                    isSelected ? Color.clear : DesignSystem.Colors.border,
                                    lineWidth: 1
                                )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func filterTitle(_ filter: RecordFilter) -> String {
        switch filter {
        case .all: String(localized: "record.filter.all")
        case .monetary: String(localized: "record.type.monetary")
        case .gift: String(localized: "record.type.gift")
        case .favor: String(localized: "record.type.favor")
        case .banquet: String(localized: "record.type.banquet")
        }
    }

    // MARK: - Month Section

    private func monthSection(_ monthKey: String) -> some View {
        Section {
            if let records = viewModel.state.value?[monthKey] {
                ForEach(records) { record in
                    Button {
                        InteractionLogger.navigation(
                            screen: "records.list",
                            target: "records.list.record.\(String(describing: record.persistentModelID))",
                            route: AppRoute.recordDetail(record.persistentModelID).logName
                        )
                        selectedRecordRoute = SelectedRecordRoute(id: record.persistentModelID)
                    } label: {
                        RecordRow(record: record)
                            .background(DesignSystem.Colors.bgSurface)
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("record.list.row.\(String(describing: record.persistentModelID))")
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            pendingDeleteRecord = record
                        } label: {
                            Label(String(localized: "common.delete"), systemImage: "trash")
                        }
                    }
                    .contextMenu {
                        if record.recordType == .monetary, record.direction == .given {
                            Button {
                                InteractionLogger.contextMenuAction(
                                    screen: "records.list",
                                    target: "records.list.returnGift",
                                    action: .open,
                                    metadata: ["record_id": String(describing: record.persistentModelID)]
                                )
                                sheetRoute = .returnGift(recordID: record.persistentModelID)
                            } label: {
                                Label(String(localized: "record.detail.returnGift"), systemImage: "gift")
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets(
                        top: 0,
                        leading: DesignSystem.Spacing.pageHorizontal,
                        bottom: DesignSystem.Spacing.block,
                        trailing: DesignSystem.Spacing.pageHorizontal
                    ))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
        } header: {
            sectionHeader(monthKey)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(DesignSystem.Typography.caption)
            .foregroundStyle(DesignSystem.Colors.textSecondary)
            .fontWeight(.semibold)
            .textCase(nil)
            .padding(.top, DesignSystem.Spacing.block)
    }

    private func listRow(
        bottomInset: CGFloat = DesignSystem.Spacing.block,
        @ViewBuilder content: () -> some View
    ) -> some View {
        content()
            .listRowInsets(EdgeInsets(
                top: 0,
                leading: DesignSystem.Spacing.pageHorizontal,
                bottom: bottomInset,
                trailing: DesignSystem.Spacing.pageHorizontal
            ))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }

    private var recordDeleteMessage: String {
        guard let pendingDeleteRecord else { return "" }
        let photoCount = Int64(pendingDeleteRecord.photos?.count ?? 0)
        return String(
            format: String(localized: "record.list.deleteConfirmMessage"),
            photoCount
        )
    }

    // MARK: - Sheet

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
        case .ocrImport:
            OCRImportView()
        case .proMembership:
            NavigationStack {
                ProMembershipView()
            }
        }
    }
}

private struct SelectedRecordRoute: Identifiable, Hashable {
    let id: PersistentIdentifier
}

@MainActor
private func makeRecordListPreviewContainer() -> ModelContainer? {
    guard let container = try? ModelContainer(
        for: Contact.self, Record.self, Event.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    ) else { return nil }
    let ctx = container.mainContext

    let c1 = Contact(name: "李梅", relation: "同事")
    let c2 = Contact(name: "陈伟", relation: "朋友")
    let c3 = Contact(name: "张伟", relation: "亲戚")
    let c4 = Contact(name: "王芳", relation: "朋友")
    let c5 = Contact(name: "刘锦", relation: "同事")
    [c1, c2, c3, c4, c5].forEach { ctx.insert($0) }

    let cal = Calendar.current
    let e1 = Event(name: "结婚随礼", type: .wedding, date: cal.liShuDateByAddingDays(-6))
    let e2 = Event(name: "满月酒", type: .birth, date: cal.liShuDateByAddingDays(-10))
    let e3 = Event(name: "聚餐", type: .other, date: cal.liShuDateByAddingDays(-15))
    let e4 = Event(name: "乔迁之喜", type: .property, date: cal.liShuDateByAddingMonths(-1))
    let e5 = Event(name: "升职庆祝", type: .other, date: cal.liShuDateByAddingMonths(-1))
    [e1, e2, e3, e4, e5].forEach { ctx.insert($0) }

    let r1 = Record.makeMonetaryRecord(
        contact: c1,
        event: e1,
        amount: 2000,
        direction: .given,
        paymentMethod: .wechat,
        date: cal.liShuDateByAddingDays(-6)
    )
    let r2 = Record.makeMonetaryRecord(
        contact: c2,
        event: e2,
        amount: 800,
        direction: .received,
        paymentMethod: .cash,
        returnedAmount: 800,
        date: cal.liShuDateByAddingDays(-10)
    )
    let r3 = Record.makeMonetaryRecord(
        contact: c3,
        event: e3,
        amount: 500,
        direction: .given,
        paymentMethod: .alipay,
        returnedAmount: 500,
        date: cal.liShuDateByAddingDays(-15)
    )
    let r4 = Record.makeMonetaryRecord(
        contact: c4,
        event: e4,
        amount: 1200,
        direction: .given,
        paymentMethod: .wechat,
        date: cal.liShuDateByAddingMonths(-1)
    )
    let r5 = Record.makeMonetaryRecord(
        contact: c5,
        event: e5,
        amount: 600,
        direction: .received,
        paymentMethod: .cash,
        returnedAmount: 600,
        date: cal.liShuDateByAddingMonths(-1)
    )
    [r1, r2, r3, r4, r5].forEach { ctx.insert($0) }

    return container
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
