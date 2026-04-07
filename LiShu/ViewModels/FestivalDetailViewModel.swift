import Foundation
import SwiftData

@Observable
class FestivalDetailViewModel {
    var occurrence: FestivalOccurrence?
    var pendingContacts: [Contact] = []
    var greetedContacts: [Contact] = []
    var selectedContactID: PersistentIdentifier?

    func load(route: FestivalRoutePayload, context: ModelContext) {
        occurrence = FestivalService.occurrence(for: route, context: context)
        guard let occurrence else {
            pendingContacts = []
            greetedContacts = []
            selectedContactID = nil
            return
        }

        pendingContacts = FestivalService.pendingContacts(for: occurrence, context: context)
        greetedContacts = FestivalService.greetedContacts(for: occurrence, context: context)
        if let selectedContactID, pendingContacts.contains(where: { $0.persistentModelID == selectedContactID }) {
            self.selectedContactID = selectedContactID
        } else {
            selectedContactID = pendingContacts.first?.persistentModelID
        }
    }

    func markGreeted(contact: Contact, context: ModelContext) {
        guard let occurrence else { return }
        FestivalService.markGreeted(contact: contact, occurrence: occurrence, context: context)
        load(route: occurrence.route, context: context)
    }

    func unmarkGreeted(contact: Contact, context: ModelContext) {
        guard let occurrence else { return }
        FestivalService.unmarkGreeted(contact: contact, occurrence: occurrence, context: context)
        load(route: occurrence.route, context: context)
    }
}
