import SwiftUI
import SwiftData

struct NotificationSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings
    @State private var systemDenied = false

    #if DEBUG
    @State private var pendingCount: Int = 0
    @State private var showTestSentToast = false
    #endif

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                if systemDenied {
                    systemDeniedBanner
                }
                pushNotificationSection
                notificationTypesSection
                #if DEBUG
                debugSection
                #endif
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .background(DesignSystem.Colors.bgPage)
        .navigationTitle(String(localized: "settings.notifications"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            let status = await NotificationManager.shared.checkAuthorizationStatus()
            systemDenied = (status == .denied)
        }
        #if DEBUG
        .overlay(alignment: .bottom) {
            if showTestSentToast {
                Text(String(localized: "debug.notification.sent"))
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textOnPrimary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(DesignSystem.Colors.primary)
                    .clipShape(Capsule())
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showTestSentToast)
        .task {
            await refreshPendingCount()
        }
        #endif
    }

    // MARK: - System Denied Banner

    private var systemDeniedBanner: some View {
        Button {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text(String(localized: "settings.notification.systemDenied"))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .multilineTextAlignment(.leading)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
            .padding(14)
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Push Notification Section

    private var pushNotificationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(String(localized: "settings.notification.section.push"))

            VStack(spacing: 0) {
                Toggle(isOn: Bindable(settings).notificationEnabled) {
                    HStack(spacing: 12) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(DesignSystem.Colors.primary)
                            .frame(width: 28, height: 28)

                        Text(String(localized: "settings.notification.allow"))
                            .font(DesignSystem.Typography.body)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                    }
                }
                .tint(DesignSystem.Colors.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .onChange(of: settings.notificationEnabled) { _, newValue in
                    if newValue {
                        Task {
                            _ = await NotificationManager.shared.requestAuthorization()
                            NotificationManager.shared.rescheduleAll(context: modelContext)
                        }
                    } else {
                        NotificationManager.shared.cancelAll()
                    }
                }

                if !settings.notificationEnabled {
                    Divider()
                        .background(DesignSystem.Colors.separator)
                        .padding(.leading, 56)

                    Text(String(localized: "settings.notification.disabledHint"))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                }
            }
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        }
    }

    // MARK: - Notification Types Section

    private var notificationTypesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(String(localized: "settings.notification.section.types"))

            VStack(spacing: 0) {
                notificationToggle(
                    icon: "calendar.badge.clock",
                    title: String(localized: "settings.notification.event"),
                    isOn: Bindable(settings).eventReminder
                )
                .onChange(of: settings.eventReminder) { _, _ in
                    NotificationManager.shared.rescheduleAll(context: modelContext)
                }

                Divider()
                    .background(DesignSystem.Colors.separator)
                    .padding(.leading, 56)

                notificationToggle(
                    icon: "gift.fill",
                    title: String(localized: "settings.notification.returnGift"),
                    isOn: Bindable(settings).returnGiftReminder
                )
                .onChange(of: settings.returnGiftReminder) { _, _ in
                    NotificationManager.shared.rescheduleAll(context: modelContext)
                }

                Divider()
                    .background(DesignSystem.Colors.separator)
                    .padding(.leading, 56)

                notificationToggle(
                    icon: "birthday.cake.fill",
                    title: String(localized: "settings.notification.birthday"),
                    isOn: Bindable(settings).birthdayReminder
                )
                .onChange(of: settings.birthdayReminder) { _, _ in
                    NotificationManager.shared.rescheduleAll(context: modelContext)
                }
            }
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
            .opacity(settings.notificationEnabled ? 1 : 0.5)
            .disabled(!settings.notificationEnabled)
        }
    }

    // MARK: - Debug Section

    #if DEBUG
    private var debugSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("🛠 DEBUG")

            VStack(spacing: 0) {
                debugButton(
                    icon: "calendar.badge.clock",
                    title: String(localized: "debug.notification.test.event")
                ) {
                    NotificationManager.shared.sendTestNotification(category: .eventReminder)
                    showToast()
                }

                debugDivider

                debugButton(
                    icon: "gift.fill",
                    title: String(localized: "debug.notification.test.returnGift")
                ) {
                    NotificationManager.shared.sendTestNotification(category: .returnGift)
                    showToast()
                }

                debugDivider

                debugButton(
                    icon: "birthday.cake.fill",
                    title: String(localized: "debug.notification.test.birthday")
                ) {
                    NotificationManager.shared.sendTestNotification(category: .birthdayReminder)
                    showToast()
                }

                debugDivider

                debugButton(
                    icon: "bell.badge.fill",
                    title: String(localized: "debug.notification.test.all")
                ) {
                    NotificationManager.shared.sendAllTestNotifications()
                    showToast()
                }

                debugDivider

                HStack(spacing: 12) {
                    Image(systemName: "list.bullet.clipboard")
                        .font(.system(size: 18))
                        .foregroundStyle(.orange)
                        .frame(width: 28, height: 28)

                    Text(String(localized: "debug.notification.pending"))
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    Spacer()

                    Text("\(pendingCount)")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .monospacedDigit()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                debugDivider

                debugButton(
                    icon: "trash",
                    title: String(localized: "debug.notification.clearAll"),
                    isDestructive: true
                ) {
                    NotificationManager.shared.cancelAll()
                    Task { await refreshPendingCount() }
                }
            }
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                    .stroke(.orange.opacity(0.3), lineWidth: 1)
            )
        }
    }

    private var debugDivider: some View {
        Divider()
            .background(DesignSystem.Colors.separator)
            .padding(.leading, 56)
    }

    private func debugButton(
        icon: String,
        title: String,
        isDestructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            action()
            Task { await refreshPendingCount() }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(isDestructive ? DesignSystem.Colors.destructive : .orange)
                    .frame(width: 28, height: 28)

                Text(title)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(isDestructive ? DesignSystem.Colors.destructive : DesignSystem.Colors.textPrimary)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func showToast() {
        showTestSentToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showTestSentToast = false
        }
    }

    private func refreshPendingCount() async {
        let requests = await NotificationManager.shared.listPendingNotifications()
        pendingCount = requests.count
    }
    #endif

    // MARK: - Helpers

    private func notificationToggle(icon: String, title: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(DesignSystem.Colors.primary)
                    .frame(width: 28, height: 28)

                Text(title)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
            }
        }
        .tint(DesignSystem.Colors.primary)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(DesignSystem.Typography.small)
            .foregroundStyle(DesignSystem.Colors.textSecondary)
            .padding(.leading, 4)
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
            .modelContainer(for: [Contact.self, Record.self, Event.self], inMemory: true)
            .environment(AppSettings.shared)
    }
}
