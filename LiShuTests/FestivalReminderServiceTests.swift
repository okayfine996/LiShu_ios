import Foundation
import Testing
@testable import LiShu

@MainActor
struct FestivalReminderServiceTests {

    @Test func testMatchedCloseContactsFiltersByCategoryAndName() {
        let family = SampleData.contact(name: "妈妈", relation: "母亲", category: RelationshipCategory.family.rawValue, circle: 1)
        let relative = SampleData.contact(name: "表哥", relation: "表兄弟", category: RelationshipCategory.relative.rawValue, circle: 2)
        let social = SampleData.contact(name: "同事张", relation: "同事", category: RelationshipCategory.social.rawValue, circle: 3)
        let unnamed = SampleData.contact(name: "   ", relation: "父亲", category: RelationshipCategory.family.rawValue, circle: 1)

        let service = FestivalReminderService()
        let result = service.matchedCloseContacts(from: [social, relative, unnamed, family])

        #expect(result.map(\.name) == ["妈妈", "表哥"])
    }

    @Test func testReminderBodySummarizesAfterThreeNames() {
        let service = FestivalReminderService()

        let body = service.makeReminderBody(
            festivalName: "中秋节",
            displayNames: ["张三", "李四", "王五"],
            remainingCount: 2
        )

        #expect(body == "中秋节即将到来，别忘了问候张三、李四、王五等 2 人")
    }

    @Test func testReminderBodyFallsBackWhenNoContactsMatched() {
        let service = FestivalReminderService()

        let body = service.makeReminderBody(
            festivalName: "中秋节",
            displayNames: [],
            remainingCount: 0
        )

        #expect(body == "中秋节即将到来，别忘了提前安排节日问候")
    }

    @Test func testReminderPayloadUsesOccurrenceMinusOneDay() {
        let referenceDate = TestDateFactory.date(year: 2026, month: 1, day: 1)
        let calendarService = FestivalCalendarService(
            calendar: TestDateFactory.gregorianCalendar,
            chineseCalendar: TestDateFactory.chineseCalendar,
            now: { referenceDate }
        )
        let service = FestivalReminderService(
            calendarService: calendarService,
            calendar: TestDateFactory.gregorianCalendar,
            now: { referenceDate }
        )
        let family = SampleData.contact(name: "妈妈", relation: "母亲", category: RelationshipCategory.family.rawValue, circle: 1)

        let payloads = service.makeReminderPayloads(contacts: [family])
        let springFestivalPayload = payloads.first { $0.festivalID == "spring-festival" }

        #expect(springFestivalPayload?.festivalName == "春节")
        #expect(springFestivalPayload?.reminderDate == TestDateFactory.date(year: 2026, month: 2, day: 16))
    }
}
