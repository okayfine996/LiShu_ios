import Foundation

enum LunarCalendarHelper {
    private static let chineseCal: Calendar = {
        var cal = Calendar(identifier: .chinese)
        cal.locale = Locale(identifier: "zh_CN")
        return cal
    }()

    static let monthNames: [Int: String] = [
        1: "正月", 2: "二月", 3: "三月", 4: "四月",
        5: "五月", 6: "六月", 7: "七月", 8: "八月",
        9: "九月", 10: "十月", 11: "冬月", 12: "腊月",
    ]

    static let dayNames: [Int: String] = [
        1: "初一", 2: "初二", 3: "初三", 4: "初四", 5: "初五",
        6: "初六", 7: "初七", 8: "初八", 9: "初九", 10: "初十",
        11: "十一", 12: "十二", 13: "十三", 14: "十四", 15: "十五",
        16: "十六", 17: "十七", 18: "十八", 19: "十九", 20: "二十",
        21: "廿一", 22: "廿二", 23: "廿三", 24: "廿四", 25: "廿五",
        26: "廿六", 27: "廿七", 28: "廿八", 29: "廿九", 30: "三十",
    ]

    /// 格式化农历生日，如"农历三月初五"
    static func format(month: Int, day: Int) -> String {
        let monthName = monthNames[month] ?? "\(month)月"
        let dayName = dayNames[day] ?? "\(day)日"
        return String(format: String(localized: "contact.birthday.lunar.format"), monthName, dayName)
    }

    /// 格式化公历生日（无年份），如"3月5日"
    static func formatGregorian(month: Int, day: Int) -> String {
        String(format: String(localized: "contact.birthday.gregorian.format"), month, day)
    }

    /// 计算下一次农历月日对应的公历 Date。
    /// 使用 Calendar.nextDate(after:matching:) 自动处理跨年和甲子边界。
    static func nextGregorianDate(lunarMonth: Int, lunarDay: Int) -> Date? {
        var comps = DateComponents()
        comps.month = lunarMonth
        comps.day = lunarDay
        return chineseCal.nextDate(after: Date(), matching: comps, matchingPolicy: .nextTime)
    }

    /// 从公历 Date 提取农历月日（用于旧数据迁移）
    static func lunarMonthDay(from date: Date) -> (month: Int, day: Int)? {
        let comps = chineseCal.dateComponents([.month, .day], from: date)
        guard let month = comps.month, let day = comps.day else { return nil }
        return (month, day)
    }

    /// 从公历 Date 提取公历月日（用于旧数据迁移）
    static func gregorianMonthDay(from date: Date) -> (month: Int, day: Int) {
        let comps = Calendar.current.dateComponents([.month, .day], from: date)
        return (comps.month ?? 1, comps.day ?? 1)
    }

    /// 将公历月日转换为农历月日（以当前年为参考）
    static func gregorianToLunar(month: Int, day: Int) -> (month: Int, day: Int)? {
        let year = Calendar.current.component(.year, from: Date())
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        guard let date = Calendar.current.date(from: comps) else { return nil }
        return lunarMonthDay(from: date)
    }

    /// 将农历月日转换为公历月日（以当前年对应的农历年为参考）
    static func lunarToGregorian(month: Int, day: Int) -> (month: Int, day: Int)? {
        let now = Date()
        let era = chineseCal.component(.era, from: now)
        let chineseYear = chineseCal.component(.year, from: now)
        var comps = DateComponents()
        comps.era = era
        comps.year = chineseYear
        comps.month = month
        comps.day = day
        if let date = chineseCal.date(from: comps) {
            return gregorianMonthDay(from: date)
        }
        // 回退：用 nextDate 搜索（处理闰月等边界情况）
        var matchComps = DateComponents()
        matchComps.month = month
        matchComps.day = day
        guard let date = chineseCal.nextDate(
            after: Calendar.current.startOfDay(for: now),
            matching: matchComps,
            matchingPolicy: .nextTime
        ) else { return nil }
        return gregorianMonthDay(from: date)
    }
}
