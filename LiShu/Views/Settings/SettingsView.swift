import SwiftUI

struct SettingsView: View {
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(DebugOverrideManager.self) private var debugOverrides
    @Environment(AppSettings.self) private var settings
    @Environment(\.restartGuideTour) private var restartGuideTour: () -> Void

    @State private var showProSheet = false
    @State private var showRestartAlert = false

    private var effectiveProAccessEnabled: Bool {
        subscriptionManager.effectiveIsPro(overrides: debugOverrides)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            SettingsContentView(
                effectiveProAccessEnabled: effectiveProAccessEnabled,
                hasActiveEntitlement: subscriptionManager.hasActiveEntitlement,
                currentSubscriptionName: subscriptionManager.currentSubscriptionName,
                appVersion: appVersion,
                icloudSyncEnabled: Binding(
                    get: { settings.icloudSyncEnabled },
                    set: handleICloudSyncChange(_:)
                ),
                onOpenProMembership: openProMembership,
                onOpenAppearance: logAppearanceNavigation,
                onOpenNotifications: logNotificationNavigation,
                onOpenDataManagement: logDataManagementNavigation,
                onOpenAbout: logAboutNavigation,
                onRateApp: rateApp,
                onRestartGuideTour: restartGuideTour
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .background(DesignSystem.Colors.bgPage)
        .navigationTitle(String(localized: "settings.title"))
        .navigationBarTitleDisplayMode(.large)
        .trackScreen("settings.root")
        .sheet(isPresented: $showProSheet) {
            NavigationStack {
                ProMembershipView()
            }
        }
        .alert(
            String(localized: "settings.icloudSync.restartTitle"),
            isPresented: $showRestartAlert
        ) {
            Button(String(localized: "common.ok"), action: restartApp)
            Button(String(localized: "common.cancel"), role: .cancel) {}
        } message: {
            Text(String(localized: "settings.icloudSync.restartMessage"))
        }
        .onChange(of: showProSheet) { _, newValue in
            InteractionLogger.sheetPresentation(
                screen: "settings.root",
                route: "sheet.settings.proMembership",
                isPresented: newValue
            )
        }
        .onChange(of: showRestartAlert) { _, newValue in
            InteractionLogger.alertPresentation(
                screen: "settings.root",
                target: "settings.icloud.restart",
                isPresented: newValue
            )
        }
    }

    private func openProMembership() {
        InteractionLogger.navigation(
            screen: "settings.root",
            target: "settings.proCard",
            route: AppRoute.proMembership.logName
        )
    }

    private func logAppearanceNavigation() {
        InteractionLogger.navigation(
            screen: "settings.root",
            target: "settings.appearance",
            route: AppRoute.appearanceSettings.logName
        )
    }

    private func logNotificationNavigation() {
        InteractionLogger.navigation(
            screen: "settings.root",
            target: "settings.notifications",
            route: AppRoute.notificationSettings.logName
        )
    }

    private func logDataManagementNavigation() {
        InteractionLogger.navigation(
            screen: "settings.root",
            target: "settings.dataManagement",
            route: AppRoute.dataManagement.logName
        )
    }

    private func logAboutNavigation() {
        InteractionLogger.navigation(
            screen: "settings.root",
            target: "settings.about",
            route: AppRoute.about.logName
        )
    }

    private func handleICloudSyncChange(_ newValue: Bool) {
        if newValue, !effectiveProAccessEnabled {
            InteractionLogger.toggle(
                screen: "settings.root",
                target: "settings.icloudSync",
                isOn: false,
                metadata: ["reason": "subscription_limit"]
            )
            showProSheet = true
        } else {
            settings.icloudSyncEnabled = newValue
            InteractionLogger.toggle(
                screen: "settings.root",
                target: "settings.icloudSync",
                isOn: newValue
            )
            showRestartAlert = true
        }
    }

    private func restartApp() {
        InteractionLogger.alertAction(
            screen: "settings.root",
            target: "settings.icloud.restart",
            action: .submit,
            result: "restart"
        )
        exit(0)
    }

    private func rateApp() {
        InteractionLogger.tap(screen: "settings.root", target: "settings.rateApp")
        guard let url = URL(string: "itms-apps://itunes.apple.com/app/id6759552120?action=write-review") else {
            return
        }
        UIApplication.shared.open(url)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environment(SubscriptionManager.shared)
    .environment(AppSettings.shared)
    .environment(DebugOverrideManager.shared)
}
