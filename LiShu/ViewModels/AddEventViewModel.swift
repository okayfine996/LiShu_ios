import Foundation
import Logging
import SwiftData

private nonisolated(unsafe) var eventsViewModelLogger: Logger { PulseDiagnostics.makeLogger(label: AppLogLabel.eventsViewModel) }

@Observable
class AddEventViewModel {
    var editingEvent: Event?
    var name: String = ""
    var eventType: EventType = .wedding
    var date: Date = .now
    var location: String = ""
    var note: String = ""
    var coverImageData: Data?

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func configure(with event: Event) {
        eventsViewModelLogger.info("Configured event editor", metadata: [
            "step": .string("configure"),
            "event_id": .string(String(describing: event.persistentModelID))
        ])
        editingEvent = event
        name = event.name
        eventType = event.type
        date = event.date
        location = event.location
        note = event.note
        coverImageData = event.coverImage
    }

    func save(context: ModelContext) -> Bool {
        guard isValid else {
            eventsViewModelLogger.warning("Rejected event save", metadata: [
                "step": .string("save"),
                "reason": .string("validation_failed")
            ])
            return false
        }

        if let existing = editingEvent {
            existing.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            existing.type = eventType
            existing.date = date
            existing.location = location.trimmingCharacters(in: .whitespacesAndNewlines)
            existing.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
            existing.coverImage = coverImageData

            do {
                try context.save()
                NotificationManager.shared.cancelEventReminder(event: existing)
                NotificationManager.shared.scheduleEventReminder(event: existing)
                eventsViewModelLogger.notice("Saved event", metadata: [
                    "step": .string("save"),
                    "event_id": .string(String(describing: existing.persistentModelID)),
                    "result": .string("updated")
                ])
                return true
            } catch {
                eventsViewModelLogger.error("Failed to save event", metadata: [
                    "step": .string("save"),
                    "result": .string("updated"),
                    "error": .string(error.localizedDescription)
                ])
                return false
            }
        } else {
            let event = Event(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                type: eventType,
                date: date,
                location: location.trimmingCharacters(in: .whitespacesAndNewlines),
                note: note.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            event.coverImage = coverImageData
            context.insert(event)

            do {
                try context.save()
                NotificationManager.shared.scheduleEventReminder(event: event)
                eventsViewModelLogger.notice("Saved event", metadata: [
                    "step": .string("save"),
                    "event_id": .string(String(describing: event.persistentModelID)),
                    "result": .string("created")
                ])
                return true
            } catch {
                eventsViewModelLogger.error("Failed to save event", metadata: [
                    "step": .string("save"),
                    "result": .string("created"),
                    "error": .string(error.localizedDescription)
                ])
                return false
            }
        }
    }
}
