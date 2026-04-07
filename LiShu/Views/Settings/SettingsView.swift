import SwiftUI

struct SettingsView: View {
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(DebugOverrideManager.self) private var debugOverrides
    @Environment(AppSettings.self) private var settings
    @State private var showDeleteAllSheet = false
    @State private var showProSheet = false
    @State private var showRestartAlert = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                proCard
                preferencesSection
                dataSection
                aboutSection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .background(DesignSystem.Colors.bgPage)
        .navigationTitle(String(localized: "settings.title"))
        .navigationBarTitleDisplayMode(.large)
        .trackScreen("settings.root")
        .sheet(isPresented: $showDeleteAllSheet) {
            DeleteAllDataView()
        }
        .sheet(isPresented: $showProSheet) {
            NavigationStack {
                ProMembershipView()
            }
        }
        .alert(
            String(localized: "settings.icloudSync.restartTitle"),
            isPresented: $showRestartAlert
        ) {
            Button(String(localized: "common.ok")) {
                InteractionLogger.alertAction(
                    screen: "settings.root",
                    target: "settings.icloud.restart",
                    action: .submit,
                    result: "restart"
                )
                exit(0)
            }
            Button(String(localized: "common.cancel"), role: .cancel) {}
        } message: {
            Text(String(localized: "settings.icloudSync.restartMessage"))
        }
        .onChange(of: showProSheet) { _, newValue in
            InteractionLogger.sheetPresentation(screen: "settings.root", route: "sheet.settings.proMembership", isPresented: newValue)
        }
        .onChange(of: showDeleteAllSheet) { _, newValue in
            InteractionLogger.sheetPresentation(screen: "settings.root", route: "sheet.settings.deleteAllData", isPresented: newValue)
        }
        .onChange(of: showRestartAlert) { _, newValue in
            InteractionLogger.alertPresentation(screen: "settings.root", target: "settings.icloud.restart", isPresented: newValue)
        }
    }

    // MARK: - Pro card

    private var effectiveProAccessEnabled: Bool {
        subscriptionManager.effectiveIsPro(overrides: debugOverrides)
    }

    private var proCard: some View {
        NavigationLink(value: AppRoute.proMembership) {
            ZStack(alignment: .bottomTrailing) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(DesignSystem.Colors.accentGold)
                            .font(.system(size: 14))
                        Text("PRO MEMBER")
                            .font(DesignSystem.Typography.small)
                            .foregroundStyle(DesignSystem.Colors.accentGold)
                            .fontWeight(.semibold)
                            .tracking(1)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(localized: "settings.pro.title"))
                            .font(DesignSystem.Typography.title2)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                            .fontWeight(.bold)

                        if effectiveProAccessEnabled {
                            Text(
                                subscriptionManager.hasActiveEntitlement
                                    ? (subscriptionManager.currentSubscriptionName ?? String(localized: "pro.status.active"))
                                    : "开发会话 PRO"
                            )
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.accentGold)
                        } else {
                            Text(String(localized: "settings.pro.subtitle"))
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                        }
                    }

                    if !effectiveProAccessEnabled {
                        HStack(spacing: 6) {
                            Text(String(localized: "settings.pro.action"))
                                .font(DesignSystem.Typography.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(DesignSystem.Colors.textOnPrimary)

                            Image(systemName: "arrow.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(DesignSystem.Colors.textOnPrimary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(DesignSystem.Colors.primary)
                        .clipShape(Capsule())
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)

                Image(systemName: "crown.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(DesignSystem.Colors.textPrimary.opacity(0.06))
                    .padding(.trailing, 16)
                    .padding(.bottom, 12)
            }
            .background(
                LinearGradient(
                    colors: [DesignSystem.Colors.proGradientStart, DesignSystem.Colors.proGradientEnd],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                    .stroke(DesignSystem.Colors.accentGold.opacity(0.2), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .simultaneousGesture(TapGesture().onEnded {
            InteractionLogger.navigation(screen: "settings.root", target: "settings.proCard", route: AppRoute.proMembership.logName)
        })
        .buttonStyle(.plain)
    }

    // MARK: - Preferences section

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(String(localized: "settings.section.preferences"))

            VStack(spacing: 0) {
                NavigationLink(value: AppRoute.appearanceSettings) {
                    settingsRow(icon: "paintpalette.fill", title: String(localized: "settings.appearance"))
                }
                .simultaneousGesture(TapGesture().onEnded {
                    InteractionLogger.navigation(
                        screen: "settings.root",
                        target: "settings.appearance",
                        route: AppRoute.appearanceSettings.logName
                    )
                })
                .buttonStyle(.plain)

                sectionDivider

                NavigationLink(value: AppRoute.notificationSettings) {
                    settingsRow(icon: "bell.fill", title: String(localized: "settings.notifications"))
                }
                .simultaneousGesture(TapGesture().onEnded {
                    InteractionLogger.navigation(
                        screen: "settings.root",
                        target: "settings.notifications",
                        route: AppRoute.notificationSettings.logName
                    )
                })
                .buttonStyle(.plain)

                sectionDivider

                NavigationLink(value: AppRoute.festivalManagement) {
                    settingsRow(icon: "sparkles", title: String(localized: "festival.management.title"))
                }
                .simultaneousGesture(TapGesture().onEnded {
                    InteractionLogger.navigation(
                        screen: "settings.root",
                        target: "settings.festivals",
                        route: AppRoute.festivalManagement.logName
                    )
                })
                .buttonStyle(.plain)
            }
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        }
    }

    // MARK: - Data section

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(String(localized: "settings.section.data"))

            VStack(spacing: 0) {
                NavigationLink(value: AppRoute.dataManagement) {
                    settingsRow(icon: "arrow.up.arrow.down.circle.fill", title: String(localized: "settings.importExport"))
                }
                .simultaneousGesture(TapGesture().onEnded {
                    InteractionLogger.navigation(
                        screen: "settings.root",
                        target: "settings.dataManagement",
                        route: AppRoute.dataManagement.logName
                    )
                })
                .buttonStyle(.plain)

                sectionDivider

                settingsToggleRow(
                    icon: "icloud.fill",
                    title: String(localized: "settings.icloudSync"),
                    isOn: Binding(
                        get: { settings.icloudSyncEnabled },
                        set: { newValue in
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
                                InteractionLogger.toggle(screen: "settings.root", target: "settings.icloudSync", isOn: newValue)
                                showRestartAlert = true
                            }
                        }
                    ),
                    badge: effectiveProAccessEnabled ? nil : "PRO"
                )
            }
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        }
    }

    // MARK: - About section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(String(localized: "settings.section.about"))

            VStack(spacing: 0) {
                NavigationLink(value: AppRoute.about) {
                    settingsRow(
                        icon: "info.circle.fill",
                        title: String(localized: "settings.about"),
                        detail: "v\(appVersion)"
                    )
                }
                .simultaneousGesture(TapGesture().onEnded {
                    InteractionLogger.navigation(screen: "settings.root", target: "settings.about", route: AppRoute.about.logName)
                })
                .buttonStyle(.plain)

                sectionDivider

                Button {
                    InteractionLogger.tap(screen: "settings.root", target: "settings.rateApp")
                    requestAppStoreRating()
                } label: {
                    settingsRow(icon: "star.fill", title: String(localized: "settings.rateApp"))
                }
                .buttonStyle(.plain)
            }
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        }
    }

    // MARK: - Helper views

    private var sectionDivider: some View {
        Divider()
            .background(DesignSystem.Colors.separator)
            .padding(.leading, 52)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(DesignSystem.Typography.small)
            .foregroundStyle(DesignSystem.Colors.textSecondary)
            .padding(.leading, 4)
    }

    private func settingsRow(
        icon: String,
        title: String,
        detail: String? = nil,
        isDestructive: Bool = false
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(isDestructive ? DesignSystem.Colors.destructive : DesignSystem.Colors.primary)
                .frame(width: 28, height: 28)

            Text(title)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(isDestructive ? DesignSystem.Colors.destructive : DesignSystem.Colors.textPrimary)

            Spacer()

            if let detail {
                Text(detail)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(DesignSystem.Colors.textTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    private func settingsToggleRow(
        icon: String,
        title: String,
        isOn: Binding<Bool>,
        badge: String? = nil
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(DesignSystem.Colors.primary)
                .frame(width: 28, height: 28)

            Text(title)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            if let badge {
                Text(badge)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(DesignSystem.Colors.textOnPrimary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(DesignSystem.Colors.accentGold)
                    .clipShape(Capsule())
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(DesignSystem.Colors.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Helpers

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private func requestAppStoreRating() {
        guard let url = URL(string: "itms-apps://itunes.apple.com/app/id6759552120?action=write-review") else { return }
        UIApplication.shared.open(url)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environment(SubscriptionManager.shared)
    .environment(AppSettings.shared)
}
