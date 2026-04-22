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

    // MARK: - gregorianToLunar

    @Test func gregorianToLunarReturnsValidRange() {
        // 9月17日 远离春节边界，结果应为有效农历月日
        let result = LunarCalendarHelper.gregorianToLunar(month: 9, day: 17)
        #expect(result != nil)
        if let result {
            #expect((1 ... 12).contains(result.month))
            #expect((1 ... 30).contains(result.day))
        }
    }

    @Test func gregorianToLunarMidSummerReturnsValidRange() {
        let result = LunarCalendarHelper.gregorianToLunar(month: 6, day: 15)
        #expect(result != nil)
        if let result {
            #expect((1 ... 12).contains(result.month))
            #expect((1 ... 30).contains(result.day))
        }
    }

    @Test func gregorianToLunarRoundTrip() {
        // 公历 → 农历 → 公历，同年内双向转换应还原（同年参考，无年份边界跳跃）
        guard let lunar = LunarCalendarHelper.gregorianToLunar(month: 9, day: 17) else { return }
        guard let back = LunarCalendarHelper.lunarToGregorian(month: lunar.month, day: lunar.day) else { return }
        #expect(back.month == 9)
        #expect(back.day == 17)
    }

    // MARK: - lunarToGregorian

    @Test func lunarToGregorianReturnsValidRange() {
        let result = LunarCalendarHelper.lunarToGregorian(month: 8, day: 15)
        #expect(result != nil)
        if let result {
            #expect((1 ... 12).contains(result.month))
            #expect((1 ... 31).contains(result.day))
        }
    }

    @Test func lunarMidAutumnFallsInSeptOrOct() {
        // 农历八月十五（中秋节）历年均在公历 9月或10月
        let result = LunarCalendarHelper.lunarToGregorian(month: 8, day: 15)
        #expect(result != nil)
        if let result {
            #expect([9, 10].contains(result.month))
        }
    }

    @Test func lunarSpringFestivalFallsInJanOrFeb() {
        // 农历正月初一（春节）历年均在公历 1月或2月
        let result = LunarCalendarHelper.lunarToGregorian(month: 1, day: 1)
        #expect(result != nil)
        if let result {
            #expect([1, 2].contains(result.month))
        }
    }

    @Test func lunarDragonBoatFallsInJunOrJul() {
        // 农历五月初五（端午节）历年均在公历 6月或7月
        let result = LunarCalendarHelper.lunarToGregorian(month: 5, day: 5)
        #expect(result != nil)
        if let result {
            #expect([6, 7].contains(result.month))
        }
    }

    @Test func lunarToGregorianRoundTrip() {
        // 农历 → 公历 → 农历，同年内应还原八月十五
        guard let gregorian = LunarCalendarHelper.lunarToGregorian(month: 8, day: 15) else { return }
        guard let back = LunarCalendarHelper.gregorianToLunar(month: gregorian.month, day: gregorian.day) else { return }
        #expect(back.month == 8)
        #expect(back.day == 15)
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
