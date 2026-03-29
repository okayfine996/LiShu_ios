import Foundation
import SwiftData

struct ExportService {
    private static let dateFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    // MARK: - JSON Export

    static func exportJSON(context: ModelContext) throws -> Data {
        let records = try context.fetch(FetchDescriptor<Record>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        ))

        let items = records.compactMap { record -> ExportRecordItem? in
            guard let contact = record.contact, let event = record.event else { return nil }
            return ExportRecordItem(
                contactName: contact.name,
                eventName: event.name,
                eventType: event.type.displayName,
                amount: record.amount,
                direction: record.direction.exportValue,
                paymentMethod: record.paymentMethod.exportValue,
                returnedAmount: record.returnedAmount,
                status: record.status.exportValue(direction: record.direction),
                date: dateFormatter.string(from: record.date),
                note: record.note
            )
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return try encoder.encode(items)
    }

    // MARK: - CSV Export

    static func exportCSV(context: ModelContext) throws -> String {
        let records = try context.fetch(FetchDescriptor<Record>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        ))

        let header = "联系人,事件,事件类型,金额,方向,支付方式,已退金额,状态,日期,备注"
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"

        let rows = records.compactMap { record -> String? in
            guard let contact = record.contact, let event = record.event else { return nil }
            return [
                escapeCSV(contact.name),
                escapeCSV(event.name),
                escapeCSV(event.type.displayName),
                String(format: "%.2f", record.amount),
                escapeCSV(record.direction.csvValue),
                escapeCSV(record.paymentMethod.csvValue),
                String(format: "%.2f", record.returnedAmount),
                escapeCSV(record.status.csvValue(direction: record.direction)),
                escapeCSV(formatter.string(from: record.date)),
                escapeCSV(record.note)
            ].joined(separator: ",")
        }

