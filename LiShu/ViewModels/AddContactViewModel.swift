import Foundation
import SwiftData

@Observable
class AddContactViewModel {
    var editingContact: Contact?
    var avatar: Data?
    var name: String = ""
    var selectedCategory: RelationshipCategory? = nil
    var selectedTag: String = ""
    var birthday: Date = .now
    var hasBirthday: Bool = false
    var phone: String = ""
    var note: String = ""
    var isFestivalReminderRecipient: Bool = false
    var showValidationAlert: Bool = false
    var needsProUpgrade: Bool = false

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func configure(with contact: Contact) {
        editingContact = contact
        avatar = contact.avatar
        name = contact.name
        selectedCategory = RelationshipCategory(rawValue: contact.category)
        selectedTag = contact.relation
        birthday = contact.birthday ?? .now
        hasBirthday = contact.birthday != nil
        phone = contact.phone
        note = contact.note
        isFestivalReminderRecipient = contact.isFestivalReminderRecipient
    }

    func saveContact(context: ModelContext) -> Bool {
        guard isValid else {
            showValidationAlert = true
            return false
        }

        let circle = selectedCategory?.circle ?? 4

        if editingContact == nil, !SubscriptionManager.shared.canAddContact(context: context) {
            needsProUpgrade = true
            return false
        }

        if let existing = editingContact {
            existing.name = name.trimmingCharacters(in: .whitespaces)
            existing.phone = phone.trimmingCharacters(in: .whitespaces)
            existing.avatar = avatar
            existing.relation = selectedTag
            existing.category = selectedCategory?.rawValue ?? ""
            existing.circle = circle
            existing.birthday = hasBirthday ? birthday : nil
            existing.note = note.trimmingCharacters(in: .whitespaces)
            existing.isFestivalReminderRecipient = isFestivalReminderRecipient

            do {
                try context.save()
                NotificationManager.shared.cancelBirthdayReminder(contact: existing)
                if hasBirthday {
                    NotificationManager.shared.scheduleBirthdayReminder(contact: existing)
                }
                return true
            } catch {
                return false
            }
        } else {
            let contact = Contact(
                name: name.trimmingCharacters(in: .whitespaces),
                phone: phone.trimmingCharacters(in: .whitespaces),
                avatar: avatar,
                relation: selectedTag,
                category: selectedCategory?.rawValue ?? "",
                circle: circle,
                birthday: hasBirthday ? birthday : nil,
                note: note.trimmingCharacters(in: .whitespaces),
                isFestivalReminderRecipient: isFestivalReminderRecipient
            )

            context.insert(contact)

            do {
                try context.save()
                if hasBirthday {
                    NotificationManager.shared.scheduleBirthdayReminder(contact: contact)
                }
                return true
            } catch {
                return false
            }
        }
    }
}
