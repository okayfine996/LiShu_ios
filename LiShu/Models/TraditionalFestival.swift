import Foundation

enum FestivalSource: String, Codable, Hashable, Sendable {
    case builtIn
    case custom
}

enum FestivalCalendarType: String, Codable, CaseIterable, Hashable, Sendable {
    case lunar
    case solar
}

enum TraditionalFestivalRule: Hashable, Sendable {
    case lunar(month: Int, day: Int)
    case solar(month: Int, day: Int)
    case lunarNewYearsEve
}

struct TraditionalFestivalDefinition: Identifiable, Hashable, Sendable {
    let id: String
    let nameKey: String?
    let customName: String?
    let rule: TraditionalFestivalRule
    let eventType: EventType
    let sortPriority: Int
    let source: FestivalSource

    static let builtIn: [TraditionalFestivalDefinition] = [
        TraditionalFestivalDefinition(
            id: "spring-festival",
            nameKey: "festival.springFestival",
            customName: nil,
            rule: .lunar(month: 1, day: 1),
            eventType: .festival,
            sortPriority: 0,
            source: .builtIn
        ),
        TraditionalFestivalDefinition(
            id: "lantern-festival",
            nameKey: "festival.lanternFestival",
            customName: nil,
            rule: .lunar(month: 1, day: 15),
            eventType: .festival,
            sortPriority: 1,
            source: .builtIn
        ),
        TraditionalFestivalDefinition(
            id: "dragon-boat-festival",
            nameKey: "festival.dragonBoatFestival",
            customName: nil,
            rule: .lunar(month: 5, day: 5),
            eventType: .festival,
            sortPriority: 2,
            source: .builtIn
        ),
        TraditionalFestivalDefinition(
            id: "qixi-festival",
            nameKey: "festival.qixiFestival",
            customName: nil,
            rule: .lunar(month: 7, day: 7),
            eventType: .festival,
            sortPriority: 3,
            source: .builtIn
        ),
        TraditionalFestivalDefinition(
            id: "mid-autumn-festival",
            nameKey: "festival.midAutumnFestival",
            customName: nil,
            rule: .lunar(month: 8, day: 15),
            eventType: .festival,
            sortPriority: 4,
            source: .builtIn
        ),
        TraditionalFestivalDefinition(
            id: "double-ninth-festival",
            nameKey: "festival.doubleNinthFestival",
            customName: nil,
            rule: .lunar(month: 9, day: 9),
            eventType: .festival,
            sortPriority: 5,
            source: .builtIn
        ),
        TraditionalFestivalDefinition(
            id: "lunar-new-years-eve",
            nameKey: "festival.lunarNewYearsEve",
            customName: nil,
            rule: .lunarNewYearsEve,
            eventType: .festival,
            sortPriority: 6,
            source: .builtIn
        )
    ]

    var isBuiltIn: Bool {
        source == .builtIn
    }

    var localizedName: String {
        if let customName, !customName.isEmpty {
            return customName
        }

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

enum FestivalRecipientContext: String, Hashable, Sendable {
    case defaultRecipients
    case festivalOverride
}

struct FestivalReminderPayload: Hashable, Sendable {
    let festivalID: String
    let festivalName: String
    let occurrenceDate: Date
    let reminderDate: Date
    let recipientContactIDs: [String]
    let recipientContext: FestivalRecipientContext
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

struct FestivalReminderRouteData: Identifiable, Hashable, Sendable {
    let festivalID: String
    let festivalName: String
    let occurrenceDate: Date

    var id: String {
        "\(festivalID)-\(Int(occurrenceDate.timeIntervalSince1970))"
    }
}

struct FestivalConfigurationRouteData: Identifiable, Hashable, Sendable {
    let festivalID: String
    let festivalName: String
    let isBuiltIn: Bool

    var id: String {
        festivalID
    }
}
