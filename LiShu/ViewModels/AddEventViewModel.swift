import Foundation
import SwiftData

@Observable
class AddEventViewModel {
    var editingEvent: Event?
    var name: String = ""
    var eventType: EventType = .wedding
    var date: Date = .now
    var location: String = ""
    var note: String = ""
    var coverImageData: Data?
    private(set) var hasAppliedPrefill = false

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func configure(with event: Event) {
        editingEvent = event
        name = event.name
        eventType = event.type
        date = event.date
        location = event.location
        note = event.note
        coverImageData = event.coverImage
    }

    func apply(prefill: FestivalEventPrefill) {
        guard editingEvent == nil, !hasAppliedPrefill else { return }
        name = prefill.name
        eventType = prefill.eventType
        date = prefill.date
        hasAppliedPrefill = true
    }

    func save(context: ModelContext) -> Bool {
        guard isValid else { return false }

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
                return true
            } catch {
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
                return true
            } catch {
                return false
            }
        }
    }
}
