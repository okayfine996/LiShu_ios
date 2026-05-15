import SwiftData
import SwiftUI

// MARK: - AppTab

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
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings
    @Environment(DeepLinkCoordinator.self) private var deepLinkCoordinator
    @State private var selectedTab: AppTab = .home
    @State private var sheetRoute: SheetRoute?
    @State private var guideMask = GuideMaskViewModel()
    @State private var suiLiGuideActive = false
    @State private var eventsPath = NavigationPath()
    @State private var contactsPath = NavigationPath()

    @Query private var allEvents: [Event]
    @Query private var allContacts: [Contact]
    @Query private var allRecords: [Record]

    private var widgetDataSignature: Int {
        var h = Hasher()
        for r in allRecords {
            h.combine(r.amount); h.combine(r.directionRaw)
            h.combine(r.date.timeIntervalSince1970); h.combine(r.recordTypeRaw)
            h.combine(r.kvData) // captures monetaryAmount and type-specific fields stored in kvData
            h.combine(r.contact?.persistentModelID.hashValue ?? 0)
            h.combine(r.event?.persistentModelID.hashValue ?? 0)
        }
        for e in allEvents {
            h.combine(e.date.timeIntervalSince1970); h.combine(e.hostModeRaw)
            h.combine(e.name); h.combine(e.typeRaw); h.combine(e.location)
            h.combine(e.primaryContact?.persistentModelID.hashValue ?? 0)
        }
        for c in allContacts {
            h.combine(c.birthday?.timeIntervalSince1970 ?? 0)
            h.combine(c.birthdayIsLunar); h.combine(c.birthdayReminderEnabled); h.combine(c.name)
        }
        return h.finalize()
    }

    // Debug probes — only written in --uitesting mode, read by WidgetEntityDeepLinkTests
    @State private var _dbgDeepLinkCalled = false
    @State private var _dbgDeepLinkResolved = false
    @State private var _dbgAllEventsCountAtDeepLink = -1

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

            NavigationStack(path: $contactsPath) {
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

            NavigationStack(path: $eventsPath) {
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
        .guideMask(viewModel: guideMask)
        .environment(\.guideCurrentAnchorID, guideMask.currentStep?.anchorID)
        .environment(\.restartGuideTour) {
            settings.hasSeenGuideTour = false
            settings.hasSeenSuiLiGuide = false
            suiLiGuideActive = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                guideMask.start(
                    flow: AppGuideFlow.mainTour(),
                    eventCount: allEvents.count,
                    contactCount: allContacts.count,
                    recordCount: allRecords.count
                )
            }
        }
        .onChange(of: guideMask.isActive) { wasActive, isNowActive in
            guard wasActive, !isNowActive else { return }
            if suiLiGuideActive {
                suiLiGuideActive = false
                settings.hasSeenSuiLiGuide = true
            } else {
                settings.hasSeenGuideTour = true
                guard !settings.hasSeenSuiLiGuide else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    suiLiGuideActive = true
                    guideMask.start(
                        flow: AppGuideFlow.suiLiTour(),
                        eventCount: allEvents.count,
                        contactCount: allContacts.count,
                        recordCount: allRecords.count
                    )
                }
            }
        }
        .onChange(of: guideMask.requiredTab) { _, newTab in
            if let newTab {
                withAnimation {
                    selectedTab = newTab
                }
            }
        }
        .onChange(of: allEvents.count) { _, newCount in
            guideMask.notifyDataChanged(eventCount: newCount, contactCount: allContacts.count, recordCount: allRecords.count)
            WidgetDataWriter.write(records: allRecords, events: allEvents, contacts: allContacts)
            retryPendingDeepLink()
        }
        .onChange(of: allContacts.count) { _, newCount in
            guideMask.notifyDataChanged(eventCount: allEvents.count, contactCount: newCount, recordCount: allRecords.count)
            WidgetDataWriter.write(records: allRecords, events: allEvents, contacts: allContacts)
            retryPendingDeepLink()
        }
        .onChange(of: allRecords.count) { _, newCount in
            guideMask.notifyDataChanged(eventCount: allEvents.count, contactCount: allContacts.count, recordCount: newCount)
            WidgetDataWriter.write(records: allRecords, events: allEvents, contacts: allContacts)
        }
        .onChange(of: widgetDataSignature) { _, _ in
            WidgetDataWriter.write(records: allRecords, events: allEvents, contacts: allContacts)
        }
        .onChange(of: deepLinkCoordinator.pending) { _, link in
            guard let link else { return }
            if handleDeepLink(link) {
                deepLinkCoordinator.pending = nil
            }
        }
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
        .onAppear {
            if let link = deepLinkCoordinator.pending, handleDeepLink(link) {
                deepLinkCoordinator.pending = nil
            }
            if CommandLine.arguments.contains("--uitest-open-ocr") {
                let descriptor = FetchDescriptor<Event>()
                if let event = try? modelContext.fetch(descriptor).first(where: { $0.hostMode == .host }) {
                    sheetRoute = .ocrImport(eventID: event.persistentModelID)
                } else {
                    let event = Event(name: "UITest 礼簿", type: .wedding, hostMode: .host, date: .now)
                    modelContext.insert(event)
                    try? modelContext.save()
                    sheetRoute = .ocrImport(eventID: event.persistentModelID)
                }
            }
            if !settings.hasSeenGuideTour {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    guideMask.start(
                        flow: AppGuideFlow.mainTour(),
                        eventCount: allEvents.count,
                        contactCount: allContacts.count,
                        recordCount: allRecords.count
                    )
                }
            } else if !settings.hasSeenSuiLiGuide {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    suiLiGuideActive = true
                    guideMask.start(
                        flow: AppGuideFlow.suiLiTour(),
                        eventCount: allEvents.count,
                        contactCount: allContacts.count,
                        recordCount: allRecords.count
                    )
                }
            }
        }
        .overlay(alignment: .topLeading) {
            if CommandLine.arguments.contains("--uitesting") {
                Group {
                    Color.clear.frame(width: 0, height: 0)
                        .accessibilityIdentifier("debug.tab.\(selectedTab.rawValue)")
                        .accessibilityHidden(false)
                    // Expose stableID for every event in allEvents so tests can read
                    // the same stableID that handleDeepLink uses for matching.
                    ForEach(allEvents, id: \.persistentModelID) { event in
                        Color.clear.frame(width: 0, height: 0)
                            .accessibilityIdentifier(
                                "debug.event.sid.\(WidgetDataWriter.stableID(for: event.persistentModelID)).\(event.name)"
                            )
                            .accessibilityHidden(false)
                    }
                    ForEach(allContacts, id: \.persistentModelID) { contact in
                        Color.clear.frame(width: 0, height: 0)
                            .accessibilityIdentifier(
                                "debug.contact.sid.\(WidgetDataWriter.stableID(for: contact.persistentModelID)).\(contact.name)"
                            )
                            .accessibilityHidden(false)
                    }
                    if _dbgDeepLinkCalled {
                        let status = _dbgDeepLinkResolved ? "resolved" : "notfound"
                        Color.clear.frame(width: 0, height: 0)
                            .accessibilityIdentifier("debug.deeplink.\(status).\(_dbgAllEventsCountAtDeepLink)")
                            .accessibilityHidden(false)
                    }
                }
            }
        }
    }

    // MARK: - Deep Link

    private func retryPendingDeepLink() {
        guard let link = deepLinkCoordinator.pending else { return }
        if handleDeepLink(link) {
            deepLinkCoordinator.pending = nil
        }
    }

    @discardableResult
    private func handleDeepLink(_ link: DeepLink) -> Bool {
        switch link {
        case .home:
            selectedTab = .home
            eventsPath = NavigationPath()
            contactsPath = NavigationPath()
            return true
        case .addRecord:
            sheetRoute = .addRecord(direction: nil, contactID: nil, eventID: nil)
            return true
        case let .addRecordForEvent(stableID):
            guard let event = allEvents.first(where: {
                WidgetDataWriter.stableID(for: $0.persistentModelID) == stableID
            }) else { return false }
            selectedTab = .events
            sheetRoute = .addRecord(direction: .received, contactID: nil, eventID: event.persistentModelID)
            return true
        case let .giveGiftForEvent(stableID):
            guard let event = allEvents.first(where: {
                WidgetDataWriter.stableID(for: $0.persistentModelID) == stableID
            }) else { return false }
            selectedTab = .events
            sheetRoute = .addRecord(direction: .given, contactID: nil, eventID: event.persistentModelID)
            return true
        case let .eventDetail(stableID):
            let isTesting = CommandLine.arguments.contains("--uitesting")
            if isTesting { _dbgDeepLinkCalled = true; _dbgAllEventsCountAtDeepLink = allEvents.count }
            guard let event = allEvents.first(where: {
                WidgetDataWriter.stableID(for: $0.persistentModelID) == stableID
            }) else {
                if isTesting { _dbgDeepLinkResolved = false }
                return false
            }
            if isTesting { _dbgDeepLinkResolved = true }
            selectedTab = .events
            eventsPath.append(AppRoute.eventDetail(event.persistentModelID))
            return true
        case let .contactDetail(stableID):
            let isTesting = CommandLine.arguments.contains("--uitesting")
            if isTesting { _dbgDeepLinkCalled = true; _dbgAllEventsCountAtDeepLink = allContacts.count }
            guard let contact = allContacts.first(where: {
                WidgetDataWriter.stableID(for: $0.persistentModelID) == stableID
            }) else {
                if isTesting { _dbgDeepLinkResolved = false }
                return false
            }
            if isTesting { _dbgDeepLinkResolved = true }
            selectedTab = .contacts
            contactsPath.append(AppRoute.contactDetail(contact.persistentModelID))
            return true
        }
    }

    // MARK: - Route Destination

    @ViewBuilder
    private func routeDestination(_ route: AppRoute) -> some View {
        switch route {
        case let .recordDetail(id):
            RecordDetailView(recordID: id)
        case let .addRecord(direction, contactID, eventID):
            AddRecordView(direction: direction, contactID: contactID, eventID: eventID)
        case let .addLedgerReceipt(eventID):
            AddLedgerReceiptView(eventID: eventID)
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
        case .widgetGallery:
            WidgetGalleryView()
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
}

#Preview {
    MainTabView()
        .modelContainer(for: [Contact.self, Record.self, Event.self], inMemory: true)
        .environment(SubscriptionManager.shared)
        .environment(AppSettings.shared)
        .environment(DeepLinkCoordinator())
}
