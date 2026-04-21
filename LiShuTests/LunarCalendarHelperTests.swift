import Foundation
@testable import LiShu
import Testing

struct LunarCalendarHelperTests {
    // MARK: - format (lunar)

    @Test func lunarFormatReturnsPrefixedString() {
        let result = LunarCalendarHelper.format(month: 1, day: 1)
        #expect(result.hasPrefix("农历"))
    }

    @Test func lunarFormatSpringFestival() {
        // 正月初一
        let result = LunarCalendarHelper.format(month: 1, day: 1)
        #expect(result.contains("正月"))
        #expect(result.contains("初一"))
    }

    @Test func lunarFormatMidAutumn() {
        // 八月十五
        let result = LunarCalendarHelper.format(month: 8, day: 15)
        #expect(result.contains("八月"))
        #expect(result.contains("十五"))
    }

    @Test func lunarFormatDragonBoat() {
        // 五月初五
        let result = LunarCalendarHelper.format(month: 5, day: 5)
        #expect(result.contains("五月"))
        #expect(result.contains("初五"))
    }

    @Test func lunarFormatWinterSolsticeMonth() {
        // 冬月（11月）
        let result = LunarCalendarHelper.format(month: 11, day: 20)
        #expect(result.contains("冬月"))
        #expect(result.contains("二十"))
    }

    @Test func lunarFormatLastMonth() {
        // 腊月（12月）三十
        let result = LunarCalendarHelper.format(month: 12, day: 30)
        #expect(result.contains("腊月"))
        #expect(result.contains("三十"))
    }

    // MARK: - formatGregorian

    @Test func gregorianFormatContainsMonthAndDay() {
        let result = LunarCalendarHelper.formatGregorian(month: 3, day: 5)
        #expect(result.contains("3"))
        #expect(result.contains("5"))
    }

    @Test func gregorianFormatDoesNotContainYear() {
        let result = LunarCalendarHelper.formatGregorian(month: 6, day: 18)
        // 不应该包含年份数字（4位数）
        #expect(!result.contains("2024"))
        #expect(!result.contains("2025"))
        #expect(!result.contains("2026"))
    }

    // MARK: - nextGregorianDate

    @Test func nextGregorianDateReturnsFutureDate() {
        let next = LunarCalendarHelper.nextGregorianDate(lunarMonth: 3, lunarDay: 5)
        #expect(next != nil)
        if let next {
            #expect(next > Date())
        }
    }

    @Test func nextGregorianDateIsWithinTwoYears() throws {
        let next = LunarCalendarHelper.nextGregorianDate(lunarMonth: 8, lunarDay: 15)
        #expect(next != nil)
        if let next {
            let twoYearsLater = try #require(Calendar.current.date(byAdding: .year, value: 2, to: Date()))
            #expect(next < twoYearsLater)
        }
    }

    @Test func nextGregorianDateLunarNewYear() {
        // 正月初一（春节）每年都有
        let next = LunarCalendarHelper.nextGregorianDate(lunarMonth: 1, lunarDay: 1)
        #expect(next != nil)
    }

    // MARK: - Migration helpers

    @Test func gregorianMonthDayExtraction() throws {
        var comps = DateComponents()
        comps.year = 1990
        comps.month = 5
        comps.day = 20
        let date = try #require(Calendar.current.date(from: comps))
        let result = LunarCalendarHelper.gregorianMonthDay(from: date)
        #expect(result.month == 5)
        #expect(result.day == 20)
    }

    @Test func lunarMonthDayExtractionIsNonNil() throws {
        // 2024-09-17 = 农历八月十五（中秋）
        var comps = DateComponents()
        comps.year = 2024
        comps.month = 9
        comps.day = 17
        let date = try #require(Calendar.current.date(from: comps))
        let result = LunarCalendarHelper.lunarMonthDay(from: date)
        #expect(result != nil)
        if let result {
            #expect(result.month == 8)
            #expect(result.day == 15)
        }
    }
}
