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
            DiagnosticsConsoleContentView(
                debugOverrides: debugOverrides,
                subscriptionManager: subscriptionManager,
                settings: settings,
                appVersionLine: appVersionLine,
                commitLine: commitLine,
                statusMessage: statusMessage,
                pendingNotificationCount: pendingNotificationCount,
                showPulseConsole: $showPulseConsole,
                onGenerateSampleData: generateSampleData,
                onClearAllData: promptClearAllData,
                onResetOCRUsage: resetOCRUsage,
                onSendEventNotification: sendEventNotification,
                onSendReturnGiftNotification: sendReturnGiftNotification,
                onSendBirthdayNotification: sendBirthdayNotification,
                onSendAllNotifications: sendAllNotifications,
                onClearAllNotifications: promptClearAllNotifications,
                onResetOnboarding: resetOnboarding,
                onRefreshEntitlements: refreshEntitlements,
                onReloadProducts: reloadProducts,
                onForceShowAd: forceShowAd,
                onResetAdFrequency: resetAdFrequency,
                onForcePreloadAd: forcePreloadAd,
                adStatusDescription: AdManager.shared.nativeAdStatusDescription
            )
            .padding(16)
        }
        .background(DesignSystem.Colors.bgPage)
        .navigationTitle(String(localized: "debug.console.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(String(localized: "common.cancel"), action: dismiss.callAsFunction)
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
        .sheet(item: shareableFileBinding) { item in
            ShareSheet(url: item.url) {
                exportedDiagnosticsFileURL = nil
                try? FileManager.default.removeItem(at: item.url)
            }
        }
        .alert(String(localized: "debug.console.exportErrorTitle"), isPresented: diagnosticsErrorBinding) {
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
            Button(String(localized: "debug.clearAllData"), role: .destructive, action: clearAllData)
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
            Button(String(localized: "debug.notification.clearAll"), role: .destructive, action: clearAllNotifications)
                .accessibilityIdentifier("debug.notification.clearAll.confirm")
            Button(String(localized: "common.cancel"), role: .cancel) {}
        } message: {
            Text(String(localized: "debug.notification.clearAll.confirmMessage"))
        }
    }

    private var appVersionLine: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private var commitLine: String {
        AppBuildInfo.commitHash
    }

    private var shareableFileBinding: Binding<DiagnosticsShareableFile?> {
        Binding(
            get: { exportedDiagnosticsFileURL.map { DiagnosticsShareableFile(id: $0.absoluteString, url: $0) } },
            set: {
                if let url = exportedDiagnosticsFileURL, $0 == nil {
                    try? FileManager.default.removeItem(at: url)
                }
                exportedDiagnosticsFileURL = $0?.url
            }
        )
    }

    private var diagnosticsErrorBinding: Binding<Bool> {
        Binding(
            get: { diagnosticsExportErrorMessage != nil },
            set: { if !$0 { diagnosticsExportErrorMessage = nil } }
        )
    }

    private func generateSampleData() {
        DebugConsoleActions.generateSampleData(context: modelContext)
        statusMessage = "已生成样例数据"
    }

    private func promptClearAllData() {
        showClearDataConfirmation = true
    }

    private func clearAllData() {
        DebugConsoleActions.clearAllData(context: modelContext)
        statusMessage = String(localized: "debug.clearAllData.result")
    }

    private func resetOCRUsage() {
        DebugConsoleActions.resetOCRUsage()
        statusMessage = "已重置 OCR 次数"
    }

    private func sendEventNotification() {
        DebugConsoleActions.sendNotificationTest(for: .eventReminder)
        statusMessage = String(localized: "debug.notification.sent")
        Task { await refreshPendingNotificationCount() }
    }

    private func sendReturnGiftNotification() {
        DebugConsoleActions.sendNotificationTest(for: .returnGift)
        statusMessage = String(localized: "debug.notification.sent")
        Task { await refreshPendingNotificationCount() }
    }

    private func sendBirthdayNotification() {
        DebugConsoleActions.sendNotificationTest(for: .birthdayReminder)
        statusMessage = String(localized: "debug.notification.sent")
        Task { await refreshPendingNotificationCount() }
    }

    private func sendAllNotifications() {
        DebugConsoleActions.sendAllNotificationTests()
        statusMessage = String(localized: "debug.notification.sent")
        Task { await refreshPendingNotificationCount() }
    }

    private func promptClearAllNotifications() {
        showClearNotificationConfirmation = true
    }

    private func clearAllNotifications() {
        DebugConsoleActions.clearAllNotifications()
        statusMessage = String(localized: "debug.notification.clearAll.result")
        Task { await refreshPendingNotificationCount() }
    }

    private func resetOnboarding() {
        DebugConsoleActions.resetOnboarding()
        statusMessage = "已重置引导页状态"
    }

    private func refreshEntitlements() {
        Task {
            await subscriptionManager.checkEntitlements()
            statusMessage = "已刷新订阅状态"
        }
    }

    private func reloadProducts() {
        Task {
            await subscriptionManager.reloadProducts()
            statusMessage = "已重新拉取商品"
        }
    }

    private func forceShowAd() {
        let success = DebugConsoleActions.forceShowNativeAd()
        statusMessage = success
            ? String(localized: "debug.ad.forceShow.success")
            : String(localized: "debug.ad.forceShow.noAd")
    }

    private func resetAdFrequency() {
        DebugConsoleActions.resetAdFrequency()
        statusMessage = String(localized: "debug.ad.resetFrequency.result")
    }

    private func forcePreloadAd() {
        DebugConsoleActions.forcePreloadAd()
        statusMessage = String(localized: "debug.ad.forcePreload.result")
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
