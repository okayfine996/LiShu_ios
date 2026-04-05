import Logging
import UIKit
import UserNotifications

private let appLifecycleLogger = PulseDiagnostics.makeLogger(label: "app.lifecycle")
private let notificationsLogger = PulseDiagnostics.makeLogger(label: "notifications.apns")

@MainActor
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        PulseDiagnostics.configureIfNeeded()
        UNUserNotificationCenter.current().delegate = self
        NotificationManager.shared.registerNotificationCategories()
        appLifecycleLogger.info("Application finished launching")
        return true
    }

    // MARK: - APNs Token

    func application(
        _: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        NotificationManager.shared.saveDeviceToken(deviceToken)
        notificationsLogger.info("APNs device token registered", metadata: [
            "token_length": .stringConvertible(deviceToken.count),
        ])
    }

    func application(
        _: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        notificationsLogger.error("APNs registration failed", metadata: [
            "error": .string(error.localizedDescription),
        ])
    }

    // MARK: - Silent Push (Background Wake)

    func application(
        _: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        NotificationManager.shared.handleRemoteNotification(
            userInfo: userInfo,
            completion: completionHandler
        )
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent _: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Future: parse response.notification.request.content.userInfo
        // to route user to specific event/contact detail page
        let userInfo = response.notification.request.content.userInfo
        let category = response.notification.request.content.categoryIdentifier
        let userInfoKeys = userInfo.keys.map { String(describing: $0) }.sorted().joined(separator: ",")
        notificationsLogger.notice("Notification tapped", metadata: [
            "category": .string(category),
            "user_info_keys": .string(userInfoKeys),
        ])

        completionHandler()
    }
}
