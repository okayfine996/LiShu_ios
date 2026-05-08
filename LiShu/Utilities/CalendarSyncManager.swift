import EventKit
import Foundation
import SwiftData

enum CalendarSyncError: LocalizedError {
    case noDefaultCalendar
    case lunarDateConversionFailed
    case missingBirthday

    var errorDescription: String? {
        switch self {
        case .noDefaultCalendar:
            String(localized: "calendar.error.noDefaultCalendar")
        case .lunarDateConversionFailed:
            String(localized: "calendar.error.lunarDateConversionFailed")
        case .missingBirthday:
            String(localized: "calendar.error.missingBirthday")
        }
    }
}

@MainActor
final class CalendarSyncManager {
    static let shared = CalendarSyncManager()
    private let store = EKEventStore()

    private init() {}

    /// 请求日历写入权限（iOS 17+ API）。已授权则快速返回，避免多余 async 开销。
    func requestWriteAccess() async -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        if status == .fullAccess || status == .writeOnly { return true }
        if status == .denied || status == .restricted { return false }
        return await (try? store.requestWriteOnlyAccessToEvents()) ?? false
    }

    /// 将 LiShu 事件写入系统日历
    func addEvent(_ event: Event) throws {
        guard let calendar = store.defaultCalendarForNewEvents else {
            throw CalendarSyncError.noDefaultCalendar
        }
        let ek = EKEvent(eventStore: store)
        ek.title = event.name
        let greg = Calendar.current
        let nineAM = greg.date(bySettingHour: 9, minute: 0, second: 0, of: event.date) ?? event.date
        ek.startDate = nineAM
        ek.endDate = greg.date(bySettingHour: 18, minute: 0, second: 0, of: event.date) ?? nineAM
        if !event.location.isEmpty { ek.location = event.location }
        if !event.note.isEmpty { ek.notes = event.note }
        ek.calendar = calendar
        ek.addAlarm(EKAlarm(relativeOffset: -86400)) // 提前 1 天提醒
        try store.save(ek, span: .thisEvent)
    }

    /// 将联系人生日写入系统日历
    func addBirthday(contact: Contact) throws {
        guard let birthday = contact.birthday else { throw CalendarSyncError.missingBirthday }
        guard let calendar = store.defaultCalendarForNewEvents else {
            throw CalendarSyncError.noDefaultCalendar
        }

        let ek = EKEvent(eventStore: store)
        ek.title = String(format: String(localized: "contact.detail.calendar.birthdayTitle"), contact.name)
        ek.isAllDay = true
        ek.calendar = calendar
        ek.addAlarm(EKAlarm(relativeOffset: 32400)) // 当天 9:00 提醒

        if contact.birthdayIsLunar {
            guard let (lunarMonth, lunarDay) = LunarCalendarHelper.lunarMonthDay(from: birthday),
                  let nextDate = LunarCalendarHelper.nextGregorianDate(lunarMonth: lunarMonth, lunarDay: lunarDay)
            else { throw CalendarSyncError.lunarDateConversionFailed }
            let dayStart = Calendar.current.startOfDay(for: nextDate)
            ek.startDate = dayStart
            // 全天事件 endDate 按 EventKit 规范为次日 00:00（左闭右开）
            ek.endDate = Calendar.current.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
            let lunarLabel = LunarCalendarHelper.format(month: lunarMonth, day: lunarDay)
            ek.notes = String(format: String(localized: "contact.detail.calendar.lunarBirthdayNote"), lunarLabel)
        } else {
            let (month, day) = LunarCalendarHelper.gregorianMonthDay(from: birthday)
            let greg = Calendar.current
            let currentYear = greg.component(.year, from: Date())
            var comps = DateComponents()
            comps.year = currentYear
            comps.month = month
            comps.day = day
            let thisYearDate = greg.date(from: comps) ?? birthday
            // 若今年日期已过，从明年开始
            let today = greg.startOfDay(for: Date())
            let startDate = thisYearDate < today
                ? greg.date(byAdding: .year, value: 1, to: thisYearDate) ?? thisYearDate
                : thisYearDate
            let dayStart = greg.startOfDay(for: startDate)
            ek.startDate = dayStart
            ek.endDate = greg.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
            ek.addRecurrenceRule(EKRecurrenceRule(recurrenceWith: .yearly, interval: 1, end: nil))
        }

        try store.save(ek, span: .thisEvent)
    }
}
