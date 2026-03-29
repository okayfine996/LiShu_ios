import Foundation
import SwiftData
import UserNotifications
import UIKit

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()
    private var settings: AppSettings { AppSettings.shared }

    enum Category: String, CaseIterable {
        case eventReminder
        case birthdayReminder
        case returnGift
        case festivalReminder
    }

    private init() {}

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            if granted {
                registerForRemoteNotifications()
            }
            return granted
        } catch {
            return false
        }
    }

    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - APNs Remote Registration

    func registerForRemoteNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
    }

    // MARK: - Device Token

    func saveDeviceToken(_ tokenData: Data) {
        let token = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
        settings.deviceToken = token
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
        let festivalCategory = UNNotificationCategory(
            identifier: Category.festivalReminder.rawValue,
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([eventCategory, birthdayCategory, returnGiftCategory, festivalCategory])
    }

    // MARK: - Event Reminders

    func scheduleEventReminder(event: Event) {
        guard settings.notificationEnabled, settings.eventReminder else { return }

        let eventDate = event.date
        guard let reminderDate = Calendar.current.date(byAdding: .day, value: -1, to: eventDate),
              reminderDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "notification.event.title")
        content.body = String(format: String(localized: "notification.event.body"), event.name)
        content.sound = .default
        content.categoryIdentifier = Category.eventReminder.rawValue
        content.userInfo = [
            "type": Category.eventReminder.rawValue,
            "eventID": stableIdentifier(for: event.persistentModelID)
        ]

        var components = Calendar.current.dateComponents([.year, .month, .day], from: reminderDate)
        components.hour = 9
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let identifier = eventNotificationID(event)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        center.add(request)
    }

    func cancelEventReminder(event: Event) {
        center.removePendingNotificationRequests(withIdentifiers: [eventNotificationID(event)])
    }

    private func eventNotificationID(_ event: Event) -> String {
        "event-\(stableIdentifier(for: event.persistentModelID))"
    }

    // MARK: - Birthday Reminders

    func scheduleBirthdayReminder(contact: Contact) {
        guard settings.notificationEnabled, settings.birthdayReminder,
              let birthday = contact.birthday else { return }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "notification.birthday.title")
        content.body = String(format: String(localized: "notification.birthday.body"), contact.name)
        content.sound = .default
        content.categoryIdentifier = Category.birthdayReminder.rawValue
        content.userInfo = [
            "type": Category.birthdayReminder.rawValue,
            "contactID": stableIdentifier(for: contact.persistentModelID)
        ]

        var components = Calendar.current.dateComponents([.month, .day], from: birthday)
        components.hour = 9
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let identifier = birthdayNotificationID(contact)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        center.add(request)
    }

    func cancelBirthdayReminder(contact: Contact) {
        center.removePendingNotificationRequests(withIdentifiers: [birthdayNotificationID(contact)])
    }

    private func birthdayNotificationID(_ contact: Contact) -> String {
        "birthday-\(stableIdentifier(for: contact.persistentModelID))"
    }

    // MARK: - Return Gift Reminders

    func scheduleReturnGiftReminder(record: Record) {
        guard settings.notificationEnabled, settings.returnGiftReminder else { return }
        guard record.direction == .given, record.status != .settled else { return }

        guard let reminderDate = Calendar.current.date(byAdding: .day, value: 30, to: record.date),
              reminderDate > Date() else { return }

        guard let contact = record.contact, let event = record.event else { return }
        let content = UNMutableNotificationContent()
        content.title = String(localized: "notification.returnGift.title")
        content.body = String(
            format: String(localized: "notification.returnGift.body"),
            contact.name,
            event.name,
            String(format: "%.0f", record.amount)
        )

        content.sound = .default
        content.categoryIdentifier = Category.returnGift.rawValue
        content.userInfo = [
            "type": Category.returnGift.rawValue,
            "recordID": stableIdentifier(for: record.persistentModelID)
        ]

        var components = Calendar.current.dateComponents([.year, .month, .day], from: reminderDate)
        components.hour = 9
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let identifier = returnGiftNotificationID(record)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        center.add(request)
    }

    func cancelReturnGiftReminder(record: Record) {
        center.removePendingNotificationRequests(withIdentifiers: [returnGiftNotificationID(record)])
    }

    private func returnGiftNotificationID(_ record: Record) -> String {
        "returnGift-\(stableIdentifier(for: record.persistentModelID))"
    }

    // MARK: - Festival Reminders

    func scheduleFestivalReminders(context: ModelContext, now: @escaping () -> Date = Date.init) {
        guard settings.notificationEnabled, settings.eventReminder else { return }

        let descriptor = FetchDescriptor<Contact>()
        guard let contacts = try? context.fetch(descriptor) else { return }

        let calendarService = FestivalCalendarService(now: now)
        let reminderService = FestivalReminderService(calendarService: calendarService, now: now)
        let payloads = reminderService.makeReminderPayloads(contacts: contacts)

        for payload in payloads {
            guard let request = makeFestivalReminderRequest(payload: payload, now: now) else { continue }
            center.add(request)
        }
    }

    func makeFestivalReminderRequest(
        payload: FestivalReminderPayload,
        now: @escaping () -> Date = Date.init
    ) -> UNNotificationRequest? {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: payload.reminderDate)
        components.hour = 9
        components.minute = 0

        guard let scheduledDate = calendar.date(from: components),
              scheduledDate > now() else {
            return nil
        }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "notification.festival.title")
        content.body = payload.bodyText
        content.sound = .default
        content.categoryIdentifier = Category.festivalReminder.rawValue
        content.userInfo = [
            "type": Category.festivalReminder.rawValue,
            "festivalID": payload.festivalID,
            "occurrenceDate": festivalDateIdentifier(from: payload.occurrenceDate)
        ]

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let identifier = festivalNotificationID(payload: payload)
        return UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    }

    func festivalNotificationID(payload: FestivalReminderPayload) -> String {
        "festival-\(payload.festivalID)-\(festivalDateIdentifier(from: payload.occurrenceDate))"
    }

    private func festivalDateIdentifier(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: date)
    }

    private func stableIdentifier(for persistentID: PersistentIdentifier) -> String {
        var hash: UInt64 = 1469598103934665603
        for byte in String(describing: persistentID).utf8 {
            hash ^= UInt64(byte)
            hash &*= 1099511628211
        }
        return String(hash, radix: 16)
    }

    // MARK: - Cancel

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }

    func cancelNotifications(for category: Category) {
        Task {
            let requests = await center.pendingNotificationRequests()
            let ids = requests
                .filter { $0.content.categoryIdentifier == category.rawValue }
                .map(\.identifier)
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    // MARK: - Reschedule All

    func rescheduleAll(context: ModelContext) {
        center.removeAllPendingNotificationRequests()

        guard settings.notificationEnabled else { return }

        if settings.eventReminder {
            let today = Calendar.current.startOfDay(for: Date())
            let descriptor = FetchDescriptor<Event>(
                predicate: #Predicate<Event> { $0.date >= today }
            )
            if let events = try? context.fetch(descriptor) {
                for event in events {
                    scheduleEventReminder(event: event)
                }
            }
            scheduleFestivalReminders(context: context)
        }

        if settings.birthdayReminder {
            let descriptor = FetchDescriptor<Contact>(
                predicate: #Predicate<Contact> { $0.birthday != nil }
            )
            if let contacts = try? context.fetch(descriptor) {
                for contact in contacts {
                    scheduleBirthdayReminder(contact: contact)
                }
            }
        }

        if settings.returnGiftReminder {
            let descriptor = FetchDescriptor<Record>(
                predicate: #Predicate<Record> { record in
                    record.directionRaw == "given" && record.statusRaw != "settled"
                }
            )
            if let records = try? context.fetch(descriptor) {
                for record in records {
                    scheduleReturnGiftReminder(record: record)
                }
            }
        }
    }

    // MARK: - Remote Notification Handler (Future Extension)

    func handleRemoteNotification(
        userInfo: [AnyHashable: Any],
        completion: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        // Currently: trigger local notification reschedule on silent push
        // Future: parse backend payload for specific tasks (data sync, etc.)
        completion(.noData)
    }

    // MARK: - Debug

    #if DEBUG
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
        case .festivalReminder:
            content.title = String(localized: "notification.festival.title")
            content.body = String(format: String(localized: "notification.festival.body.contacts"), "中秋节", "张三、李四、王五等 2 人")
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
            case .festivalReminder:
                content.title = String(localized: "notification.festival.title")
                content.body = String(format: String(localized: "notification.festival.body.contacts"), "中秋节", "张三、李四、王五等 2 人")
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
    #endif
}
