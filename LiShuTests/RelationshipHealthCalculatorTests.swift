import Foundation
@testable import LiShu
import Testing

@MainActor
struct RelationshipHealthCalculatorTests {
    @Test("no records returns hidden result")
    func noRecords() {
        let contact = SampleData.contact(name: "空联系人")

        let result = RelationshipHealthCalculator.evaluate(contact: contact)

        #expect(result.hasRecords == false)
        #expect(result.score == 0)
        #expect(result.lastInteractionDate == nil)
    }

    @Test("recent frequent balanced contact is close")
    func recentFrequentBalancedContact() {
        let now = Date(timeIntervalSince1970: 1_715_000_000)
        let calendar = Calendar(identifier: .gregorian)
        let contact = SampleData.contact(name: "密切联系")
        let event = SampleData.event()

        contact.records = [
            SampleData.record(
                contact: contact,
                event: event,
                amount: 300,
                direction: .given,
                date: calendar.date(byAdding: .day, value: -12, to: now) ?? now
            ),
            SampleData.record(
                contact: contact,
                event: event,
                amount: 300,
                direction: .received,
                date: calendar.date(byAdding: .day, value: -20, to: now) ?? now
            ),
            SampleData.record(
                contact: contact,
                event: event,
                amount: 500,
                direction: .given,
                date: calendar.date(byAdding: .day, value: -45, to: now) ?? now
            ),
            SampleData.record(
                contact: contact,
                event: event,
                amount: 500,
                direction: .received,
                date: calendar.date(byAdding: .day, value: -70, to: now) ?? now
            ),
            SampleData.recordGift(
                contact: contact,
                event: event,
                direction: .given,
                date: calendar.date(byAdding: .day, value: -30, to: now) ?? now
            ),
        ]

        let result = RelationshipHealthCalculator.evaluate(contact: contact, now: now, calendar: calendar)

        #expect(result.hasRecords == true)
        #expect(result.level == .close)
        #expect(result.score >= 75)
        #expect(result.daysSinceLastInteraction == 12)
    }

    @Test("old one-sided contact needs attention")
    func oldOneSidedContactNeedsAttention() {
        let now = Date(timeIntervalSince1970: 1_715_000_000)
        let calendar = Calendar(identifier: .gregorian)
        let contact = SampleData.contact(name: "欠人情")
        let event = SampleData.event()

        contact.records = [
            SampleData.record(
                contact: contact,
                event: event,
                amount: 1500,
                direction: .received,
                date: calendar.date(byAdding: .day, value: -430, to: now) ?? now,
                relationshipWeight: .support
            ),
        ]

        let result = RelationshipHealthCalculator.evaluate(contact: contact, now: now, calendar: calendar)

        #expect(result.level == .needsAttention)
        #expect(result.outstandingBalance == 1500)
        #expect(result.score < 35)
    }
}
