import SwiftData
import SwiftUI

struct EventListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = EventListViewModel()
    @State private var sheetRoute: SheetRoute?
    @State private var pendingDeleteEvent: Event?
    @State private var selectedEventRoute: SelectedEventRoute?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                switch viewModel.state {
                case .idle, .loading:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case let .loaded(events) where events.isEmpty:
                    EmptyStateView(
                        icon: "calendar",
                        message: String(localized: "event.list.empty"),
                        actionTitle: String(localized: "event.add.title"),
                        action: {
                            sheetRoute = .addEvent
                        }
                    )
                case .loaded:
                    eventListContent
                case let .error(message):
                    ErrorStateView(message: message) {
                        viewModel.load(context: modelContext)
                    }
                }
            }
        }
        .background(DesignSystem.Colors.bgPage)
        .navigationTitle(String(localized: "event.list.title"))
        .navigationBarTitleDisplayMode(.large)
        .trackScreen("events.list")
        .searchable(text: $viewModel.searchText, prompt: String(localized: "common.search"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    InteractionLogger.tap(
                        screen: "events.list",
                        target: "events.list.add",
                        route: SheetRoute.addEvent.logName,
                        presentation: .sheet
                    )
                    sheetRoute = .addEvent
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.primary)
                }
                .accessibilityIdentifier("event.list.addButton")
            }
        }
        .onAppear {
            viewModel.load(context: modelContext)
        }
        .sheet(item: $sheetRoute) { route in
            sheetContent(for: route)
        }
        .navigationDestination(item: $selectedEventRoute) { route in
            EventDetailView(eventID: route.id)
        }
        .onChange(of: sheetRoute) { _, newValue in
            if let newValue {
                InteractionLogger.sheetPresentation(screen: "events.list", route: newValue.logName, isPresented: true)
            }
            if newValue == nil {
                viewModel.load(context: modelContext)
            }
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
            String(localized: "event.detail.deleteConfirm"),
            isPresented: Binding(
                get: { pendingDeleteEvent != nil },
                set: { if !$0 { pendingDeleteEvent = nil } }
            )
        ) {
            Button(String(localized: "common.cancel"), role: .cancel) {
                pendingDeleteEvent = nil
            }
            Button(String(localized: "common.delete"), role: .destructive) {
                guard let pendingDeleteEvent else { return }
                viewModel.deleteEvent(pendingDeleteEvent, context: modelContext)
                self.pendingDeleteEvent = nil
            }
        } message: {
            Text(eventDeleteMessage)
        }
    }

    // MARK: - Event List Content

    private var eventListContent: some View {
        List {
            listRow {
                eventTypeFilterPills
            }

            if viewModel.hasNoResults {
                listRow {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        message: String(localized: "event.list.noResults")
                    )
                }
            } else {
                if !viewModel.filteredUpcomingEvents.isEmpty {
                    upcomingSection
                }

                if !viewModel.filteredPastEvents.isEmpty {
                    pastSection
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Event Type Filter Pills

    private var eventTypeFilterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "All" pill
                Button {
                    withAnimation { viewModel.selectedTypeFilter = nil }
                    InteractionLogger.tap(screen: "events.list", target: "events.list.filter.all")
                } label: {
                    Text(String(localized: "record.filter.all"))
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(viewModel.selectedTypeFilter == nil ? .white : DesignSystem.Colors.textPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(viewModel.selectedTypeFilter == nil ? DesignSystem.Colors.primary : DesignSystem.Colors.bgCard)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                ForEach(EventType.allCases, id: \.self) { type in
                    Button {
                        withAnimation { viewModel.selectedTypeFilter = type }
                        InteractionLogger.tap(screen: "events.list", target: "events.list.filter.\(type.rawValue)")
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: type.iconName)
                                .font(.system(size: 12))
                            Text(type.displayName)
                                .font(DesignSystem.Typography.caption)
                        }
                        .foregroundStyle(viewModel.selectedTypeFilter == type ? .white : DesignSystem.Colors.textPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(viewModel.selectedTypeFilter == type ? DesignSystem.Colors.primary : DesignSystem.Colors.bgCard)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Upcoming Section

    private var upcomingSection: some View {
        Section {
            ForEach(viewModel.filteredUpcomingEvents) { event in
                eventRow(event, badge: upcomingBadge(event.date))
            }
        } header: {
            sectionHeader(String(localized: "event.list.upcoming"))
        }
    }

    // MARK: - Past Section

    private var pastSection: some View {
        Section {
            ForEach(viewModel.filteredPastEvents) { event in
                eventRow(event, badge: nil)
            }
        } header: {
            sectionHeader(String(localized: "event.list.past"))
        }
    }

    // MARK: - Helpers

    private func eventRow(_ event: Event, badge: String?) -> some View {
        Button {
            InteractionLogger.navigation(
                screen: "events.list",
                target: "events.list.event.\(String(describing: event.persistentModelID))",
                route: AppRoute.eventDetail(event.persistentModelID).logName
            )
            selectedEventRoute = SelectedEventRoute(id: event.persistentModelID)
        } label: {
            EventRowCard(
                name: event.name,
                coverImage: event.coverImage,
                eventType: event.type,
                date: event.date,
                location: event.location,
                recordCount: (event.records ?? []).count,
                badge: badge
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("event.list.row.\(event.name)")
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                pendingDeleteEvent = event
            } label: {
                Label(String(localized: "common.delete"), systemImage: "trash")
            }
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 10, trailing: 16))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(DesignSystem.Typography.caption)
            .foregroundStyle(DesignSystem.Colors.textSecondary)
            .fontWeight(.semibold)
            .textCase(nil)
            .padding(.top, 10)
    }

    private func listRow(@ViewBuilder content: () -> some View) -> some View {
        content()
            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 12, trailing: 16))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }

    private func upcomingBadge(_ date: Date) -> String {
        let days = viewModel.daysUntil(date)
        if days == 0 {
            return String(localized: "home.today")
        }
        return String(format: String(localized: "event.list.daysAfterFormat"), days)
    }

    private var eventDeleteMessage: String {
        guard let pendingDeleteEvent else { return "" }
        let records = pendingDeleteEvent.records ?? []
        let recordCount = Int64(records.count)
        let photoCount = Int64(records.reduce(0) { $0 + ($1.photos?.count ?? 0) })
        return String(
            format: String(localized: "event.list.deleteConfirmMessage"),
            recordCount,
            photoCount
        )
    }

    @ViewBuilder
    private func sheetContent(for route: SheetRoute) -> some View {
        switch route {
        case .addEvent:
            NavigationStack {
                AddEventView()
            }
        default:
            EmptyView()
        }
    }
}

private struct SelectedEventRoute: Identifiable, Hashable {
    let id: PersistentIdentifier
}

@MainActor
private func makeEventListPreviewContainer() -> ModelContainer? {
    guard let container = try? ModelContainer(
        for: Contact.self, Record.self, Event.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    ) else { return nil }
    let ctx = container.mainContext

    let c1 = Contact(name: "张三", relation: "同事")
    let c2 = Contact(name: "李四", relation: "朋友")
    [c1, c2].forEach { ctx.insert($0) }

    let cal = Calendar.current
    let e1 = Event(name: "张三的婚礼", type: .wedding, date: cal.liShuDateByAddingDays(3), location: "北京国贸大酒店")
    let e2 = Event(name: "李四生日宴", type: .birthday, date: cal.liShuDateByAddingDays(10), location: "上海外滩")
    let e3 = Event(name: "小明毕业典礼", type: .education, date: cal.liShuDateByAddingDays(21), location: "广州大学")
    let e4 = Event(name: "春节聚会", type: .festival, date: cal.liShuDateByAddingMonths(-2), location: "老家")
    let e5 = Event(name: "王五乔迁", type: .property, date: cal.liShuDateByAddingMonths(-3), location: "深圳南山")
    [e1, e2, e3, e4, e5].forEach { ctx.insert($0) }

    let r1 = Record.makeMonetaryRecord(
        contact: c1,
        event: e4,
        amount: 500,
        direction: .given,
        date: cal.liShuDateByAddingMonths(-2)
    )
    let r2 = Record.makeMonetaryRecord(
        contact: c2,
        event: e4,
        amount: 300,
        direction: .received,
        date: cal.liShuDateByAddingMonths(-2)
    )
    let r3 = Record.makeMonetaryRecord(
        contact: c1,
        event: e5,
        amount: 1000,
        direction: .given,
        date: cal.liShuDateByAddingMonths(-3)
    )
    [r1, r2, r3].forEach { ctx.insert($0) }

    return container
}

#Preview {
    Group {
        if let container = makeEventListPreviewContainer() {
            NavigationStack {
                EventListView()
            }
            .modelContainer(container)
        } else {
            Text(String(localized: "common.preview.unavailable"))
        }
    }
}
