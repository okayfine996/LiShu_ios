import Foundation
import SwiftData

enum RelationshipHealthLevel: String, CaseIterable {
    case close
    case stable
    case distant
    case needsAttention

    var localizedTitle: String {
        switch self {
        case .close:
            String(localized: "statistics.hero.relationship.close")
        case .stable:
            String(localized: "statistics.hero.relationship.stable")
        case .distant:
            String(localized: "statistics.hero.relationship.distant")
        case .needsAttention:
            String(localized: "statistics.hero.relationship.needsAttention")
        }
    }
}

struct RelationshipHealthResult: Equatable {
    let score: Int
    let level: RelationshipHealthLevel
    let daysSinceLastInteraction: Int
    let lastInteractionDate: Date?
    let hasRecords: Bool
    let pastYearInteractionCount: Int
    let nonFinancialInteractionCount: Int
    let outstandingBalance: Double
}

struct RelationshipHealthSummary: Equatable {
    var close: Int = 0
    var stable: Int = 0
    var distant: Int = 0
    var needsAttention: Int = 0
}

enum RelationshipHealthCalculator {
    static func evaluate(
        contact: Contact,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> RelationshipHealthResult {
        let records = (contact.records ?? []).sorted { $0.date > $1.date }
        guard let lastInteractionDate = records.first?.date else {
            return RelationshipHealthResult(
                score: 0,
                level: .needsAttention,
                daysSinceLastInteraction: Int.max,
                lastInteractionDate: nil,
                hasRecords: false,
                pastYearInteractionCount: 0,
                nonFinancialInteractionCount: 0,
                outstandingBalance: 0
            )
        }

        let today = calendar.startOfDay(for: now)
        let lastDay = calendar.startOfDay(for: lastInteractionDate)
        let daysSinceLastInteraction = max(
            calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0,
            0
        )

        let oneYearAgo = calendar.date(byAdding: .day, value: -365, to: today) ?? today
        let pastYearRecords = records.filter { $0.date >= oneYearAgo }
        let pastYearInteractionCount = pastYearRecords.count
        let nonFinancialInteractionCount = pastYearRecords.filter { $0.recordType != .monetary }.count

        let monetaryRecords = records.filter { $0.recordType == .monetary }
        let receivedAmount = monetaryRecords
            .filter { $0.direction == .received }
            .reduce(0.0) { $0 + $1.resolvedDisplayAmount }
        let givenAmount = monetaryRecords
            .filter { $0.direction == .given }
            .reduce(0.0) { $0 + $1.resolvedDisplayAmount }
        let outstandingBalance = max(receivedAmount - givenAmount, 0)

        let recencyScore = scoreForRecency(daysSinceLastInteraction)
        let frequencyScore = scoreForFrequency(pastYearInteractionCount)
        let balanceScore = scoreForBalance(receivedAmount: receivedAmount, givenAmount: givenAmount)
        let nonFinancialBonus = min(nonFinancialInteractionCount * 2, 10)
        let outstandingPenalty = penaltyForOutstanding(
            records: records,
            outstandingBalance: outstandingBalance
        )

        let rawScore = recencyScore + frequencyScore + balanceScore + nonFinancialBonus - outstandingPenalty
        let score = min(max(rawScore, 0), 100)

        return RelationshipHealthResult(
            score: score,
            level: level(for: score),
            daysSinceLastInteraction: daysSinceLastInteraction,
            lastInteractionDate: lastInteractionDate,
            hasRecords: true,
            pastYearInteractionCount: pastYearInteractionCount,
            nonFinancialInteractionCount: nonFinancialInteractionCount,
            outstandingBalance: outstandingBalance
        )
    }

    static func evaluateAll(
        contacts: [Contact],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [PersistentIdentifier: RelationshipHealthResult] {
        Dictionary(uniqueKeysWithValues: contacts.map { contact in
            (
                contact.persistentModelID,
                evaluate(contact: contact, now: now, calendar: calendar)
            )
        })
    }

    static func summarize(
        contacts: [Contact],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> RelationshipHealthSummary {
        let results = contacts.map { evaluate(contact: $0, now: now, calendar: calendar) }
            .filter(\.hasRecords)
        var summary = RelationshipHealthSummary()

        for result in results {
            switch result.level {
            case .close:
                summary.close += 1
            case .stable:
                summary.stable += 1
            case .distant:
                summary.distant += 1
            case .needsAttention:
                summary.needsAttention += 1
            }
        }

        return summary
    }

    static func relativeInteractionText(for result: RelationshipHealthResult) -> String? {
        guard result.hasRecords else { return nil }
        if result.daysSinceLastInteraction == 0 {
            return String(localized: "exchange.lastContact.today")
        }
        return String(
            format: String(localized: "exchange.lastContact.daysAgo"),
            result.daysSinceLastInteraction
        )
    }

    private static func scoreForRecency(_ days: Int) -> Int {
        switch days {
        case ...30:
            45
        case ...90:
            38
        case ...180:
            28
        case ...365:
            16
        case ...540:
            8
        default:
            0
        }
    }

    private static func scoreForFrequency(_ count: Int) -> Int {
        switch count {
        case 12...:
            25
        case 8...:
            21
        case 5...:
            16
        case 3...:
            12
        case 1...:
            6
        default:
            0
        }
    }

    private static func scoreForBalance(receivedAmount: Double, givenAmount: Double) -> Int {
        if receivedAmount == 0, givenAmount == 0 {
            return 9
        }

        let dominant = max(receivedAmount, givenAmount)
        let ratio = min(receivedAmount, givenAmount) / dominant
        return Int((ratio * 15).rounded())
    }

    private static func penaltyForOutstanding(records: [Record], outstandingBalance: Double) -> Int {
        let outstandingLoad = max(
            weightedLoad(for: records, direction: .received) - weightedLoad(for: records, direction: .given),
            0
        )

        var penalty = 0

        switch outstandingLoad {
        case 6...:
            penalty += 2
        case 3...:
            penalty += 1
        default:
            break
        }

        switch outstandingBalance {
        case 1000...:
            penalty += 3
        case 300...:
            penalty += 2
        case let amount where amount > 0:
            penalty += 1
        default:
            break
        }

        return min(penalty, 5)
    }

    private static func weightedLoad(for records: [Record], direction: RecordDirection) -> Int {
        records
            .filter { $0.direction == direction }
            .reduce(0) { $0 + $1.relationshipWeight.healthLoad }
    }

    private static func level(for score: Int) -> RelationshipHealthLevel {
        switch score {
        case 75...:
            .close
        case 55...:
            .stable
        case 35...:
            .distant
        default:
            .needsAttention
        }
    }
}

private extension RelationshipWeight {
    var healthLoad: Int {
        switch self {
        case .trivial:
            1
        case .kindness:
            2
        case .reciprocal:
            3
        case .support:
            4
        case .profound:
            5
        }
    }
}
