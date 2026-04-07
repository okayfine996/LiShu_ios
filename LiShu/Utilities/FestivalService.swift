import Foundation
import SwiftData

@MainActor
enum FestivalService {
    struct BuiltinDefinition {
        let id: BuiltinFestivalID
        let recurrence: FestivalRecurrence
        let lunarMonth: Int?
        let lunarDay: Int?
        let sortOrder: Int
    }

    private static let gregorianCalendar = Calendar(identifier: .gregorian)
    private static let chineseCalendar = Calendar(identifier: .chinese)

    static let builtins: [BuiltinDefinition] = [
        BuiltinDefinition(id: .springFestival, recurrence: .annualLunar, lunarMonth: 1, lunarDay: 1, sortOrder: 0),
        BuiltinDefinition(id: .lanternFestival, recurrence: .annualLunar, lunarMonth: 1, lunarDay: 15, sortOrder: 1),
        BuiltinDefinition(id: .dragonBoatFestival, recurrence: .annualLunar, lunarMonth: 5, lunarDay: 5, sortOrder: 2),
        BuiltinDefinition(id: .qixiFestival, recurrence: .annualLunar, lunarMonth: 7, lunarDay: 7, sortOrder: 3),
        BuiltinDefinition(id: .midAutumnFestival, recurrence: .annualLunar, lunarMonth: 8, lunarDay: 15, sortOrder: 4),
        BuiltinDefinition(id: .doubleNinthFestival, recurrence: .annualLunar, lunarMonth: 9, lunarDay: 9, sortOrder: 5),
        BuiltinDefinition(id: .chineseNewYearsEve, recurrence: .annualLunar, lunarMonth: nil, lunarDay: nil, sortOrder: 6),
    ]

    static func builtInOccurrences(
        today: Date = .now,
        settings: AppSettings? = nil
    ) -> [FestivalOccurrence] {
        let resolvedSettings = settings ?? AppSettings.shared
        return builtins.compactMap { definition in
            occurrence(for: definition.id, today: today, settings: resolvedSettings)
        }
    }

    static func userFestivalOccurrences(
        context: ModelContext,
        today: Date = .now
    ) -> [FestivalOccurrence] {
        let festivals = (try? context.fetch(FetchDescriptor<UserFestival>(sortBy: [SortDescriptor(\.createdAt)]))) ?? []
        return festivals.compactMap { occurrence(for: $0, today: today) }
    }

    static func allOccurrences(
        context: ModelContext,
        today: Date = .now,
        settings: AppSettings? = nil
    ) -> [FestivalOccurrence] {
        let resolvedSettings = settings ?? AppSettings.shared
        let all = builtInOccurrences(today: today, settings: resolvedSettings) + userFestivalOccurrences(context: context, today: today)
        return all.sorted {
            if $0.countdownDays == $1.countdownDays {
                return $0.sortOrder < $1.sortOrder
            }
            return $0.countdownDays < $1.countdownDays
        }
    }

    static func occurrence(
        for route: FestivalRoutePayload,
        context: ModelContext,
        today: Date = .now,
        settings: AppSettings? = nil
    ) -> FestivalOccurrence? {
        let resolvedSettings = settings ?? AppSettings.shared
        switch route {
        case let .builtin(id):
            return occurrence(for: id, today: today, settings: resolvedSettings)
        case let .userFestival(id):
            guard let festival = context.model(for: id) as? UserFestival else { return nil }
            return occurrence(for: festival, today: today)
        }
    }

    static func occurrence(
        for builtinID: BuiltinFestivalID,
        today: Date = .now,
        settings: AppSettings? = nil
    ) -> FestivalOccurrence? {
        let resolvedSettings = settings ?? AppSettings.shared
        guard let definition = builtins.first(where: { $0.id == builtinID }),
              let date = nextDate(for: definition, from: today)
        else {
            return nil
        }

        let countdown = countdownDays(from: today, to: date)
        return FestivalOccurrence(
            route: .builtin(builtinID),
            name: builtinID.localizedTitle,
            date: date,
            countdownDays: countdown,
            recurrence: definition.recurrence,
            reminderEnabled: resolvedSettings.builtinFestivalReminderEnabled(for: builtinID),
            contactSelectionMode: resolvedSettings.builtinFestivalContactSelectionMode(for: builtinID),
            secondaryText: lunarSummary(for: definition),
            isExpired: false,
            sortOrder: definition.sortOrder
        )
    }

