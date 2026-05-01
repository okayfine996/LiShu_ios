import Foundation
import SwiftData

@Observable
class GiftReceivingModeViewModel {
    private let form: AddLedgerReceiptViewModel
    let eventID: PersistentIdentifier

    // MARK: - 联系人搜索

    var contactSearchText: String = ""
    var searchResults: [Contact] = []
    var isSearchDropdownVisible: Bool = false
    var canQuickAddContact: Bool = false

    // MARK: - 表单代理

    var selectedContact: Contact? {
        get { form.selectedContact }
        set { form.selectedContact = newValue }
    }

    var monetaryAmount: String {
        get { form.monetaryAmount }
        set { form.monetaryAmount = newValue }
    }

    var monetaryPaymentMethod: PaymentMethod {
        get { form.monetaryPaymentMethod }
        set { form.monetaryPaymentMethod = newValue }
    }

    var note: String {
        get { form.note }
        set { form.note = newValue }
    }

    var isNoteExpanded: Bool = false
    var isValid: Bool {
        form.isValid
    }

    // MARK: - 统计

    var totalReceivedCount: Int = 0
    var totalReceivedAmount: Double = 0
    var recentRecords: [Record] = []
    private let recentRecordsLimit = 5

    // MARK: - 交互反馈

    var successToastMessage: String?
    var submitError: String?
    private var toastDismissTask: Task<Void, Never>?
    var requestFocusField: GRMFocusField?

    init(eventID: PersistentIdentifier) {
        self.eventID = eventID
        form = AddLedgerReceiptViewModel(eventID: eventID)
    }

    // MARK: - Load

    func load(context: ModelContext) {
        form.load(context: context)
        refreshStats()
        requestFocusField = .contactSearch
    }

    // MARK: - 联系人搜索

    func updateContactSearch(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            searchResults = []
            isSearchDropdownVisible = false
            canQuickAddContact = false
            return
        }
        searchResults = form.allContacts.filter {
            $0.name.localizedCaseInsensitiveContains(trimmed)
        }
        isSearchDropdownVisible = true
        let exactMatch = form.allContacts.contains {
            $0.name.trimmingCharacters(in: .whitespacesAndNewlines)
                .localizedCaseInsensitiveCompare(trimmed) == .orderedSame
        }
        canQuickAddContact = !exactMatch
    }

    func selectContact(_ contact: Contact) {
        form.selectedContact = contact
        contactSearchText = contact.name
        isSearchDropdownVisible = false
        canQuickAddContact = false
        searchResults = []
        requestFocusField = .amount
    }

    func quickAddContact(name: String, context: ModelContext) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let contact = Contact(name: trimmed)
        context.insert(contact)
        try? context.save()
        form.reloadContacts(context: context)
        selectContact(contact)
    }

    func dismissDropdown() {
        isSearchDropdownVisible = false
    }

    // MARK: - 提交

    @discardableResult
    @MainActor
    func submit(context: ModelContext) -> Bool {
        guard isValid else { return false }

        let savedName = form.selectedContact?.name ?? ""
        let savedAmount = form.monetaryAmount

        guard form.save(context: context) else {
            submitError = String(localized: "common.saveError")
            return false
        }

        refreshStats()
        form.resetForContinuousEntry()
        contactSearchText = ""
        searchResults = []
        isSearchDropdownVisible = false
        canQuickAddContact = false
        isNoteExpanded = false
        requestFocusField = .contactSearch
        showSuccessToast(name: savedName, amount: savedAmount)
        return true
    }

    // MARK: - 删除最近记录

    @MainActor
    func deleteRecord(_ record: Record, context: ModelContext) {
        context.delete(record)
        try? context.save()
        refreshStats()
    }

    // MARK: - 统计刷新

    func refreshStats() {
        guard let event = form.selectedEvent else { return }
        let received = (event.records ?? [])
            .filter { $0.direction == .received && $0.recordType == .monetary }
        totalReceivedCount = received.count
        totalReceivedAmount = received.reduce(0.0) { $0 + $1.resolvedDisplayAmount }
        recentRecords = received
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(recentRecordsLimit)
            .map(\.self)
    }

    // MARK: - Toast

    private func showSuccessToast(name: String, amount: String) {
        let displayAmount = amount.isEmpty ? "0" : amount
        successToastMessage = String(
            format: String(localized: "giftReceiving.toast.success"),
            name,
            displayAmount
        )
        toastDismissTask?.cancel()
        toastDismissTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.8))
            self.successToastMessage = nil
        }
    }
}
