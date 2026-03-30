import SwiftUI
import SwiftData

struct FestivalReminderDetailView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Contact.createdAt) private var contacts: [Contact]
    @Query(sort: \CustomFestival.createdAt) private var customFestivals: [CustomFestival]
    @Query private var preferences: [FestivalReminderPreference]

    let route: FestivalReminderRouteData

    @State private var recentRecords: [Record] = []
    @State private var sheetRoute: SheetRoute?

    private let customFestivalService = CustomFestivalService()
    private let reminderService = FestivalReminderService()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                headerCard
                recipientSection
                actionSection
                infoSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(DesignSystem.Colors.bgPage)
        .navigationTitle(String(localized: "festival.detail.title"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadRecentRecords)
        .sheet(item: $sheetRoute) { route in
            switch route {
            case .addFestivalEvent(let prefill):
                NavigationStack {
                    AddEventView(prefill: prefill)
                }
            default:
                EmptyView()
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(occurrence.name)
                        .font(DesignSystem.Typography.title2)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    Text(formatDate(occurrence.date))
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }

                Spacer()

                Text(occurrence.definition.isBuiltIn ? String(localized: "festival.management.builtIn") : String(localized: "festival.management.custom"))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(occurrence.definition.isBuiltIn ? DesignSystem.Colors.primary : DesignSystem.Colors.accentGold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(DesignSystem.Colors.bgTag)
                    .clipShape(Capsule())
            }

            Text(countdownText(for: occurrence.daysRemaining))
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.primary)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(DesignSystem.Colors.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
    }

    private var recipientSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "festival.detail.recipients"))
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            if resolvedRecipients.contacts.isEmpty {
                infoCard(String(localized: "festival.detail.noRecipients"))
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(resolvedRecipients.contacts.enumerated()), id: \.element.persistentModelID) { index, contact in
                        NavigationLink {
                            ContactDetailView(contactID: contact.persistentModelID)
                        } label: {
                            recipientRow(contact)
                        }
                        .buttonStyle(.plain)

                        if index < resolvedRecipients.contacts.count - 1 {
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

    private func recipientRow(_ contact: Contact) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                AvatarView(imageData: contact.avatar, name: contact.name, size: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(contact.name)
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                        .fontWeight(.semibold)

                    Text(contact.relation.isEmpty ? String(localized: "common.unknown") : contact.relation)
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }

            if let summary = recordSummary(for: contact.identifier) {
                Text(summary)
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                    .padding(.leading, 52)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private var actionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "festival.detail.actions"))
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            VStack(spacing: 12) {
                Button {
                    sheetRoute = .addFestivalEvent(
                        FestivalEventPrefill(
                            name: occurrence.name,
                            eventType: .festival,
                            date: occurrence.date
                        )
                    )
                } label: {
                    Text(String(localized: "festival.detail.createEvent"))
                }
                .buttonStyle(PrimaryButtonStyle())

                NavigationLink {
                    FestivalRecipientSettingsView(route: configurationRoute)
                } label: {
                    Text(String(localized: "festival.detail.adjustRecipients"))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "festival.detail.moreInfo"))
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            VStack(spacing: 0) {
                infoRow(
                    label: String(localized: "festival.detail.reminderTime"),
                    value: reminderTimeText
                )
                Divider()
                    .background(DesignSystem.Colors.separator)
                    .padding(.leading, 16)
                infoRow(
                    label: String(localized: "festival.detail.recipientMode"),
                    value: resolvedRecipients.context == .defaultRecipients
                        ? String(localized: "festival.detail.recipientModeDefault")
                        : String(localized: "festival.detail.recipientModeCustom")
                )
            }
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        }
    }

    private var configurationRoute: FestivalConfigurationRouteData {
        FestivalConfigurationRouteData(
            festivalID: occurrence.definition.id,
            festivalName: occurrence.name,
            isBuiltIn: occurrence.definition.isBuiltIn
        )
    }

    private var occurrence: TraditionalFestivalOccurrence {
        let definition = resolvedDefinition
        let calendarService = FestivalCalendarService(definitions: [definition])
        let daysRemaining = calendarService.daysRemaining(until: route.occurrenceDate, from: Date())
        return TraditionalFestivalOccurrence(
            definition: definition,
            name: route.festivalName,
            date: route.occurrenceDate,
            daysRemaining: daysRemaining
        )
    }

    private var resolvedDefinition: TraditionalFestivalDefinition {
        let definitions = customFestivalService.allDefinitions(customFestivals: customFestivals)
        if let matched = definitions.first(where: { $0.id == route.festivalID }) {
            return matched
        }

        let builtInIDs = Set(TraditionalFestivalDefinition.builtIn.map(\.id))
        return TraditionalFestivalDefinition(
            id: route.festivalID,
            nameKey: nil,
            customName: route.festivalName,
            rule: .solar(
                month: Calendar.current.component(.month, from: route.occurrenceDate),
                day: Calendar.current.component(.day, from: route.occurrenceDate)
            ),
            eventType: .festival,
            sortPriority: 999,
            source: builtInIDs.contains(route.festivalID) ? .builtIn : .custom
        )
    }

    private var resolvedRecipients: (contacts: [Contact], context: FestivalRecipientContext) {
        reminderService.resolveRecipients(
            for: route.festivalID,
            contacts: contacts,
            preferences: preferences
        )
    }

    private var reminderTimeText: String {
        let reminderDate = Calendar.current.date(byAdding: .day, value: -1, to: occurrence.date) ?? occurrence.date
        return "\(formatDate(reminderDate)) 09:00"
    }

    private func recordSummary(for contactIdentifier: String) -> String? {
        guard let record = recentRecords.first(where: { $0.contact?.identifier == contactIdentifier }) else {
            return nil
        }
        let eventName = record.event?.name ?? String(localized: "common.unknown")
        return String(
            format: String(localized: "festival.detail.latestRecord"),
            eventName,
            String(format: "%.0f", record.amount)
        )
    }

    private func loadRecentRecords() {
        let recipientIDs = Set(resolvedRecipients.contacts.map(\.identifier))
        guard !recipientIDs.isEmpty else {
            recentRecords = []
            return
        }

        var descriptor = FetchDescriptor<Record>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 20
        let fetched = (try? modelContext.fetch(descriptor)) ?? []
        recentRecords = fetched.filter { record in
            guard let contact = record.contact else { return false }
            return recipientIDs.contains(contact.identifier)
        }
    }

    private func countdownText(for daysRemaining: Int) -> String {
        switch daysRemaining {
        case 0:
            return String(localized: "festival.detail.today")
        case 1:
            return String(localized: "festival.detail.tomorrow")
        default:
            return String(
                format: String(localized: "festival.detail.daysRemaining"),
                Int64(daysRemaining)
            )
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh-Hans")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: date)
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

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Spacer()

            Text(value)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

#Preview {
    NavigationStack {
        FestivalReminderDetailView(
            route: FestivalReminderRouteData(
                festivalID: "spring-festival",
                festivalName: "春节",
                occurrenceDate: .now
            )
        )
    }
    .modelContainer(for: [Contact.self, Record.self, Event.self, CustomFestival.self, FestivalReminderPreference.self], inMemory: true)
}
