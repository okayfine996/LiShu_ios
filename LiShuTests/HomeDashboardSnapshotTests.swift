import Foundation
@testable import LiShu
import Testing

@MainActor
struct HomeDashboardStaleContactsTests {
    @Test("stale contacts section keeps top 3 most overdue contacts")
    func staleContactsTopThree() {
        let calendar = Calendar(identifier: .gregorian)
        let now = Date(timeIntervalSince1970: 1_715_000_000)
        let event = SampleData.event()

        let mostOverdue = SampleData.contact(name: "A")
        let second = SampleData.contact(name: "B")
        let third = SampleData.contact(name: "C")
        let healthy = SampleData.contact(name: "D")

        mostOverdue.records = [
            SampleData.record(
                contact: mostOverdue,
                event: event,
                amount: 800,
                direction: .received,
                date: calendar.date(byAdding: .day, value: -500, to: now) ?? now
            ),
        ]
        second.records = [
            SampleData.record(
                contact: second,
                event: event,
                amount: 500,
                direction: .given,
                date: calendar.date(byAdding: .day, value: -360, to: now) ?? now
            ),
        ]
        third.records = [
            SampleData.record(
                contact: third,
                event: event,
                amount: 200,
                direction: .given,
                date: calendar.date(byAdding: .day, value: -250, to: now) ?? now
            ),
        ]
        healthy.records = [
            SampleData.record(
                contact: healthy,
                event: event,
                amount: 300,
                direction: .given,
                date: calendar.date(byAdding: .day, value: -10, to: now) ?? now
            ),
            SampleData.record(
                contact: healthy,
                event: event,
                amount: 300,
                direction: .received,
                date: calendar.date(byAdding: .day, value: -20, to: now) ?? now
            ),
            SampleData.recordGift(
                contact: healthy,
                event: event,
                direction: .given,
                date: calendar.date(byAdding: .day, value: -15, to: now) ?? now
            ),
        ]

        let snapshot = HomeDashboardSnapshot.build(
            records: (mostOverdue.records ?? []) + (second.records ?? []) + (third.records ?? []) + (healthy.records ?? []),
            events: [],
            contacts: [mostOverdue, second, third, healthy],
            now: now,
            calendar: calendar
        )

        #expect(snapshot.staleContacts.map(\.contact.name) == ["A", "B", "C"])
    }
}
