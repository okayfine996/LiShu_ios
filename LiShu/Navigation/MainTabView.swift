import SwiftUI
import SwiftData

enum AppTab: String, CaseIterable {
    case home = "home"
    case records = "records"
    case contacts = "contacts"
    case events = "events"
    case settings = "settings"
}

struct MainTabView: View {
    @State private var selectedTab: AppTab = .home
    @State private var sheetRoute: SheetRoute?
    @State private var notificationRouter = NotificationRouter.shared

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
        .onChange(of: notificationRouter.pendingFestivalRoute) { _, newValue in
            guard let route = newValue else { return }
            selectedTab = .home
            sheetRoute = .festivalReminderDetail(route)
            _ = notificationRouter.consumeFestivalRoute()
        }
    }

    // MARK: - Route Destination

    @ViewBuilder
    private func routeDestination(_ route: AppRoute) -> some View {
        switch route {
        case .recordDetail(let id):
            RecordDetailView(recordID: id)
        case .addRecord(let direction, let contactID):
            AddRecordView(direction: direction, contactID: contactID)
        case .monthlyDetail(let year, let month):
            MonthlyDetailView(period: .month(year: year, month: month))
        case .periodDetail(let period):
            MonthlyDetailView(period: period)
        case .contactExchange(let id):
            ContactExchangeView(contactID: id)
        case .contactDetail(let id):
            ContactDetailView(contactID: id)
        case .addContact:
            AddContactView()
        case .eventList:
            EventListView()
        case .eventDetail(let id):
            EventDetailView(eventID: id)
        case .addEvent:
            AddEventView()
        case .statistics:
            StatisticsView()
        case .eventTypeDetail(let type, let year):
            EventTypeDetailView(eventType: type, year: year)
        case .netValueRanking(let year):
            NetValueRankingView(year: year)
        case .circleDetail(let circle, let year):
            CircleDetailView(circle: circle, year: year)
        case .proMembership:
            ProMembershipView()
        case .appearanceSettings:
            AppearanceSettingsView()
        case .notificationSettings:
            NotificationSettingsView()
        case .festivalManagement:
            FestivalManagementView()
        case .addCustomFestival:
            AddCustomFestivalView()
        case .festivalRecipientSettings(let route):
            FestivalRecipientSettingsView(route: route)
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
        case .addFestivalEvent(let prefill):
            NavigationStack {
                AddEventView(prefill: prefill)
            }
        case .festivalReminderDetail(let route):
            NavigationStack {
                FestivalReminderDetailView(route: route)
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

#Preview {
    MainTabView()
        .modelContainer(for: [Contact.self, Record.self, Event.self, CustomFestival.self, FestivalReminderPreference.self], inMemory: true)
        .environment(SubscriptionManager.shared)
        .environment(AppSettings.shared)
}
