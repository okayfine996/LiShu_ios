import SwiftData
import SwiftUI

struct AddContactView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = AddContactViewModel()
    @State private var showProSheet = false
    @State private var showContactPicker = false

    var contactID: PersistentIdentifier?

    init(contactID: PersistentIdentifier? = nil) {
        self.contactID = contactID
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            DesignSystem.Colors.bgPage
                .ignoresSafeArea()

            AddContactEditorContent(
                avatar: $viewModel.avatar,
                name: $viewModel.name,
                selectedCategory: $viewModel.selectedCategory,
                selectedTag: $viewModel.selectedTag,
                birthdayDate: $viewModel.birthdayDate,
                hasBirthday: $viewModel.hasBirthday,
                birthdayIsLunar: $viewModel.birthdayIsLunar,
                birthdayReminderEnabled: $viewModel.birthdayReminderEnabled,
                phone: $viewModel.phone,
                location: $viewModel.location,
                note: $viewModel.note,
                screenName: screenName,
                onImportContacts: showContactsPicker
            )

            AddContactSaveBar(action: saveContact)
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .trackScreen(screenName)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(String(localized: "common.cancel"), action: cancel)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .accessibilityIdentifier("contact.add.cancelButton")
            }
        }
        .onAppear(perform: configureIfNeeded)
        .alert(
            String(localized: "contact.add.validationTitle"),
            isPresented: $viewModel.showValidationAlert
        ) {
            Button(String(localized: "common.confirm"), role: .cancel) {}
        } message: {
            Text(String(localized: "contact.add.validationMessage"))
        }
        .sheet(isPresented: $showProSheet, onDismiss: { viewModel.needsProUpgrade = false }) {
            NavigationStack {
                ProMembershipView()
                    .environment(SubscriptionManager.shared)
            }
        }
        .onChange(of: showProSheet) { oldValue, newValue in
            handleProSheetChange(oldValue, newValue)
        }
        .sheet(isPresented: $showContactPicker) {
            ContactPickerView(
                onSelect: { name, phone in
                    viewModel.name = name
                    viewModel.phone = phone
                    showContactPicker = false
                },
                onCancel: { showContactPicker = false }
            )
        }
        .onChange(of: showContactPicker) { oldValue, newValue in
            handleContactPickerChange(oldValue, newValue)
        }
        .onChange(of: viewModel.hasBirthday) { _, isOn in
            InteractionLogger.toggle(
                screen: screenName,
                target: "contacts.editor.birthday",
                isOn: isOn
            )
        }
    }

    private var screenName: String {
        contactID == nil ? "contacts.add" : "contacts.edit"
    }

    private var navigationTitle: String {
        viewModel.editingContact != nil
            ? String(localized: "contact.edit.title")
            : String(localized: "contact.add.title")
    }

    private func configureIfNeeded() {
        guard let contactID, let contact = modelContext.model(for: contactID) as? Contact else { return }
        viewModel.configure(with: contact)
    }

    private func cancel() {
        InteractionLogger.tap(
            screen: screenName,
            target: "contacts.editor.cancel"
        )
        dismiss()
    }

    private func showContactsPicker() {
        InteractionLogger.tap(
            screen: screenName,
            target: "contacts.editor.importPhone",
            route: "sheet.contacts.picker",
            presentation: .sheet
        )
        showContactPicker = true
    }

    private func saveContact() {
        if viewModel.saveContact(context: modelContext) {
            InteractionLogger.submit(
                screen: screenName,
                target: "contacts.editor.save",
                action: .save,
                result: "success",
                metadata: ["contact_name": viewModel.name.trimmingCharacters(in: .whitespacesAndNewlines)]
            )
            if viewModel.editingContact == nil {
                AdManager.shared.scheduleNativeAd()
            }
            dismiss()
        } else if viewModel.needsProUpgrade {
            InteractionLogger.submit(
                screen: screenName,
                target: "contacts.editor.save",
                action: .save,
                result: "blocked",
                reason: "subscription_limit"
            )
            showProSheet = true
        } else {
            InteractionLogger.submit(
                screen: screenName,
                target: "contacts.editor.save",
                action: .save,
                result: "failed",
                reason: viewModel.showValidationAlert ? "validation" : "persistence"
            )
        }
    }

    private func handleProSheetChange(_: Bool, _ newValue: Bool) {
        InteractionLogger.sheetPresentation(
            screen: screenName,
            route: "sheet.settings.proMembership",
            isPresented: newValue
        )
    }

    private func handleContactPickerChange(_: Bool, _ newValue: Bool) {
        InteractionLogger.sheetPresentation(
            screen: screenName,
            route: "sheet.contacts.picker",
            isPresented: newValue
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AddContactView()
    }
    .modelContainer(for: [Contact.self, Record.self, Event.self], inMemory: true)
}
