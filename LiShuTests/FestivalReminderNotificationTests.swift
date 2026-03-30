import Foundation
import UserNotifications
import Testing
@testable import LiShu

@MainActor
struct FestivalReminderNotificationTests {

    @Test func testMakeFestivalReminderRequestBuildsCategoryAndIdentifier() {
        let payload = FestivalReminderPayload(
            festivalID: "mid-autumn-festival",
            festivalName: "中秋节",
            occurrenceDate: TestDateFactory.date(year: 2026, month: 9, day: 25),
            reminderDate: TestDateFactory.date(year: 2026, month: 9, day: 24),
            recipientContactIDs: ["contact-1", "contact-2"],
            recipientContext: .festivalOverride,
            contactNames: ["张三", "李四", "王五", "赵六"],
            displayNames: ["张三", "李四", "王五"],
            remainingCount: 1,
            bodyText: "中秋节即将到来，别忘了问候张三、李四、王五等 1 人"
        )

        let now = TestDateFactory.date(year: 2026, month: 9, day: 1)
        let request = NotificationManager.shared.makeFestivalReminderRequest(payload: payload, now: { now })

        #expect(request != nil)
        #expect(request?.identifier == "festival-mid-autumn-festival-20260925")
        #expect(request?.content.categoryIdentifier == NotificationManager.Category.festivalReminder.rawValue)
        #expect(request?.content.title == "节日提醒")
        #expect(request?.content.body == "中秋节即将到来，别忘了问候张三、李四、王五等 1 人")

        let trigger = request?.trigger as? UNCalendarNotificationTrigger
        #expect(trigger?.dateComponents.hour == 9)
        #expect(trigger?.dateComponents.minute == 0)
    }

    @Test func testMakeFestivalReminderRequestSkipsPastReminderDate() {
        let payload = FestivalReminderPayload(
            festivalID: "spring-festival",
            festivalName: "春节",
            occurrenceDate: TestDateFactory.date(year: 2026, month: 2, day: 17),
            reminderDate: TestDateFactory.date(year: 2026, month: 2, day: 16),
            recipientContactIDs: ["contact-1"],
            recipientContext: .defaultRecipients,
            contactNames: ["妈妈"],
            displayNames: ["妈妈"],
            remainingCount: 0,
            bodyText: "春节即将到来，别忘了问候妈妈"
        )

        let now = TestDateFactory.gregorianCalendar.date(
            from: DateComponents(year: 2026, month: 2, day: 16, hour: 10, minute: 0)
        ) ?? TestDateFactory.date(year: 2026, month: 2, day: 16)
        let request = NotificationManager.shared.makeFestivalReminderRequest(payload: payload, now: { now })

        #expect(request == nil)
    }
}
