import Foundation
import Logging
import SwiftData
import UIKit
import UserNotifications

private let notificationLogger = PulseDiagnostics.makeLogger(label: AppLogLabel.notifications)

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()
    private var settings: AppSettings {
        AppSettings.shared
    }

    enum Category: String, CaseIterable {
        case eventReminder
        case birthdayReminder
        case returnGift
    }

    private init() {}

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        notificationLogger.notice("Requesting notification authorization", metadata: [
            "step": .string("authorization"),
            "action": .string("request"),
        ])
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            if granted {
                registerForRemoteNotifications()
            }
            notificationLogger.notice("Notification authorization finished", metadata: [
                "step": .string("authorization"),
                "result": .string(granted ? "granted" : "denied"),
            ])
            return granted
        } catch {
            notificationLogger.error("Notification authorization failed", metadata: [
                "step": .string("authorization"),
                "error": .string(error.localizedDescription),
            ])
            return false
        }
    }

    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        notificationLogger.info("Fetched notification authorization status", metadata: [
            "step": .string("authorization_status"),
            "result": .string(String(describing: settings.authorizationStatus)),
        ])
        return settings.authorizationStatus
    }

    // MARK: - APNs Remote Registration

    func registerForRemoteNotifications() {
        notificationLogger.notice("Registering for remote notifications", metadata: [
            "step": .string("apns_registration"),
        ])
        UIApplication.shared.registerForRemoteNotifications()
    }

    // MARK: - Device Token

    func saveDeviceToken(_ tokenData: Data) {
        let token = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
        settings.deviceToken = token
        notificationLogger.notice("Saved APNs device token", metadata: [
            "step": .string("device_token"),
            "result": .string("updated"),
        ])
    }

    var deviceTokenString: String? {
        settings.deviceToken
    }

    // MARK: - Notification Categories

    func registerNotificationCategories() {
        let eventCategory = UNNotificationCategory(
            identifier: Category.eventReminder.rawValue,
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        let birthdayCategory = UNNotificationCategory(
            identifier: Category.birthdayReminder.rawValue,
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        let returnGiftCategory = UNNotificationCategory(
            identifier: Category.returnGift.rawValue,
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([eventCategory, birthdayCategory, returnGiftCategory])
        notificationLogger.info("Registered notification categories", metadata: [
            "step": .string("categories"),
            "count": .stringConvertible(Category.allCases.count),
        ])
    }

    // MARK: - Event Reminders

    func scheduleEventReminder(event: Event) {
        guard settings.notificationEnabled, settings.eventReminder else {
            notificationLogger.info("Skipped event reminder", metadata: [
                "step": .string("schedule_event"),
                "event_id": .string(stableIdentifier(for: event.persistentModelID)),
                "reason": .string("notifications_disabled"),
            ])
            return
        }

        let eventDate = event.date
        guard let reminderDate = Calendar.current.date(byAdding: .day, value: -1, to: eventDate),
              reminderDate > Date()
        else {
            notificationLogger.info("Skipped event reminder", metadata: [
                "step": .string("schedule_event"),
                "event_id": .string(stableIdentifier(for: event.persistentModelID)),
                "reason": .string("reminder_date_invalid"),
            ])
            return
        }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "notification.event.title")
        content.body = String(format: String(localized: "notification.event.body"), event.name)
        content.sound = .default
        content.categoryIdentifier = Category.eventReminder.rawValue
        content.userInfo = [
            "type": Category.eventReminder.rawValue,
            "eventID": stableIdentifier(for: event.persistentModelID),
        ]

        var components = Calendar.current.dateComponents([.year, .month, .day], from: reminderDate)
        components.hour = 9
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let identifier = eventNotificationID(event)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        center.add(request)
        notificationLogger.notice("Scheduled event reminder", metadata: [
            "step": .string("schedule_event"),
            "event_id": .string(stableIdentifier(for: event.persistentModelID)),
            "result": .string("scheduled"),
        ])
    }

    func cancelEventReminder(event: Event) {
        center.removePendingNotificationRequests(withIdentifiers: [eventNotificationID(event)])
        notificationLogger.info("Cancelled event reminder", metadata: [
            "step": .string("cancel_event"),
            "event_id": .string(stableIdentifier(for: event.persistentModelID)),
        ])
    }

    func cancelRemindersForEventDeletion(event: Event) {
        cancelEventReminder(event: event)
        for record in event.records ?? [] {
            cancelReturnGiftReminder(record: record)
        }
    }

    private func eventNotificationID(_ event: Event) -> String {
        "event-\(stableIdentifier(for: event.persistentModelID))"
    }

    // MARK: - Birthday Reminders

    func scheduleBirthdayReminder(contact: Contact) {
        guard settings.notificationEnabled, settings.birthdayReminder,
              contact.birthdayReminderEnabled
        else {
            notificationLogger.info("Skipped birthday reminder", metadata: [
                "step": .string("schedule_birthday"),
                "contact_id": .string(stableIdentifier(for: contact.persistentModelID)),
                "reason": .string("notifications_disabled_or_reminder_off"),
            ])
            return
        }

        guard let birthdayDate = contact.birthday else {
            notificationLogger.info("Skipped birthday reminder", metadata: [
                "step": .string("schedule_birthday"),
                "contact_id": .string(stableIdentifier(for: contact.persistentModelID)),
                "reason": .string("no_birthday_data"),
            ])
            return
        }

        let monthDay: (month: Int, day: Int)
        if contact.birthdayIsLunar {
            guard let md = LunarCalendarHelper.lunarMonthDay(from: birthdayDate) else {
                notificationLogger.info("Skipped birthday reminder", metadata: [
                    "step": .string("schedule_birthday"),
                    "contact_id": .string(stableIdentifier(for: contact.persistentModelID)),
                    "reason": .string("lunar_date_resolution_failed"),
                ])
                return
            }
            monthDay = md
        } else {
            monthDay = LunarCalendarHelper.gregorianMonthDay(from: birthdayDate)
        }
        let month = monthDay.month
        let day = monthDay.day

        let content = UNMutableNotificationContent()
        content.title = String(localized: "notification.birthday.title")
        content.body = String(format: String(localized: "notification.birthday.body"), contact.name)
        content.sound = .default
        content.categoryIdentifier = Category.birthdayReminder.rawValue
        content.userInfo = [
            "type": Category.birthdayReminder.rawValue,
            "contactID": stableIdentifier(for: contact.persistentModelID),
        ]

        let identifier = birthdayNotificationID(contact)

        if contact.birthdayIsLunar {
            // 农历：用 Calendar.nextDate 计算下次公历日期，调度一次性通知（启动时 rescheduleAll 续约）
            guard let nextDate = LunarCalendarHelper.nextGregorianDate(lunarMonth: month, lunarDay: day) else {
                notificationLogger.info("Skipped birthday reminder", metadata: [
                    "step": .string("schedule_birthday"),
                    "contact_id": .string(stableIdentifier(for: contact.persistentModelID)),
                    "reason": .string("lunar_next_date_resolution_failed"),
                ])
                return
            }
            var components = Calendar.current.dateComponents([.year, .month, .day], from: nextDate)
            components.hour = 9
            components.minute = 0
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
        } else {
            // 公历：按月日每年重复，无需年份
            var components = DateComponents()
            components.month = month
            components.day = day
            components.hour = 9
            components.minute = 0
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
        }

        notificationLogger.notice("Scheduled birthday reminder", metadata: [
            "step": .string("schedule_birthday"),
            "contact_id": .string(stableIdentifier(for: contact.persistentModelID)),
            "isLunar": .string(contact.birthdayIsLunar ? "true" : "false"),
            "result": .string("scheduled"),
        ])
    }

    func cancelBirthdayReminder(contact: Contact) {
        center.removePendingNotificationRequests(withIdentifiers: [birthdayNotificationID(contact)])
        notificationLogger.info("Cancelled birthday reminder", metadata: [
            "step": .string("cancel_birthday"),
            "contact_id": .string(stableIdentifier(for: contact.persistentModelID)),
        ])
    }

    private func birthdayNotificationID(_ contact: Contact) -> String {
        "birthday-\(stableIdentifier(for: contact.persistentModelID))"
    }

    // MARK: - Return Gift Reminders

    func scheduleReturnGiftReminder(record: Record) {
        guard settings.notificationEnabled, settings.returnGiftReminder else {
            notificationLogger.info("Skipped return gift reminder", metadata: [
                "step": .string("schedule_return_gift"),
                "record_id": .string(stableIdentifier(for: record.persistentModelID)),
                "reason": .string("notifications_disabled"),
            ])
            return
        }
        guard record.isMonetary else { return }
        guard record.direction == .given, !record.hasReturnedGift else { return }

        guard let reminderDate = Calendar.current.date(byAdding: .day, value: 30, to: record.date),
              reminderDate > Date()
        else {
            notificationLogger.info("Skipped return gift reminder", metadata: [
                "step": .string("schedule_return_gift"),
                "record_id": .string(stableIdentifier(for: record.persistentModelID)),
                "reason": .string("reminder_date_invalid"),
            ])
            return
        }

        guard let contact = record.contact, let event = record.event else {
            notificationLogger.warning("Skipped return gift reminder", metadata: [
                "step": .string("schedule_return_gift"),
                "record_id": .string(stableIdentifier(for: record.persistentModelID)),
                "reason": .string("missing_related_entities"),
            ])
            return
        }
        let content = UNMutableNotificationContent()
        content.title = String(localized: "notification.returnGift.title")
        content.body = String(
            format: String(localized: "notification.returnGift.body"),
            contact.name,
            event.name,
            String(format: "%.0f", record.monetaryAmount)
        )

        content.sound = .default
        content.categoryIdentifier = Category.returnGift.rawValue
        content.userInfo = [
            "type": Category.returnGift.rawValue,
            "recordID": stableIdentifier(for: record.persistentModelID),
        ]

        var components = Calendar.current.dateComponents([.year, .month, .day], from: reminderDate)
        components.hour = 9
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let identifier = returnGiftNotificationID(record)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        center.add(request)
        notificationLogger.notice("Scheduled return gift reminder", metadata: [
            "step": .string("schedule_return_gift"),
            "record_id": .string(stableIdentifier(for: record.persistentModelID)),
            "result": .string("scheduled"),
        ])
    }

    func cancelReturnGiftReminder(record: Record) {
        center.removePendingNotificationRequests(withIdentifiers: [returnGiftNotificationID(record)])
        notificationLogger.info("Cancelled return gift reminder", metadata: [
            "step": .string("cancel_return_gift"),
            "record_id": .string(stableIdentifier(for: record.persistentModelID)),
        ])
    }

    private func returnGiftNotificationID(_ record: Record) -> String {
        "returnGift-\(stableIdentifier(for: record.persistentModelID))"
    }

    private func stableIdentifier(for persistentID: PersistentIdentifier) -> String {
        var hash: UInt64 = 1_469_598_103_934_665_603
        for byte in String(describing: persistentID).utf8 {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }
        return String(hash, radix: 16)
    }

    // MARK: - Cancel

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
        notificationLogger.notice("Cancelled all pending notifications", metadata: [
            "step": .string("cancel_all"),
        ])
    }

    func cancelNotifications(for category: Category) {
        Task {
            let requests = await center.pendingNotificationRequests()
            let ids = requests
                .filter { $0.content.categoryIdentifier == category.rawValue }
                .map(\.identifier)
            center.removePendingNotificationRequests(withIdentifiers: ids)
            notificationLogger.info("Cancelled notifications for category", metadata: [
                "step": .string("cancel_category"),
                "target": .string(category.rawValue),
                "count": .stringConvertible(ids.count),
            ])
        }
    }

    // MARK: - Reschedule All

    func rescheduleAll(context: ModelContext) {
        center.removeAllPendingNotificationRequests()
        notificationLogger.notice("Rescheduling notifications", metadata: [
            "step": .string("reschedule_all"),
            "result": .string("started"),
        ])

        guard settings.notificationEnabled else {
            notificationLogger.info("Skipped notification reschedule", metadata: [
                "step": .string("reschedule_all"),
                "reason": .string("notifications_disabled"),
            ])
            return
        }

        if settings.eventReminder {
            let today = Calendar.current.startOfDay(for: Date())
            let descriptor = FetchDescriptor<Event>(
                predicate: #Predicate<Event> { $0.date >= today }
            )
            if let events = try? context.fetch(descriptor) {
                for event in events {
                    scheduleEventReminder(event: event)
                }
                notificationLogger.info("Rescheduled event reminders", metadata: [
                    "step": .string("reschedule_all"),
                    "count": .stringConvertible(events.count),
                ])
            }
        }

        if settings.birthdayReminder {
            let descriptor = FetchDescriptor<Contact>(
                predicate: #Predicate<Contact> { $0.birthdayReminderEnabled == true }
            )
            if let contacts = try? context.fetch(descriptor) {
                let eligible = contacts.filter { $0.birthday != nil }
                for contact in eligible {
                    scheduleBirthdayReminder(contact: contact)
                }
                notificationLogger.info("Rescheduled birthday reminders", metadata: [
                    "step": .string("reschedule_all"),
                    "count": .stringConvertible(eligible.count),
                ])
            }
        }

        if settings.returnGiftReminder {
            let descriptor = FetchDescriptor<Record>(
                predicate: #Predicate<Record> { record in
                    record.directionRaw == "given" && record.recordTypeRaw == "monetary"
                }
            )
            if let records = try? context.fetch(descriptor) {
                for record in records where !record.hasReturnedGift {
                    scheduleReturnGiftReminder(record: record)
                }
                notificationLogger.info("Rescheduled return gift reminders", metadata: [
                    "step": .string("reschedule_all"),
                    "count": .stringConvertible(records.count),
                ])
            }
        }
    }

    // MARK: - Remote Notification Handler (Future Extension)

    func handleRemoteNotification(
        userInfo: [AnyHashable: Any],
        completion: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        notificationLogger.notice("Handled remote notification", metadata: [
            "step": .string("remote_notification"),
            "count": .stringConvertible(userInfo.count),
        ])
        // Currently: trigger local notification reschedule on silent push
        // Future: parse backend payload for specific tasks (data sync, etc.)
        completion(.noData)
    }

    // MARK: - Debug

    func sendTestNotification(category: Category) {
        let content = UNMutableNotificationContent()
        content.sound = .default
        content.categoryIdentifier = category.rawValue

        switch category {
        case .eventReminder:
            content.title = String(localized: "notification.event.title")
            content.body = String(format: String(localized: "notification.event.body"), "张三的婚礼")
        case .birthdayReminder:
            content.title = String(localized: "notification.birthday.title")
            content.body = String(format: String(localized: "notification.birthday.body"), "李四")
        case .returnGift:
            content.title = String(localized: "notification.returnGift.title")
            content.body = String(format: String(localized: "notification.returnGift.body"), "王五", "乔迁之喜", "1000")
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(
            identifier: "debug-\(category.rawValue)-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    func sendAllTestNotifications() {
        for (index, category) in Category.allCases.enumerated() {
            let content = UNMutableNotificationContent()
            content.sound = .default
            content.categoryIdentifier = category.rawValue

            switch category {
            case .eventReminder:
                content.title = String(localized: "notification.event.title")
                content.body = String(format: String(localized: "notification.event.body"), "张三的婚礼")
            case .birthdayReminder:
                content.title = String(localized: "notification.birthday.title")
                content.body = String(format: String(localized: "notification.birthday.body"), "李四")
            case .returnGift:
                content.title = String(localized: "notification.returnGift.title")
                content.body = String(format: String(localized: "notification.returnGift.body"), "王五", "乔迁之喜", "1000")
            }

            let delay = TimeInterval(2 + index * 3)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
            let request = UNNotificationRequest(
                identifier: "debug-\(category.rawValue)-\(UUID().uuidString)",
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }

    func listPendingNotifications() async -> [UNNotificationRequest] {
        await center.pendingNotificationRequests()
    }
}
