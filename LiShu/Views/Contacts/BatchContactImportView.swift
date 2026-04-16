import Contacts
import SwiftData
import SwiftUI

/// A single contact item for batch import (one row per name+phone pair)
struct PhoneContactItem: Identifiable {
    let id: String
    let displayName: String
    let phone: String
    let isExisting: Bool

    static func key(name: String, phone: String) -> String {
        "\(name)|\(normalizePhone(phone))"
    }

    static func normalizePhone(_ phone: String) -> String {
        phone.filter(\.isNumber)
    }
}

@Observable
@MainActor
final class BatchContactImportViewModel {
    enum AccessState {
        case idle
        case loading
        case granted
        case denied
        case empty
    }

    var accessState: AccessState = .idle
    var allItems: [PhoneContactItem] = []
    var searchText: String = ""
    var selectedIDs: Set<String> = []
    var showProSheet = false
    var importSuccessCount: Int?
    var isLoadingImport = false

    var filteredItems: [PhoneContactItem] {
        guard !searchText.isEmpty else { return allItems }
        let query = searchText.lowercased()
        return allItems.filter {
            $0.displayName.lowercased().contains(query) || $0.phone.contains(query)
        }
    }

    var selectableItems: [PhoneContactItem] {
        filteredItems.filter { !$0.isExisting }
    }

    var selectedCount: Int {
        selectedIDs.filter { id in
            selectableItems.contains { $0.id == id }
        }.count
    }

    var isAllSelectableSelected: Bool {
        let selectableIDs = Set(selectableItems.map(\.id))
        guard !selectableIDs.isEmpty else { return false }
        return selectableIDs.isSubset(of: selectedIDs)
    }

    func requestAccessAndFetch() async {
        accessState = .loading
        let store = CNContactStore()
        do {
            let granted = try await store.requestAccess(for: .contacts)
            guard granted else {
                accessState = .denied
                return
            }
            let items = fetchContacts(store: store)
            allItems = items
            accessState = items.isEmpty ? .empty : .granted
        } catch {
            accessState = .denied
        }
    }

    private func fetchContacts(store: CNContactStore) -> [PhoneContactItem] {
        let keys: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
        ]
        let request = CNContactFetchRequest(keysToFetch: keys)
        var items: [PhoneContactItem] = []
        var seenKeys = Set<String>()
        do {
            try store.enumerateContacts(with: request) { contact, _ in
                let familyName = contact.familyName
                let givenName = contact.givenName
                let displayName = [familyName, givenName].filter { !$0.isEmpty }.joined()
                let name = displayName.isEmpty ? String(localized: "common.unknown") : displayName

                if contact.phoneNumbers.isEmpty {
                    let key = PhoneContactItem.key(name: name, phone: "")
                    guard !seenKeys.contains(key) else { return }
                    seenKeys.insert(key)
                    items.append(PhoneContactItem(id: key, displayName: name, phone: "", isExisting: false))
                } else {
                    for phoneNumber in contact.phoneNumbers {
                        let phone = phoneNumber.value.stringValue
                        let key = PhoneContactItem.key(name: name, phone: phone)
                        guard !seenKeys.contains(key) else { continue }
                        seenKeys.insert(key)
                        items.append(
                            PhoneContactItem(id: key, displayName: name, phone: phone, isExisting: false)
                        )
                    }
                }
            }
        } catch {}
        return items
    }

    func markExisting(context: ModelContext) {
        let existingContacts: [Contact]
        do {
            existingContacts = try context.fetch(FetchDescriptor<Contact>())
        } catch {
            return
        }
        let existingKeys = Set(existingContacts.map { contact in
            PhoneContactItem.key(name: contact.name, phone: contact.phone)
        })
        allItems = allItems.map { item in
            PhoneContactItem(
                id: item.id,
                displayName: item.displayName,
                phone: item.phone,
                isExisting: existingKeys.contains(item.id)
            )
        }
    }

    func toggleSelection(_ id: String) {
        guard let item = allItems.first(where: { $0.id == id }), !item.isExisting else { return }
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }

    func selectAll() {
        selectedIDs.formUnion(selectableItems.map(\.id))
    }

    func deselectAll() {
        selectedIDs.removeAll()
    }

    func performImport(context: ModelContext) async -> Bool {
        let toImport = allItems.filter { selectedIDs.contains($0.id) && !$0.isExisting }
        guard !toImport.isEmpty else { return false }

        if !SubscriptionManager.shared.canAddContacts(toImport.count, context: context) {
            showProSheet = true
            return false
        }

        isLoadingImport = true
        for item in toImport {
            let contact = Contact(
                name: item.displayName,
                phone: item.phone,
                avatar: nil,
                relation: "",
                category: "",
                circle: 4,
                birthday: nil,
                location: "",
                note: ""
            )
            context.insert(contact)
        }
        do {
            try context.save()
            importSuccessCount = toImport.count
            isLoadingImport = false
            return true
        } catch {
            isLoadingImport = false
            return false
        }
    }
}

struct BatchContactImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = BatchContactImportViewModel()

    var body: some View {
        ZStack {
            DesignSystem.Colors.bgPage
                .ignoresSafeArea()

            BatchContactImportStateView(
                accessState: viewModel.accessState,
                viewModel: viewModel,
                onImport: importContacts
            )
        }
        .navigationTitle(String(localized: "contact.import.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(String(localized: "common.cancel"), action: dismiss.callAsFunction)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }

            ToolbarItem(placement: .primaryAction) {
                if viewModel.accessState == .granted, !viewModel.selectableItems.isEmpty {
                    Button(selectAllButtonTitle, action: toggleSelectAll)
                        .foregroundStyle(DesignSystem.Colors.primary)
                }
            }
        }
        .task {
            await viewModel.requestAccessAndFetch()
            viewModel.markExisting(context: modelContext)
        }
        .sheet(isPresented: $viewModel.showProSheet) {
            NavigationStack {
                ProMembershipView()
                    .environment(SubscriptionManager.shared)
            }
        }
        .alert(String(localized: "contact.import.title"), isPresented: importSuccessBinding) {
            Button(String(localized: "common.ok"), action: dismissAfterSuccess)
        } message: {
            if let count = viewModel.importSuccessCount {
                Text(String(format: String(localized: "contact.import.success"), Int64(count)))
            }
        }
    }

    private var selectAllButtonTitle: String {
        viewModel.isAllSelectableSelected
            ? String(localized: "contact.import.deselectAll")
            : String(localized: "contact.import.selectAll")
    }

    private var importSuccessBinding: Binding<Bool> {
        Binding(
            get: { viewModel.importSuccessCount != nil },
            set: {
                if !$0 {
                    viewModel.importSuccessCount = nil
                    dismiss()
                }
            }
        )
    }

    private func toggleSelectAll() {
        if viewModel.isAllSelectableSelected {
            viewModel.deselectAll()
        } else {
            viewModel.selectAll()
        }
    }

    private func importContacts() {
        Task {
            _ = await viewModel.performImport(context: modelContext)
        }
    }

    private func dismissAfterSuccess() {
        viewModel.importSuccessCount = nil
        dismiss()
    }
}

#Preview {
    NavigationStack {
        BatchContactImportView()
    }
    .modelContainer(for: Contact.self, inMemory: true)
}
