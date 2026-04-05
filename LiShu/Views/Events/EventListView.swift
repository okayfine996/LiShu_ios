import SwiftUI
import SwiftData

struct EventListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = EventListViewModel()
    @State private var sheetRoute: SheetRoute?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                switch viewModel.state {
                case .idle, .loading:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .loaded(let events) where events.isEmpty:
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
                case .error(let message):
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
                    InteractionLogger.tap(screen: "events.list", target: "events.list.add", route: SheetRoute.addEvent.logName, presentation: .sheet)
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
            InteractionLogger.screenView("events.list")
            viewModel.load(context: modelContext)
        }
        .sheet(item: $sheetRoute) { route in
            sheetContent(for: route)
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
    }

    // MARK: - Event List Content

    private var eventListContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                eventTypeFilterPills

                if viewModel.hasNoResults {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        message: String(localized: "event.list.noResults")
                    )
                } else {
                    if !viewModel.filteredUpcomingEvents.isEmpty {
                        upcomingSection
                    }

                    if !viewModel.filteredPastEvents.isEmpty {
                        pastSection
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .padding(.bottom, 60)
        }
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
    }

    // MARK: - Upcoming Section

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "event.list.upcoming"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .fontWeight(.semibold)

            VStack(spacing: 10) {
                ForEach(viewModel.filteredUpcomingEvents) { event in
                    NavigationLink(value: AppRoute.eventDetail(event.persistentModelID)) {
                        EventRowCard(
                            name: event.name,
                            coverImage: event.coverImage,
                            eventType: event.type,
                            date: event.date,
                            location: event.location,
                            recordCount: (event.records ?? []).count,
                            badge: upcomingBadge(event.date)
                        )
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        InteractionLogger.navigation(
                            screen: "events.list",
                            target: "events.list.event.\(String(describing: event.persistentModelID))",
                            route: AppRoute.eventDetail(event.persistentModelID).logName
                        )
                    })
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Past Section

    private var pastSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "event.list.past"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .fontWeight(.semibold)

            VStack(spacing: 10) {
                ForEach(viewModel.filteredPastEvents) { event in
                    NavigationLink(value: AppRoute.eventDetail(event.persistentModelID)) {
                        EventRowCard(
                            name: event.name,
                            coverImage: event.coverImage,
                            eventType: event.type,
                            date: event.date,
                            location: event.location,
                            recordCount: (event.records ?? []).count
                        )
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        InteractionLogger.navigation(
                            screen: "events.list",
                            target: "events.list.event.\(String(describing: event.persistentModelID))",
                            route: AppRoute.eventDetail(event.persistentModelID).logName
                        )
                    })
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Helpers

    private func upcomingBadge(_ date: Date) -> String {
        let days = viewModel.daysUntil(date)
        if days == 0 {
            return String(localized: "home.today")
        }
        return String(format: String(localized: "event.list.daysAfterFormat"), days)
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
    let e1 = Event(name: "张三的婚礼", type: .wedding, date: cal.date(byAdding: .day, value: 3, to: .now)!, location: "北京国贸大酒店")
    let e2 = Event(name: "李四生日宴", type: .birthday, date: cal.date(byAdding: .day, value: 10, to: .now)!, location: "上海外滩")
    let e3 = Event(name: "小明毕业典礼", type: .education, date: cal.date(byAdding: .day, value: 21, to: .now)!, location: "广州大学")
    let e4 = Event(name: "春节聚会", type: .festival, date: cal.date(byAdding: .month, value: -2, to: .now)!, location: "老家")
    let e5 = Event(name: "王五乔迁", type: .property, date: cal.date(byAdding: .month, value: -3, to: .now)!, location: "深圳南山")
    [e1, e2, e3, e4, e5].forEach { ctx.insert($0) }

    let r1 = Record.makeMonetaryRecord(contact: c1, event: e4, amount: 500, direction: .given, date: cal.date(byAdding: .month, value: -2, to: .now)!)
    let r2 = Record.makeMonetaryRecord(contact: c2, event: e4, amount: 300, direction: .received, date: cal.date(byAdding: .month, value: -2, to: .now)!)
    let r3 = Record.makeMonetaryRecord(contact: c1, event: e5, amount: 1000, direction: .given, date: cal.date(byAdding: .month, value: -3, to: .now)!)
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
