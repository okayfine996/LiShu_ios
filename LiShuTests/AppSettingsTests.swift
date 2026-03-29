import Foundation
import Testing
@testable import LiShu

@MainActor
struct AppSettingsTests {

    private let defaults = UserDefaults.standard

    private func cleanupKeys() {
        let keys = [
            "hasSeenOnboarding", "colorScheme", "icloudSyncEnabled",
            "notificationEnabled", "eventReminder", "returnGiftReminder",
            "birthdayReminder", "ocrUsageCount", "ocrUsageMonth",
            "ocrUsageYear", "apnsDeviceToken"
        ]
        for key in keys {
            defaults.removeObject(forKey: key)
        }
    }

    @Test("default values after clearing UserDefaults")
    func testDefaultValues() {
        cleanupKeys()
        let settings = AppSettings.shared

        #expect(settings.hasSeenOnboarding == false)
        #expect(settings.colorScheme == "system")
        #expect(settings.icloudSyncEnabled == false)
        #expect(settings.notificationEnabled == false)
        #expect(settings.eventReminder == true)
        #expect(settings.returnGiftReminder == true)
        #expect(settings.birthdayReminder == true)
        #expect(settings.ocrUsageCount == 0)
        #expect(settings.deviceToken == nil)

        cleanupKeys()
    }

    @Test("colorScheme read/write round-trip")
    func testColorSchemeReadWrite() {
        cleanupKeys()
        let settings = AppSettings.shared

        settings.colorScheme = "dark"
        #expect(settings.colorScheme == "dark")

        settings.colorScheme = "light"
        #expect(settings.colorScheme == "light")

        settings.colorScheme = "system"
        #expect(settings.colorScheme == "system")

        cleanupKeys()
    }

    @Test("notification settings read/write")
    func testNotificationSettings() {
        cleanupKeys()
        let settings = AppSettings.shared

        settings.notificationEnabled = true
        #expect(settings.notificationEnabled == true)

        settings.eventReminder = false
        #expect(settings.eventReminder == false)

        settings.returnGiftReminder = false
        #expect(settings.returnGiftReminder == false)

        settings.birthdayReminder = false
        #expect(settings.birthdayReminder == false)

        cleanupKeys()
    }

    @Test("OCR usage tracking read/write")
    func testOCRUsageTracking() {
        cleanupKeys()
        let settings = AppSettings.shared

        settings.ocrUsageCount = 5
        #expect(settings.ocrUsageCount == 5)

        settings.ocrUsageMonth = 3
        #expect(settings.ocrUsageMonth == 3)

        settings.ocrUsageYear = 2026
        #expect(settings.ocrUsageYear == 2026)

        cleanupKeys()
    }
}