    static func occurrence(
        for festival: UserFestival,
        today: Date = .now
    ) -> FestivalOccurrence? {
        let todayStart = gregorianCalendar.startOfDay(for: today)
        let date = nextDate(for: festival, from: todayStart)
        guard let date else {
            return FestivalOccurrence(
                route: .userFestival(festival.persistentModelID),
                name: festival.name,
                date: todayStart,
                countdownDays: 0,
                recurrence: festival.recurrence,
                reminderEnabled: festival.reminderEnabled,
                contactSelectionMode: festival.contactSelectionMode,
                secondaryText: String(localized: "festival.status.expired"),
                isExpired: true,
                sortOrder: 1000
            )
        }

        let countdown = countdownDays(from: todayStart, to: date)
        return FestivalOccurrence(
            route: .userFestival(festival.persistentModelID),
            name: festival.name,
            date: date,
            countdownDays: countdown,
            recurrence: festival.recurrence,
            reminderEnabled: festival.reminderEnabled,
            contactSelectionMode: festival.contactSelectionMode,
            secondaryText: userFestivalSummary(for: festival),
            isExpired: false,
            sortOrder: 1000
        )
    }

    static func recommendedContacts(
        context: ModelContext
    ) -> [Contact] {
        let contacts = (try? context.fetch(FetchDescriptor<Contact>(sortBy: [SortDescriptor(\.name)]))) ?? []
        return contacts
            .filter { $0.circle == 1 || $0.circle == 2 }
            .sorted { lhs, rhs in
                if lhs.circle != rhs.circle {
                    return lhs.circle < rhs.circle
                }
                let lhsDate = lastInteractionDate(for: lhs) ?? .distantPast
                let rhsDate = lastInteractionDate(for: rhs) ?? .distantPast
                if lhsDate == rhsDate {
                    return lhs.name.localizedCompare(rhs.name) == .orderedAscending
                }
                return lhsDate > rhsDate
            }
    }

    static func finalContacts(
        for route: FestivalRoutePayload,
        context: ModelContext,
        settings: AppSettings? = nil
    ) -> [Contact] {
        let resolvedSettings = settings ?? AppSettings.shared
        let preferredContacts = preferredContacts(for: route, context: context)
        let recommended = recommendedContacts(context: context)
        let mode = contactSelectionMode(for: route, context: context, settings: resolvedSettings)

        switch mode {
        case .recommendedOnly:
            return recommended
        case .manualOnly:
            return preferredContacts.isEmpty ? recommended : preferredContacts
        case .manualPlusRecommended:
            if preferredContacts.isEmpty {
                return recommended
            }
            var result = preferredContacts
            let existingIDs = Set(preferredContacts.map(\.persistentModelID))
            result.append(contentsOf: recommended.filter { !existingIDs.contains($0.persistentModelID) })
            return result
        }
    }

    static func preferredContacts(
        for route: FestivalRoutePayload,
        context: ModelContext
    ) -> [Contact] {
        let key = route.key
        let descriptor = FetchDescriptor<FestivalContactPreference>(
            predicate: #Predicate<FestivalContactPreference> { $0.festivalKey == key },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        let preferences = (try? context.fetch(descriptor)) ?? []
        return preferences.compactMap(\.contact)
    }

    static func greetedContacts(
        for occurrence: FestivalOccurrence,
        context: ModelContext
    ) -> [Contact] {
        let key = occurrence.route.key
        let year = gregorianCalendar.component(.year, from: occurrence.date)
        let descriptor = FetchDescriptor<FestivalGreeting>(
            predicate: #Predicate<FestivalGreeting> { $0.festivalKey == key },
            sortBy: [SortDescriptor(\.greetedAt, order: .reverse)]
        )
        let greetings = (try? context.fetch(descriptor)) ?? []
        return greetings
            .filter { $0.festivalYear == year }
            .compactMap(\.contact)
    }

    static func pendingContacts(
        for occurrence: FestivalOccurrence,
        context: ModelContext,
        settings: AppSettings? = nil
    ) -> [Contact] {
        let resolvedSettings = settings ?? AppSettings.shared
        let greeted = Set(greetedContacts(for: occurrence, context: context).map(\.persistentModelID))
        return finalContacts(for: occurrence.route, context: context, settings: resolvedSettings)
            .filter { !greeted.contains($0.persistentModelID) }
    }

    static func markGreeted(
        contact: Contact,
        occurrence: FestivalOccurrence,
        context: ModelContext,
        relatedRecordID: String? = nil
    ) {
        let year = gregorianCalendar.component(.year, from: occurrence.date)
        let key = occurrence.route.key
        let contactID = contact.persistentModelID
        let descriptor = FetchDescriptor<FestivalGreeting>(
            predicate: #Predicate<FestivalGreeting> {
                $0.festivalKey == key &&
                    $0.festivalYear == year
            }
        )
        let existing = ((try? context.fetch(descriptor)) ?? []).first { $0.contact?.persistentModelID == contactID }
        if let existing {
            existing.greetedAt = .now
            existing.relatedRecordID = relatedRecordID
        } else {
            context.insert(FestivalGreeting(
                festivalKey: key,
                festivalYear: year,
                festivalDate: occurrence.date,
                contact: contact,
                relatedRecordID: relatedRecordID
            ))
        }
        try? context.save()
    }

