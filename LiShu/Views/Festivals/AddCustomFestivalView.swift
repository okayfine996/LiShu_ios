import SwiftUI
import SwiftData

struct AddCustomFestivalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Contact.createdAt) private var contacts: [Contact]
    @Query private var preferences: [FestivalReminderPreference]

    @State private var viewModel = AddCustomFestivalViewModel()

    var body: some View {
        ZStack(alignment: .bottom) {
            DesignSystem.Colors.bgPage
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    basicInfoSection
                    reminderSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .padding(.bottom, 96)
            }

            saveButton
        }
        .navigationTitle(String(localized: "festival.custom.addTitle"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(String(localized: "common.cancel")) {
                    dismiss()
                }
                .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
        }
        .alert(
            String(localized: "festival.custom.validationTitle"),
            isPresented: $viewModel.showValidationAlert
        ) {
            Button(String(localized: "common.ok"), role: .cancel) { }
        } message: {
            Text(String(localized: "festival.custom.validationMessage"))
        }
    }

    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(String(localized: "festival.custom.basicInfo"))

            VStack(alignment: .leading, spacing: 8) {
                fieldLabel(String(localized: "festival.custom.name"))
                TextField(
                    String(localized: "festival.custom.namePlaceholder"),
                    text: $viewModel.name
                )
                .textFieldStyle(StandardTextFieldStyle())
            }

            VStack(alignment: .leading, spacing: 8) {
                fieldLabel(String(localized: "festival.custom.calendarType"))
                Picker("", selection: $viewModel.calendarType) {
                    Text(String(localized: "festival.calendar.lunar")).tag(FestivalCalendarType.lunar)
                    Text(String(localized: "festival.calendar.solar")).tag(FestivalCalendarType.solar)
                }
                .pickerStyle(.segmented)
            }

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    fieldLabel(String(localized: "festival.custom.month"))
                    Picker("", selection: $viewModel.month) {
                        ForEach(Array(viewModel.monthRange), id: \.self) { month in
                            Text(String(format: String(localized: "festival.custom.monthValue"), Int64(month)))
                                .tag(month)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(DesignSystem.Colors.bgSurface)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.Radius.input)
                            .stroke(DesignSystem.Colors.border, lineWidth: 1)
                    )
                }

                VStack(alignment: .leading, spacing: 8) {
                    fieldLabel(String(localized: "festival.custom.day"))
                    Picker("", selection: $viewModel.day) {
                        ForEach(Array(viewModel.dayRange), id: \.self) { day in
                            Text(String(format: String(localized: "festival.custom.dayValue"), Int64(day)))
                                .tag(day)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(DesignSystem.Colors.bgSurface)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.Radius.input)
                            .stroke(DesignSystem.Colors.border, lineWidth: 1)
                    )
                }
            }
        }
    }

    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(String(localized: "festival.custom.reminder"))

            toggleCard(
                title: String(localized: "festival.custom.enableReminder"),
                subtitle: String(localized: "festival.custom.enableReminderHint"),
                isOn: $viewModel.isReminderEnabled
            )

            toggleCard(
                title: String(localized: "festival.custom.useDefaultRecipients"),
                subtitle: String(localized: "festival.custom.useDefaultRecipientsHint"),
                isOn: $viewModel.useDefaultRecipients
            )

            if !viewModel.useDefaultRecipients {
                VStack(alignment: .leading, spacing: 8) {
                    fieldLabel(String(localized: "festival.custom.recipients"))

                    if contacts.isEmpty {
                        infoCard(String(localized: "festival.custom.noContacts"))
                    } else {
                        VStack(spacing: 0) {
                            ForEach(Array(contacts.enumerated()), id: \.element.persistentModelID) { index, contact in
                                Button {
                                    toggleRecipient(contact.identifier)
                                } label: {
                                    HStack(spacing: 12) {
                                        AvatarView(imageData: contact.avatar, name: contact.name, size: 40)

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(contact.name)
                                                .font(DesignSystem.Typography.body)
                                                .foregroundStyle(DesignSystem.Colors.textPrimary)

                                            Text(contact.relation.isEmpty ? String(localized: "common.unknown") : contact.relation)
                                                .font(DesignSystem.Typography.small)
                                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                                        }

                                        Spacer()

                                        Image(systemName: viewModel.selectedContactIDs.contains(contact.identifier) ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(
                                                viewModel.selectedContactIDs.contains(contact.identifier)
                                                    ? DesignSystem.Colors.primary
                                                    : DesignSystem.Colors.textTertiary
                                            )
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)

                                if index < contacts.count - 1 {
                                    Divider()
                                        .background(DesignSystem.Colors.separator)
                                        .padding(.leading, 68)
                                }
                            }
                        }
                        .background(DesignSystem.Colors.bgSurface)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
                    }
                }
            }
        }
    }

    private var saveButton: some View {
        Button {
            if viewModel.save(context: modelContext, preferences: preferences) {
                dismiss()
            }
        } label: {
            Text(String(localized: "common.save"))
        }
        .buttonStyle(PrimaryButtonStyle())
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .background(
            LinearGradient(
                colors: [DesignSystem.Colors.bgPage.opacity(0), DesignSystem.Colors.bgPage],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }

    private func toggleRecipient(_ identifier: String) {
        if viewModel.selectedContactIDs.contains(identifier) {
            viewModel.selectedContactIDs.remove(identifier)
        } else {
            viewModel.selectedContactIDs.insert(identifier)
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(DesignSystem.Typography.title3)
            .foregroundStyle(DesignSystem.Colors.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func fieldLabel(_ title: String) -> some View {
        Text(title)
            .font(DesignSystem.Typography.caption)
            .foregroundStyle(DesignSystem.Colors.textSecondary)
    }

    private func toggleCard(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Text(subtitle)
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
        }
        .tint(DesignSystem.Colors.primary)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
    }

    private func infoCard(_ text: String) -> some View {
        Text(text)
            .font(DesignSystem.Typography.caption)
            .foregroundStyle(DesignSystem.Colors.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
    }
}

#Preview {
    NavigationStack {
        AddCustomFestivalView()
    }
    .modelContainer(for: [Contact.self, CustomFestival.self, FestivalReminderPreference.self], inMemory: true)
}
