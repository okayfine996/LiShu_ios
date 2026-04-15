import SwiftData
import SwiftUI

struct ContactListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ContactListViewModel()
    @State private var presentedSheet: SheetRoute?
    @State private var showBatchImport = false
    @State private var pendingDeleteContact: Contact?
    @State private var selectedContactRoute: SelectedContactRoute?

    var body: some View {
        ZStack {
            DesignSystem.Colors.bgPage
                .ignoresSafeArea()

            Group {
                switch viewModel.state {
                case .idle, .loading:
                    ProgressView()
                case let .loaded(contacts) where contacts.isEmpty:
                    EmptyStateView(
                        icon: "person.2.fill",
                        message: String(localized: "contact.list.empty"),
                        actionTitle: String(localized: "contact.add.title"),
                        action: { presentedSheet = .addContact }
                    )
                case .loaded:
                    contactListContent
                case let .error(message):
                    ErrorStateView(
                        message: message,
                        retryAction: { viewModel.loadContacts(context: modelContext) }
                    )
                }
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.large)
        .trackScreen("contacts.list")
        .searchable(text: $viewModel.searchText, prompt: String(localized: "common.search"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        InteractionLogger.tap(
                            screen: "contacts.list",
                            target: "contacts.list.add",
                            route: SheetRoute.addContact.logName,
                            presentation: .sheet
                        )
                        presentedSheet = .addContact
                    } label: {
                        Label(String(localized: "contact.add.title"), systemImage: "person.badge.plus")
                    }
                    Button {
                        InteractionLogger.tap(
                            screen: "contacts.list",
                            target: "contacts.list.batchImport",
                            route: "sheet.contacts.batchImport",
                            presentation: .sheet
                        )
                        showBatchImport = true
                    } label: {
                        Label(String(localized: "contact.batch.import"), systemImage: "person.crop.rectangle.stack")
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.primary)
                }
                .accessibilityIdentifier("contact.list.addButton")
            }
        }
        .sheet(isPresented: $showBatchImport, onDismiss: {
            viewModel.loadContacts(context: modelContext)
        }) {
            NavigationStack {
                BatchContactImportView()
            }
        }
        .sheet(item: $presentedSheet) { route in
            switch route {
            case .addContact:
                NavigationStack {
                    AddContactView()
                }
            case let .editContact(contactID):
                NavigationStack {
                    AddContactView(contactID: contactID)
                }
            default:
                EmptyView()
            }
        }
        .navigationDestination(item: $selectedContactRoute) { route in
            ContactDetailView(contactID: route.id)
        }
        .onChange(of: presentedSheet) { _, newValue in
            if let newValue {
                InteractionLogger.sheetPresentation(screen: "contacts.list", route: newValue.logName, isPresented: true)
            }
            if newValue == nil {
                viewModel.loadContacts(context: modelContext)
            }
        }
        .onAppear {
            viewModel.loadContacts(context: modelContext)
        }
        .onChange(of: showBatchImport) { _, newValue in
            InteractionLogger.sheetPresentation(screen: "contacts.list", route: "sheet.contacts.batchImport", isPresented: newValue)
        }
        .alert(String(localized: "common.error"), isPresented: Binding(
            get: { viewModel.deleteError != nil },
            set: { if !$0 { viewModel.deleteError = nil } }
        )) {
            Button(String(localized: "common.ok")) {
                viewModel.deleteError = nil
            }
        } message: {
            if let message = viewModel.deleteError {
                Text(message)
            }
        }
        .alert(
            String(localized: "contact.detail.deleteConfirm"),
            isPresented: Binding(
                get: { pendingDeleteContact != nil },
                set: { if !$0 { pendingDeleteContact = nil } }
            )
        ) {
            Button(String(localized: "common.cancel"), role: .cancel) {
                pendingDeleteContact = nil
            }
            Button(String(localized: "common.delete"), role: .destructive) {
                guard let pendingDeleteContact else { return }
                viewModel.deleteContact(pendingDeleteContact, context: modelContext)
                self.pendingDeleteContact = nil
            }
        } message: {
            Text(contactDeleteMessage)
        }
    }

    // MARK: - Navigation Title

    private var navigationTitle: String {
        let title = String(localized: "contact.list.title")
        if viewModel.totalCount > 0 {
            return "\(title) (\(viewModel.totalCount))"
        }
        return title
    }

    // MARK: - Contact List Content

    private var contactListContent: some View {
        List {
            listRow(bottomInset: DesignSystem.Spacing.block) {
                filterSection
            }

            if viewModel.filteredContacts.isEmpty {
                listRow(bottomInset: DesignSystem.Spacing.section) {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        message: String(localized: "contact.list.noResults")
                    )
                }
            } else {
                ForEach(viewModel.groupedContacts) { group in
                    groupSection(group)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(DesignSystem.Colors.bgPage)
    }

    // MARK: - Filter Section

    private var filterSection: some View {
        CapsuleSegmentedControl(
            options: ContactCircleFilter.allCases,
            selected: $viewModel.selectedFilter,
            titleForOption: { $0.title }
        )
    }

    // MARK: - Group Section

    private func groupSection(_ group: ContactGroup) -> some View {
        Section {
            ForEach(group.contacts) { contact in
                contactRow(contact)
            }
        } header: {
            sectionHeader(group.title)
        }
    }

    private func contactRow(_ contact: Contact) -> some View {
        Button {
            InteractionLogger.navigation(
                screen: "contacts.list",
                target: "contacts.list.contact.\(String(describing: contact.persistentModelID))",
                route: AppRoute.contactDetail(contact.persistentModelID).logName
            )
            selectedContactRoute = SelectedContactRoute(id: contact.persistentModelID)
        } label: {
            ContactRow(
                avatar: contact.avatar,
                name: contact.name,
                relation: contact.relation,
                netValue: contact.netValue
            )
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("contact.list.row.\(contact.name)")
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                pendingDeleteContact = contact
            } label: {
                Label(String(localized: "common.delete"), systemImage: "trash")
            }
        }
        .listRowInsets(EdgeInsets(
            top: 0,
            leading: DesignSystem.Spacing.pageHorizontal,
            bottom: DesignSystem.Spacing.block,
            trailing: DesignSystem.Spacing.pageHorizontal
        ))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(DesignSystem.Typography.caption)
            .foregroundStyle(DesignSystem.Colors.textSecondary)
            .fontWeight(.semibold)
            .textCase(nil)
            .padding(.top, DesignSystem.Spacing.block)
    }

    private func listRow(
        bottomInset: CGFloat = DesignSystem.Spacing.block,
        @ViewBuilder content: () -> some View
    ) -> some View {
        content()
            .listRowInsets(EdgeInsets(
                top: 0,
                leading: DesignSystem.Spacing.pageHorizontal,
                bottom: bottomInset,
                trailing: DesignSystem.Spacing.pageHorizontal
            ))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }

    private var contactDeleteMessage: String {
        guard let pendingDeleteContact else { return "" }
        let records = pendingDeleteContact.records ?? []
        let recordCount = Int64(records.count)
        let photoCount = Int64(records.reduce(0) { $0 + ($1.photos?.count ?? 0) })
        return String(
            format: String(localized: "contact.list.deleteConfirmMessage"),
            recordCount,
            photoCount
        )
    }
}

private struct SelectedContactRoute: Identifiable, Hashable {
    let id: PersistentIdentifier
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ContactListView()
    }
    .modelContainer(for: Contact.self, inMemory: true)
}