    static func unmarkGreeted(
        contact: Contact,
        occurrence: FestivalOccurrence,
        context: ModelContext
    ) {
        let year = gregorianCalendar.component(.year, from: occurrence.date)
        let key = occurrence.route.key
        let contactID = contact.persistentModelID
        let descriptor = FetchDescriptor<FestivalGreeting>(
            predicate: #Predicate<FestivalGreeting> {
                $0.festivalKey == key &&
                    $0.festivalYear == year
            }
        )
        let greetings = (try? context.fetch(descriptor)) ?? []
        for item in greetings where item.contact?.persistentModelID == contactID {
            context.delete(item)
        }
        try? context.save()
    }

    static func replacePreferredContacts(
        for route: FestivalRoutePayload,
        contacts: [Contact],
        context: ModelContext
    ) {
        let key = route.key
        let descriptor = FetchDescriptor<FestivalContactPreference>(
            predicate: #Predicate<FestivalContactPreference> { $0.festivalKey == key }
        )
        let existing = (try? context.fetch(descriptor)) ?? []
        for item in existing {
            context.delete(item)
        }
        for contact in contacts {
            context.insert(FestivalContactPreference(festivalKey: key, contact: contact))
        }
        try? context.save()
    }

    static func contactSelectionMode(
        for route: FestivalRoutePayload,
        context: ModelContext,
        settings: AppSettings? = nil
    ) -> FestivalContactSelectionMode {
        let resolvedSettings = settings ?? AppSettings.shared
        switch route {
        case let .builtin(id):
            return resolvedSettings.builtinFestivalContactSelectionMode(for: id)
        case let .userFestival(id):
            guard let festival = context.model(for: id) as? UserFestival else { return .recommendedOnly }
            return festival.contactSelectionMode
        }
    }

    static func setContactSelectionMode(
        _ mode: FestivalContactSelectionMode,
        for route: FestivalRoutePayload,
        context: ModelContext,
        settings: AppSettings? = nil
    ) {
        let resolvedSettings = settings ?? AppSettings.shared
        switch route {
        case let .builtin(id):
            resolvedSettings.setBuiltinFestivalContactSelectionMode(mode, for: id)
        case let .userFestival(id):
            guard let festival = context.model(for: id) as? UserFestival else { return }
            festival.contactSelectionMode = mode
            try? context.save()
        }
    }

    static func setReminderEnabled(
        _ isEnabled: Bool,
        for route: FestivalRoutePayload,
        context: ModelContext,
        settings: AppSettings? = nil
    ) {
        let resolvedSettings = settings ?? AppSettings.shared
        switch route {
        case let .builtin(id):
            resolvedSettings.setBuiltinFestivalReminderEnabled(isEnabled, for: id)
        case let .userFestival(id):
            guard let festival = context.model(for: id) as? UserFestival else { return }
            festival.reminderEnabled = isEnabled
            try? context.save()
        }
    }

    static func formatGregorianDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = gregorianCalendar
        formatter.locale = Locale(identifier: "zh-Hans")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }

    static func formatFullGregorianDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = gregorianCalendar
        formatter.locale = Locale(identifier: "zh-Hans")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: date)
    }

    private static func occurrenceYearCandidates(from date: Date) -> [Int] {
        let year = gregorianCalendar.component(.year, from: date)
        return [year, year + 1]
    }

    private static func nextDate(
        for definition: BuiltinDefinition,
        from today: Date
    ) -> Date? {
        for year in occurrenceYearCandidates(from: today) {
            if let date = lunarDate(
                inGregorianYear: year,
                lunarMonth: definition.lunarMonth,
                lunarDay: definition.lunarDay,
                isNewYearsEve: definition.id == .chineseNewYearsEve
            ),
                date >= gregorianCalendar.startOfDay(for: today)
            {
                return date
            }
        }
        return nil
    }

    private static func nextDate(
        for festival: UserFestival,
        from today: Date
    ) -> Date? {
        let todayStart = gregorianCalendar.startOfDay(for: today)
        switch festival.recurrence {
        case .annualGregorian:
            guard let month = festival.gregorianMonth, let day = festival.gregorianDay else { return nil }
            for year in occurrenceYearCandidates(from: todayStart) {
                if let date = gregorianCalendar.date(from: DateComponents(year: year, month: month, day: day)),
                   date >= todayStart
                {
                    return date
                }
            }
            return nil
        case .annualLunar:
            guard let month = festival.lunarMonth, let day = festival.lunarDay else { return nil }
            for year in occurrenceYearCandidates(from: todayStart) {
                if let date = lunarDate(inGregorianYear: year, lunarMonth: month, lunarDay: day, isNewYearsEve: false),
                   date >= todayStart
                {
                    return date
                }
            }
            return nil
        case .oneTime:
            guard let oneTimeDate = festival.oneTimeDate else { return nil }
            let normalized = gregorianCalendar.startOfDay(for: oneTimeDate)
            return normalized >= todayStart ? normalized : nil
        }
    }

    private static func lunarDate(
        inGregorianYear year: Int,
        lunarMonth: Int?,
        lunarDay: Int?,
        isNewYearsEve: Bool
    ) -> Date? {
        guard let start = gregorianCalendar.date(from: DateComponents(year: year, month: 1, day: 1)),
              let end = gregorianCalendar.date(from: DateComponents(year: year + 1, month: 1, day: 1))
        else {
            return nil
        }
        var current = start

        while current < end {
            let chinese = chineseCalendar.dateComponents([.month, .day], from: current)
            if isNewYearsEve {
                guard let nextDay = gregorianCalendar.date(byAdding: .day, value: 1, to: current) else {
                    return nil
                }
                let nextChinese = chineseCalendar.dateComponents([.month, .day], from: nextDay)
                if nextChinese.month == 1, nextChinese.day == 1 {
                    return gregorianCalendar.startOfDay(for: current)
                }
            } else if chinese.month == lunarMonth, chinese.day == lunarDay {
                return gregorianCalendar.startOfDay(for: current)
            }
            guard let nextDate = gregorianCalendar.date(byAdding: .day, value: 1, to: current) else {
                return nil
            }
            current = nextDate
        }
        return nil
    }

    private static func countdownDays(from start: Date, to end: Date) -> Int {
        let startOfDay = gregorianCalendar.startOfDay(for: start)
        let endOfDay = gregorianCalendar.startOfDay(for: end)
        let components = gregorianCalendar.dateComponents([.day], from: startOfDay, to: endOfDay)
        return max(components.day ?? 0, 0)
    }

    private static func lunarSummary(for definition: BuiltinDefinition) -> String {
        switch definition.id {
        case .springFestival:
            String(localized: "festival.lunar.springFestival")
        case .lanternFestival:
            String(localized: "festival.lunar.lanternFestival")
        case .dragonBoatFestival:
            String(localized: "festival.lunar.dragonBoatFestival")
        case .qixiFestival:
            String(localized: "festival.lunar.qixiFestival")
        case .midAutumnFestival:
            String(localized: "festival.lunar.midAutumnFestival")
        case .doubleNinthFestival:
            String(localized: "festival.lunar.doubleNinthFestival")
        case .chineseNewYearsEve:
            String(localized: "festival.lunar.chineseNewYearsEve")
        }
    }

    private static func userFestivalSummary(for festival: UserFestival) -> String {
        switch festival.recurrence {
        case .annualGregorian:
            guard let month = festival.gregorianMonth, let day = festival.gregorianDay else {
                return String(localized: "festival.recurrence.annualGregorian")
            }
            return String(format: String(localized: "festival.summary.gregorian"), month, day)
        case .annualLunar:
            guard let month = festival.lunarMonth, let day = festival.lunarDay else {
                return String(localized: "festival.recurrence.annualLunar")
            }
            return String(format: String(localized: "festival.summary.lunar"), month, day)
        case .oneTime:
            guard let date = festival.oneTimeDate else { return String(localized: "festival.recurrence.oneTime") }
            return formatFullGregorianDate(date)
        }
    }

    private static func lastInteractionDate(for contact: Contact) -> Date? {
        (contact.records ?? []).map(\.date).max()
    }
}
