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
            guard let contact = record.contact else { return nil }
            return ExportRecordItem(
                contactName: contact.name,
                eventName: record.event?.name ?? "",
                eventType: record.event?.type.displayName ?? "",
                amount: record.resolvedDisplayAmount,
                direction: record.direction.exportValue,
                paymentMethod: record.isMonetary ? record.resolvedPaymentMethod.exportValue : "",
                returnedAmount: record.resolvedReturnedAmount,
                status: record.exportReturnGiftStatusValue(for: record.direction),
                date: dateFormatter.string(from: record.date),
                recordType: record.recordType.rawValue,
                relationshipWeight: record.relationshipWeight.rawValue,
                favorDescription: record.resolvedDescription,
                note: record.note,
                kvData: record.kvData
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

        let header = "联系人,事件,事件类型,金额,方向,支付方式,已退金额,状态,日期,记录类型,情分分量,人情描述,备注,kvData"
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"

        let rows = records.compactMap { record -> String? in
            guard let contact = record.contact else { return nil }
            return [
                escapeCSV(contact.name),
                escapeCSV(record.event?.name ?? ""),
                escapeCSV(record.event?.type.displayName ?? ""),
                String(format: "%.2f", record.resolvedDisplayAmount),
                escapeCSV(record.direction.csvValue),
                escapeCSV(record.isMonetary ? record.resolvedPaymentMethod.csvValue : ""),
                String(format: "%.2f", record.resolvedReturnedAmount),
                escapeCSV(record.csvReturnGiftStatus(for: record.direction)),
                escapeCSV(formatter.string(from: record.date)),
                escapeCSV(record.recordType.displayName),
                escapeCSV(record.relationshipWeight.displayName),
                escapeCSV(record.resolvedDescription),
                escapeCSV(record.note),
                escapeCSV(record.kvData)
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

            // Detect format: new 14 columns (with relationship weight + kvData),
            // old 13 columns (with kvData), new 13 columns (with relationship weight),
            // old 12 columns (typed), or old 10 columns
            let recordType: RecordType
            let relationshipWeight: RelationshipWeight
            let favorDescription: String
            let note: String
            let kvDataStr: String?

            if fields.count >= 14 {
                recordType = parseRecordType(fields[9])
                relationshipWeight = parseRelationshipWeight(fields[10])
                favorDescription = fields[11]
                note = fields[12]
                kvDataStr = fields[13]
            } else if fields.count == 13 {
                let col12 = fields[12].trimmingCharacters(in: .whitespacesAndNewlines)
                if looksLikeRelationshipWeightColumn(fields[10]) {
                    recordType = parseRecordType(fields[9])
                    relationshipWeight = parseRelationshipWeight(fields[10])
                    favorDescription = fields[11]
                    note = fields[12]
                    kvDataStr = nil
                } else if col12.hasPrefix("{") {
                    recordType = parseRecordType(fields[9])
                    favorDescription = fields[10]
                    note = fields[11]
                    kvDataStr = fields[12]
                    relationshipWeight = .reciprocal
                } else {
                    recordType = parseRecordType(fields[9])
                    relationshipWeight = parseRelationshipWeight(fields[10])
                    favorDescription = fields[11]
                    note = fields[12]
                    kvDataStr = nil
                }
            } else if fields.count >= 12 {
                recordType = parseRecordType(fields[9])
                favorDescription = fields[10]
                note = fields[11]
                kvDataStr = nil
                relationshipWeight = .reciprocal
            } else {
                recordType = .monetary
                relationshipWeight = .reciprocal
                favorDescription = ""
                note = fields.count > 9 ? fields[9] : ""
                kvDataStr = nil
            }

            let amount = Double(amountStr) ?? 0

            // Validate: monetary requires amount > 0; non-monetary requires favorDescription
            if recordType.isMonetary {
                guard amount > 0 else {
                    result.errors += 1
                    continue
                }
            } else {
                guard !favorDescription.trimmingCharacters(in: .whitespaces).isEmpty else {
                    result.errors += 1
                    continue
                }
            }

            let contact = findOrCreateContact(name: contactName, context: context)
            let eventType = parseEventType(eventTypeStr)
            let event = findOrCreateEventIfNeeded(name: eventName, type: eventType, context: context)
            let direction = parseDirection(directionStr)
            let paymentMethod = parsePaymentMethod(paymentStr)
            let returnedAmount = recordType.isMonetary ? (Double(returnedStr) ?? 0) : 0
            let date = parseDate(dateStr) ?? Date()

            let record = Record(
                contact: contact,
                event: event,
                direction: direction,
                returnedAmount: returnedAmount,
                note: note,
                date: date,
                recordType: recordType,
                relationshipWeight: relationshipWeight
            )

            // Write kvData: use imported value if present, otherwise build from old fields
            if let kv = kvDataStr, !kv.isEmpty, kv != "{}" {
                record.kvData = kv
                record.updateStatus()
            } else {
                // Build type data from old fields for dual-write
                let typeData: RecordTypeData
                switch recordType {
                case .monetary:
                    typeData = .monetary(MonetaryData(amount: amount, paymentMethod: paymentMethod.rawValue, returnedAmount: returnedAmount))
                case .gift:
                    typeData = .gift(GiftData(giftName: favorDescription, estimatedValue: amount > 0 ? amount : nil))
                case .favor:
                    typeData = .favor(FavorData(description: favorDescription))
                case .banquet:
                    typeData = .banquet(BanquetData(location: favorDescription))
                }
                record.applyTypeData(typeData)
                record.updateStatus()
            }

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

    static func findOrCreateEventIfNeeded(name: String, type: EventType, context: ModelContext) -> Event? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return findOrCreateEvent(name: trimmed, type: type, context: context)
    }

    /// 区分「新 13 列」（第 10 列为情分分量）与「旧 13 列 + kvData」（第 12 列为 JSON）。
    private static func looksLikeRelationshipWeightColumn(_ raw: String) -> Bool {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return false }
        if RelationshipWeight(rawValue: s) != nil { return true }
        if RelationshipWeight.allCases.contains(where: { $0.displayName == s }) { return true }
        switch s {
        case "举手之劳", "点滴之恩", "礼尚往来", "倾力相助", "重如泰山":
            return true
        default:
            return false
        }
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

    static func parseRecordType(_ str: String) -> RecordType {
        let s = str.trimmingCharacters(in: .whitespaces)
        // Match by rawValue or display name
        if let byRaw = RecordType(rawValue: s) { return byRaw }
        switch s {
        case "金额": return .monetary
        case "礼品": return .gift
        case "帮忙": return .favor
        case "宴请": return .banquet
        case "其他": return .favor
        case "探望": return .favor
        default: return .monetary
        }
    }

    static func parseRelationshipWeight(_ str: String) -> RelationshipWeight {
        let s = str.trimmingCharacters(in: .whitespaces)
        if let byRaw = RelationshipWeight(rawValue: s) { return byRaw }
        switch s {
        case "举手之劳": return .trivial
        case "点滴之恩": return .kindness
        case "礼尚往来": return .reciprocal
        case "倾力相助": return .support
        case "重如泰山": return .profound
        default: return .reciprocal
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
    let recordType: String
    let relationshipWeight: String
    let favorDescription: String
    let note: String
    let kvData: String
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

private extension Record {
    func exportReturnGiftStatusValue(for direction: RecordDirection) -> String {
        if direction == .received { return "received" }
        if !isMonetary { return "not_applicable" }
        return hasReturnedGift ? "returned" : "none"
    }

    func csvReturnGiftStatus(for direction: RecordDirection) -> String {
        if direction == .received { return String(localized: "record.status.received") }
        if !isMonetary { return "" }
        return hasReturnedGift
            ? String(localized: "record.returnGift.returned")
            : String(localized: "record.returnGift.notReturned")
    }
}
