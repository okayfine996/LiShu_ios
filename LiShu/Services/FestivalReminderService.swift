import Foundation

struct FestivalReminderService {
    private let calendarService: FestivalCalendarService
    private let calendar: Calendar
    private let now: () -> Date

    init(
        calendarService: FestivalCalendarService = FestivalCalendarService(),
        calendar: Calendar = .current,
        now: @escaping () -> Date = Date.init
    ) {
        self.calendarService = calendarService
        self.calendar = calendar
        self.now = now
    }

    func makeReminderPayloads(
        contacts: [Contact],
        preferences: [FestivalReminderPreference]
    ) -> [FestivalReminderPayload] {
        return calendarService.allUpcomingFestivals().compactMap { occurrence in
            guard let reminderDate = reminderDate(for: occurrence.date) else { return nil }

            let resolution = resolveRecipients(
                for: occurrence.definition.id,
                contacts: contacts,
                preferences: preferences
            )
            let names = resolution.contacts.map(\.name)
            let displayNames = Array(names.prefix(3))
            let remainingCount = max(names.count - displayNames.count, 0)

            return FestivalReminderPayload(
                festivalID: occurrence.definition.id,
                festivalName: occurrence.name,
                occurrenceDate: occurrence.date,
                reminderDate: reminderDate,
                recipientContactIDs: resolution.contacts.map(\.identifier),
                recipientContext: resolution.context,
                contactNames: names,
                displayNames: displayNames,
                remainingCount: remainingCount,
                bodyText: makeReminderBody(
                    festivalName: occurrence.name,
                    displayNames: displayNames,
                    remainingCount: remainingCount
                )
            )
        }
    }

    func makeEventPrefill(from occurrence: TraditionalFestivalOccurrence) -> FestivalEventPrefill {
        FestivalEventPrefill(
            name: occurrence.name,
            eventType: occurrence.eventType,
            date: occurrence.date
        )
    }

    func defaultRecipients(from contacts: [Contact]) -> [Contact] {
        contacts
            .filter { contact in
                let trimmedName = contact.name.trimmingCharacters(in: .whitespacesAndNewlines)
                return !trimmedName.isEmpty && contact.isFestivalReminderRecipient
            }
            .sorted(by: sortContacts)
    }

    func resolveRecipients(
        for festivalID: String,
        contacts: [Contact],
        preferences: [FestivalReminderPreference]
    ) -> (contacts: [Contact], context: FestivalRecipientContext) {
        guard let preference = preferences.first(where: { $0.festivalID == festivalID }) else {
            return (defaultRecipients(from: contacts), .defaultRecipients)
        }

        if preference.useDefaultRecipients {
            return (defaultRecipients(from: contacts), .defaultRecipients)
        }

        let selectedIDs = Set(preference.recipientContactIDs)
        let matched = contacts
            .filter { selectedIDs.contains($0.identifier) }
            .sorted(by: sortContacts)
        return (matched, .festivalOverride)
    }

    func reminderDate(for occurrenceDate: Date) -> Date? {
        let startOfOccurrence = calendar.startOfDay(for: occurrenceDate)
        return calendar.date(byAdding: .day, value: -1, to: startOfOccurrence)
    }

    func makeReminderBody(festivalName: String, displayNames: [String], remainingCount: Int) -> String {
        if displayNames.isEmpty {
            return String(
                format: String(localized: "notification.festival.body.generic"),
                festivalName
            )
        }

        let displayText = if remainingCount > 0 {
            displayNames.joined(separator: "、") + String(
                format: String(localized: "notification.festival.moreContacts"),
                remainingCount
            )
        } else {
            displayNames.joined(separator: "、")
        }

        return String(
            format: String(localized: "notification.festival.body.contacts"),
            festivalName,
            displayText
        )
    }

    private func sortContacts(_ lhs: Contact, _ rhs: Contact) -> Bool {
        if lhs.circle == rhs.circle {
            if lhs.createdAt == rhs.createdAt {
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
            return lhs.createdAt < rhs.createdAt
        }
        return lhs.circle < rhs.circle
    }
}
