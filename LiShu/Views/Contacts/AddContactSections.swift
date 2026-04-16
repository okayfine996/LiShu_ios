import SwiftUI

struct AddContactEditorContent: View {
    @Binding var avatar: Data?
    @Binding var name: String
    @Binding var selectedCategory: RelationshipCategory?
    @Binding var selectedTag: String
    @Binding var birthday: Date
    @Binding var hasBirthday: Bool
    @Binding var phone: String
    @Binding var location: String
    @Binding var note: String

    let screenName: String
    let onBirthdayToggle: () -> Void
    let onImportContacts: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                AddContactAvatarSection(avatar: $avatar, name: name)
                AddContactFormSection(
                    name: $name,
                    selectedCategory: $selectedCategory,
                    selectedTag: $selectedTag,
                    birthday: $birthday,
                    hasBirthday: $hasBirthday,
                    phone: $phone,
                    location: $location,
                    note: $note,
                    onBirthdayToggle: onBirthdayToggle,
                    onImportContacts: onImportContacts
                )
            }
            .padding(.vertical, 16)
            .padding(.bottom, 80)
        }
    }
}

private struct AddContactAvatarSection: View {
    @Binding var avatar: Data?
    let name: String

    var body: some View {
        HStack {
            Spacer()
            AvatarImagePicker(imageData: $avatar, name: name)
            Spacer()
        }
    }
}

private struct AddContactFormSection: View {
    @Binding var name: String
    @Binding var selectedCategory: RelationshipCategory?
    @Binding var selectedTag: String
    @Binding var birthday: Date
    @Binding var hasBirthday: Bool
    @Binding var phone: String
    @Binding var location: String
    @Binding var note: String

    let onBirthdayToggle: () -> Void
    let onImportContacts: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            AddContactField(label: String(localized: "contact.add.name")) {
                TextField(
                    String(localized: "contact.add.namePlaceholder"),
                    text: $name
                )
                .textFieldStyle(StandardTextFieldStyle())
                .accessibilityIdentifier("contact.add.nameField")
            }

            AddContactField(label: String(localized: "contact.add.relation")) {
                RelationTagPicker(
                    selectedCategory: $selectedCategory,
                    selectedTag: $selectedTag
                )
            }

            AddContactBirthdayField(
                birthday: $birthday,
                hasBirthday: $hasBirthday,
                onToggle: onBirthdayToggle
            )

            AddContactPhoneField(
                phone: $phone,
                onImportContacts: onImportContacts
            )

            AddContactField(label: String(localized: "contact.add.location")) {
                TextField(
                    String(localized: "contact.add.locationPlaceholder"),
                    text: $location
                )
                .textFieldStyle(StandardTextFieldStyle())
                .accessibilityIdentifier("contact.add.locationField")
            }

            AddContactNotesField(note: $note)
        }
        .padding(.horizontal, 16)
    }
}

private struct AddContactField<Content: View>: View {
    let label: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            content
        }
    }
}

private struct AddContactBirthdayField: View {
    @Binding var birthday: Date
    @Binding var hasBirthday: Bool

    let onToggle: () -> Void

    var body: some View {
        AddContactField(label: String(localized: "contact.add.birthday")) {
            HStack {
                if hasBirthday {
                    DatePicker(
                        "",
                        selection: $birthday,
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    .tint(DesignSystem.Colors.primary)
                } else {
                    Text(String(localized: "contact.add.birthdayPlaceholder"))
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }

                Spacer()

                Button(action: onToggle) {
                    Image(systemName: "calendar")
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(
                            hasBirthday
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
}

private struct AddContactPhoneField: View {
    @Binding var phone: String
    let onImportContacts: () -> Void

    var body: some View {
        AddContactField(label: String(localized: "contact.add.phone")) {
            HStack {
                Spacer()

                Button(action: onImportContacts) {
                    HStack(spacing: 4) {
                        Image(systemName: "person.crop.rectangle")
                            .font(DesignSystem.Typography.small)
                        Text(String(localized: "contact.add.importFromContacts"))
                            .font(DesignSystem.Typography.small)
                    }
                    .foregroundStyle(DesignSystem.Colors.primary)
                }
            }

            TextField(
                String(localized: "contact.add.phonePlaceholder"),
                text: $phone
            )
            .textFieldStyle(StandardTextFieldStyle())
            .keyboardType(.phonePad)
        }
    }
}

private struct AddContactNotesField: View {
    @Binding var note: String

    var body: some View {
        AddContactField(label: String(localized: "contact.add.notes")) {
            TextEditor(text: $note)
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
                    if note.isEmpty {
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
}

struct AddContactSaveBar: View {
    let action: () -> Void

    var body: some View {
        Button(String(localized: "contact.add.saveContact"), action: action)
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
