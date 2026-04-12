import Foundation
import Logging
import SwiftData

private let eventsViewModelLogger = PulseDiagnostics.makeLogger(label: AppLogLabel.eventsViewModel)

@Observable
class AddEventViewModel {
    var editingEvent: Event?
    var name: String = ""
    var eventType: EventType = .wedding
    var hostMode: EventHostMode = .guest
    var date: Date = .now
    var location: String = ""
    var note: String = ""
    var coverImageData: Data?

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var draftPayload: EventLogPayload {
        EventLogPayload(
            id: editingEvent.map { String(describing: $0.persistentModelID) } ?? "pending",
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            type: eventType.rawValue,
            date: date,
            location: location.trimmingCharacters(in: .whitespacesAndNewlines),
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            coverImagePresent: coverImageData != nil,
            recordCount: editingEvent?.records?.count ?? 0,
            createdAt: editingEvent?.createdAt ?? .now
        )
    }

    func configure(with event: Event) {
        eventsViewModelLogger.info("Configured event editor", metadata: [
            "step": .string("configure"),
            "event_id": .string(String(describing: event.persistentModelID)),
        ])
        editingEvent = event
        name = event.name
        eventType = event.type
        hostMode = event.hostMode
        date = event.date
        location = event.location
        note = event.note
        coverImageData = event.coverImage
    }

    @MainActor
    func save(context: ModelContext) -> Bool {
        guard isValid else {
            eventsViewModelLogger.warning("Rejected event save", metadata: [
                "step": .string("save"),
                "reason": .string("validation_failed"),
            ])
            return false
        }

        if let existing = editingEvent {
            BusinessDataLogger.entityMutation(
                domain: "event",
                screen: "events.form",
                operation: "update_attempt",
                payload: draftPayload,
                results: [draftPayload]
            )
            existing.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            existing.type = eventType
            existing.hostMode = hostMode
            existing.date = date
            existing.location = location.trimmingCharacters(in: .whitespacesAndNewlines)
            existing.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
            existing.coverImage = coverImageData.flatMap {
                ImagePipeline.optimizedJPEGData(
                    from: $0,
                    maxPixelSize: ImagePipeline.Preset.eventCoverMaxPixelSize,
                    compressionQuality: 0.84
                ) ?? $0
            }

            do {
                try context.save()
                NotificationManager.shared.cancelEventReminder(event: existing)
                NotificationManager.shared.scheduleEventReminder(event: existing)
                BusinessDataLogger.entityMutation(
                    domain: "event",
                    screen: "events.form",
                    operation: "update",
                    payload: draftPayload,
                    results: [existing.logPayload()]
                )
                eventsViewModelLogger.notice("Saved event", metadata: [
                    "step": .string("save"),
                    "event_id": .string(String(describing: existing.persistentModelID)),
                    "result": .string("updated"),
                ])
                return true
            } catch {
                BusinessDataLogger.entityMutation(
                    domain: "event",
                    screen: "events.form",
                    operation: "update_failed",
                    payload: draftPayload,
                    error: error.localizedDescription
                )
                eventsViewModelLogger.error("Failed to save event", metadata: [
                    "step": .string("save"),
                    "result": .string("updated"),
                    "error": .string(error.localizedDescription),
                ])
                return false
            }
        } else {
            BusinessDataLogger.entityMutation(
                domain: "event",
                screen: "events.form",
                operation: "create_attempt",
                payload: draftPayload,
                results: [draftPayload]
            )
            let event = Event(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                type: eventType,
                hostMode: hostMode,
                date: date,
                location: location.trimmingCharacters(in: .whitespacesAndNewlines),
                note: note.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            event.coverImage = coverImageData.flatMap {
                ImagePipeline.optimizedJPEGData(
                    from: $0,
                    maxPixelSize: ImagePipeline.Preset.eventCoverMaxPixelSize,
                    compressionQuality: 0.84
                ) ?? $0
            }
            context.insert(event)

            do {
                try context.save()
                NotificationManager.shared.scheduleEventReminder(event: event)
                BusinessDataLogger.entityMutation(
                    domain: "event",
                    screen: "events.form",
                    operation: "create",
                    payload: draftPayload,
                    results: [event.logPayload()]
                )
                eventsViewModelLogger.notice("Saved event", metadata: [
                    "step": .string("save"),
                    "event_id": .string(String(describing: event.persistentModelID)),
                    "result": .string("created"),
                ])
                return true
            } catch {
                BusinessDataLogger.entityMutation(
                    domain: "event",
                    screen: "events.form",
                    operation: "create_failed",
                    payload: draftPayload,
                    error: error.localizedDescription
                )
                eventsViewModelLogger.error("Failed to save event", metadata: [
                    "step": .string("save"),
                    "result": .string("created"),
                    "error": .string(error.localizedDescription),
                ])
                return false
            }
        }
    }
}
