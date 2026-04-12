import Foundation
import SwiftData

@Observable
class AddLedgerReceiptViewModel {
    private let form = AddRecordViewModel()
    private(set) var eventID: PersistentIdentifier
    private var hasLoaded = false

    init(eventID: PersistentIdentifier) {
        self.eventID = eventID
    }

    var selectedContact: Contact? {
        get { form.selectedContact }
        set { form.selectedContact = newValue }
    }

    var selectedEvent: Event? {
        form.selectedEvent
    }

    var allContacts: [Contact] {
        form.allContacts
    }

    var date: Date {
        get { form.date }
        set { form.date = newValue }
    }

    var note: String {
        get { form.note }
        set { form.note = newValue }
    }

    var monetaryAmount: String {
        get { form.monetaryAmount }
        set { form.monetaryAmount = newValue }
    }

    var monetaryPaymentMethod: PaymentMethod {
        get { form.monetaryPaymentMethod }
        set { form.monetaryPaymentMethod = newValue }
    }

    var relationshipWeight: RelationshipWeight {
        get { form.relationshipWeight }
        set { form.relationshipWeight = newValue }
    }

    var newPhotoItems: [NewRecordPhotoItem] {
        get { form.newPhotoItems }
        set { form.newPhotoItems = newValue }
    }

    var isValid: Bool {
        form.isValid
    }

    var direction: RecordDirection {
        form.direction
    }

    var recordType: RecordType {
        form.recordType
    }

    var contextSelection: RecordContextSelection {
        form.contextSelection
    }

    func load(context: ModelContext) {
        guard !hasLoaded else { return }
        hasLoaded = true
        form.loadData(context: context)
        form.configure(direction: .received, contactID: nil, eventID: eventID, context: context)
        form.recordType = .monetary
        form.contextSelection = .event
    }

    func reloadContacts(context: ModelContext) {
        form.loadData(context: context)
        form.selectEvent(context.model(for: eventID) as? Event)
        form.setContextSelection(.event)
        form.recordType = .monetary
    }

    @MainActor
    func save(context: ModelContext) -> Bool {
        form.recordType = .monetary
        form.contextSelection = .event
        form.direction = .received
        return form.save(context: context)
    }

    func resetForContinuousEntry() {
        form.resetForContinuousEntry()
    }
}
