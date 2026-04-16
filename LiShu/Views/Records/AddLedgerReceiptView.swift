import PhotosUI
import SwiftData
import SwiftUI

struct AddLedgerReceiptView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel: AddLedgerReceiptViewModel
    @State private var showAddContactSheet = false
    @State private var showProSheet = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var contactIDsBeforeAddSheet: Set<PersistentIdentifier> = []
    @State private var continuousSaveMessage: String?

    init(eventID: PersistentIdentifier) {
        _viewModel = State(initialValue: AddLedgerReceiptViewModel(eventID: eventID))
    }

    var body: some View {
        AddLedgerReceiptFormView(
            viewModel: viewModel,
            selectedPhotoItems: $selectedPhotoItems,
            continuousSaveMessage: continuousSaveMessage,
            onCreateContact: openAddContact,
            onSaveAndContinue: { saveRecord(andContinue: true) }
        )
        .background(DesignSystem.Colors.bgPage)
        .navigationTitle(String(localized: "event.ledger.primaryAction"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .onAppear(perform: loadData)
        .onChange(of: selectedPhotoItems) { _, newItems in
            handleSelectedPhotoItems(newItems)
        }
        .sheet(isPresented: $showAddContactSheet, onDismiss: refreshContactsAfterAddSheet, content: makeAddContactSheet)
        .sheet(isPresented: $showProSheet, content: makeProSheet)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(action: dismiss.callAsFunction) {
                Image(systemName: "xmark")
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button(String(localized: "common.save")) {
                saveRecord(andContinue: false)
            }
            .foregroundStyle(viewModel.isValid ? DesignSystem.Colors.primary : DesignSystem.Colors.textTertiary)
            .disabled(!viewModel.isValid)
        }
    }

    private func makeAddContactSheet() -> some View {
        NavigationStack {
            AddContactView()
        }
    }

    private func makeProSheet() -> some View {
        NavigationStack {
            ProMembershipView()
                .environment(SubscriptionManager.shared)
        }
    }

    private func loadData() {
        viewModel.load(context: modelContext)
    }

    private func handleSelectedPhotoItems(_ items: [PhotosPickerItem]) {
        Task {
            var loaded: [NewRecordPhotoItem] = []
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self), !data.isEmpty,
                   let optimized = ImagePipeline.optimizedJPEGData(
                       from: data,
                       maxPixelSize: ImagePipeline.Preset.recordPhotoMaxPixelSize,
                       compressionQuality: 0.84
                   )
                {
                    loaded.append(NewRecordPhotoItem(id: UUID(), data: optimized))
                }
            }
            await MainActor.run {
                viewModel.newPhotoItems = loaded
            }
        }
    }

    private func openAddContact() {
        contactIDsBeforeAddSheet = Set(viewModel.allContacts.map(\.persistentModelID))
        showAddContactSheet = true
    }

    private func refreshContactsAfterAddSheet() {
        viewModel.reloadContacts(context: modelContext)
        let newContacts = viewModel.allContacts.filter { !contactIDsBeforeAddSheet.contains($0.persistentModelID) }
        if let newestContact = newContacts.max(by: { $0.createdAt < $1.createdAt }) {
            viewModel.selectedContact = newestContact
        }
        contactIDsBeforeAddSheet = []
    }

    private func saveRecord(andContinue: Bool) {
        if !SubscriptionManager.shared.canAddRecord(context: modelContext) {
            showProSheet = true
            return
        }

        if viewModel.save(context: modelContext) {
            guard andContinue else {
                dismiss()
                return
            }

            let contactName = viewModel.selectedContact?.name ?? ""
            let amount = viewModel.monetaryAmount
            if !contactName.isEmpty {
                continuousSaveMessage = String(
                    format: String(localized: "record.add.continueSuccess"),
                    contactName,
                    amount.isEmpty ? "0" : amount
                )
            }
            viewModel.resetForContinuousEntry()
            selectedPhotoItems = []
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(2))
                continuousSaveMessage = nil
            }
        }
    }
}

@MainActor
private func makeAddLedgerReceiptPreviewContainer() -> (ModelContainer, PersistentIdentifier)? {
    guard let container = try? ModelContainer(
        for: Contact.self, Record.self, Event.self, RecordPhoto.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    ) else {
        return nil
    }

    let context = container.mainContext
    let event = Event(name: "我的婚礼", type: .wedding, hostMode: .host, date: .now, location: "锦绣悦府")
    let contacts = [
        Contact(name: "陈明", relation: "同事"),
        Contact(name: "邓伟", relation: "朋友"),
        Contact(name: "何洁", relation: "亲戚"),
    ]

    context.insert(event)
    contacts.forEach { context.insert($0) }
    try? context.save()

    return (container, event.persistentModelID)
}

#Preview {
    if let (container, eventID) = makeAddLedgerReceiptPreviewContainer() {
        NavigationStack {
            AddLedgerReceiptView(eventID: eventID)
        }
        .modelContainer(container)
        .environment(SubscriptionManager.shared)
    } else {
        Text(String(localized: "common.preview.unavailable"))
    }
}
