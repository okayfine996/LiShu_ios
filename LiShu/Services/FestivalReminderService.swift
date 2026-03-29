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

    func makeReminderPayloads(contacts: [Contact]) -> [FestivalReminderPayload] {
        let matchedContacts = matchedCloseContacts(from: contacts)
        let names = matchedContacts.map(\.name)
        let displayNames = Array(names.prefix(3))
        let remainingCount = max(names.count - displayNames.count, 0)

        return calendarService.allUpcomingFestivals().compactMap { occurrence in
            guard let reminderDate = reminderDate(for: occurrence.date) else { return nil }
            return FestivalReminderPayload(
                festivalID: occurrence.definition.id,
                festivalName: occurrence.name,
                occurrenceDate: occurrence.date,
                reminderDate: reminderDate,
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

    func matchedCloseContacts(from contacts: [Contact]) -> [Contact] {
        contacts
            .filter { contact in
                let trimmedName = contact.name.trimmingCharacters(in: .whitespacesAndNewlines)
                let isCloseCategory = contact.category == RelationshipCategory.family.rawValue
                    || contact.category == RelationshipCategory.relative.rawValue
                return !trimmedName.isEmpty && isCloseCategory
            }
            .sorted { lhs, rhs in
                if lhs.circle == rhs.circle {
                    if lhs.createdAt == rhs.createdAt {
                        return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
                    }
                    return lhs.createdAt < rhs.createdAt
                }
                return lhs.circle < rhs.circle
            }
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
}
