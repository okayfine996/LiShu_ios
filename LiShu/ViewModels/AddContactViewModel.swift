import Foundation
import Logging
import SwiftData

private let contactsViewModelLogger = PulseDiagnostics.makeLogger(label: AppLogLabel.contactsViewModel)

@Observable
class AddContactViewModel {
    var editingContact: Contact?
    var avatar: Data?
    var name: String = ""
    var selectedCategory: RelationshipCategory?
    var selectedTag: String = ""
    /// 生日月份（1–12），仅在 hasBirthday == true 时有效
    var birthdayMonth: Int = 1
    /// 生日日（1–31 公历，1–30 农历），仅在 hasBirthday == true 时有效
    var birthdayDay: Int = 1
    var hasBirthday: Bool = true
    var birthdayIsLunar: Bool = false
    var birthdayReminderEnabled: Bool = false
    var phone: String = ""
    var location: String = ""
    var note: String = ""
    var showValidationAlert: Bool = false
    var needsProUpgrade: Bool = false

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var draftPayload: ContactLogPayload {
        ContactLogPayload(
            id: editingContact.map { String(describing: $0.persistentModelID) } ?? "pending",
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            phone: phone.trimmingCharacters(in: .whitespacesAndNewlines),
            relation: selectedTag,
            category: selectedCategory?.rawValue ?? "",
            circle: selectedCategory?.circle ?? 4,
            birthday: nil,
            location: location.trimmingCharacters(in: .whitespacesAndNewlines),
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            avatarPresent: avatar != nil,
            recordCount: editingContact?.records?.count ?? 0,
            createdAt: editingContact?.createdAt ?? .now
        )
    }

    func configure(with contact: Contact) {
        contactsViewModelLogger.info("Configured contact editor", metadata: [
            "step": .string("configure"),
            "contact_id": .string(String(describing: contact.persistentModelID)),
        ])
        editingContact = contact
        avatar = contact.avatar
        name = contact.name
        selectedCategory = RelationshipCategory(rawValue: contact.category)
        selectedTag = contact.relation
        birthdayIsLunar = contact.birthdayIsLunar
        birthdayReminderEnabled = contact.birthdayReminderEnabled
        phone = contact.phone
        location = contact.location
        note = contact.note

        if contact.birthdayMonth > 0 {
            // 新数据：直接读取月日
            birthdayMonth = contact.birthdayMonth
            birthdayDay = contact.birthdayDay
            hasBirthday = true
        } else if let legacyDate = contact.birthday {
            // 旧数据迁移：从 Date 提取月日
            if contact.birthdayIsLunar {
                if let md = LunarCalendarHelper.lunarMonthDay(from: legacyDate) {
                    birthdayMonth = md.month
                    birthdayDay = md.day
                } else {
                    hasBirthday = false
                    return
                }
            } else {
                let md = LunarCalendarHelper.gregorianMonthDay(from: legacyDate)
                birthdayMonth = md.month
                birthdayDay = md.day
            }
            hasBirthday = true
        } else {
            birthdayMonth = 1
            birthdayDay = 1
            hasBirthday = false
        }
    }

