import Foundation
import SwiftData

@MainActor
enum DebugConsoleActions {
    static func generateSampleData(context: ModelContext) {
        DebugDataGenerator.generateSampleData(context: context)
    }

    static func clearAllData(context: ModelContext) {
        DebugDataGenerator.clearAllData(context: context)
    }

    static func resetOCRUsage() {
        let settings = AppSettings.shared
        settings.ocrUsageCount = 0
        settings.ocrUsageMonth = Calendar.current.component(.month, from: .now)
        settings.ocrUsageYear = Calendar.current.component(.year, from: .now)
    }

    static func resetOnboarding() {
        AppSettings.shared.hasSeenOnboarding = false
    }

    static func sendNotificationTest(for category: NotificationManager.Category) {
        NotificationManager.shared.sendTestNotification(category: category)
    }

    static func sendAllNotificationTests() {
        NotificationManager.shared.sendAllTestNotifications()
    }

    static func clearAllNotifications() {
        NotificationManager.shared.cancelAll()
    }

    static func pendingNotificationCount() async -> Int {
        await NotificationManager.shared.listPendingNotifications().count
    }

    /// 强制触发弹出广告，返回是否成功（false 表示广告未加载）
    @discardableResult
    static func forceShowNativeAd() -> Bool {
        AdManager.shared.forceShowNativeAd()
    }

    static func resetAdFrequency() {
        AdManager.shared.resetFrequencyControls()
    }

    static func forcePreloadAd() {
        AdManager.shared.forcePreloadNativeAd()
    }
}
