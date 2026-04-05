import Foundation
import Logging

private nonisolated(unsafe) var appSettingsLogger: Logger { PulseDiagnostics.makeLogger(label: AppLogLabel.settings) }

@Observable
@MainActor
class AppSettings {
    static let shared = AppSettings()

    private let defaults = UserDefaults.standard

    // MARK: - Keys

    private enum Keys {
        static let hasSeenOnboarding = "hasSeenOnboarding"
        static let colorScheme = "colorScheme"



        static let icloudSyncEnabled = "icloudSyncEnabled"
        static let notificationEnabled = "notificationEnabled"
        static let eventReminder = "eventReminder"
        static let returnGiftReminder = "returnGiftReminder"
        static let birthdayReminder = "birthdayReminder"
        static let ocrUsageCount = "ocrUsageCount"
        static let ocrUsageMonth = "ocrUsageMonth"
        static let ocrUsageYear = "ocrUsageYear"
        static let deviceToken = "apnsDeviceToken"
    }

    private init() {}

    // MARK: - Onboarding

    var hasSeenOnboarding: Bool {
        get { access(keyPath: \.hasSeenOnboarding); return defaults.bool(forKey: Keys.hasSeenOnboarding) }
        set {
            withMutation(keyPath: \.hasSeenOnboarding) { defaults.set(newValue, forKey: Keys.hasSeenOnboarding) }
            appSettingsLogger.notice("Updated app setting", metadata: [
                "action": .string("set"),
                "target": .string("onboarding.seen"),
                "result": .string(newValue ? "true" : "false")
            ])
        }
    }

    // MARK: - Appearance

    var colorScheme: String {
        get { access(keyPath: \.colorScheme); return defaults.string(forKey: Keys.colorScheme) ?? "system" }
        set {
            withMutation(keyPath: \.colorScheme) { defaults.set(newValue, forKey: Keys.colorScheme) }
            appSettingsLogger.notice("Updated app setting", metadata: [
                "action": .string("set"),
                "target": .string("appearance.color_scheme"),
                "result": .string(newValue)
            ])
        }
    }

    // MARK: - Security

    // MARK: - Data

    var icloudSyncEnabled: Bool {
        get { access(keyPath: \.icloudSyncEnabled); return defaults.object(forKey: Keys.icloudSyncEnabled) as? Bool ?? false }
        set {
            withMutation(keyPath: \.icloudSyncEnabled) { defaults.set(newValue, forKey: Keys.icloudSyncEnabled) }
            appSettingsLogger.notice("Updated app setting", metadata: [
                "action": .string("set"),
                "target": .string("storage.icloud_sync"),
                "result": .string(newValue ? "enabled" : "disabled")
            ])
        }
    }

    // MARK: - Notifications

    var notificationEnabled: Bool {
        get { access(keyPath: \.notificationEnabled); return defaults.object(forKey: Keys.notificationEnabled) as? Bool ?? false }
        set {
            withMutation(keyPath: \.notificationEnabled) { defaults.set(newValue, forKey: Keys.notificationEnabled) }
            appSettingsLogger.notice("Updated app setting", metadata: [
                "action": .string("set"),
                "target": .string("notifications.enabled"),
                "result": .string(newValue ? "enabled" : "disabled")
            ])
        }
    }

    var eventReminder: Bool {
        get { access(keyPath: \.eventReminder); return defaults.object(forKey: Keys.eventReminder) as? Bool ?? true }
        set {
            withMutation(keyPath: \.eventReminder) { defaults.set(newValue, forKey: Keys.eventReminder) }
            appSettingsLogger.notice("Updated app setting", metadata: [
                "action": .string("set"),
                "target": .string("notifications.event_reminder"),
                "result": .string(newValue ? "enabled" : "disabled")
            ])
        }
    }

    var returnGiftReminder: Bool {
        get { access(keyPath: \.returnGiftReminder); return defaults.object(forKey: Keys.returnGiftReminder) as? Bool ?? true }
        set {
            withMutation(keyPath: \.returnGiftReminder) { defaults.set(newValue, forKey: Keys.returnGiftReminder) }
            appSettingsLogger.notice("Updated app setting", metadata: [
                "action": .string("set"),
                "target": .string("notifications.return_gift_reminder"),
                "result": .string(newValue ? "enabled" : "disabled")
            ])
        }
    }

    var birthdayReminder: Bool {
        get { access(keyPath: \.birthdayReminder); return defaults.object(forKey: Keys.birthdayReminder) as? Bool ?? true }
        set {
            withMutation(keyPath: \.birthdayReminder) { defaults.set(newValue, forKey: Keys.birthdayReminder) }
            appSettingsLogger.notice("Updated app setting", metadata: [
                "action": .string("set"),
                "target": .string("notifications.birthday_reminder"),
                "result": .string(newValue ? "enabled" : "disabled")
            ])
        }
    }

    // MARK: - OCR Usage

    var ocrUsageCount: Int {
        get { access(keyPath: \.ocrUsageCount); return defaults.integer(forKey: Keys.ocrUsageCount) }
        set {
            withMutation(keyPath: \.ocrUsageCount) { defaults.set(newValue, forKey: Keys.ocrUsageCount) }
            appSettingsLogger.info("Updated app setting", metadata: [
                "action": .string("set"),
                "target": .string("ocr.usage_count"),
                "result": .stringConvertible(newValue)
            ])
        }
    }

    var ocrUsageMonth: Int {
        get { access(keyPath: \.ocrUsageMonth); return defaults.integer(forKey: Keys.ocrUsageMonth) }
        set {
            withMutation(keyPath: \.ocrUsageMonth) { defaults.set(newValue, forKey: Keys.ocrUsageMonth) }
            appSettingsLogger.info("Updated app setting", metadata: [
                "action": .string("set"),
                "target": .string("ocr.usage_month"),
                "result": .stringConvertible(newValue)
            ])
        }
    }

    var ocrUsageYear: Int {
        get { access(keyPath: \.ocrUsageYear); return defaults.integer(forKey: Keys.ocrUsageYear) }
        set {
            withMutation(keyPath: \.ocrUsageYear) { defaults.set(newValue, forKey: Keys.ocrUsageYear) }
            appSettingsLogger.info("Updated app setting", metadata: [
                "action": .string("set"),
                "target": .string("ocr.usage_year"),
                "result": .stringConvertible(newValue)
            ])
        }
    }

    // MARK: - Device Token

    var deviceToken: String? {
        get { access(keyPath: \.deviceToken); return defaults.string(forKey: Keys.deviceToken) }
        set {
            withMutation(keyPath: \.deviceToken) { defaults.set(newValue, forKey: Keys.deviceToken) }
            appSettingsLogger.notice("Updated app setting", metadata: [
                "action": .string("set"),
                "target": .string("notifications.device_token"),
                "result": .string(newValue == nil ? "cleared" : "updated")
            ])
        }
    }
}