        return ([header] + rows).joined(separator: "\n")
    }

    static func escapeCSV(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return value
    }

    // MARK: - CSV Import

    static func importCSV(url: URL, context: ModelContext) throws -> ImportResult {
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let content = try String(contentsOf: url, encoding: .utf8)
        let rows = parseCSVRows(content)

        guard rows.count > 1 else { return ImportResult() }

        var result = ImportResult()

        for fields in rows.dropFirst() {
            if fields.allSatisfy({ $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
                continue
            }
            guard fields.count >= 9 else {
                result.errors += 1
                continue
            }

            let contactName = fields[0]
            let eventName = fields[1]
            let eventTypeStr = fields[2]
            let amountStr = fields[3]
            let directionStr = fields[4]
            let paymentStr = fields[5]
            let returnedStr = fields[6]
            let dateStr = fields[8]
            let note = fields.count > 9 ? fields[9] : ""

            guard let amount = Double(amountStr), amount > 0 else {
                result.errors += 1
                continue
            }

            let contact = findOrCreateContact(name: contactName, context: context)
            let eventType = parseEventType(eventTypeStr)
            let event = findOrCreateEvent(name: eventName, type: eventType, context: context)
            let direction = parseDirection(directionStr)
            let paymentMethod = parsePaymentMethod(paymentStr)
            let returnedAmount = Double(returnedStr) ?? 0
            let date = parseDate(dateStr) ?? Date()

            let record = Record(
                contact: contact,
                event: event,
                amount: amount,
                direction: direction,
                paymentMethod: paymentMethod,
                returnedAmount: returnedAmount,
                note: note,
                date: date
            )
            context.insert(record)
            result.imported += 1
        }

        try context.save()
        return result
    }

    static func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        var index = line.startIndex

        while index < line.endIndex {
            let ch = line[index]

            switch ch {
            case "\"":
                if inQuotes {
                    let next = line.index(after: index)
                    if next < line.endIndex && line[next] == "\"" {
                        current.append("\"")
                        index = next
                    } else {
                        inQuotes = false
                    }
                } else if current.isEmpty {
                    inQuotes = true
                } else {
                    current.append(ch)
                }
            case "," where !inQuotes:
                result.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            default:
                current.append(ch)
            }

            index = line.index(after: index)
        }

        result.append(current.trimmingCharacters(in: .whitespaces))
        return result
    }

    private static func parseCSVRows(_ content: String) -> [[String]] {
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var inQuotes = false
        var index = content.startIndex

        func commitField() {
            row.append(field.trimmingCharacters(in: .whitespaces))
            field = ""
        }

        func commitRow() {
            if row.count == 1 && row[0].isEmpty {
                row.removeAll()
                return
            }
            rows.append(row)
            row.removeAll()
        }

        while index < content.endIndex {
            let ch = content[index]

            switch ch {
            case "\"":
                if inQuotes {
                    let next = content.index(after: index)
                    if next < content.endIndex && content[next] == "\"" {
                        field.append("\"")
                        index = next
                    } else {
                        inQuotes = false
                    }
                } else if field.isEmpty {
                    inQuotes = true
                } else {
                    field.append(ch)
                }
            case "," where !inQuotes:
                commitField()
            case "\n" where !inQuotes, "\r" where !inQuotes:
                commitField()
                commitRow()
                if ch == "\r" {
                    let next = content.index(after: index)
                    if next < content.endIndex && content[next] == "\n" {
                        index = next
                    }
                }
            default:
                field.append(ch)
            }

            index = content.index(after: index)
        }

        if !field.isEmpty || !row.isEmpty {
            commitField()
            commitRow()
        }

        return rows
    }

    static func findOrCreateContact(name: String, context: ModelContext) -> Contact {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let predicate = #Predicate<Contact> { $0.name == trimmed }
        var descriptor = FetchDescriptor<Contact>(predicate: predicate)
        descriptor.fetchLimit = 1

        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let contact = Contact(name: trimmed)
        context.insert(contact)
        return contact
    }

    static func findOrCreateEvent(name: String, type: EventType, context: ModelContext) -> Event {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let typeRaw = type.rawValue
        let predicate = #Predicate<Event> { $0.name == trimmed && $0.typeRaw == typeRaw }
        var descriptor = FetchDescriptor<Event>(predicate: predicate)
        descriptor.fetchLimit = 1

        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let event = Event(name: trimmed, type: type)
        context.insert(event)
        return event
    }

    static func parseEventType(_ str: String) -> EventType {
        let s = str.trimmingCharacters(in: .whitespaces)
        switch s {
        case "婚礼": return .wedding
        case "丧葬": return .funeral
        case "满月": return .birth
        case "生日": return .birthday
        case "节庆": return .festival
        case "乔迁": return .property
        case "升学": return .education
        case "其他": return .other
        default: return .other
        }
    }

    static func parseDirection(_ str: String) -> RecordDirection {
        let s = str.trimmingCharacters(in: .whitespaces)
        switch s {
        case "送出", "随礼", "given": return .given
        case "收到", "收礼", "received": return .received
        default: return .given
        }
    }

    static func parsePaymentMethod(_ str: String) -> PaymentMethod {
        let s = str.trimmingCharacters(in: .whitespaces)
        switch s {
        case "现金", "cash": return .cash
        case "微信", "wechat": return .wechat
        case "支付宝", "alipay": return .alipay
        default: return .cash
        }
    }

    static func parseDate(_ str: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.date(from: str.trimmingCharacters(in: .whitespaces))
    }
}

// MARK: - Import Types

struct ImportResult {
    var imported: Int = 0
    var skipped: Int = 0
    var errors: Int = 0
}

enum ImportError: LocalizedError {
    case accessDenied
    case invalidFormat

    var errorDescription: String? {
        switch self {
        case .accessDenied: return String(localized: "import.error.accessDenied")
        case .invalidFormat: return String(localized: "import.error.invalidFormat")
        }
    }
}

// MARK: - Export Models

private struct ExportRecordItem: Encodable {
    let contactName: String
    let eventName: String
    let eventType: String
    let amount: Double
    let direction: String
    let paymentMethod: String
    let returnedAmount: Double
    let status: String
    let date: String
    let note: String
}

// MARK: - Export Value Extensions

private extension RecordDirection {
    var exportValue: String {
        switch self {
        case .given: return "given"
        case .received: return "received"
        }
    }

    var csvValue: String {
        switch self {
        case .given: return String(localized: "record.direction.given")
        case .received: return String(localized: "record.direction.received")
        }
    }
}

private extension PaymentMethod {
    var exportValue: String {
        rawValue
    }

    var csvValue: String {
        switch self {
        case .cash: return String(localized: "payment.cash")
        case .wechat: return String(localized: "payment.wechat")
        case .alipay: return String(localized: "payment.alipay")
        }
    }
}

private extension RecordStatus {
    func exportValue(direction: RecordDirection) -> String {
        if direction == .received { return "received" }
        return rawValue
    }

    func csvValue(direction: RecordDirection) -> String {
        if direction == .received { return String(localized: "record.status.received") }
        switch self {
        case .open: return String(localized: "record.status.open")
        case .partial: return String(localized: "record.status.partial")
        case .settled: return String(localized: "record.status.settled")
        }
    }
}
