import Foundation

struct CustomFestivalService {
    func allDefinitions(customFestivals: [CustomFestival]) -> [TraditionalFestivalDefinition] {
        TraditionalFestivalDefinition.builtIn + customFestivalDefinitions(from: customFestivals)
    }

    func enabledDefinitions(
        customFestivals: [CustomFestival],
        preferences: [FestivalReminderPreference]
    ) -> [TraditionalFestivalDefinition] {
        let preferenceMap = preferenceLookup(from: preferences)

        return allDefinitions(customFestivals: customFestivals)
            .filter { definition in
                let preference = preferenceMap[definition.id]
                if definition.isBuiltIn {
                    return preference?.isReminderEnabled ?? true
                }

                let customFestival = customFestivals.first { $0.identifier == definition.id }
                let modelEnabled = customFestival?.isEnabled ?? false
                let reminderEnabled = preference?.isReminderEnabled ?? true
                return modelEnabled && reminderEnabled
            }
    }

    func customFestivalDefinitions(from customFestivals: [CustomFestival]) -> [TraditionalFestivalDefinition] {
        customFestivals
            .sorted { lhs, rhs in
                if lhs.createdAt == rhs.createdAt {
                    return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
                }
                return lhs.createdAt < rhs.createdAt
            }
            .enumerated()
            .map { offset, festival in
                TraditionalFestivalDefinition(
                    id: festival.identifier,
                    nameKey: nil,
                    customName: festival.name,
                    rule: rule(for: festival),
                    eventType: .festival,
                    sortPriority: 100 + offset,
                    source: .custom
                )
            }
    }

    func preferenceLookup(from preferences: [FestivalReminderPreference]) -> [String: FestivalReminderPreference] {
        Dictionary(uniqueKeysWithValues: preferences.map { ($0.festivalID, $0) })
    }

    private func rule(for festival: CustomFestival) -> TraditionalFestivalRule {
        switch festival.calendarType {
        case .lunar:
            return .lunar(month: festival.month, day: festival.day)
        case .solar:
            return .solar(month: festival.month, day: festival.day)
        }
    }

}
