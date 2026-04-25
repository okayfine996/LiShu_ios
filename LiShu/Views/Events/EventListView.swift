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
            DesignSystem.Colors.bgPage
                .ignoresSafeArea()

            EventListStateContainer(
                state: viewModel.state,
                filteredUpcomingEvents: viewModel.filteredUpcomingEvents,
                filteredPastEvents: viewModel.filteredPastEvents,
                hasNoResults: viewModel.hasNoResults,
                selectedTypeFilter: viewModel.selectedTypeFilter,
                upcomingBadge: upcomingBadge,
                onRetry: loadData,
                onAddEvent: presentAddEventSheet,
                onSelectAllFilter: selectAllFilter,
                onSelectTypeFilter: selectTypeFilter(_:),
                onSelectEvent: showEventDetail(_:),
                onDeleteEvent: confirmDelete(_:)
            )
        }
        .navigationTitle(String(localized: "event.list.title"))
        .navigationBarTitleDisplayMode(.large)
        .trackScreen("events.list")
        .searchable(text: $viewModel.searchText, prompt: String(localized: "common.search"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: presentAddEventSheet) {
                    Image(systemName: "plus")
                        .font(DesignSystem.Typography.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(DesignSystem.Colors.primary)
                }
                .accessibilityIdentifier("event.list.addButton")
                .guideAnchor(id: "event.list.addButton")
            }
        }
        .onAppear(perform: loadData)
        .sheet(item: $sheetRoute) { route in
            sheetContent(for: route)
        }
        .navigationDestination(item: $selectedEventRoute) { route in
            EventDetailView(eventID: route.id)
        }
        .onChange(of: sheetRoute) { _, newValue in
            handleSheetRouteChange(newValue)
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

    private func loadData() {
        viewModel.load(context: modelContext)
    }

    private func presentAddEventSheet() {
        InteractionLogger.tap(
            screen: "events.list",
            target: "events.list.add",
            route: SheetRoute.addEvent.logName,
            presentation: .sheet
        )
        sheetRoute = .addEvent
    }

    private func handleSheetRouteChange(_ newValue: SheetRoute?) {
        if let newValue {
            InteractionLogger.sheetPresentation(
                screen: "events.list",
                route: newValue.logName,
                isPresented: true
            )
        } else {
            loadData()
        }
    }

    private func selectAllFilter() {
        withAnimation {
            viewModel.selectedTypeFilter = nil
        }
        InteractionLogger.tap(screen: "events.list", target: "events.list.filter.all")
    }

    private func selectTypeFilter(_ type: EventType) {
        withAnimation {
            viewModel.selectedTypeFilter = type
        }
        InteractionLogger.tap(screen: "events.list", target: "events.list.filter.\(type.rawValue)")
    }

    private func showEventDetail(_ event: Event) {
        InteractionLogger.navigation(
            screen: "events.list",
            target: "events.list.event.\(String(describing: event.persistentModelID))",
            route: AppRoute.eventDetail(event.persistentModelID).logName
        )
        selectedEventRoute = SelectedEventRoute(id: event.persistentModelID)
    }

    private func confirmDelete(_ event: Event) {
        pendingDeleteEvent = event
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
