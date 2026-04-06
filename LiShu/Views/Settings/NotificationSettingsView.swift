import SwiftData
import SwiftUI

@MainActor
struct NotificationSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings
    @State private var systemDenied = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                if systemDenied {
                    systemDeniedBanner
                }
                pushNotificationSection
                notificationTypesSection
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
