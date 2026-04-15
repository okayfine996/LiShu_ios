import Foundation
import PulseUI
import SwiftData
import SwiftUI

private struct DiagnosticsShareableFile: Identifiable {
    let id: String
    let url: URL
}

struct DiagnosticsConsoleContainerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(DebugOverrideManager.self) private var debugOverrides

    @State private var exportedDiagnosticsFileURL: URL?
    @State private var diagnosticsExportErrorMessage: String?
    @State private var pendingNotificationCount = 0
    @State private var statusMessage: String?
    @State private var showPulseConsole = false
    @State private var showClearDataConfirmation = false
    @State private var showClearNotificationConfirmation = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                if debugOverrides.proAccessOverrideEnabled {
                    overrideBanner
                }
                overviewSection
                membershipSection
                dataToolsSection
                notificationDebugSection
                appFlowSection
                diagnosticsLogsSection
            }
            .padding(16)
        }
        .background(DesignSystem.Colors.bgPage)
        .navigationTitle(String(localized: "debug.console.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(String(localized: "common.cancel")) {
                    dismiss()
                }
            }

            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(String(localized: "debug.console.exportTextLog")) {
                        exportDiagnosticsLog(as: .detailedText)
                    }
                    Button(String(localized: "debug.console.exportJsonLog")) {
                        exportDiagnosticsLog(as: .jsonLines)
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .trackScreen("settings.diagnosticsConsole")
        .task {
            await refreshPendingNotificationCount()
        }
        .sheet(item: Binding(
            get: { exportedDiagnosticsFileURL.map { DiagnosticsShareableFile(id: $0.absoluteString, url: $0) } },
            set: {
                if let url = exportedDiagnosticsFileURL, $0 == nil {
                    try? FileManager.default.removeItem(at: url)
                }
                exportedDiagnosticsFileURL = $0?.url
            }
        )) { item in
            ShareSheet(url: item.url) {
                exportedDiagnosticsFileURL = nil
                try? FileManager.default.removeItem(at: item.url)
            }
        }
        .alert(String(localized: "debug.console.exportErrorTitle"), isPresented: Binding(
            get: { diagnosticsExportErrorMessage != nil },
            set: { if !$0 { diagnosticsExportErrorMessage = nil } }
        )) {
            Button(String(localized: "common.ok")) {
                diagnosticsExportErrorMessage = nil
            }
        } message: {
            if let diagnosticsExportErrorMessage {
                Text(diagnosticsExportErrorMessage)
            }
        }
        .confirmationDialog(
            String(localized: "debug.clearAllData.confirmTitle"),
            isPresented: $showClearDataConfirmation,
            titleVisibility: .visible
        ) {
            Button(String(localized: "debug.clearAllData"), role: .destructive) {
                DebugConsoleActions.clearAllData(context: modelContext)
                statusMessage = String(localized: "debug.clearAllData.result")
            }
            .accessibilityIdentifier("debug.clearAllData.confirm")
            Button(String(localized: "common.cancel"), role: .cancel) {}
        } message: {
            Text(String(localized: "debug.clearAllData.confirmMessage"))
        }
        .confirmationDialog(
            String(localized: "debug.notification.clearAll.confirmTitle"),
            isPresented: $showClearNotificationConfirmation,
            titleVisibility: .visible
        ) {
            Button(String(localized: "debug.notification.clearAll"), role: .destructive) {
                DebugConsoleActions.clearAllNotifications()
                statusMessage = String(localized: "debug.notification.clearAll.result")
                Task { await refreshPendingNotificationCount() }
            }
            .accessibilityIdentifier("debug.notification.clearAll.confirm")
            Button(String(localized: "common.cancel"), role: .cancel) {}
        } message: {
            Text(String(localized: "debug.notification.clearAll.confirmMessage"))
        }
    }

    private var effectiveProAccessEnabled: Bool {
        subscriptionManager.effectiveIsPro(overrides: debugOverrides)
    }

    private var appVersionLine: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private var commitLine: String {
        AppBuildInfo.commitHash
    }

    private var overrideBanner: some View {
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

    private var overviewSection: some View {
        consoleSection("诊断") {
            infoRow(title: "版本", value: appVersionLine)
            infoRow(title: "Commit", value: commitLine)
            if let statusMessage {
                infoRow(title: "最近操作", value: statusMessage)
            }
        }
    }

    private var membershipSection: some View {
        consoleSection("会员与权限") {
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

                infoRow(title: "真实购买态", value: subscriptionManager.hasActiveEntitlement ? "已购买" : "未购买")
                infoRow(title: "当前生效态", value: effectiveProAccessEnabled ? "Pro 已生效" : "普通用户")
                infoRow(
                    title: "覆盖来源",
                    value: debugOverrides.overrideSourceDescription(hasEntitlement: subscriptionManager.hasActiveEntitlement)
                )
            }
        }
    }

    private var dataToolsSection: some View {
        consoleSection("开发数据") {
            actionButton(icon: "plus.circle.fill", title: "生成样例数据") {
                DebugConsoleActions.generateSampleData(context: modelContext)
                statusMessage = "已生成样例数据"
            }

            sectionDivider

            actionButton(icon: "trash.fill", title: "清空全部数据", role: .destructive) {
                showClearDataConfirmation = true
            }
            .accessibilityIdentifier("debug.clearAllData.button")

            sectionDivider

            actionButton(icon: "arrow.counterclockwise.circle.fill", title: "重置 OCR 次数") {
                DebugConsoleActions.resetOCRUsage()
                statusMessage = "已重置 OCR 次数"
            }
        }
    }

    private var notificationDebugSection: some View {
        consoleSection("通知调试") {
            actionButton(icon: "calendar.badge.clock", title: String(localized: "debug.notification.test.event")) {
                DebugConsoleActions.sendNotificationTest(for: .eventReminder)
                statusMessage = String(localized: "debug.notification.sent")
                Task { await refreshPendingNotificationCount() }
            }

            sectionDivider

            actionButton(icon: "gift.fill", title: String(localized: "debug.notification.test.returnGift")) {
                DebugConsoleActions.sendNotificationTest(for: .returnGift)
                statusMessage = String(localized: "debug.notification.sent")
                Task { await refreshPendingNotificationCount() }
            }

            sectionDivider

            actionButton(icon: "birthday.cake.fill", title: String(localized: "debug.notification.test.birthday")) {
                DebugConsoleActions.sendNotificationTest(for: .birthdayReminder)
                statusMessage = String(localized: "debug.notification.sent")
                Task { await refreshPendingNotificationCount() }
            }

            sectionDivider

            actionButton(icon: "bell.badge.fill", title: String(localized: "debug.notification.test.all")) {
                DebugConsoleActions.sendAllNotificationTests()
                statusMessage = String(localized: "debug.notification.sent")
                Task { await refreshPendingNotificationCount() }
            }

            sectionDivider

            infoRow(title: String(localized: "debug.notification.pending"), value: "\(pendingNotificationCount)")

            sectionDivider

            actionButton(icon: "trash", title: String(localized: "debug.notification.clearAll"), role: .destructive) {
                showClearNotificationConfirmation = true
            }
            .accessibilityIdentifier("debug.notification.clearAll.button")
        }
    }

    private var appFlowSection: some View {
        consoleSection("应用流程") {
            actionButton(icon: "hand.wave.fill", title: "重置引导页状态") {
                DebugConsoleActions.resetOnboarding()
                statusMessage = "已重置引导页状态"
            }

            sectionDivider

            actionButton(icon: "arrow.clockwise.circle", title: "强制刷新订阅状态") {
                Task {
                    await subscriptionManager.checkEntitlements()
                    statusMessage = "已刷新订阅状态"
                }
            }

            sectionDivider

            actionButton(icon: "cart.badge.plus", title: "重新拉取商品") {
                Task {
                    await subscriptionManager.reloadProducts()
                    statusMessage = "已重新拉取商品"
                }
            }

            sectionDivider

            infoRow(title: "引导页状态", value: settings.hasSeenOnboarding ? "已完成" : "未完成")
        }
    }

    private var diagnosticsLogsSection: some View {
        consoleSection("日志控制台") {
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
                sectionDivider

                ConsoleView()
                    .closeButtonHidden()
                    .toolbar(.hidden, for: .navigationBar)
                    .frame(height: 420)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
            }
        }
    }

    private func consoleSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
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

    private func infoRow(title: String, value: String) -> some View {
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

    private func actionButton(
        icon: String,
        title: String,
        role: ButtonRole? = nil,
        accessibilityIdentifier: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
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

    private var sectionDivider: some View {
        Divider()
            .padding(.vertical, 12)
    }

    private func exportDiagnosticsLog(as format: DiagnosticsExportService.ExportFormat) {
        do {
            switch format {
            case .detailedText:
                exportedDiagnosticsFileURL = try DiagnosticsExportService.exportDetailedLogs()
            case .jsonLines:
                exportedDiagnosticsFileURL = try DiagnosticsExportService.exportDetailedJSONLines()
            }
        } catch {
            diagnosticsExportErrorMessage = error.localizedDescription
        }
    }

    private func refreshPendingNotificationCount() async {
        pendingNotificationCount = await DebugConsoleActions.pendingNotificationCount()
    }
}

#Preview {
    NavigationStack {
        DiagnosticsConsoleContainerView()
            .environment(AppSettings.shared)
            .environment(SubscriptionManager.shared)
            .environment(DebugOverrideManager.shared)
    }
}
