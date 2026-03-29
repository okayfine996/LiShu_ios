import Foundation

enum TraditionalFestivalRule: Hashable, Sendable {
    case lunar(month: Int, day: Int)
    case lunarNewYearsEve
}

struct TraditionalFestivalDefinition: Identifiable, Hashable, Sendable {
    let id: String
    let nameKey: String
    let rule: TraditionalFestivalRule
    let eventType: EventType
    let sortPriority: Int

    static let builtIn: [TraditionalFestivalDefinition] = [
        TraditionalFestivalDefinition(
            id: "spring-festival",
            nameKey: "festival.springFestival",
            rule: .lunar(month: 1, day: 1),
            eventType: .festival,
            sortPriority: 0
        ),
        TraditionalFestivalDefinition(
            id: "lantern-festival",
            nameKey: "festival.lanternFestival",
            rule: .lunar(month: 1, day: 15),
            eventType: .festival,
            sortPriority: 1
        ),
        TraditionalFestivalDefinition(
            id: "dragon-boat-festival",
            nameKey: "festival.dragonBoatFestival",
            rule: .lunar(month: 5, day: 5),
            eventType: .festival,
            sortPriority: 2
        ),
        TraditionalFestivalDefinition(
            id: "qixi-festival",
            nameKey: "festival.qixiFestival",
            rule: .lunar(month: 7, day: 7),
            eventType: .festival,
            sortPriority: 3
        ),
        TraditionalFestivalDefinition(
            id: "mid-autumn-festival",
            nameKey: "festival.midAutumnFestival",
            rule: .lunar(month: 8, day: 15),
            eventType: .festival,
            sortPriority: 4
        ),
        TraditionalFestivalDefinition(
            id: "double-ninth-festival",
            nameKey: "festival.doubleNinthFestival",
            rule: .lunar(month: 9, day: 9),
            eventType: .festival,
            sortPriority: 5
        ),
        TraditionalFestivalDefinition(
            id: "lunar-new-years-eve",
            nameKey: "festival.lunarNewYearsEve",
            rule: .lunarNewYearsEve,
            eventType: .festival,
            sortPriority: 6
        )
    ]

    var localizedName: String {
        switch id {
        case "spring-festival":
            return String(localized: "festival.springFestival")
        case "lantern-festival":
            return String(localized: "festival.lanternFestival")
        case "dragon-boat-festival":
            return String(localized: "festival.dragonBoatFestival")
        case "qixi-festival":
            return String(localized: "festival.qixiFestival")
        case "mid-autumn-festival":
            return String(localized: "festival.midAutumnFestival")
        case "double-ninth-festival":
            return String(localized: "festival.doubleNinthFestival")
        case "lunar-new-years-eve":
            return String(localized: "festival.lunarNewYearsEve")
        default:
            return String(localized: "event.type.festival")
        }
    }
}

struct TraditionalFestivalOccurrence: Identifiable, Hashable, Sendable {
    let definition: TraditionalFestivalDefinition
    let name: String
    let date: Date
    let daysRemaining: Int

    var id: String {
        let timestamp = Int(date.timeIntervalSince1970)
        return "\(definition.id)-\(timestamp)"
    }

    var eventType: EventType {
        definition.eventType
    }
}

struct FestivalReminderPayload: Hashable, Sendable {
    let festivalID: String
    let festivalName: String
    let occurrenceDate: Date
    let reminderDate: Date
    let contactNames: [String]
    let displayNames: [String]
    let remainingCount: Int
    let bodyText: String
}

struct FestivalEventPrefill: Hashable, Sendable {
    let name: String
    let eventType: EventType
    let date: Date
}
