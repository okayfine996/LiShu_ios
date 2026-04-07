import Foundation
import SwiftData

enum FestivalRecurrence: String, CaseIterable, Codable {
    case annualGregorian
    case annualLunar
    case oneTime

    var localizedTitle: String {
        switch self {
        case .annualGregorian:
            String(localized: "festival.recurrence.annualGregorian")
        case .annualLunar:
            String(localized: "festival.recurrence.annualLunar")
        case .oneTime:
            String(localized: "festival.recurrence.oneTime")
        }
    }
}

enum FestivalContactSelectionMode: String, CaseIterable, Codable {
    case recommendedOnly
    case manualOnly
    case manualPlusRecommended

    var localizedTitle: String {
        switch self {
        case .recommendedOnly:
            String(localized: "festival.contactSelection.recommendedOnly")
        case .manualOnly:
            String(localized: "festival.contactSelection.manualOnly")
        case .manualPlusRecommended:
            String(localized: "festival.contactSelection.manualPlusRecommended")
        }
    }
}

enum BuiltinFestivalID: String, CaseIterable, Codable, Hashable {
    case springFestival
    case lanternFestival
    case dragonBoatFestival
    case qixiFestival
    case midAutumnFestival
    case doubleNinthFestival
    case chineseNewYearsEve

    var localizedTitle: String {
        switch self {
        case .springFestival:
            String(localized: "festival.name.springFestival")
        case .lanternFestival:
            String(localized: "festival.name.lanternFestival")
        case .dragonBoatFestival:
            String(localized: "festival.name.dragonBoatFestival")
        case .qixiFestival:
            String(localized: "festival.name.qixiFestival")
        case .midAutumnFestival:
            String(localized: "festival.name.midAutumnFestival")
        case .doubleNinthFestival:
            String(localized: "festival.name.doubleNinthFestival")
        case .chineseNewYearsEve:
            String(localized: "festival.name.chineseNewYearsEve")
        }
    }

    var imageAssetName: String? {
        switch self {
        case .springFestival:
            "spring_festival"
        case .lanternFestival:
            "lantern_festival"
        case .dragonBoatFestival:
            "dragon_boat"
        case .qixiFestival:
            "qixi"
        case .midAutumnFestival:
            "mid_autumn"
        case .doubleNinthFestival:
            "double_ninth"
        case .chineseNewYearsEve:
            "new_years_eve"
        }
    }
}

enum FestivalRoutePayload: Hashable {
    case builtin(BuiltinFestivalID)
    case userFestival(PersistentIdentifier)

    var key: String {
        switch self {
        case let .builtin(id):
            "builtin:\(id.rawValue)"
        case let .userFestival(id):
            "user:\(String(describing: id))"
        }
    }
}

struct FestivalOccurrence: Identifiable, Hashable {
    let route: FestivalRoutePayload
    let name: String
    let date: Date
    let countdownDays: Int
    let recurrence: FestivalRecurrence
    let reminderEnabled: Bool
    let contactSelectionMode: FestivalContactSelectionMode
    let secondaryText: String
    let isExpired: Bool
    let sortOrder: Int

    var id: String {
        route.key
    }
}

@Model
final class UserFestival {
    var name: String = ""
    @Attribute(.externalStorage)
    var coverImage: Data?
    var recurrenceRaw: String = FestivalRecurrence.annualGregorian.rawValue
    var gregorianMonth: Int?
    var gregorianDay: Int?
    var lunarMonth: Int?
    var lunarDay: Int?
    var oneTimeDate: Date?
    var reminderEnabled: Bool = true
    var contactSelectionModeRaw: String = FestivalContactSelectionMode.recommendedOnly.rawValue
    var createdAt: Date = Date()

    init(
        name: String,
        coverImage: Data? = nil,
        recurrence: FestivalRecurrence,
        gregorianMonth: Int? = nil,
        gregorianDay: Int? = nil,
        lunarMonth: Int? = nil,
        lunarDay: Int? = nil,
        oneTimeDate: Date? = nil,
        reminderEnabled: Bool = true,
        contactSelectionMode: FestivalContactSelectionMode = .recommendedOnly
    ) {
        self.name = name
        self.coverImage = coverImage
        recurrenceRaw = recurrence.rawValue
        self.gregorianMonth = gregorianMonth
        self.gregorianDay = gregorianDay
        self.lunarMonth = lunarMonth
        self.lunarDay = lunarDay
        self.oneTimeDate = oneTimeDate
        self.reminderEnabled = reminderEnabled
        contactSelectionModeRaw = contactSelectionMode.rawValue
        createdAt = Date()
    }

    var recurrence: FestivalRecurrence {
        get { FestivalRecurrence(rawValue: recurrenceRaw) ?? .annualGregorian }
        set { recurrenceRaw = newValue.rawValue }
    }

    var contactSelectionMode: FestivalContactSelectionMode {
        get { FestivalContactSelectionMode(rawValue: contactSelectionModeRaw) ?? .recommendedOnly }
        set { contactSelectionModeRaw = newValue.rawValue }
    }
}

@Model
final class FestivalGreeting {
    var festivalKey: String = ""
    var festivalYear: Int = 0
    var festivalDate: Date = Date()
    var statusRaw: String = "greeted"
    var greetedAt: Date = Date()
    var relatedRecordID: String?
    @Relationship(deleteRule: .nullify)
    var contact: Contact?

    init(
        festivalKey: String,
        festivalYear: Int,
        festivalDate: Date,
        contact: Contact,
        relatedRecordID: String? = nil
    ) {
        self.festivalKey = festivalKey
        self.festivalYear = festivalYear
        self.festivalDate = festivalDate
        self.contact = contact
        self.relatedRecordID = relatedRecordID
        greetedAt = Date()
    }
}

@Model
final class FestivalContactPreference {
    var festivalKey: String = ""
    var createdAt: Date = Date()
    @Relationship(deleteRule: .nullify)
    var contact: Contact?

    init(festivalKey: String, contact: Contact) {
        self.festivalKey = festivalKey
        self.contact = contact
        createdAt = Date()
    }
}
