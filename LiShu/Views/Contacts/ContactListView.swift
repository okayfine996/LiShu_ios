import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct ContactListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ContactListViewModel()
    @State private var presentedSheet: SheetRoute?
    @State private var showBatchImport = false
    @State private var pendingDeleteContact: Contact?
    @State private var selectedContactRoute: SelectedContactRoute?
    @State private var showContactCSVImporter = false
    @State private var contactShareURL: URL?
    @State private var contactImportResult: ContactImportResult?
    @State private var showContactImportPreview = false
    @State private var contactImportPreviewViewModel: ContactImportPreviewViewModel?

    private var navigationTitle: String {
        let title = String(localized: "contact.list.title")
        return viewModel.totalCount > 0 ? "\(title) (\(viewModel.totalCount))" : title
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

    var body: some View {
        ZStack {
            DesignSystem.Colors.bgPage
                .ignoresSafeArea()

            ContactListStateContainer(
                viewModel: viewModel,
                onRetry: loadContacts,
                onAddContact: presentAddContactSheet,
                onSelectContact: showContactDetail(_:),
                onDeleteContact: confirmDelete(_:),
                onEditContact: editContact(_:),
                onBatchImport: presentBatchImport
            )
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.large)
        .trackScreen("contacts.list")
        .searchable(text: $viewModel.searchText, prompt: String(localized: "common.search"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ContactListToolbarMenu(
                    onAddContact: presentAddContactSheet,
                    onBatchImport: presentBatchImport,
                    onExportCSV: exportContactCSV,
                    onImportCSV: { showContactCSVImporter = true },
                    onDownloadTemplate: downloadContactTemplate
                )
            }
        }
        .sheet(isPresented: $showBatchImport, onDismiss: loadContacts) {
            NavigationStack {
                BatchContactImportView()
            }
        }
        .sheet(item: $presentedSheet) { route in
            contactSheet(for: route)
        }
        .navigationDestination(item: $selectedContactRoute) { route in
            ContactDetailView(contactID: route.id)
        }
        .onAppear(perform: loadContacts)
        .onChange(of: presentedSheet) { _, newValue in
            handlePresentedSheetChange(newValue)
        }
        .onChange(of: showBatchImport) { _, newValue in
            InteractionLogger.sheetPresentation(
                screen: "contacts.list",
                route: "sheet.contacts.batchImport",
                isPresented: newValue
            )
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
                deletePendingContact()
            }
        } message: {
            Text(contactDeleteMessage)
        }
        .fileImporter(
            isPresented: $showContactCSVImporter,
            allowedContentTypes: [.commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            handleContactCSVImport(result)
        }
        .navigationDestination(isPresented: $showContactImportPreview) {
            if let contactImportPreviewViewModel {
                ContactImportPreviewView(viewModel: contactImportPreviewViewModel) { importResult in
                    handleCompletedContactImport(importResult)
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { contactShareURL != nil },
            set: { if !$0 {
                if let url = contactShareURL { cleanUpTempFile(url) }
                contactShareURL = nil
            }}
        )) {
            if let url = contactShareURL {
                ShareSheet(url: url)
            }
        }
        .alert(
            String(localized: "contact.csv.importResult"),
            isPresented: Binding(
                get: { contactImportResult != nil },
                set: { if !$0 { contactImportResult = nil } }
            )
        ) {
            Button(String(localized: "common.ok")) { contactImportResult = nil }
        } message: {
            if let r = contactImportResult {
                Text(String(format: String(localized: "contact.csv.importResultMessage"), r.created, r.updated, r.failed))
            }
        }
        .onChange(of: showContactImportPreview) { _, newValue in
            if !newValue {
                contactImportPreviewViewModel = nil
            }
        }
    }

    private func loadContacts() {
        viewModel.loadContacts(context: modelContext)
    }

    private func presentAddContactSheet() {
        InteractionLogger.tap(
            screen: "contacts.list",
            target: "contacts.list.add",
            route: SheetRoute.addContact.logName,
            presentation: .sheet
        )
        presentedSheet = .addContact
    }

    private func presentBatchImport() {
        InteractionLogger.tap(
            screen: "contacts.list",
            target: "contacts.list.batchImport",
            route: "sheet.contacts.batchImport",
            presentation: .sheet
        )
        showBatchImport = true
    }

    private func showContactDetail(_ contact: Contact) {
        InteractionLogger.navigation(
            screen: "contacts.list",
            target: "contacts.list.contact.\(String(describing: contact.persistentModelID))",
            route: AppRoute.contactDetail(contact.persistentModelID).logName
        )
        selectedContactRoute = SelectedContactRoute(id: contact.persistentModelID)
    }

    private func confirmDelete(_ contact: Contact) {
        pendingDeleteContact = contact
    }

    private func editContact(_ contact: Contact) {
        presentedSheet = .editContact(contact.persistentModelID)
    }

    private func handlePresentedSheetChange(_ newValue: SheetRoute?) {
        if let newValue {
            InteractionLogger.sheetPresentation(
                screen: "contacts.list",
                route: newValue.logName,
                isPresented: true
            )
        }

        if newValue == nil {
            loadContacts()
        }
    }

    private func deletePendingContact() {
        guard let pendingDeleteContact else { return }
        viewModel.deleteContact(pendingDeleteContact, context: modelContext)
        self.pendingDeleteContact = nil
    }

    private func exportContactCSV() {
        do {
            let csv = try ExportService.exportContactCSV(context: modelContext)
            let dateStr = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
                .replacingOccurrences(of: "/", with: "-")
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("contacts_\(dateStr).csv")
            try csv.write(to: url, atomically: true, encoding: .utf8)
            contactShareURL = url
        } catch {
            viewModel.deleteError = error.localizedDescription
        }
    }

    private func downloadContactTemplate() {
        let csv = ExportService.contactCSVTemplate()
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("contacts_template.csv")
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            contactShareURL = url
        } catch {
            viewModel.deleteError = error.localizedDescription
        }
    }

    private func handleContactCSVImport(_ result: Result<[URL], Error>) {
        switch result {
        case let .success(urls):
            guard let url = urls.first else { return }
            let didStartAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if didStartAccessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            do {
                let content = try String(contentsOf: url, encoding: .utf8)
                let previewResult = ExportService.previewContactCSV(
                    content: content,
                    sourceFileName: url.lastPathComponent
                )
                contactImportPreviewViewModel = ContactImportPreviewViewModel(previewResult: previewResult)
                showContactImportPreview = true
            } catch {
                viewModel.deleteError = error.localizedDescription
            }
        case let .failure(error):
            viewModel.deleteError = error.localizedDescription
        }
    }

    private func handleCompletedContactImport(_ result: ContactImportResult) {
        showContactImportPreview = false
        contactImportResult = result
        loadContacts()
    }

    private func cleanUpTempFile(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    @ViewBuilder
    private func contactSheet(for route: SheetRoute) -> some View {
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
}

private struct SelectedContactRoute: Identifiable, Hashable {
    let id: PersistentIdentifier
}
