import SwiftUI
import SwiftData

struct RecordListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = RecordListViewModel()
    @State private var sheetRoute: SheetRoute?
    @State private var showOCRImport = false

    var body: some View {
        VStack(spacing: 0) {
            recordsContent
        }
        .background(DesignSystem.Colors.bgPage)
        .navigationTitle(String(localized: "record.list.title"))
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $viewModel.searchText, prompt: String(localized: "record.list.searchPlaceholder"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        sheetRoute = .addRecord(direction: nil, contactID: nil)
                    } label: {
                        Label(String(localized: "home.addRecord"), systemImage: "square.and.pencil")
                    }
                    Button {
                        showOCRImport = true
                    } label: {
                        Label(String(localized: "record.ocr.import"), systemImage: "doc.viewfinder")
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.primary)
                }
            }
        }
        .onAppear {
            viewModel.load(context: modelContext)
        }
        .onChange(of: viewModel.filter) { _, _ in
            viewModel.load(context: modelContext)
        }
        .onChange(of: viewModel.searchText) { _, _ in
            viewModel.load(context: modelContext)
        }
        .sheet(item: $sheetRoute) { route in
            sheetContent(for: route)
        }
        .onChange(of: sheetRoute) { _, newValue in
            if newValue == nil {
                viewModel.load(context: modelContext)
            }
        }
        .fullScreenCover(isPresented: $showOCRImport, onDismiss: {
            viewModel.load(context: modelContext)
        }) {
            OCRImportView()
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
    }

    // MARK: - Records Content

    @ViewBuilder
    private var recordsContent: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded(let grouped) where grouped.isEmpty:
            if hasActiveQuery {
                filteredEmptyContent
            } else {
                EmptyStateView(
                    icon: "doc.text",
                    message: String(localized: "record.list.empty"),
                    actionTitle: String(localized: "home.addRecord"),
                    action: {
                        sheetRoute = .addRecord(direction: nil, contactID: nil)
                    }
                )
            }
        case .loaded:
            recordsList
        case .error(let message):
            ErrorStateView(message: message) {
                viewModel.load(context: modelContext)
            }
        }
    }

    private var hasActiveQuery: Bool {
        viewModel.filter != .all || !viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var filteredEmptyContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                filterChips

                EmptyStateView(
                    icon: "line.3.horizontal.decrease.circle",
                    message: String(localized: "record.list.empty"),
                    actionTitle: String(localized: "record.filter.all"),
                    action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.filter = .all
                            viewModel.searchText = ""
                        }
                    }
                )
                .frame(minHeight: 320)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 80)
        }
    }

    private var recordsList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                filterChips

                ForEach(viewModel.sortedMonthKeys, id: \.self) { monthKey in
                    monthSection(monthKey)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 80)
        }
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
        case .all: return String(localized: "record.filter.all")
        case .monetary: return String(localized: "record.type.monetary")
        case .gift: return String(localized: "record.type.gift")
        case .favor: return String(localized: "record.type.favor")
        case .banquet: return String(localized: "record.type.banquet")
        }
    }

    // MARK: - Month Section

    private func monthSection(_ monthKey: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(monthKey)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .fontWeight(.semibold)
                .padding(.leading, 4)

            if let records = viewModel.state.value?[monthKey] {
                ForEach(records) { record in
                    NavigationLink(value: AppRoute.recordDetail(record.persistentModelID)) {
                        RecordRow(
                            avatar: record.contact?.avatar,
                            contactName: record.contact?.name ?? "",
                            eventName: record.event?.name ?? "",
                            amount: record.resolvedDisplayAmount,
                            direction: record.direction,
                            date: record.date,
                            recordType: record.recordType,
                            favorDescription: record.resolvedDescription,
                            kvData: record.kvData,
                            contextTag: record.contextTag
                        )
                    }
                    .buttonStyle(.plain)
                    .background(DesignSystem.Colors.bgSurface)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
                    .contextMenu {
                        Button {
                            sheetRoute = .returnGift(recordID: record.persistentModelID)
                        } label: {
                            Label(String(localized: "record.detail.returnGift"), systemImage: "gift")
                        }
                        Button(role: .destructive) {
                            viewModel.deleteRecord(record, context: modelContext)
                        } label: {
                            Label(String(localized: "common.delete"), systemImage: "trash")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Sheet

    @ViewBuilder
    private func sheetContent(for route: SheetRoute) -> some View {
        switch route {
        case .addRecord(let direction, let contactID):
            NavigationStack {
                AddRecordView(direction: direction, contactID: contactID)
            }
        case .addContact:
            NavigationStack {
                AddContactView()
            }
        case .addEvent:
            NavigationStack {
                AddEventView()
            }
        case .editContact(let contactID):
            NavigationStack {
                AddContactView(contactID: contactID)
            }
        case .editEvent(let eventID):
            NavigationStack {
                AddEventView(eventID: eventID)
            }
        case .editRecord(let recordID):
            NavigationStack {
                AddRecordView(recordID: recordID)
            }
        case .returnGift(let recordID):
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
    let e1 = Event(name: "结婚随礼", type: .wedding, date: cal.date(byAdding: .day, value: -6, to: .now)!)
    let e2 = Event(name: "满月酒", type: .birth, date: cal.date(byAdding: .day, value: -10, to: .now)!)
    let e3 = Event(name: "聚餐", type: .other, date: cal.date(byAdding: .day, value: -15, to: .now)!)
    let e4 = Event(name: "乔迁之喜", type: .property, date: cal.date(byAdding: .month, value: -1, to: .now)!)
    let e5 = Event(name: "升职庆祝", type: .other, date: cal.date(byAdding: .month, value: -1, to: .now)!)
    [e1, e2, e3, e4, e5].forEach { ctx.insert($0) }

    let r1 = Record(contact: c1, event: e1, amount: 2000, direction: .given, paymentMethod: .wechat, date: cal.date(byAdding: .day, value: -6, to: .now)!)
    let r2 = Record(contact: c2, event: e2, amount: 800, direction: .received, paymentMethod: .cash, returnedAmount: 800, date: cal.date(byAdding: .day, value: -10, to: .now)!)
    let r3 = Record(contact: c3, event: e3, amount: 500, direction: .given, paymentMethod: .alipay, returnedAmount: 500, date: cal.date(byAdding: .day, value: -15, to: .now)!)
    let r4 = Record(contact: c4, event: e4, amount: 1200, direction: .given, paymentMethod: .wechat, date: cal.date(byAdding: .month, value: -1, to: .now)!)
    let r5 = Record(contact: c5, event: e5, amount: 600, direction: .received, paymentMethod: .cash, returnedAmount: 600, date: cal.date(byAdding: .month, value: -1, to: .now)!)
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
