import Foundation
import SwiftData

struct CircleMemberItem: Identifiable {
    let contact: Contact
    let income: Double
    let expense: Double
    let lastRecordDate: Date?

    var id: PersistentIdentifier {
        contact.persistentModelID
    }

    var netValue: Double {
        income - expense
    }

    var totalAmount: Double {
        income + expense
    }
}

@Observable
class CircleDetailViewModel {
    var circle: Int = 1
    var circleName: String = ""
    var circleIcon: String = ""
    var closenessLevel: String = ""
    var memberCount: Int = 0
    var totalAmount: Double = 0
    var totalIncome: Double = 0
    var totalExpense: Double = 0
    var netValue: Double = 0
    var averageAmount: Double = 0
    var averageNetValue: Double = 0
    var members: [CircleMemberItem] = []
    var state: LoadingState<Bool> = .idle

    func load(circle: Int, year: Int, context: ModelContext) {
        self.circle = circle
        state = .loading

        circleName = circleDisplayName(circle)
        circleIcon = circleSystemIcon(circle)
        closenessLevel = circleCloseness(circle)

        let calendar = Calendar.current

        do {
            let descriptor = FetchDescriptor<Contact>(
                predicate: #Predicate<Contact> { $0.circle == circle }
            )
            let contacts = try context.fetch(descriptor)
            var queryRecords: [Record] = []

            var memberItems: [CircleMemberItem] = []
            var sumIncome: Double = 0
            var sumExpense: Double = 0
            var activeMemberCount = 0

            for contact in contacts {
                let yearRecords = (contact.records ?? []).filter {
                    calendar.component(.year, from: $0.date) == year
                }
                guard !yearRecords.isEmpty else { continue }
                queryRecords.append(contentsOf: yearRecords)

                activeMemberCount += 1

                let income = yearRecords
                    .filter { $0.direction == .received }
                    .reduce(0.0) { $0 + $1.resolvedDisplayAmount }
                let expense = yearRecords
                    .filter { $0.direction == .given }
                    .reduce(0.0) { $0 + $1.resolvedDisplayAmount }
                let lastDate = yearRecords.map(\.date).max()

                sumIncome += income
                sumExpense += expense

                memberItems.append(CircleMemberItem(
                    contact: contact,
                    income: income,
                    expense: expense,
                    lastRecordDate: lastDate
                ))
            }

            memberCount = activeMemberCount
            totalIncome = sumIncome
            totalExpense = sumExpense
            totalAmount = sumIncome + sumExpense
            netValue = sumIncome - sumExpense

            let count = Double(max(memberCount, 1))
            averageAmount = totalAmount / count
            averageNetValue = netValue / count

            members = memberItems.sorted { abs($0.netValue) > abs($1.netValue) }

            state = .loaded(true)
            BusinessDataLogger.recordQuery(
                screen: "statistics.circleDetail",
                operation: "load",
                searchText: "",
                filters: [
                    "circle": String(circle),
                    "year": String(year),
                ],
                sort: "net_value_desc",
                records: queryRecords.sorted { $0.date > $1.date }
            )
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    // MARK: - Display Helpers

    func circleDisplayName(_ circle: Int) -> String {
        switch circle {
        case 1: String(localized: "statistics.circle.family")
        case 2: String(localized: "statistics.circle.close")
        case 3: String(localized: "statistics.circle.social")
        default: String(localized: "statistics.circle.other")
        }
    }

    private func circleSystemIcon(_ circle: Int) -> String {
        switch circle {
        case 1: "figure.2.and.child.holdinghands"
        case 2: "person.2"
        case 3: "building.2"
        default: "person.3"
        }
    }

    private func circleCloseness(_ circle: Int) -> String {
        switch circle {
        case 1: String(localized: "circle.detail.closeness.high")
        case 2: String(localized: "circle.detail.closeness.medium")
        case 3: String(localized: "circle.detail.closeness.low")
        default: String(localized: "circle.detail.closeness.general")
        }
    }

    // MARK: - Formatting

    func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return "¥" + (formatter.string(from: NSNumber(value: amount)) ?? String(format: "%.0f", amount))
    }

    func formatCompactAmount(_ amount: Double) -> String {
        if abs(amount) >= 10000 {
            return String(format: "%.1fw", amount / 10000)
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? String(format: "%.0f", amount)
    }

    func formatNetValue(_ value: Double) -> String {
        let prefix = value >= 0 ? "+" : ""
        return prefix + formatAmount(value)
    }
}
