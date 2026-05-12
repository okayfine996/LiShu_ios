import Foundation
import SwiftData

struct HomeRelationshipHealthItem: Identifiable {
    let contact: Contact
    let relationshipHealth: RelationshipHealthResult

    var id: PersistentIdentifier {
        contact.persistentModelID
    }
}

struct HomeDashboardSnapshot {
    let currentYear: Int
    let yearlyIncome: Double
    let yearlyExpense: Double
    let contactCount: Int
    let recordCount: Int
    let monetaryCount: Int
    let nonFinancialInteractionCount: Int
    let coreCircleActiveContactCount: Int
    let giftCount: Int
    let favorCount: Int
    let banquetCount: Int
    let previousYearTotalExchangeAmount: Double
    let pendingReturnCount: Int
    let mostActiveContactName: String?
    let mostActiveContactRecordCount: Int
    let recentRecords: [Record]
    let upcomingEvents: [Event]
    let hostLedgerEvents: [Event]
    let staleContacts: [HomeRelationshipHealthItem]

    var totalExchangeAmount: Double {
        yearlyIncome + yearlyExpense
    }

    var incomeRatio: Double {
        guard totalExchangeAmount > 0 else { return 0 }
        return yearlyIncome / totalExchangeAmount
    }

    var expenseRatio: Double {
        guard totalExchangeAmount > 0 else { return 0 }
        return yearlyExpense / totalExchangeAmount
    }

    var yearOverYearChangeRate: Double? {
        guard previousYearTotalExchangeAmount > 0 else { return nil }
        return (totalExchangeAmount - previousYearTotalExchangeAmount) / previousYearTotalExchangeAmount
    }

    var coreCircleRatioPercent: Int {
        guard contactCount > 0 else { return 0 }
        return Int((Double(coreCircleActiveContactCount) / Double(contactCount) * 100).rounded())
    }

