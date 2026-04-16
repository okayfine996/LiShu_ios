import PulseUI
import SwiftUI

struct DiagnosticsConsoleContentView: View {
    let debugOverrides: DebugOverrideManager
    let subscriptionManager: SubscriptionManager
    let settings: AppSettings
    let appVersionLine: String
    let commitLine: String
    let statusMessage: String?
    let pendingNotificationCount: Int
    @Binding var showPulseConsole: Bool
    let onGenerateSampleData: () -> Void
    let onClearAllData: () -> Void
    let onResetOCRUsage: () -> Void
    let onSendEventNotification: () -> Void
    let onSendReturnGiftNotification: () -> Void
    let onSendBirthdayNotification: () -> Void
    let onSendAllNotifications: () -> Void
    let onClearAllNotifications: () -> Void
    let onResetOnboarding: () -> Void
    let onRefreshEntitlements: () -> Void
    let onReloadProducts: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            if debugOverrides.proAccessOverrideEnabled {
                DiagnosticsOverrideBanner()
            }

            DiagnosticsInfoSection(
                title: "诊断",
                rows: [
                    .info(title: "版本", value: appVersionLine),
                    .info(title: "Commit", value: commitLine),
                    statusMessage.map { .info(title: "最近操作", value: $0) },
                ].compactMap(\.self)
            )

            DiagnosticsMembershipSection(
                debugOverrides: debugOverrides,
                hasActiveEntitlement: subscriptionManager.hasActiveEntitlement,
                effectiveIsPro: subscriptionManager.effectiveIsPro(overrides: debugOverrides)
            )

            DiagnosticsActionSection(
                title: "开发数据",
                rows: [
                    .action(icon: "plus.circle.fill", title: "生成样例数据", action: onGenerateSampleData),
                    .action(
                        icon: "trash.fill",
                        title: "清空全部数据",
                        role: .destructive,
                        accessibilityIdentifier: "debug.clearAllData.button",
                        action: onClearAllData
                    ),
                    .action(
                        icon: "arrow.counterclockwise.circle.fill",
                        title: "重置 OCR 次数",
                        action: onResetOCRUsage
                    ),
                ]
            )

            DiagnosticsActionSection(
                title: "通知调试",
                rows: [
                    .action(
                        icon: "calendar.badge.clock",
                        title: String(localized: "debug.notification.test.event"),
                        action: onSendEventNotification
                    ),
                    .action(
                        icon: "gift.fill",
                        title: String(localized: "debug.notification.test.returnGift"),
                        action: onSendReturnGiftNotification
                    ),
                    .action(
                        icon: "birthday.cake.fill",
                        title: String(localized: "debug.notification.test.birthday"),
                        action: onSendBirthdayNotification
                    ),
                    .action(
                        icon: "bell.badge.fill",
                        title: String(localized: "debug.notification.test.all"),
                        action: onSendAllNotifications
                    ),
                    .info(
                        title: String(localized: "debug.notification.pending"),
                        value: "\(pendingNotificationCount)"
                    ),
                    .action(
                        icon: "trash",
                        title: String(localized: "debug.notification.clearAll"),
                        role: .destructive,
                        accessibilityIdentifier: "debug.notification.clearAll.button",
                        action: onClearAllNotifications
                    ),
                ]
            )

            DiagnosticsActionSection(
                title: "应用流程",
                rows: [
                    .action(icon: "hand.wave.fill", title: "重置引导页状态", action: onResetOnboarding),
                    .action(icon: "arrow.clockwise.circle", title: "强制刷新订阅状态", action: onRefreshEntitlements),
                    .action(icon: "cart.badge.plus", title: "重新拉取商品", action: onReloadProducts),
                    .info(title: "引导页状态", value: settings.hasSeenOnboarding ? "已完成" : "未完成"),
                ]
            )

            DiagnosticsLogsSection(showPulseConsole: $showPulseConsole)
        }
    }
}

