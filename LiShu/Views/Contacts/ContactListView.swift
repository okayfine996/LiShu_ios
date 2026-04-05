import SwiftData
import SwiftUI

struct ContactListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ContactListViewModel()
    @State private var presentedSheet: SheetRoute?
    @State private var showBatchImport = false

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
                        InteractionLogger.tap(screen: "contacts.list", target: "contacts.list.add", route: SheetRoute.addContact.logName, presentation: .sheet)
                        presentedSheet = .addContact
                    } label: {
                        Label(String(localized: "contact.add.title"), systemImage: "person.badge.plus")
                    }
                    Button {
                        InteractionLogger.tap(screen: "contacts.list", target: "contacts.list.batchImport", route: "sheet.contacts.batchImport", presentation: .sheet)
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
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                filterSection

                if viewModel.filteredContacts.isEmpty {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        message: String(localized: "contact.list.noResults")
                    )
                } else {
                    ForEach(viewModel.groupedContacts) { group in
                        groupSection(group)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 80)
        }
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
        VStack(alignment: .leading, spacing: 10) {
            Text(group.title)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .fontWeight(.semibold)
                .padding(.leading, 4)

            ForEach(group.contacts) { contact in
                NavigationLink(value: AppRoute.contactDetail(contact.persistentModelID)) {
                    ContactRow(
                        avatar: contact.avatar,
                        name: contact.name,
                        relation: contact.relation,
                        netValue: contact.netValue
                    )
                }
                .simultaneousGesture(TapGesture().onEnded {
                    InteractionLogger.navigation(
                        screen: "contacts.list",
                        target: "contacts.list.contact.\(String(describing: contact.persistentModelID))",
                        route: AppRoute.contactDetail(contact.persistentModelID).logName
                    )
                })
                .buttonStyle(.plain)
                .background(DesignSystem.Colors.bgSurface)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ContactListView()
    }
    .modelContainer(for: Contact.self, inMemory: true)
}