    static func build(
        records: [Record],
        events: [Event],
        contacts: [Contact],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> HomeDashboardSnapshot {
        let currentYear = calendar.component(.year, from: now)
        let today = calendar.startOfDay(for: now)

        guard let startOfYear = calendar.date(from: DateComponents(year: currentYear, month: 1, day: 1)),
              let endOfYear = calendar.date(from: DateComponents(year: currentYear + 1, month: 1, day: 1)),
              let startOfPreviousYear = calendar.date(from: DateComponents(year: currentYear - 1, month: 1, day: 1))
        else {
            return .empty(currentYear: currentYear)
        }

        let contactsByID = Dictionary(uniqueKeysWithValues: contacts.map { ($0.persistentModelID, $0) })
        let currentYearRecords = records.filter { $0.date >= startOfYear && $0.date < endOfYear }
        let previousYearRecords = records.filter { $0.date >= startOfPreviousYear && $0.date < startOfYear }
        let monetaryRecords = currentYearRecords.filter { $0.recordType == .monetary }
        let previousYearMonetaryRecords = previousYearRecords.filter { $0.recordType == .monetary }

        let yearlyIncome = monetaryRecords
            .filter { $0.direction == .received }
            .reduce(0.0) { $0 + $1.monetaryAmount }

        let yearlyExpense = monetaryRecords
            .filter { $0.direction == .given }
            .reduce(0.0) { $0 + $1.monetaryAmount }

        let contactIDs = Set<PersistentIdentifier>(currentYearRecords.compactMap { $0.contact?.persistentModelID })
        let coreCircleContactIDs = Set<PersistentIdentifier>(currentYearRecords.compactMap { record in
            guard let contactID = record.contact?.persistentModelID,
                  let contact = contactsByID[contactID] ?? record.contact,
                  contact.circle <= 2
            else {
                return nil
            }
            return contactID
        })

        var interactionCountsByContact: [PersistentIdentifier: (name: String, count: Int)] = [:]
        for record in currentYearRecords {
            guard let contactID = record.contact?.persistentModelID else { continue }
            let contact = contactsByID[contactID] ?? record.contact
            let contactName = contact?.name ?? ""
            var value = interactionCountsByContact[contactID] ?? (name: contactName, count: 0)
            value.name = contactName
            value.count += 1
            interactionCountsByContact[contactID] = value
        }

        let mostActiveContact = interactionCountsByContact.values.max { lhs, rhs in
            if lhs.count == rhs.count {
                return lhs.name > rhs.name
            }
            return lhs.count < rhs.count
        }

        let upcomingEvents = events
            .filter { $0.date >= today }
            .sorted { $0.date < $1.date }
            .prefix(5)

        let pendingReturnCount = events
            .filter { event in
                event.date >= startOfYear && event.date < endOfYear &&
                    event.hostMode == .guest &&
                    !(event.records ?? []).contains { $0.direction == .given }
            }
            .count

        let hostLedgerEvents = events
            .filter { $0.hostMode == .host }
            .sorted { lhs, rhs in
                let lhsUpcoming = lhs.date >= today
                let rhsUpcoming = rhs.date >= today
                if lhsUpcoming != rhsUpcoming {
                    return lhsUpcoming && !rhsUpcoming
                }
                if lhsUpcoming {
                    return lhs.date < rhs.date
                }
                return lhs.date > rhs.date
            }
            .prefix(20)

        let healthResults = RelationshipHealthCalculator.evaluateAll(contacts: contacts, now: now, calendar: calendar)
        let staleContacts = contacts
            .compactMap { contact -> HomeRelationshipHealthItem? in
                guard let result = healthResults[contact.persistentModelID],
                      result.hasRecords,
                      result.level == .distant || result.level == .needsAttention
                else { return nil }
                return HomeRelationshipHealthItem(contact: contact, relationshipHealth: result)
            }
            .sorted { lhs, rhs in
                if lhs.relationshipHealth.daysSinceLastInteraction == rhs.relationshipHealth.daysSinceLastInteraction {
                    return lhs.contact.name < rhs.contact.name
                }
                return lhs.relationshipHealth.daysSinceLastInteraction > rhs.relationshipHealth.daysSinceLastInteraction
            }
            .prefix(3)

        return HomeDashboardSnapshot(
            currentYear: currentYear,
            yearlyIncome: yearlyIncome,
            yearlyExpense: yearlyExpense,
            contactCount: contactIDs.count,
            recordCount: currentYearRecords.count,
            monetaryCount: monetaryRecords.count,
            nonFinancialInteractionCount: currentYearRecords.filter { $0.recordType != .monetary }.count,
            coreCircleActiveContactCount: coreCircleContactIDs.count,
            giftCount: currentYearRecords.filter { $0.recordType == .gift }.count,
            favorCount: currentYearRecords.filter { $0.recordType == .favor }.count,
            banquetCount: currentYearRecords.filter { $0.recordType == .banquet }.count,
            previousYearTotalExchangeAmount: previousYearMonetaryRecords.reduce(0.0) { $0 + $1.monetaryAmount },
            pendingReturnCount: pendingReturnCount,
            mostActiveContactName: mostActiveContact?.name,
            mostActiveContactRecordCount: mostActiveContact?.count ?? 0,
            recentRecords: Array(records.sorted { $0.date > $1.date }.prefix(5)),
            upcomingEvents: Array(upcomingEvents),
            hostLedgerEvents: Array(hostLedgerEvents),
            staleContacts: Array(staleContacts)
        )
    }

    private static func empty(currentYear: Int) -> HomeDashboardSnapshot {
        HomeDashboardSnapshot(
            currentYear: currentYear,
            yearlyIncome: 0,
            yearlyExpense: 0,
            contactCount: 0,
            recordCount: 0,
            monetaryCount: 0,
            nonFinancialInteractionCount: 0,
            coreCircleActiveContactCount: 0,
            giftCount: 0,
            favorCount: 0,
            banquetCount: 0,
            previousYearTotalExchangeAmount: 0,
            pendingReturnCount: 0,
            mostActiveContactName: nil,
            mostActiveContactRecordCount: 0,
            recentRecords: [],
            upcomingEvents: [],
            hostLedgerEvents: [],
            staleContacts: []
        )
    }
}
