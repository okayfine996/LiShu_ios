import Foundation
import SwiftData

@Observable
class AddRecordViewModel {
    var editingRecord: Record?
    var direction: RecordDirection = .given
    var selectedContact: Contact?
    var selectedEvent: Event?
    var amountText: String = ""
    var paymentMethod: PaymentMethod = .cash
    var date: Date = .now
    var note: String = ""
    var contactSearchText: String = ""
    var isShowingContactPicker: Bool = false
    var eventSearchText: String = ""
    var isShowingEventPicker: Bool = false
    /// Pending photo data from PhotosPicker, converted to RecordPhoto on save
    var newPhotoData: [Data] = []

    var isCreatingNewContact: Bool = false
    var newContactName: String = ""

    var isCreatingNewEvent: Bool = false
    var newEventName: String = ""
    var newEventType: EventType = .other

    var allContacts: [Contact] = []
    var allEvents: [Event] = []

    var filteredContacts: [Contact] {
        if contactSearchText.isEmpty {
            return allContacts
        }
        return allContacts.filter { $0.name.localizedCaseInsensitiveContains(contactSearchText) }
    }

    var filteredEvents: [Event] {
        if eventSearchText.isEmpty {
            return allEvents
        }
        return allEvents.filter { $0.name.localizedCaseInsensitiveContains(eventSearchText) }
    }

    var amount: Double {
        Double(amountText) ?? 0
    }

    var isValid: Bool {
        let hasContact = selectedContact != nil || (isCreatingNewContact && !newContactName.trimmingCharacters(in: .whitespaces).isEmpty)
        let hasEvent = selectedEvent != nil || (isCreatingNewEvent && !newEventName.trimmingCharacters(in: .whitespaces).isEmpty)
        return hasContact && hasEvent && amount > 0
    }

    var directionLabel: String {
        direction == .given
            ? String(localized: "record.add.sendTo")
            : String(localized: "record.add.receiveFrom")
    }

    var confirmButtonTitle: String {
        direction == .given
            ? String(localized: "record.add.confirmGiven")
            : String(localized: "record.add.confirmReceived")
    }

    var navigationTitle: String {
        direction == .given
            ? String(localized: "record.add.titleGiven")
            : String(localized: "record.add.titleReceived")
    }

    func loadData(context: ModelContext) {
        do {
            let contactDescriptor = FetchDescriptor<Contact>(
                sortBy: [SortDescriptor(\.name)]
            )
            allContacts = try context.fetch(contactDescriptor)

            let eventDescriptor = FetchDescriptor<Event>(
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            allEvents = try context.fetch(eventDescriptor)
        } catch {
            allContacts = []
            allEvents = []
        }
    }

    func configure(direction: RecordDirection?, contactID: PersistentIdentifier?, context: ModelContext) {
        if let dir = direction {
            self.direction = dir
        }
        if let cID = contactID {
            self.selectedContact = context.model(for: cID) as? Contact
        }
    }

    func configure(with record: Record) {
        editingRecord = record
        direction = record.direction
        selectedContact = record.contact
        selectedEvent = record.event  // may be nil for CloudKit-synced orphan records
        amountText = record.amount == Double(Int(record.amount)) ? String(Int(record.amount)) : String(record.amount)
        paymentMethod = record.paymentMethod
        date = record.date
        note = record.note
    }

    private func resolveContact(context: ModelContext) -> Contact? {
        if let contact = selectedContact {
            return contact
        }
        if isCreatingNewContact {
            let trimmed = newContactName.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { return nil }
            let contact = Contact(name: trimmed)
            context.insert(contact)
            return contact
        }
        return nil
    }

    private func resolveEvent(context: ModelContext) -> Event? {
        if let event = selectedEvent {
            return event
        }
        if isCreatingNewEvent {
            let trimmed = newEventName.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { return nil }
            let event = Event(name: trimmed, type: newEventType)
            context.insert(event)
            return event
        }
        return nil
    }

    func save(context: ModelContext) -> Bool {
        guard isValid,
              let contact = resolveContact(context: context),
              let event = resolveEvent(context: context) else { return false }

        if let existing = editingRecord {
            existing.contact = contact
            existing.event = event
            existing.amount = amount
            existing.direction = direction
            existing.paymentMethod = paymentMethod
            existing.note = note
            existing.date = date
            existing.updateStatus()

            for data in newPhotoData {
                let photo = RecordPhoto(record: existing, imageData: data)
                context.insert(photo)
            }
            newPhotoData = []

            do {
                try context.save()
                NotificationManager.shared.cancelReturnGiftReminder(record: existing)
                if existing.direction == .given, existing.status != .settled {
                    NotificationManager.shared.scheduleReturnGiftReminder(record: existing)
                }
                return true
            } catch {
                return false
            }
        } else {
            let record = Record(
                contact: contact,
                event: event,
                amount: amount,
                direction: direction,
                paymentMethod: paymentMethod,
                note: note,
                date: date
            )

            context.insert(record)

            for data in newPhotoData {
                let photo = RecordPhoto(record: record, imageData: data)
                context.insert(photo)
            }
            newPhotoData = []

            do {
                try context.save()
                if record.direction == .given, record.status != .settled {
                    NotificationManager.shared.scheduleReturnGiftReminder(record: record)
                }
                return true
            } catch {
                return false
            }
        }
    }
}
