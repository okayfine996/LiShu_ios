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
        phone.filter { $0.isNumber }
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
            $0.displayName.lowercased().contains(query) ||
            $0.phone.contains(query)
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
            CNContactPhoneNumbersKey as CNKeyDescriptor
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
                    items.append(PhoneContactItem(
                        id: key,
                        displayName: name,
                        phone: "",
                        isExisting: false
                    ))
                } else {
                    for phoneNumber in contact.phoneNumbers {
                        let phone = phoneNumber.value.stringValue
                        let key = PhoneContactItem.key(name: name, phone: phone)
                        guard !seenKeys.contains(key) else { continue }
                        seenKeys.insert(key)
                        items.append(PhoneContactItem(
                            id: key,
                            displayName: name,
                            phone: phone,
                            isExisting: false
                        ))
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
        let existingKeys = Set(existingContacts.map { c in
            PhoneContactItem.key(name: c.name, phone: c.phone)
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

        let currentCount: Int
        do {
            currentCount = try context.fetchCount(FetchDescriptor<Contact>())
        } catch {
            return false
        }
        let afterCount = currentCount + toImport.count
        if afterCount > 20 && !SubscriptionManager.shared.isPro {
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

            Group {
                switch viewModel.accessState {
                case .idle, .loading:
                    ProgressView()
                case .denied:
                    EmptyStateView(
                        icon: "person.crop.circle.badge.exclamationmark",
                        message: String(localized: "contact.import.noAccess")
                    )
                case .empty:
                    EmptyStateView(
                        icon: "person.2.slash",
                        message: String(localized: "contact.import.empty")
                    )
                case .granted:
                    mainContent
                }
            }
        }
        .navigationTitle(String(localized: "contact.import.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(String(localized: "common.cancel")) {
                    dismiss()
                }
                .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
            ToolbarItem(placement: .primaryAction) {
                if viewModel.accessState == .granted && !viewModel.selectableItems.isEmpty {
                    Button(viewModel.isAllSelectableSelected
                        ? String(localized: "contact.import.deselectAll")
                        : String(localized: "contact.import.selectAll")
                    ) {
                        if viewModel.isAllSelectableSelected {
                            viewModel.deselectAll()
                        } else {
                            viewModel.selectAll()
                        }
                    }
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
        .alert(String(localized: "contact.import.title"), isPresented: Binding(
            get: { viewModel.importSuccessCount != nil },
            set: { if !$0 { viewModel.importSuccessCount = nil; dismiss() } }
        )) {
            Button(String(localized: "common.ok")) {
                viewModel.importSuccessCount = nil
                dismiss()
            }
        } message: {
            if let count = viewModel.importSuccessCount {
                Text(String(format: String(localized: "contact.import.success"), Int64(count)))
            }
        }
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            searchBar
            contactList
            importButton
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(DesignSystem.Colors.textTertiary)
            TextField(
                String(localized: "contact.import.search"),
                text: $viewModel.searchText
            )
            .font(DesignSystem.Typography.caption)
            .foregroundStyle(DesignSystem.Colors.textPrimary)

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.input)
                .stroke(DesignSystem.Colors.border, lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var contactList: some View {
        List {
            ForEach(viewModel.filteredItems) { item in
                contactRow(item)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func contactRow(_ item: PhoneContactItem) -> some View {
        let isSelectable = !item.isExisting
        return HStack(spacing: 12) {
            Button {
                if isSelectable {
                    viewModel.toggleSelection(item.id)
                }
            } label: {
                Image(systemName: viewModel.selectedIDs.contains(item.id) ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(
                        isSelectable
                            ? (viewModel.selectedIDs.contains(item.id) ? DesignSystem.Colors.primary : DesignSystem.Colors.textTertiary)
                            : DesignSystem.Colors.textTertiary.opacity(0.5)
                    )
            }
            .disabled(!isSelectable)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.displayName)
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    if item.isExisting {
                        Text(String(localized: "contact.import.exists"))
                            .font(DesignSystem.Typography.small)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(DesignSystem.Colors.bgTag)
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.tag))
                    }
                }
                if !item.phone.isEmpty {
                    Text(item.phone)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .listRowInsets(EdgeInsets())
        .listRowBackground(DesignSystem.Colors.bgSurface)
    }

    private var importButton: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(DesignSystem.Colors.separator)
                .frame(height: 1)
            Button {
                Task {
                    _ = await viewModel.performImport(context: modelContext)
                }
            } label: {
                if viewModel.isLoadingImport {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(String(format: String(localized: "contact.import.button"), Int64(viewModel.selectedCount)))
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(viewModel.selectedCount == 0 || viewModel.isLoadingImport)
            .padding(16)
        }
        .background(DesignSystem.Colors.bgPage)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BatchContactImportView()
    }
    .modelContainer(for: Contact.self, inMemory: true)
}