    @MainActor
    func saveContact(context: ModelContext) -> Bool {
        guard isValid else {
            showValidationAlert = true
            contactsViewModelLogger.warning("Rejected contact save", metadata: [
                "step": .string("save"),
                "reason": .string("validation_failed"),
            ])
            return false
        }

        let circle = selectedCategory?.circle ?? 4

        if editingContact == nil, !SubscriptionManager.shared.canAddContact(context: context) {
            needsProUpgrade = true
            contactsViewModelLogger.warning("Rejected contact save", metadata: [
                "step": .string("save"),
                "reason": .string("subscription_limit"),
            ])
            return false
        }

        if let existing = editingContact {
            BusinessDataLogger.entityMutation(
                domain: "contact",
                screen: "contacts.form",
                operation: "update_attempt",
                payload: draftPayload,
                results: [draftPayload]
            )
            existing.name = name.trimmingCharacters(in: .whitespaces)
            existing.phone = phone.trimmingCharacters(in: .whitespaces)
            existing.avatar = avatar.flatMap {
                ImagePipeline.optimizedJPEGData(
                    from: $0,
                    maxPixelSize: ImagePipeline.Preset.avatarMaxPixelSize,
                    compressionQuality: 0.82
                ) ?? $0
            }
            existing.relation = selectedTag
            existing.category = selectedCategory?.rawValue ?? ""
            existing.circle = circle
            existing.birthdayMonth = hasBirthday ? birthdayMonth : 0
            existing.birthdayDay = hasBirthday ? birthdayDay : 0
            existing.birthday = nil // 新数据不再使用旧字段
            existing.birthdayIsLunar = hasBirthday ? birthdayIsLunar : false
            existing.birthdayReminderEnabled = hasBirthday && birthdayReminderEnabled
            existing.location = location.trimmingCharacters(in: .whitespacesAndNewlines)
            existing.note = note.trimmingCharacters(in: .whitespaces)

            do {
                try context.save()
                NotificationManager.shared.cancelBirthdayReminder(contact: existing)
                if hasBirthday, birthdayReminderEnabled {
                    NotificationManager.shared.scheduleBirthdayReminder(contact: existing)
                }
                BusinessDataLogger.entityMutation(
                    domain: "contact",
                    screen: "contacts.form",
                    operation: "update",
                    payload: draftPayload,
                    results: [existing.logPayload()]
                )
                contactsViewModelLogger.notice("Saved contact", metadata: [
                    "step": .string("save"),
                    "contact_id": .string(String(describing: existing.persistentModelID)),
                    "result": .string("updated"),
                ])
                return true
            } catch {
                BusinessDataLogger.entityMutation(
                    domain: "contact",
                    screen: "contacts.form",
                    operation: "update_failed",
                    payload: draftPayload,
                    error: error.localizedDescription
                )
                contactsViewModelLogger.error("Failed to save contact", metadata: [
                    "step": .string("save"),
                    "result": .string("updated"),
                    "error": .string(error.localizedDescription),
                ])
                return false
            }
        } else {
            BusinessDataLogger.entityMutation(
                domain: "contact",
                screen: "contacts.form",
                operation: "create_attempt",
                payload: draftPayload,
                results: [draftPayload]
            )
            let contact = Contact(
                name: name.trimmingCharacters(in: .whitespaces),
                phone: phone.trimmingCharacters(in: .whitespaces),
                avatar: avatar.flatMap {
                    ImagePipeline.optimizedJPEGData(
                        from: $0,
                        maxPixelSize: ImagePipeline.Preset.avatarMaxPixelSize,
                        compressionQuality: 0.82
                    ) ?? $0
                },
                relation: selectedTag,
                category: selectedCategory?.rawValue ?? "",
                circle: circle,
                birthdayMonth: hasBirthday ? birthdayMonth : 0,
                birthdayDay: hasBirthday ? birthdayDay : 0,
                birthdayIsLunar: hasBirthday ? birthdayIsLunar : false,
                birthdayReminderEnabled: hasBirthday && birthdayReminderEnabled,
                location: location.trimmingCharacters(in: .whitespacesAndNewlines),
                note: note.trimmingCharacters(in: .whitespaces)
            )

            context.insert(contact)

            do {
                try context.save()
                if hasBirthday, birthdayReminderEnabled {
                    NotificationManager.shared.scheduleBirthdayReminder(contact: contact)
                }
                BusinessDataLogger.entityMutation(
                    domain: "contact",
                    screen: "contacts.form",
                    operation: "create",
                    payload: draftPayload,
                    results: [contact.logPayload()]
                )
                contactsViewModelLogger.notice("Saved contact", metadata: [
                    "step": .string("save"),
                    "contact_id": .string(String(describing: contact.persistentModelID)),
                    "result": .string("created"),
                ])
                return true
            } catch {
                BusinessDataLogger.entityMutation(
                    domain: "contact",
                    screen: "contacts.form",
                    operation: "create_failed",
                    payload: draftPayload,
                    error: error.localizedDescription
                )
                contactsViewModelLogger.error("Failed to save contact", metadata: [
                    "step": .string("save"),
                    "result": .string("created"),
                    "error": .string(error.localizedDescription),
                ])
                return false
            }
        }
    }
}
