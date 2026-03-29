import Foundation
import Testing
@testable import LiShu

struct FestivalCalendarServiceTests {

    @Test func testUpcomingFestivalsAreLimitedAndSorted() {
        let referenceDate = TestDateFactory.date(year: 2026, month: 1, day: 1)
        let service = FestivalCalendarService(
            calendar: TestDateFactory.gregorianCalendar,
            chineseCalendar: TestDateFactory.chineseCalendar,
            now: { referenceDate }
        )

        let festivals = service.upcomingFestivals(limit: 3)

        #expect(festivals.count == 3)
        #expect(festivals[0].definition.id == "lunar-new-years-eve")
        #expect(festivals[1].definition.id == "spring-festival")
        #expect(festivals[2].definition.id == "lantern-festival")
        #expect(festivals[0].date <= festivals[1].date)
        #expect(festivals[1].date <= festivals[2].date)
    }

    @Test func testSpringFestivalRollsToNextCycleAfterPassingCurrentOccurrence() {
        let referenceDate = TestDateFactory.date(year: 2026, month: 2, day: 18)
        let service = FestivalCalendarService(
            calendar: TestDateFactory.gregorianCalendar,
            chineseCalendar: TestDateFactory.chineseCalendar,
            now: { referenceDate }
        )

        let springFestival = service.allUpcomingFestivals().first { $0.definition.id == "spring-festival" }

        #expect(springFestival != nil)
        #expect(springFestival?.date ?? .distantPast > referenceDate)
        #expect(TestDateFactory.gregorianCalendar.component(.year, from: springFestival?.date ?? .distantPast) >= 2027)
    }

    @Test func testLunarNewYearsEveResolvesToExpectedDateFor2026() {
        let referenceDate = TestDateFactory.date(year: 2026, month: 1, day: 1)
        let service = FestivalCalendarService(
            calendar: TestDateFactory.gregorianCalendar,
            chineseCalendar: TestDateFactory.chineseCalendar,
            now: { referenceDate }
        )

        let newYearsEve = service.allUpcomingFestivals().first { $0.definition.id == "lunar-new-years-eve" }

        #expect(newYearsEve?.date == TestDateFactory.date(year: 2026, month: 2, day: 16))
        #expect(newYearsEve?.daysRemaining == 46)
    }
}
