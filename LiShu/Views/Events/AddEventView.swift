import PhotosUI
import SwiftData
import SwiftUI

struct AddEventView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = AddEventViewModel()
    @State private var selectedCoverItem: PhotosPickerItem?
    @State private var showAddContactSheet = false
    @State private var contactIDsBeforeAdd: Set<PersistentIdentifier> = []
    @Query(sort: \Contact.name) private var contacts: [Contact]

    var eventID: PersistentIdentifier?
    var defaultHostMode: EventHostMode

    init(eventID: PersistentIdentifier? = nil, defaultHostMode: EventHostMode = .guest) {
        self.eventID = eventID
        self.defaultHostMode = defaultHostMode
    }

    private var navigationTitleText: String {
        if viewModel.editingEvent != nil {
            return String(localized: "event.edit.title")
        }

        return defaultHostMode == .host
            ? String(localized: "event.ledger.add.title")
            : String(localized: "event.add.title")
    }

    private var screenName: String {
        eventID == nil ? "events.add" : "events.edit"
    }

    var body: some View {
        AddEventFormView(
            viewModel: viewModel,
            selectedCoverItem: $selectedCoverItem,
            screenName: screenName,
            navigationTitleText: navigationTitleText,
            contacts: contacts,
            onSave: saveEvent,
            onCreateContact: openAddContact
        )
        .background(DesignSystem.Colors.bgPage)
        .navigationTitle(navigationTitleText)
        .navigationBarTitleDisplayMode(.inline)
        .sheetCancelButton(action: cancel)
        .trackScreen(screenName)
        .onAppear(perform: configureInitialState)
        .onChange(of: selectedCoverItem) { _, newValue in
            Task {
                await loadCoverImage(from: newValue)
            }
        }
        .sheet(isPresented: $showAddContactSheet, onDismiss: refreshContactsAfterAdd) {
            NavigationStack {
                AddContactView()
            }
        }
    }

    private func configureInitialState() {
        if let eventID, let event = modelContext.model(for: eventID) as? Event {
            viewModel.configure(with: event)
            return
        }

        if viewModel.name.isEmpty, viewModel.location.isEmpty, viewModel.note.isEmpty {
            viewModel.hostMode = defaultHostMode
        }
    }

    private func loadCoverImage(from item: PhotosPickerItem?) async {
        guard
            let data = try? await item?.loadTransferable(type: Data.self),
            !data.isEmpty,
            let optimized = ImagePipeline.optimizedJPEGData(
                from: data,
                maxPixelSize: ImagePipeline.Preset.eventCoverMaxPixelSize,
                compressionQuality: 0.84
            )
        else {
            return
        }

        await MainActor.run {
            viewModel.coverImageData = optimized
        }
    }

    private func cancel() {
        InteractionLogger.tap(screen: screenName, target: "events.editor.cancel")
        dismiss()
    }

    private func saveEvent() {
        if viewModel.save(context: modelContext) {
            InteractionLogger.submit(
                screen: screenName,
                target: "events.editor.save",
                action: .save,
                result: "success",
                metadata: ["event_name": viewModel.name.trimmingCharacters(in: .whitespacesAndNewlines)]
            )
            dismiss()
            return
        }

        InteractionLogger.submit(
            screen: screenName,
            target: "events.editor.save",
            action: .save,
            result: "failed",
            reason: "validation_or_persistence"
        )
    }

    private func openAddContact() {
        contactIDsBeforeAdd = Set(contacts.map(\.persistentModelID))
        showAddContactSheet = true
    }

    private func refreshContactsAfterAdd() {
        let newContacts = contacts.filter { !contactIDsBeforeAdd.contains($0.persistentModelID) }
        if let newContact = newContacts.first {
            viewModel.primaryContact = newContact
        }
        contactIDsBeforeAdd = []
    }
}
