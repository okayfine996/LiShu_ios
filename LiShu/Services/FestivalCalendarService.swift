import Foundation

struct FestivalCalendarService {
    private let definitions: [TraditionalFestivalDefinition]
    private let calendar: Calendar
    private let chineseCalendar: Calendar
    private let now: () -> Date

    init(
        definitions: [TraditionalFestivalDefinition] = TraditionalFestivalDefinition.builtIn,
        calendar: Calendar = .current,
        chineseCalendar: Calendar = Calendar(identifier: .chinese),
        now: @escaping () -> Date = Date.init
    ) {
        self.definitions = definitions
        self.calendar = calendar
        self.chineseCalendar = chineseCalendar
        self.now = now
    }

    func upcomingFestivals(limit: Int) -> [TraditionalFestivalOccurrence] {
        Array(allUpcomingFestivals().prefix(limit))
    }

    func allUpcomingFestivals() -> [TraditionalFestivalOccurrence] {
        let referenceDate = calendar.startOfDay(for: now())

        return definitions
            .compactMap { nextOccurrence(for: $0, from: referenceDate) }
            .sorted {
                if $0.date == $1.date {
                    return $0.definition.sortPriority < $1.definition.sortPriority
                }
                return $0.date < $1.date
            }
    }

    func nextOccurrence(for definition: TraditionalFestivalDefinition, from referenceDate: Date) -> TraditionalFestivalOccurrence? {
        let referenceDay = calendar.startOfDay(for: referenceDate)
        let currentChineseYear = chineseCalendar.component(.year, from: referenceDay)

        let candidateDate: Date?
        switch definition.rule {
        case .lunar(let month, let day):
            candidateDate = nextLunarDate(month: month, day: day, currentChineseYear: currentChineseYear, referenceDay: referenceDay)
        case .solar(let month, let day):
            candidateDate = nextSolarDate(month: month, day: day, referenceDay: referenceDay)
        case .lunarNewYearsEve:
            candidateDate = nextLunarNewYearsEve(currentChineseYear: currentChineseYear, referenceDay: referenceDay)
        }

        guard let date = candidateDate else { return nil }
        let normalizedDate = calendar.startOfDay(for: date)

        return TraditionalFestivalOccurrence(
            definition: definition,
            name: definition.localizedName,
            date: normalizedDate,
            daysRemaining: daysRemaining(until: normalizedDate, from: referenceDay)
        )
    }

    func daysRemaining(until targetDate: Date, from referenceDate: Date) -> Int {
        let start = calendar.startOfDay(for: referenceDate)
        let end = calendar.startOfDay(for: targetDate)
        return max(calendar.dateComponents([.day], from: start, to: end).day ?? 0, 0)
    }

    private func nextLunarDate(month: Int, day: Int, currentChineseYear: Int, referenceDay: Date) -> Date? {
        for year in [currentChineseYear, currentChineseYear + 1] {
            var components = DateComponents()
            components.calendar = chineseCalendar
            components.year = year
            components.month = month
            components.day = day
            components.isLeapMonth = false

            if let date = chineseCalendar.date(from: components),
               calendar.startOfDay(for: date) >= referenceDay {
                return date
            }
        }

        return nil
    }

    private func nextSolarDate(month: Int, day: Int, referenceDay: Date) -> Date? {
        let currentYear = calendar.component(.year, from: referenceDay)

        for year in [currentYear, currentYear + 1] {
            let components = DateComponents(year: year, month: month, day: day)
            if let date = calendar.date(from: components),
               calendar.startOfDay(for: date) >= referenceDay {
                return date
            }
        }

        return nil
    }

    private func nextLunarNewYearsEve(currentChineseYear: Int, referenceDay: Date) -> Date? {
        for year in [currentChineseYear, currentChineseYear + 1] {
            var nextNewYearComponents = DateComponents()
            nextNewYearComponents.calendar = chineseCalendar
            nextNewYearComponents.year = year + 1
            nextNewYearComponents.month = 1
            nextNewYearComponents.day = 1

            guard let nextNewYear = chineseCalendar.date(from: nextNewYearComponents),
                  let eveDate = calendar.date(byAdding: .day, value: -1, to: nextNewYear) else {
                continue
            }

            if calendar.startOfDay(for: eveDate) >= referenceDay {
                return eveDate
            }
        }

        return nil
    }
}
