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

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    avatarSection
                    formSection
                }
                .padding(.vertical, 16)
                .padding(.bottom, 80)
            }

            saveButton
        }
        .navigationTitle(viewModel.editingContact != nil ? String(localized: "contact.edit.title") : String(localized: "contact.add.title"))
        .navigationBarTitleDisplayMode(.inline)
        .trackScreen(contactID == nil ? "contacts.add" : "contacts.edit")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(String(localized: "common.cancel")) {
                    InteractionLogger.tap(
                        screen: contactID == nil ? "contacts.add" : "contacts.edit",
                        target: "contacts.editor.cancel"
                    )
                    dismiss()
                }
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .accessibilityIdentifier("contact.add.cancelButton")
            }
        }
        .onAppear {
            if let contactID, let contact = modelContext.model(for: contactID) as? Contact {
                viewModel.configure(with: contact)
            }
        }
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
        .onChange(of: showProSheet) { _, newValue in
            InteractionLogger.sheetPresentation(
                screen: contactID == nil ? "contacts.add" : "contacts.edit",
                route: "sheet.settings.proMembership",
                isPresented: newValue
            )
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
        .onChange(of: showContactPicker) { _, newValue in
            InteractionLogger.sheetPresentation(
                screen: contactID == nil ? "contacts.add" : "contacts.edit",
                route: "sheet.contacts.picker",
                isPresented: newValue
            )
        }
    }

    // MARK: - Avatar Section

    private var avatarSection: some View {
        HStack {
            Spacer()
            AvatarImagePicker(imageData: $viewModel.avatar, name: viewModel.name)
            Spacer()
        }
    }

    // MARK: - Form Section

    private var formSection: some View {
        VStack(spacing: 20) {
            nameField
            relationField
            birthdayField
            phoneField
            locationField
            notesField
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Name Field

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "contact.add.name"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            TextField(
                String(localized: "contact.add.namePlaceholder"),
                text: $viewModel.name
            )
            .textFieldStyle(StandardTextFieldStyle())
            .accessibilityIdentifier("contact.add.nameField")
        }
    }

    // MARK: - Relation Field

    private var relationField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "contact.add.relation"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            RelationTagPicker(
                selectedCategory: $viewModel.selectedCategory,
                selectedTag: $viewModel.selectedTag
            )
        }
    }

    // MARK: - Birthday Field

    private var birthdayField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "contact.add.birthday"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            HStack {
                if viewModel.hasBirthday {
                    DatePicker(
                        "",
                        selection: $viewModel.birthday,
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    .tint(DesignSystem.Colors.primary)
                } else {
                    Text("mm/dd/yyyy")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        viewModel.hasBirthday.toggle()
                    }
                    InteractionLogger.toggle(
                        screen: contactID == nil ? "contacts.add" : "contacts.edit",
                        target: "contacts.editor.birthday",
                        isOn: viewModel.hasBirthday
                    )
                } label: {
                    Image(systemName: "calendar")
                        .font(.system(size: 18))
                        .foregroundStyle(
                            viewModel.hasBirthday
                                ? DesignSystem.Colors.primary
                                : DesignSystem.Colors.textTertiary
                        )
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.input)
                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
            )
        }
    }

    // MARK: - Phone Field

    private var phoneField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(String(localized: "contact.add.phone"))
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                Spacer()

                Button {
                    InteractionLogger.tap(
                        screen: contactID == nil ? "contacts.add" : "contacts.edit",
                        target: "contacts.editor.importPhone",
                        route: "sheet.contacts.picker",
                        presentation: .sheet
                    )
                    showContactPicker = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "person.crop.rectangle")
                            .font(.system(size: 12))
                        Text(String(localized: "contact.add.importFromContacts"))
                            .font(DesignSystem.Typography.small)
                    }
                    .foregroundStyle(DesignSystem.Colors.primary)
                }
            }

            TextField(
                String(localized: "contact.add.phonePlaceholder"),
                text: $viewModel.phone
            )
            .textFieldStyle(StandardTextFieldStyle())
            .keyboardType(.phonePad)
        }
    }

    // MARK: - Location Field

    private var locationField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "contact.add.location"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            TextField(
                String(localized: "contact.add.locationPlaceholder"),
                text: $viewModel.location
            )
            .textFieldStyle(StandardTextFieldStyle())
            .accessibilityIdentifier("contact.add.locationField")
        }
    }

    // MARK: - Notes Field

    private var notesField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "contact.add.notes"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            TextEditor(text: $viewModel.note)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 80)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(DesignSystem.Colors.bgSurface)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.input)
                        .stroke(DesignSystem.Colors.border, lineWidth: 1)
                )
                .overlay(alignment: .topLeading) {
                    if viewModel.note.isEmpty {
                        Text(String(localized: "contact.add.notesPlaceholder"))
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            .allowsHitTesting(false)
                    }
                }
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            if viewModel.saveContact(context: modelContext) {
                InteractionLogger.submit(
                    screen: contactID == nil ? "contacts.add" : "contacts.edit",
                    target: "contacts.editor.save",
                    action: .save,
                    result: "success",
                    metadata: ["contact_name": viewModel.name.trimmingCharacters(in: .whitespacesAndNewlines)]
                )
                dismiss()
            } else if viewModel.needsProUpgrade {
                InteractionLogger.submit(
                    screen: contactID == nil ? "contacts.add" : "contacts.edit",
                    target: "contacts.editor.save",
                    action: .save,
                    result: "blocked",
                    reason: "subscription_limit"
                )
                showProSheet = true
            } else {
                InteractionLogger.submit(
                    screen: contactID == nil ? "contacts.add" : "contacts.edit",
                    target: "contacts.editor.save",
                    action: .save,
                    result: "failed",
                    reason: viewModel.showValidationAlert ? "validation" : "persistence"
                )
            }
        } label: {
            Text(String(localized: "contact.add.saveContact"))
        }
        .buttonStyle(PrimaryButtonStyle())
        .accessibilityIdentifier("contact.add.saveButton")
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .background(
            LinearGradient(
                colors: [
                    DesignSystem.Colors.bgPage.opacity(0),
                    DesignSystem.Colors.bgPage,
                ],
                startPoint: .top,
                endPoint: .init(x: 0.5, y: 0.3)
            )
            .ignoresSafeArea()
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