private struct DiagnosticsOverrideBanner: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("临时 Pro 权限已启用")
                .font(DesignSystem.Typography.body)
                .fontWeight(.semibold)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Text("该状态会在本次 App 存活期间持续生效；关闭控制台不会失效，重启 App 后才会恢复真实权限校验。")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.orange.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                .stroke(Color.orange.opacity(0.35), lineWidth: 1)
        )
    }
}

private struct DiagnosticsMembershipSection: View {
    let debugOverrides: DebugOverrideManager
    let hasActiveEntitlement: Bool
    let effectiveIsPro: Bool

    var body: some View {
        DiagnosticsSection(title: "会员与权限") {
            VStack(spacing: 12) {
                Toggle(isOn: Binding(
                    get: { debugOverrides.proAccessOverrideEnabled },
                    set: { debugOverrides.proAccessOverrideEnabled = $0 }
                )) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("临时启用 Pro 权限（本次启动）")
                            .font(DesignSystem.Typography.body)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)

                        Text("仅用于开发调试，不会写入本地持久化。关闭控制台后仍保留，重启 App 才会恢复。")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                }
                .tint(.orange)

                DiagnosticsInfoRow(title: "真实购买态", value: hasActiveEntitlement ? "已购买" : "未购买")
                DiagnosticsInfoRow(title: "当前生效态", value: effectiveIsPro ? "Pro 已生效" : "普通用户")
                DiagnosticsInfoRow(
                    title: "覆盖来源",
                    value: debugOverrides.overrideSourceDescription(hasEntitlement: hasActiveEntitlement)
                )
            }
        }
    }
}

private struct DiagnosticsActionSection: View {
    let title: String
    let rows: [DiagnosticsRow]

    var body: some View {
        DiagnosticsSection(title: title) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    switch row {
                    case let .info(title, value):
                        DiagnosticsInfoRow(title: title, value: value)
                    case let .action(icon, title, role, identifier, action):
                        DiagnosticsActionRow(
                            icon: icon,
                            title: title,
                            role: role,
                            accessibilityIdentifier: identifier,
                            action: action
                        )
                    }

                    if index < rows.count - 1 {
                        Divider().padding(.vertical, 12)
                    }
                }
            }
        }
    }
}

private struct DiagnosticsLogsSection: View {
    @Binding var showPulseConsole: Bool

    var body: some View {
        DiagnosticsSection(title: "日志控制台") {
            Button {
                showPulseConsole.toggle()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: showPulseConsole ? "rectangle.compress.vertical" : "rectangle.expand.vertical")
                        .font(.system(size: 18))
                        .foregroundStyle(DesignSystem.Colors.primary)
                        .frame(width: 28, height: 28)

                    Text(showPulseConsole ? "收起日志控制台" : "打开日志控制台")
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    Spacer()
                }
                .padding(.vertical, 2)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if showPulseConsole {
                Divider().padding(.vertical, 12)

                ConsoleView()
                    .closeButtonHidden()
                    .toolbar(.hidden, for: .navigationBar)
                    .frame(height: 420)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
            }
        }
    }
}

private struct DiagnosticsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .padding(.leading, 4)

            VStack(alignment: .leading, spacing: 0) {
                content()
            }
            .padding(16)
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        }
    }
}

private struct DiagnosticsInfoSection: View {
    let title: String
    let rows: [DiagnosticsRow]

    var body: some View {
        DiagnosticsActionSection(title: title, rows: rows)
    }
}

private struct DiagnosticsInfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Spacer()

            Text(value)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.trailing)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }
}

private struct DiagnosticsActionRow: View {
    let icon: String
    let title: String
    let role: ButtonRole?
    let accessibilityIdentifier: String?
    let action: () -> Void

    var body: some View {
        Button(role: role, action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(role == .destructive ? DesignSystem.Colors.destructive : DesignSystem.Colors.primary)
                    .frame(width: 28, height: 28)

                Text(title)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(role == .destructive ? DesignSystem.Colors.destructive : DesignSystem.Colors.textPrimary)

                Spacer()
            }
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(accessibilityIdentifier ?? "")
    }
}

private enum DiagnosticsRow {
    case info(title: String, value: String)
    case action(icon: String, title: String, role: ButtonRole? = nil, accessibilityIdentifier: String? = nil, action: () -> Void)
}
