import Foundation
import Logging
import SwiftData

private nonisolated(unsafe) var eventListLogger: Logger { PulseDiagnostics.makeLogger(label: AppLogLabel.eventsViewModel) }

@Observable
class EventListViewModel {
    var state: LoadingState<[Event]> = .idle
    var selectedTypeFilter: EventType?
    var searchText: String = ""
    var deleteError: String?

    private var searchedEvents: [Event] {
        guard let events = state.value else { return [] }
        let trimmed = searchText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return events }
        return events.filter {
            $0.name.localizedCaseInsensitiveContains(trimmed)
            || $0.location.localizedCaseInsensitiveContains(trimmed)
            || $0.type.displayName.localizedCaseInsensitiveContains(trimmed)
        }
    }

    var upcomingEvents: [Event] {
        let today = Calendar.current.startOfDay(for: Date())
        return searchedEvents.filter { $0.date >= today }
            .sorted { $0.date < $1.date }
    }

    var pastEvents: [Event] {
        let today = Calendar.current.startOfDay(for: Date())
        return searchedEvents.filter { $0.date < today }
            .sorted { $0.date > $1.date }
    }

    var filteredUpcomingEvents: [Event] {
        guard let filter = selectedTypeFilter else { return upcomingEvents }
        return upcomingEvents.filter { $0.type == filter }
    }

    var filteredPastEvents: [Event] {
        guard let filter = selectedTypeFilter else { return pastEvents }
        return pastEvents.filter { $0.type == filter }
    }

    var hasNoResults: Bool {
        filteredUpcomingEvents.isEmpty && filteredPastEvents.isEmpty
    }

    func load(context: ModelContext) {
        state = .loading
        do {
            let descriptor = FetchDescriptor<Event>(
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            let events = try context.fetch(descriptor)
            state = .loaded(events)
            eventListLogger.notice("Loaded events", metadata: [
                "step": .string("load"),
                "count": .stringConvertible(events.count),
                "result": .string("success")
            ])
        } catch {
            state = .error(error.localizedDescription)
            eventListLogger.error("Failed to load events", metadata: [
                "step": .string("load"),
                "error": .string(error.localizedDescription)
            ])
        }
    }

    func deleteEvent(_ event: Event, context: ModelContext) {
        guard (event.records ?? []).isEmpty else {
            deleteError = String(localized: "event.detail.deleteBlocked")
            eventListLogger.warning("Blocked event deletion", metadata: [
                "step": .string("delete"),
                "event_id": .string(String(describing: event.persistentModelID)),
                "reason": .string("has_records")
            ])
            return
        }
        context.delete(event)
        do {
            try context.save()
            eventListLogger.notice("Deleted event", metadata: [
                "step": .string("delete"),
                "event_id": .string(String(describing: event.persistentModelID)),
                "result": .string("success")
            ])
            load(context: context)
        } catch {
            deleteError = error.localizedDescription
            eventListLogger.error("Failed to delete event", metadata: [
                "step": .string("delete"),
                "event_id": .string(String(describing: event.persistentModelID)),
                "error": .string(error.localizedDescription)
            ])
            load(context: context)
        }
    }

    func daysUntil(_ date: Date) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let eventDay = calendar.startOfDay(for: date)
        let components = calendar.dateComponents([.day], from: today, to: eventDay)
        return components.day ?? 0
    }

    func formatEventDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }
}
