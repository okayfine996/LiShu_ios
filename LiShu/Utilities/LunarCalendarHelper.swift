import Foundation

enum LunarCalendarHelper {
    private static let chineseCal: Calendar = {
        var cal = Calendar(identifier: .chinese)
        cal.locale = Locale(identifier: "zh_CN")
        return cal
    }()

    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .chinese)
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "MMM"
        return f
    }()

    // MARK: - Name helpers (via system API)

    /// 农历月名，如"正月"、"腊月"
    static func lunarMonthName(month: Int) -> String {
        guard let date = dateFromLunar(month: month, day: 1) else { return "\(month)月" }
        return monthFormatter.string(from: date)
    }

    /// 农历日名，如"初一"、"三十"
    static func lunarDayName(day: Int) -> String {
        let names = [
            "初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十",
            "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十",
            "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十",
        ]
        guard (1...names.count).contains(day) else { return "\(day)日" }
        return names[day - 1]
    }

    // MARK: - Date construction

    /// 农历月日 → Date（以当前农历年为参考，失败时 nextDate fallback）
    static func dateFromLunar(month: Int, day: Int) -> Date? {
        let now = Date()
        let era = chineseCal.component(.era, from: now)
        let chineseYear = chineseCal.component(.year, from: now)
        var comps = DateComponents()
        comps.era = era
        comps.year = chineseYear
        comps.month = month
        comps.day = day
        if let date = chineseCal.date(from: comps) {
            return date
        }
        // fallback：nextDate 处理腊月三十、闰月等在当年不存在的情况
        var matchComps = DateComponents()
        matchComps.month = month
        matchComps.day = day
        return chineseCal.nextDate(
            after: Calendar.current.startOfDay(for: now),
            matching: matchComps,
            matchingPolicy: .nextTime
        )
    }

    /// 公历月日 → Date（以当前年为参考）
    static func dateFromGregorian(month: Int, day: Int) -> Date? {
        let year = Calendar.current.component(.year, from: Date())
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        return Calendar.current.date(from: comps)
    }

    // MARK: - Format

    /// 格式化农历生日，如"农历三月初五"
    static func format(month: Int, day: Int) -> String {
        let monthName = lunarMonthName(month: month)
        let dayName = lunarDayName(day: day)
        return String(format: String(localized: "contact.birthday.lunar.format"), monthName, dayName)
    }

    /// 格式化公历生日（无年份），如"3月5日"
    static func formatGregorian(month: Int, day: Int) -> String {
        String(format: String(localized: "contact.birthday.gregorian.format"), month, day)
    }

    // MARK: - Reminder scheduling

    /// 计算下一次农历月日对应的公历 Date
    static func nextGregorianDate(lunarMonth: Int, lunarDay: Int) -> Date? {
        nextGregorianDate(lunarMonth: lunarMonth, lunarDay: lunarDay, after: Date(), includingStartDay: false)
    }

    /// 计算指定起点之后的下一次农历月日对应的公历 Date。
    static func nextGregorianDate(
        lunarMonth: Int,
        lunarDay: Int,
        after start: Date,
        includingStartDay: Bool = true
    ) -> Date? {
        let startOfDay = Calendar.current.startOfDay(for: start)
        if includingStartDay {
            let today = chineseCal.dateComponents([.month, .day], from: startOfDay)
            if today.month == lunarMonth, today.day == lunarDay {
                return startOfDay
            }
        }
        var comps = DateComponents()
        comps.month = lunarMonth
        comps.day = lunarDay
        let searchStart = includingStartDay ? startOfDay : start
        return chineseCal.nextDate(after: searchStart, matching: comps, matchingPolicy: .nextTime)
    }

    // MARK: - Extraction helpers

    /// 从公历 Date 提取农历月日
    static func lunarMonthDay(from date: Date) -> (month: Int, day: Int)? {
        let comps = chineseCal.dateComponents([.month, .day], from: date)
        guard let month = comps.month, let day = comps.day else { return nil }
        return (month, day)
    }

    /// 从公历 Date 提取公历月日
    static func gregorianMonthDay(from date: Date) -> (month: Int, day: Int) {
        let comps = Calendar.current.dateComponents([.month, .day], from: date)
        // ?? 1 is a defensive fallback; for any valid Date these components are always present.
        return (comps.month ?? 1, comps.day ?? 1)
    }

    // MARK: - Day count

    /// 获取指定农历月的实际天数（大月 30 天，小月 29 天）
    static func lunarDayCount(for month: Int) -> Int {
        guard let date = dateFromLunar(month: month, day: 1),
              let range = chineseCal.range(of: .day, in: .month, for: date)
        else { return 30 }
        return range.count
    }

    // MARK: - Conversion (month/day only, current year as reference)

    /// 公历月日转农历月日（以当前年为参考）
    static func gregorianToLunar(month: Int, day: Int) -> (month: Int, day: Int)? {
        guard let date = dateFromGregorian(month: month, day: day) else { return nil }
        return lunarMonthDay(from: date)
    }

    /// 农历月日转公历月日（以当前农历年为参考）
    static func lunarToGregorian(month: Int, day: Int) -> (month: Int, day: Int)? {
        guard let date = dateFromLunar(month: month, day: day) else { return nil }
        return gregorianMonthDay(from: date)
    }
}
