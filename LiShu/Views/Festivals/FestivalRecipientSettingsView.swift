import SwiftUI
import SwiftData

struct FestivalRecipientSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Contact.createdAt) private var contacts: [Contact]
    @Query(sort: \CustomFestival.createdAt) private var customFestivals: [CustomFestival]
    @Query private var preferences: [FestivalReminderPreference]

    let route: FestivalConfigurationRouteData

    @State private var isReminderEnabled = true
    @State private var useDefaultRecipients = true
    @State private var selectedContactIDs: Set<String> = []

    private let preferenceStore = FestivalPreferenceStore()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                summarySection
                recipientSection
                if !route.isBuiltIn {
                    deleteSection
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(DesignSystem.Colors.bgPage)
        .navigationTitle(route.festivalName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(String(localized: "common.save")) {
                    saveSettings()
                }
                .foregroundStyle(DesignSystem.Colors.primary)
            }
        }
        .onAppear(perform: loadState)
    }

    private var summarySection: some View {
        VStack(spacing: 12) {
            toggleCard(
                title: String(localized: "festival.settings.enableReminder"),
                subtitle: String(localized: "festival.settings.enableReminderHint"),
                isOn: $isReminderEnabled
            )

            toggleCard(
                title: String(localized: "festival.settings.useDefaultRecipients"),
                subtitle: String(localized: "festival.settings.useDefaultRecipientsHint"),
                isOn: $useDefaultRecipients
            )
        }
    }

    @ViewBuilder
    private var recipientSection: some View {
        if useDefaultRecipients {
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "festival.settings.defaultRecipients"))
                    .font(DesignSystem.Typography.title3)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Text(
                    String(
                        format: String(localized: "festival.settings.defaultRecipientsSummary"),
                        Int64(defaultRecipients.count)
                    )
                )
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(DesignSystem.Colors.bgSurface)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
            }
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "festival.settings.customRecipients"))
                    .font(DesignSystem.Typography.title3)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

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

                                Image(systemName: selectedContactIDs.contains(contact.identifier) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(
                                        selectedContactIDs.contains(contact.identifier)
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

    private var deleteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "festival.settings.customActions"))
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Button(role: .destructive) {
                deleteCustomFestival()
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text(String(localized: "festival.settings.deleteCustomFestival"))
                }
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.destructive)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(DesignSystem.Colors.bgSurface)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
            }
            .buttonStyle(.plain)
        }
    }

    private var defaultRecipients: [Contact] {
        contacts.filter { $0.isFestivalReminderRecipient }
    }

    private func loadState() {
        let preference = preferenceStore.preference(for: route.festivalID, in: preferences)
        let customFestival = customFestivals.first { $0.identifier == route.festivalID }

        if route.isBuiltIn {
            isReminderEnabled = preference?.isReminderEnabled ?? true
        } else {
            isReminderEnabled = (customFestival?.isEnabled ?? true) && (preference?.isReminderEnabled ?? true)
        }

        useDefaultRecipients = preference?.useDefaultRecipients ?? true
        selectedContactIDs = Set(preference?.recipientContactIDs ?? [])
    }

    private func saveSettings() {
        if let customFestival = customFestivals.first(where: { $0.identifier == route.festivalID }) {
            customFestival.isEnabled = isReminderEnabled
        }

        preferenceStore.upsertPreference(
            festivalID: route.festivalID,
            preferences: preferences,
            context: modelContext,
            isReminderEnabled: isReminderEnabled,
            useDefaultRecipients: useDefaultRecipients,
            recipientContactIDs: Array(selectedContactIDs).sorted()
        )

        do {
            try modelContext.save()
            NotificationManager.shared.rescheduleAll(context: modelContext)
            dismiss()
        } catch { }
    }

    private func deleteCustomFestival() {
        guard let customFestival = customFestivals.first(where: { $0.identifier == route.festivalID }) else { return }
        if let preference = preferenceStore.preference(for: route.festivalID, in: preferences) {
            modelContext.delete(preference)
        }
        modelContext.delete(customFestival)

        do {
            try modelContext.save()
            NotificationManager.shared.rescheduleAll(context: modelContext)
            dismiss()
        } catch { }
    }

    private func toggleRecipient(_ identifier: String) {
        if selectedContactIDs.contains(identifier) {
            selectedContactIDs.remove(identifier)
        } else {
            selectedContactIDs.insert(identifier)
        }
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
}

#Preview {
    NavigationStack {
        FestivalRecipientSettingsView(
            route: FestivalConfigurationRouteData(
                festivalID: "spring-festival",
                festivalName: "春节",
                isBuiltIn: true
            )
        )
    }
    .modelContainer(for: [Contact.self, CustomFestival.self, FestivalReminderPreference.self], inMemory: true)
}
