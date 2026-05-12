import Foundation
import Logging
import SwiftData

private let contactListLogger = PulseDiagnostics.makeLogger(label: AppLogLabel.contactsViewModel)

/// Filter options for contacts by circle level
enum ContactCircleFilter: String, CaseIterable, Hashable {
    case all
    case family
    case relative
    case social

    var title: String {
        switch self {
        case .all: String(localized: "contact.filter.all")
        case .family: String(localized: "contact.filter.family")
        case .relative: String(localized: "contact.filter.relative")
        case .social: String(localized: "contact.filter.social")
        }
    }

    var relationshipCategory: RelationshipCategory? {
        switch self {
        case .all: nil
        case .family: .family
        case .relative: .relative
        case .social: .social
        }
    }
}

/// Represents a group of contacts under a relationship category
struct ContactGroup: Identifiable {
    let id: String
    let title: String
    let contacts: [Contact]
}

@Observable
class ContactListViewModel {
    private enum Logging {
        static let searchDebounceInterval: TimeInterval = 0.35
    }

    var state: LoadingState<[Contact]> = .idle
    var relationshipHealthResults: [PersistentIdentifier: RelationshipHealthResult] = [:]
    var selectedFilter: ContactCircleFilter = .all {
        didSet {
            cancelPendingSearchLog()
            logCurrentQueryIfAvailable(operation: "filter_change")
        }
    }

    var deleteError: String?
    var searchText: String = "" {
        didSet {
            scheduleSearchQueryLog()
        }
    }

    /// All contacts loaded from SwiftData
    private var allContacts: [Contact] = []
    private var pendingSearchLogWorkItem: DispatchWorkItem?

    /// Filtered contacts based on current filter and search
    var filteredContacts: [Contact] {
        var result = allContacts

        // Apply circle filter
        if let category = selectedFilter.relationshipCategory {
            result = result.filter { $0.category == category.rawValue }
        }

        // Apply search
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(query) ||
                    $0.relation.lowercased().contains(query)
            }
        }

        return result
    }

    /// Contacts grouped by relationship category
    var groupedContacts: [ContactGroup] {
        let contacts = filteredContacts
        var groups: [ContactGroup] = []

        for category in RelationshipCategory.allCases {
            let categoryContacts = contacts.filter {
                $0.category == category.rawValue
            }
            if !categoryContacts.isEmpty {
                groups.append(ContactGroup(
                    id: category.rawValue,
                    title: category.rawValue,
                    contacts: categoryContacts.sorted { $0.name < $1.name }
                ))
            }
        }

        // Contacts without a category
        let uncategorized = contacts.filter { contact in
            !RelationshipCategory.allCases.contains { $0.rawValue == contact.category }
        }
        if !uncategorized.isEmpty {
            groups.append(ContactGroup(
                id: "other",
                title: String(localized: "contact.filter.other"),
                contacts: uncategorized.sorted { $0.name < $1.name }
            ))
        }

        return groups
    }

    /// Total count of contacts (unfiltered)
    var totalCount: Int {
        allContacts.count
    }

    /// Count of filtered contacts
    var filteredCount: Int {
        filteredContacts.count
    }

    /// Load all contacts from SwiftData
    func loadContacts(context: ModelContext) {
        state = .loading
        do {
            let descriptor = FetchDescriptor<Contact>(
                sortBy: [SortDescriptor(\.name)]
            )
            let contacts = try context.fetch(descriptor)
            allContacts = contacts
            state = .loaded(contacts)
            relationshipHealthResults = RelationshipHealthCalculator.evaluateAll(contacts: contacts)
            cancelPendingSearchLog()
            logCurrentQueryIfAvailable(operation: "load")
            contactListLogger.notice("Loaded contacts", metadata: [
                "step": .string("load"),
                "count": .stringConvertible(contacts.count),
                "result": .string("success"),
            ])
        } catch {
            state = .error(String(localized: "contact.list.loadError"))
            BusinessDataLogger.entityQuery(
                domain: "contact",
                screen: "contacts.list",
                operation: "load_failed",
                searchText: searchText.trimmingCharacters(in: .whitespacesAndNewlines),
                filters: ["circleFilter": selectedFilter.rawValue],
                sort: "name_asc",
                results: [ContactLogPayload](),
                error: error.localizedDescription
            )
            contactListLogger.error("Failed to load contacts", metadata: [
                "step": .string("load"),
                "error": .string(error.localizedDescription),
            ])
        }
    }

    /// Delete a contact
    func deleteContact(_ contact: Contact, context: ModelContext) {
        let deletedPayload = contact.logPayload()
        contactListLogger.notice("Deleting contact", metadata: [
            "step": .string("delete"),
            "contact_id": .string(String(describing: contact.persistentModelID)),
        ])
        context.delete(contact)
        do {
            try context.save()
            BusinessDataLogger.entityMutation(
                domain: "contact",
                screen: "contacts.list",
                operation: "delete",
                payload: deletedPayload,
                results: [deletedPayload]
            )
            contactListLogger.notice("Deleted contact", metadata: [
                "step": .string("delete"),
                "contact_id": .string(String(describing: contact.persistentModelID)),
                "result": .string("success"),
            ])
            loadContacts(context: context)
        } catch {
            deleteError = error.localizedDescription
            BusinessDataLogger.entityMutation(
                domain: "contact",
                screen: "contacts.list",
                operation: "delete_failed",
                payload: deletedPayload,
                error: error.localizedDescription
            )
            contactListLogger.error("Failed to delete contact", metadata: [
                "step": .string("delete"),
                "contact_id": .string(String(describing: contact.persistentModelID)),
                "error": .string(error.localizedDescription),
            ])
            loadContacts(context: context)
        }
    }

    deinit {
        MainActor.assumeIsolated {
            cancelPendingSearchLog()
        }
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
        BusinessDataLogger.entityQuery(
            domain: "contact",
            screen: "contacts.list",
            operation: operation,
            searchText: searchText.trimmingCharacters(in: .whitespacesAndNewlines),
            filters: ["circleFilter": selectedFilter.rawValue],
            sort: "name_asc",
            results: filteredContacts.map { $0.logPayload() }
        )
    }
}
