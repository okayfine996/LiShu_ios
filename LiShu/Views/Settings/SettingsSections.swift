import SwiftUI

struct SettingsContentView: View {
    let effectiveProAccessEnabled: Bool
    let hasActiveEntitlement: Bool
    let currentSubscriptionName: String?
    let appVersion: String
    let icloudSyncEnabled: Binding<Bool>
    let onOpenProMembership: () -> Void
    let onOpenAppearance: () -> Void
    let onOpenNotifications: () -> Void
    let onOpenDataManagement: () -> Void
    let onOpenAbout: () -> Void
    let onRateApp: () -> Void
    let onRestartGuideTour: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            SettingsProCard(
                effectiveProAccessEnabled: effectiveProAccessEnabled,
                hasActiveEntitlement: hasActiveEntitlement,
                currentSubscriptionName: currentSubscriptionName,
                onTap: onOpenProMembership
            )

            SettingsSection(
                title: String(localized: "settings.section.preferences"),
                rows: [
                    .navigation(
                        icon: "paintpalette.fill",
                        title: String(localized: "settings.appearance"),
                        route: .appearanceSettings,
                        onNavigate: onOpenAppearance
                    ),
                    .navigation(
                        icon: "bell.fill",
                        title: String(localized: "settings.notifications"),
                        route: .notificationSettings,
                        onNavigate: onOpenNotifications
                    ),
                ]
            )

            SettingsSection(
                title: String(localized: "settings.section.data"),
                rows: [
                    .navigation(
                        icon: "arrow.up.arrow.down.circle.fill",
                        title: String(localized: "settings.importExport"),
                        route: .dataManagement,
                        onNavigate: onOpenDataManagement
                    ),
                    .toggle(
                        icon: "icloud.fill",
                        title: String(localized: "settings.icloudSync"),
                        isOn: icloudSyncEnabled,
                        badge: effectiveProAccessEnabled ? nil : "PRO"
                    ),
                ]
            )

            SettingsSection(
                title: String(localized: "settings.section.about"),
                rows: [
                    .navigation(
                        icon: "info.circle.fill",
                        title: String(localized: "settings.about"),
                        detail: "v\(appVersion)",
                        route: .about,
                        onNavigate: onOpenAbout
                    ),
                    .button(
                        icon: "star.fill",
                        title: String(localized: "settings.rateApp"),
                        action: onRateApp
                    ),
                    .button(
                        icon: "questionmark.circle.fill",
                        title: String(localized: "settings.restartGuideTour"),
                        action: onRestartGuideTour
                    ),
                ]
            )
        }
    }
}

private struct SettingsProCard: View {
    let effectiveProAccessEnabled: Bool
    let hasActiveEntitlement: Bool
    let currentSubscriptionName: String?
    let onTap: () -> Void

    var body: some View {
        NavigationLink(value: AppRoute.proMembership) {
            ZStack(alignment: .bottomTrailing) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(DesignSystem.Colors.accentGold)
                            .font(DesignSystem.Typography.caption)
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
                            Text(subscriptionText)
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
                                .font(DesignSystem.Typography.small.weight(.semibold))
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
        .simultaneousGesture(TapGesture().onEnded(onTap))
        .buttonStyle(.plain)
    }

    private var subscriptionText: String {
        if hasActiveEntitlement {
            currentSubscriptionName ?? String(localized: "pro.status.active")
        } else {
            "开发会话 PRO"
        }
    }
}

private struct SettingsSection: View {
    let title: String
    let rows: [SettingsRow]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    SettingsRowView(row: row)
                    if index < rows.count - 1 {
                        Divider()
                            .background(DesignSystem.Colors.separator)
                            .padding(.leading, 52)
                    }
                }
            }
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        }
    }
}

private struct SettingsRowView: View {
    let row: SettingsRow

    var body: some View {
        switch row {
        case let .navigation(icon, title, detail, route, onNavigate):
            NavigationLink(value: route) {
                SettingsNavigationRow(icon: icon, title: title, detail: detail)
            }
            .simultaneousGesture(TapGesture().onEnded(onNavigate))
            .buttonStyle(.plain)
        case let .button(icon, title, action):
            Button(action: action) {
                SettingsNavigationRow(icon: icon, title: title, detail: nil)
            }
            .buttonStyle(.plain)
        case let .toggle(icon, title, isOn, badge):
            SettingsToggleRow(icon: icon, title: title, isOn: isOn, badge: badge)
        }
    }
}

private struct SettingsNavigationRow: View {
    let icon: String
    let title: String
    let detail: String?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(DesignSystem.Colors.primary)
                .frame(width: 28, height: 28)

            Text(title)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

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
}

private struct SettingsToggleRow: View {
    let icon: String
    let title: String
    let isOn: Binding<Bool>
    let badge: String?

    var body: some View {
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
}

private enum SettingsRow {
    case navigation(icon: String, title: String, detail: String? = nil, route: AppRoute, onNavigate: () -> Void)
    case button(icon: String, title: String, action: () -> Void)
    case toggle(icon: String, title: String, isOn: Binding<Bool>, badge: String? = nil)
}
