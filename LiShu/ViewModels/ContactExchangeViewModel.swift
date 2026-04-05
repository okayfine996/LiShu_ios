import Foundation
import SwiftData

@Observable
class ContactExchangeViewModel {
    var contact: Contact?
    var records: [Record] = []

    var totalGiven: Double {
        records.filter { $0.direction == .given }.reduce(0) { $0 + $1.resolvedDisplayAmount }
    }

    var totalReceived: Double {
        records.filter { $0.direction == .received }.reduce(0) { $0 + $1.resolvedDisplayAmount }
    }

    var netValue: Double {
        totalReceived - totalGiven
    }

    var givenRatio: Double {
        let total = totalGiven + totalReceived
        guard total > 0 else { return 0.5 }
        return totalGiven / total
    }

    var netLabel: String {
        if netValue > 0 {
            String(localized: "exchange.net.theyOwe")
        } else if netValue < 0 {
            String(localized: "exchange.net.iOwe")
        } else {
            String(localized: "exchange.net.even")
        }
    }

    var lastContactText: String? {
        guard let latest = records.first?.date else { return nil }
        let days = Calendar.current.dateComponents([.day], from: latest, to: .now).day ?? 0
        if days == 0 {
            return String(localized: "exchange.lastContact.today")
        } else {
            return String(format: String(localized: "exchange.lastContact.daysAgo"), days)
        }
    }

    func load(contactID: PersistentIdentifier, context: ModelContext) {
        contact = context.model(for: contactID) as? Contact
        guard let contact else {
            records = []
            return
        }
        records = (contact.records ?? []).sorted { $0.date > $1.date }
    }

    func formatAmount(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return "¥" + (formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value))
    }

    func formatNetAmount() -> String {
        let prefix = netValue >= 0 ? "+" : ""
        return prefix + formatAmount(abs(netValue))
    }

    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = String(localized: "exchange.dateFormat")
        return formatter.string(from: date)
    }
}
