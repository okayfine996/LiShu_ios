import SwiftUI
import SwiftData

private struct FestivalManagementItem: Identifiable {
    let definition: TraditionalFestivalDefinition
    let occurrence: TraditionalFestivalOccurrence?
    let isReminderEnabled: Bool
    let useDefaultRecipients: Bool
    let recipientCount: Int

    var id: String { definition.id }

    var configurationRoute: FestivalConfigurationRouteData {
        FestivalConfigurationRouteData(
            festivalID: definition.id,
            festivalName: definition.localizedName,
            isBuiltIn: definition.isBuiltIn
        )
    }
}

struct FestivalManagementView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Contact.createdAt) private var contacts: [Contact]
    @Query(sort: \CustomFestival.createdAt) private var customFestivals: [CustomFestival]
    @Query private var preferences: [FestivalReminderPreference]

    private let customFestivalService = CustomFestivalService()
    private let preferenceStore = FestivalPreferenceStore()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                summaryCard
                festivalListSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(DesignSystem.Colors.bgPage)
        .navigationTitle(String(localized: "festival.management.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: AppRoute.addCustomFestival) {
                    Image(systemName: "plus")
                        .foregroundStyle(DesignSystem.Colors.primary)
                }
                .accessibilityIdentifier("festival.management.addButton")
            }
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "festival.management.defaultRecipients"))
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Text(
                String(
                    format: String(localized: "festival.management.defaultRecipientsSummary"),
                    Int64(defaultRecipients.count)
                )
            )
            .font(DesignSystem.Typography.body)
            .foregroundStyle(DesignSystem.Colors.textSecondary)

            Text(String(localized: "festival.management.defaultRecipientsHint"))
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(DesignSystem.Colors.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
    }

    private var festivalListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "festival.management.listTitle"))
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            VStack(spacing: 0) {
                ForEach(Array(festivalItems.enumerated()), id: \.element.id) { index, item in
                    VStack(spacing: 0) {
                        HStack(alignment: .top, spacing: 12) {
                            NavigationLink(value: AppRoute.festivalRecipientSettings(item.configurationRoute)) {
                                festivalRow(item)
                            }
                            .buttonStyle(.plain)

                            Toggle("", isOn: Binding(
                                get: { item.isReminderEnabled },
                                set: { updateReminderEnabled(for: item, isEnabled: $0) }
                            ))
                            .labelsHidden()
                            .tint(DesignSystem.Colors.primary)
                            .padding(.top, 10)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)

                        if index < festivalItems.count - 1 {
                            Divider()
                                .background(DesignSystem.Colors.separator)
                                .padding(.leading, 16)
                        }
                    }
                }
            }
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        }
    }

    private func festivalRow(_ item: FestivalManagementItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(item.definition.localizedName)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .fontWeight(.semibold)

                Text(item.definition.isBuiltIn ? String(localized: "festival.management.builtIn") : String(localized: "festival.management.custom"))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(item.definition.isBuiltIn ? DesignSystem.Colors.primary : DesignSystem.Colors.accentGold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(DesignSystem.Colors.bgTag)
                    .clipShape(Capsule())
            }

            if let occurrence = item.occurrence {
                Text(formatDate(occurrence.date))
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }

            Text(recipientSummary(for: item))
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var defaultRecipients: [Contact] {
        contacts.filter { $0.isFestivalReminderRecipient }
    }

    private var festivalItems: [FestivalManagementItem] {
        let definitions = customFestivalService.allDefinitions(customFestivals: customFestivals)
        let calendarService = FestivalCalendarService(definitions: definitions)
        let occurrences = Dictionary(
            uniqueKeysWithValues: calendarService.allUpcomingFestivals().map { ($0.definition.id, $0) }
        )

        return definitions
            .map { definition in
                let preference = preferenceStore.preference(for: definition.id, in: preferences)
                let customFestival = customFestivals.first { $0.identifier == definition.id }
                let reminderEnabled = if definition.isBuiltIn {
                    preference?.isReminderEnabled ?? true
                } else {
                    (customFestival?.isEnabled ?? false) && (preference?.isReminderEnabled ?? true)
                }

                let useDefaultRecipients = preference?.useDefaultRecipients ?? true
                let recipientCount = useDefaultRecipients
                    ? defaultRecipients.count
                    : preference?.recipientContactIDs.count ?? 0

                return FestivalManagementItem(
                    definition: definition,
                    occurrence: occurrences[definition.id],
                    isReminderEnabled: reminderEnabled,
                    useDefaultRecipients: useDefaultRecipients,
                    recipientCount: recipientCount
                )
            }
            .sorted { lhs, rhs in
                switch (lhs.occurrence?.date, rhs.occurrence?.date) {
                case let (left?, right?):
                    if left == right {
                        return lhs.definition.sortPriority < rhs.definition.sortPriority
                    }
                    return left < right
                case (.some, .none):
                    return true
                case (.none, .some):
                    return false
                case (.none, .none):
                    return lhs.definition.sortPriority < rhs.definition.sortPriority
                }
            }
    }

    private func updateReminderEnabled(for item: FestivalManagementItem, isEnabled: Bool) {
        if let customFestival = customFestivals.first(where: { $0.identifier == item.definition.id }) {
            customFestival.isEnabled = isEnabled
        }

        let existing = preferenceStore.preference(for: item.definition.id, in: preferences)
        let useDefaultRecipients = existing?.useDefaultRecipients ?? true
        let recipientIDs = existing?.recipientContactIDs ?? []
        preferenceStore.upsertPreference(
            festivalID: item.definition.id,
            preferences: preferences,
            context: modelContext,
            isReminderEnabled: isEnabled,
            useDefaultRecipients: useDefaultRecipients,
            recipientContactIDs: recipientIDs
        )

        persistChanges()
    }

    private func persistChanges() {
        do {
            try modelContext.save()
            NotificationManager.shared.rescheduleAll(context: modelContext)
        } catch { }
    }

    private func recipientSummary(for item: FestivalManagementItem) -> String {
        if item.useDefaultRecipients {
            return String(
                format: String(localized: "festival.management.recipientDefaultSummary"),
                Int64(item.recipientCount)
            )
        }

        return String(
            format: String(localized: "festival.management.recipientOverrideSummary"),
            Int64(item.recipientCount)
        )
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh-Hans")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        FestivalManagementView()
    }
    .modelContainer(for: [Contact.self, CustomFestival.self, FestivalReminderPreference.self], inMemory: true)
}
