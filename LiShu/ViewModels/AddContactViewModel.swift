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
    var birthday: Date = .now
    var hasBirthday: Bool = false
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
            birthday: hasBirthday ? birthday : nil,
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
        birthday = contact.birthday ?? .now
        hasBirthday = contact.birthday != nil
        phone = contact.phone
        location = contact.location
        note = contact.note
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
            BusinessDataLogger.entityQuery(
                domain: "contact",
                screen: "contacts.form",
                operation: "update_attempt",
                searchText: "",
                filters: [:],
                sort: "",
                results: [draftPayload]
            )
            existing.name = name.trimmingCharacters(in: .whitespaces)
            existing.phone = phone.trimmingCharacters(in: .whitespaces)
            existing.avatar = avatar
            existing.relation = selectedTag
            existing.category = selectedCategory?.rawValue ?? ""
            existing.circle = circle
            existing.birthday = hasBirthday ? birthday : nil
            existing.location = location.trimmingCharacters(in: .whitespacesAndNewlines)
            existing.note = note.trimmingCharacters(in: .whitespaces)

            do {
                try context.save()
                NotificationManager.shared.cancelBirthdayReminder(contact: existing)
                if hasBirthday {
                    NotificationManager.shared.scheduleBirthdayReminder(contact: existing)
                }
                BusinessDataLogger.entityQuery(
                    domain: "contact",
                    screen: "contacts.form",
                    operation: "update",
                    searchText: "",
                    filters: [:],
                    sort: "",
                    results: [existing.logPayload()]
                )
                contactsViewModelLogger.notice("Saved contact", metadata: [
                    "step": .string("save"),
                    "contact_id": .string(String(describing: existing.persistentModelID)),
                    "result": .string("updated"),
                ])
                return true
            } catch {
                BusinessDataLogger.entityQuery(
                    domain: "contact",
                    screen: "contacts.form",
                    operation: "update_failed",
                    searchText: "",
                    filters: [:],
                    sort: "",
                    results: [draftPayload],
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
            BusinessDataLogger.entityQuery(
                domain: "contact",
                screen: "contacts.form",
                operation: "create_attempt",
                searchText: "",
                filters: [:],
                sort: "",
                results: [draftPayload]
            )
            let contact = Contact(
                name: name.trimmingCharacters(in: .whitespaces),
                phone: phone.trimmingCharacters(in: .whitespaces),
                avatar: avatar,
                relation: selectedTag,
                category: selectedCategory?.rawValue ?? "",
                circle: circle,
                birthday: hasBirthday ? birthday : nil,
                location: location.trimmingCharacters(in: .whitespacesAndNewlines),
                note: note.trimmingCharacters(in: .whitespaces)
            )

            context.insert(contact)

            do {
                try context.save()
                if hasBirthday {
                    NotificationManager.shared.scheduleBirthdayReminder(contact: contact)
                }
                BusinessDataLogger.entityQuery(
                    domain: "contact",
                    screen: "contacts.form",
                    operation: "create",
                    searchText: "",
                    filters: [:],
                    sort: "",
                    results: [contact.logPayload()]
                )
                contactsViewModelLogger.notice("Saved contact", metadata: [
                    "step": .string("save"),
                    "contact_id": .string(String(describing: contact.persistentModelID)),
                    "result": .string("created"),
                ])
                return true
            } catch {
                BusinessDataLogger.entityQuery(
                    domain: "contact",
                    screen: "contacts.form",
                    operation: "create_failed",
                    searchText: "",
                    filters: [:],
                    sort: "",
                    results: [draftPayload],
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
