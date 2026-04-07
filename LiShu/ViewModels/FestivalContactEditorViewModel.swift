import Foundation
import SwiftData

@Observable
class FestivalContactEditorViewModel {
    enum SelectionStyle: String, CaseIterable {
        case byCircle
        case byPerson

        var localizedTitle: String {
            switch self {
            case .byCircle:
                String(localized: "festival.contactEditor.byCircle")
            case .byPerson:
                String(localized: "festival.contactEditor.byPerson")
            }
        }
    }

    struct CircleGroup: Identifiable, Hashable {
        let circle: Int
        let title: String
        let contacts: [Contact]

        var id: Int {
            circle
        }
    }

    var mode: FestivalContactSelectionMode = .recommendedOnly
    var contacts: [Contact] = []
    var selectedContactIDs: Set<PersistentIdentifier> = []
    var searchText: String = ""
    var selectionStyle: SelectionStyle = .byCircle

    var selectedContacts: [Contact] {
        contacts.filter { selectedContactIDs.contains($0.persistentModelID) }
    }

    var filteredContacts: [Contact] {
        if searchText.isEmpty {
            return contacts
        }
        return contacts.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.relation.localizedCaseInsensitiveContains(searchText) ||
                $0.category.localizedCaseInsensitiveContains(searchText)
        }
    }

    var circleGroups: [CircleGroup] {
        Dictionary(grouping: contacts, by: \.circle)
            .map { circle, members in
                CircleGroup(
                    circle: circle,
                    title: circleTitle(for: circle),
                    contacts: members.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
                )
            }
            .sorted { $0.circle < $1.circle }
    }

    func load(route: FestivalRoutePayload, context: ModelContext) {
        mode = FestivalService.contactSelectionMode(for: route, context: context)
        contacts = ((try? context.fetch(FetchDescriptor<Contact>(sortBy: [SortDescriptor(\.name)]))) ?? [])
        selectedContactIDs = Set(FestivalService.preferredContacts(for: route, context: context).map(\.persistentModelID))
    }

    func configureDraft(
        mode: FestivalContactSelectionMode,
        contacts: [Contact],
        selectedContactIDs: Set<PersistentIdentifier>
    ) {
        self.mode = mode
        self.contacts = contacts.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
        self.selectedContactIDs = selectedContactIDs
    }

    func toggleSelection(for contact: Contact) {
        if selectedContactIDs.contains(contact.persistentModelID) {
            selectedContactIDs.remove(contact.persistentModelID)
        } else {
            selectedContactIDs.insert(contact.persistentModelID)
        }
    }

    func toggleCircle(_ group: CircleGroup) {
        let ids = group.contacts.map(\.persistentModelID)
        let allSelected = ids.allSatisfy { selectedContactIDs.contains($0) }

        if allSelected {
            ids.forEach { selectedContactIDs.remove($0) }
        } else {
            ids.forEach { selectedContactIDs.insert($0) }
        }
    }

    func save(route: FestivalRoutePayload, context: ModelContext) {
        let selectedContacts = contacts.filter { selectedContactIDs.contains($0.persistentModelID) }
        FestivalService.replacePreferredContacts(for: route, contacts: selectedContacts, context: context)
        FestivalService.setContactSelectionMode(mode, for: route, context: context)
    }

    private func circleTitle(for circle: Int) -> String {
        switch circle {
        case 1:
            String(localized: "festival.contactEditor.circle.family")
        case 2:
            String(localized: "festival.contactEditor.circle.relatives")
        case 3:
            String(localized: "festival.contactEditor.circle.social")
        default:
            String(localized: "festival.contactEditor.circle.other")
        }
    }
}
