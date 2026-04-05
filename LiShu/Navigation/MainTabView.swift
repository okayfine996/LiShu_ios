import SwiftData
import SwiftUI

enum AppTab: String, CaseIterable {
    case home
    case records
    case contacts
    case events
    case settings

    var screenName: String {
        switch self {
        case .home: "home.dashboard"
        case .records: "records.list"
        case .contacts: "contacts.list"
        case .events: "events.list"
        case .settings: "settings.root"
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab: AppTab = .home
    @State private var sheetRoute: SheetRoute?

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
                    .navigationDestination(for: AppRoute.self) { route in
                        routeDestination(route)
                    }
            }
            .accessibilityIdentifier("tab.home")
            .tabItem {
                Label(String(localized: "tab.home"), systemImage: "house.fill")
            }
            .tag(AppTab.home)

            NavigationStack {
                RecordListView()
                    .navigationDestination(for: AppRoute.self) { route in
                        routeDestination(route)
                    }
            }
            .accessibilityIdentifier("tab.records")
            .tabItem {
                Label(String(localized: "tab.records"), systemImage: "doc.text")
            }
            .tag(AppTab.records)

            NavigationStack {
                ContactListView()
                    .navigationDestination(for: AppRoute.self) { route in
                        routeDestination(route)
                    }
            }
            .accessibilityIdentifier("tab.contacts")
            .tabItem {
                Label(String(localized: "tab.contacts"), systemImage: "person.2.fill")
            }
            .tag(AppTab.contacts)

            NavigationStack {
                EventListView()
                    .navigationDestination(for: AppRoute.self) { route in
                        routeDestination(route)
                    }
            }
            .accessibilityIdentifier("tab.events")
            .tabItem {
                Label(String(localized: "tab.events"), systemImage: "calendar")
            }
            .tag(AppTab.events)

            NavigationStack {
                SettingsView()
                    .navigationDestination(for: AppRoute.self) { route in
                        routeDestination(route)
                    }
            }
            .accessibilityIdentifier("tab.settings")
            .tabItem {
                Label(String(localized: "tab.settings"), systemImage: "gearshape.fill")
            }
            .tag(AppTab.settings)
        }
        .tint(DesignSystem.Colors.primary)
        .sheet(item: $sheetRoute) { route in
            sheetContent(for: route)
        }
        .trackScreen(selectedTab.screenName, metadata: ["presentation": UILogPresentation.tab.rawValue])
        .onChange(of: selectedTab) { oldValue, newValue in
            guard oldValue != newValue else { return }
            InteractionLogger.tabSwitch(
                screen: oldValue.screenName,
                target: "main.tab.\(newValue.rawValue)",
                route: newValue.screenName
            )
        }
        .onChange(of: sheetRoute) { oldValue, newValue in
            if let oldValue, newValue == nil {
                InteractionLogger.sheetPresentation(
                    screen: selectedTab.screenName,
                    route: oldValue.logName,
                    isPresented: false
                )
            }
            if let newValue {
                InteractionLogger.sheetPresentation(
                    screen: selectedTab.screenName,
                    route: newValue.logName,
                    isPresented: true
                )
            }
        }
    }

    // MARK: - Route Destination

    @ViewBuilder
    private func routeDestination(_ route: AppRoute) -> some View {
        switch route {
        case let .recordDetail(id):
            RecordDetailView(recordID: id)
        case let .addRecord(direction, contactID):
            AddRecordView(direction: direction, contactID: contactID)
        case let .monthlyDetail(year, month):
            MonthlyDetailView(period: .month(year: year, month: month))
        case let .periodDetail(period):
            MonthlyDetailView(period: period)
        case let .contactExchange(id):
            ContactExchangeView(contactID: id)
        case let .contactDetail(id):
            ContactDetailView(contactID: id)
        case .addContact:
            AddContactView()
        case .eventList:
            EventListView()
        case let .eventDetail(id):
            EventDetailView(eventID: id)
        case .addEvent:
            AddEventView()
        case .statistics:
            StatisticsView()
        case let .eventTypeComposition(year):
            CompositionDetailView(mode: .eventTypes(year: year))
        case let .netValueRanking(year):
            NetValueRankingView(year: year)
        case let .circleDetail(circle, year):
            CircleDetailView(circle: circle, year: year)
        case let .recordTypeComposition(year):
            CompositionDetailView(mode: .recordTypes(year: year))
        case let .heatmapDetail(year):
            HeatmapDetailView(year: year)
        case .proMembership:
            ProMembershipView()
        case .appearanceSettings:
            AppearanceSettingsView()
        case .notificationSettings:
            NotificationSettingsView()
        case .dataManagement:
            DataManagementView()
        case .importExport:
            DataManagementView()
        case .about:
            AboutView()
        case .termsOfService:
            TermsOfServiceView()
        case .privacyPolicy:
            PrivacyPolicyView()
        }
    }

    // MARK: - Sheet Content

    @ViewBuilder
    private func sheetContent(for route: SheetRoute) -> some View {
        switch route {
        case let .addRecord(direction, contactID):
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

#Preview {
    MainTabView()
        .modelContainer(for: [Contact.self, Record.self, Event.self], inMemory: true)
        .environment(SubscriptionManager.shared)
        .environment(AppSettings.shared)
}
