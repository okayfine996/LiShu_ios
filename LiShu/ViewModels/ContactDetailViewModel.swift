import Foundation
import SwiftData

@Observable
class ContactDetailViewModel {
    var contact: Contact?
    var isLoading: Bool = true
    var isShowingDeleteAlert: Bool = false

    /// Sorted records for the contact, newest first
    var sortedRecords: [Record] {
        guard let contact else { return [] }
        return (contact.records ?? []).sorted { $0.date > $1.date }
    }

    /// Load the contact by its persistent identifier
    func load(id: PersistentIdentifier, context: ModelContext) {
        isLoading = true
        contact = context.model(for: id) as? Contact
        isLoading = false
    }

    /// Reload the contact data (e.g. after adding a record or editing)
    func reload(context: ModelContext) {
        guard let contact else { return }
        self.contact = context.model(for: contact.persistentModelID) as? Contact
    }

    /// Delete the current contact. Returns true if successful.
    func deleteContact(context: ModelContext) -> Bool {
        guard let contact else { return false }
        NotificationManager.shared.cancelBirthdayReminder(contact: contact)
        context.delete(contact)
        do {
            try context.save()
            return true
        } catch {
            return false
        }
    }

    // MARK: - Formatted Values

    func formatAmount(_ amount: Double) -> String {
        "¥" + String(format: "%.0f", amount)
    }

    func formatNetValue(_ value: Double) -> String {
        let prefix = value >= 0 ? "+" : ""
        return prefix + "¥" + String(format: "%.0f", value)
    }

    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy'年'M'月'd'日'"
        return formatter.string(from: date)
    }

    func circleText(_ level: Int) -> String {
        switch level {
        case 1: return String(localized: "contact.filter.family")
        case 2: return String(localized: "contact.filter.relative")
        case 3: return String(localized: "contact.filter.social")
        default: return String(localized: "contact.filter.other")
        }
    }
}
