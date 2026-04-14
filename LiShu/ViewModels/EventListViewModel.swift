import Foundation
import Logging
import SwiftData

private let eventListLogger = PulseDiagnostics.makeLogger(label: AppLogLabel.eventsViewModel)

@Observable
class EventListViewModel {
    private enum Logging {
        static let searchDebounceInterval: TimeInterval = 0.35
    }

    var state: LoadingState<[Event]> = .idle
    var selectedTypeFilter: EventType? {
        didSet {
            cancelPendingSearchLog()
            logCurrentQueryIfAvailable(operation: "filter_change")
        }
    }

    var searchText: String = "" {
        didSet {
            scheduleSearchQueryLog()
        }
    }

    var deleteError: String?

    private var allEvents: [Event] = []
    private var pendingSearchLogWorkItem: DispatchWorkItem?

    private var searchedEvents: [Event] {
        let events = allEvents
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
            allEvents = events
            state = .loaded(events)
            cancelPendingSearchLog()
            logCurrentQueryIfAvailable(operation: "load")
            eventListLogger.notice("Loaded events", metadata: [
                "step": .string("load"),
                "count": .stringConvertible(events.count),
                "result": .string("success"),
            ])
        } catch {
            state = .error(error.localizedDescription)
            BusinessDataLogger.entityQuery(
                domain: "event",
                screen: "events.list",
                operation: "load_failed",
                searchText: searchText.trimmingCharacters(in: .whitespacesAndNewlines),
                filters: ["eventType": selectedTypeFilter?.rawValue ?? "all"],
                sort: "date_desc_split",
                results: [EventLogPayload](),
                error: error.localizedDescription
            )
            eventListLogger.error("Failed to load events", metadata: [
                "step": .string("load"),
                "error": .string(error.localizedDescription),
            ])
        }
    }

    func deleteEvent(_ event: Event, context: ModelContext) {
        let deletedPayload = event.logPayload()
        context.delete(event)
        do {
            try context.save()
            NotificationManager.shared.cancelRemindersForEventDeletion(event: event)
            BusinessDataLogger.entityMutation(
                domain: "event",
                screen: "events.list",
                operation: "delete",
                payload: deletedPayload,
                results: [deletedPayload]
            )
            eventListLogger.notice("Deleted event", metadata: [
                "step": .string("delete"),
                "event_id": .string(String(describing: event.persistentModelID)),
                "result": .string("success"),
            ])
            load(context: context)
        } catch {
            deleteError = error.localizedDescription
            BusinessDataLogger.entityMutation(
                domain: "event",
                screen: "events.list",
                operation: "delete_failed",
                payload: deletedPayload,
                error: error.localizedDescription
            )
            eventListLogger.error("Failed to delete event", metadata: [
                "step": .string("delete"),
                "event_id": .string(String(describing: event.persistentModelID)),
                "error": .string(error.localizedDescription),
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

    deinit {
        cancelPendingSearchLog()
    }

    private func scheduleSearchQueryLog() {
        guard case .loaded = state else { return }
        let workItem = DispatchWorkItem { [weak self] in
            self?.logCurrentQueryIfAvailable(operation: "search_change")
        }
        cancelPendingSearchLog()
        pendingSearchLogWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + Logging.searchDebounceInterval, execute: workItem)
    }

    private func cancelPendingSearchLog() {
        pendingSearchLogWorkItem?.cancel()
        pendingSearchLogWorkItem = nil
    }

    private func logCurrentQueryIfAvailable(operation: String) {
        guard case .loaded = state else { return }
        if operation != "search_change" {
            cancelPendingSearchLog()
        }
        let results = filteredUpcomingEvents + filteredPastEvents
        BusinessDataLogger.entityQuery(
            domain: "event",
            screen: "events.list",
            operation: operation,
            searchText: searchText.trimmingCharacters(in: .whitespacesAndNewlines),
            filters: ["eventType": selectedTypeFilter?.rawValue ?? "all"],
            sort: "date_desc_split",
            results: results.map { $0.logPayload() }
        )
    }
}
