import Foundation
@testable import LiShu
import SwiftData
import Testing

@MainActor
struct FestivalServiceTests {
    @Test func builtinFestivalsAreAvailable() {
        let occurrences = FestivalService.builtInOccurrences(
            today: Calendar.current.date(from: DateComponents(year: 2026, month: 6, day: 1)) ?? .now
        )

        #expect(occurrences.count == 7)
        #expect(occurrences.allSatisfy { !$0.isExpired })
    }

    @Test func annualGregorianFestivalRollsIntoNextYear() throws {
        let db = try TestDB()
        let festival = UserFestival(
            name: "家祭",
            recurrence: .annualGregorian,
            gregorianMonth: 5,
            gregorianDay: 20
        )
        db.context.insert(festival)
        try db.context.save()

        let today = Calendar.current.date(from: DateComponents(year: 2026, month: 12, day: 31)) ?? .now
        let occurrence = FestivalService.occurrence(for: festival, today: today)

        #expect(occurrence != nil)
        #expect(FestivalService.formatFullGregorianDate(occurrence?.date ?? .now) == "2027年5月20日")
    }

    @Test func manualOnlyFallsBackToRecommendedWhenNoManualContacts() throws {
        let db = try TestDB()
        let family = SampleData.contact(name: "张三", relation: "叔叔", category: "亲属", circle: 2)
        let social = SampleData.contact(name: "李四", relation: "同学", category: "社交", circle: 3)
        let festival = UserFestival(name: "家祭", recurrence: .annualGregorian, gregorianMonth: 10, gregorianDay: 1)
        festival.contactSelectionMode = .manualOnly

        db.context.insert(family)
        db.context.insert(social)
        db.context.insert(festival)
        try db.context.save()

        let contacts = FestivalService.finalContacts(
            for: .userFestival(festival.persistentModelID),
            context: db.context
        )

        #expect(contacts.map(\.name) == ["张三"])
    }

    @Test func recommendedContactsPrioritizeCloserCircleBeforeRecency() throws {
        let db = try TestDB()
        let family = SampleData.contact(name: "家人A", relation: "家人", category: "家人", circle: 1)
        let relative = SampleData.contact(name: "亲属B", relation: "亲属", category: "亲属", circle: 2)
        let outsider = SampleData.contact(name: "朋友C", relation: "朋友", category: "社交", circle: 3)
        let event = SampleData.event()
        let recentRecord = SampleData.record(contact: relative, event: event, date: .now)
        let olderRecord = SampleData.record(
            contact: family,
            event: event,
            date: Calendar.current.date(byAdding: .day, value: -10, to: .now) ?? .now
        )

        [family, relative, outsider, event, recentRecord, olderRecord].forEach(db.context.insert)
        try db.context.save()

        let contacts = FestivalService.recommendedContacts(context: db.context)

        #expect(contacts.map(\.name) == ["家人A", "亲属B"])
    }

    @Test func manualPlusRecommendedPreservesManualOrderAndDeduplicates() throws {
        let db = try TestDB()
        let family = SampleData.contact(name: "家人A", relation: "家人", category: "家人", circle: 1)
        let relative = SampleData.contact(name: "亲属B", relation: "亲属", category: "亲属", circle: 2)
        let festival = UserFestival(name: "家祭", recurrence: .annualGregorian, gregorianMonth: 10, gregorianDay: 1)
        festival.contactSelectionMode = .manualPlusRecommended

        [family, relative, festival].forEach(db.context.insert)
        try db.context.save()

        FestivalService.replacePreferredContacts(
            for: .userFestival(festival.persistentModelID),
            contacts: [relative],
            context: db.context
        )

        let contacts = FestivalService.finalContacts(
            for: .userFestival(festival.persistentModelID),
            context: db.context
        )

        #expect(contacts.map(\.name) == ["亲属B", "家人A"])
    }

    @Test func homeViewModelLoadsOnlyThreeFestivals() throws {
        let db = try TestDB()
        db.context.insert(UserFestival(name: "家祭", recurrence: .annualGregorian, gregorianMonth: 10, gregorianDay: 1))
        db.context.insert(UserFestival(name: "纪念日", recurrence: .annualGregorian, gregorianMonth: 11, gregorianDay: 1))
        db.context.insert(UserFestival(name: "师父寿辰", recurrence: .annualGregorian, gregorianMonth: 12, gregorianDay: 1))
        try db.context.save()

        let viewModel = HomeViewModel()
        viewModel.load(context: db.context)

        #expect(viewModel.upcomingFestivals.count == 3)
    }
}
