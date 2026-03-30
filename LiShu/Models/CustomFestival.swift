import Foundation
import SwiftData

@Model
final class CustomFestival {
    var identifier: String = UUID().uuidString
    var name: String = ""
    var calendarTypeRaw: String = FestivalCalendarType.lunar.rawValue
    var month: Int = 1
    var day: Int = 1
    var isEnabled: Bool = true
    var createdAt: Date = Foundation.Date(timeIntervalSince1970: 0)

    init(
        identifier: String = UUID().uuidString,
        name: String,
        calendarType: FestivalCalendarType,
        month: Int,
        day: Int,
        isEnabled: Bool = true
    ) {
        self.identifier = identifier
        self.name = name
        self.calendarTypeRaw = calendarType.rawValue
        self.month = month
        self.day = day
        self.isEnabled = isEnabled
        self.createdAt = Foundation.Date.now
    }

    var calendarType: FestivalCalendarType {
        get { FestivalCalendarType(rawValue: calendarTypeRaw) ?? .lunar }
        set { calendarTypeRaw = newValue.rawValue }
    }
}
