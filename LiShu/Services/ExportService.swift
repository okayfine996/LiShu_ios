import Foundation
import Logging
import SwiftData

private nonisolated(unsafe) var exportLogger: Logger { PulseDiagnostics.makeLogger(label: AppLogLabel.export) }
private nonisolated(unsafe) var importLogger: Logger { PulseDiagnostics.makeLogger(label: AppLogLabel.importFlow) }

struct ExportService {

    // MARK: - CSV Export

    /// 表头：`备注` 后为 6 列类型平铺字段，不含 `kvData`；不含退礼展示用「状态」列。
    private static let csvHeader =
        "联系人,事件,事件类型,金额,方向,支付方式,已退金额,日期,记录类型,情分分量,人情描述,备注,礼品名称,礼品估值,帮忙说明,宴请地点,宴请宾客,宴请额外费用"

    static func exportCSV(context: ModelContext) throws -> String {
        exportLogger.notice("Starting CSV export", metadata: [
            "step": .string("export_csv")
        ])
        let records = try context.fetch(FetchDescriptor<Record>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        ))

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"

        let rows = records.compactMap { record -> String? in
            guard let contact = record.contact else { return nil }
            let flat = flatTypeColumnsForExport(record)
            guard flat.count == 6 else { return nil }
            return [
                escapeCSV(contact.name),
                escapeCSV(record.event?.name ?? ""),
                escapeCSV(record.event?.type.displayName ?? ""),
                String(format: "%.2f", record.resolvedDisplayAmount),
                escapeCSV(record.direction.csvValue),
                escapeCSV(record.isMonetary ? record.resolvedPaymentMethod.csvValue : ""),
                String(format: "%.2f", record.resolvedReturnedAmount),
                escapeCSV(formatter.string(from: record.date)),
                escapeCSV(record.recordType.displayName),
                escapeCSV(record.relationshipWeight.displayName),
                escapeCSV(record.resolvedDescription),
                escapeCSV(record.note),
                flat[0],
                flat[1],
                flat[2],
                flat[3],
                flat[4],
                flat[5],
            ].joined(separator: ",")
        }

        let content = ([csvHeader] + rows).joined(separator: "\n")
        exportLogger.notice("Finished CSV export", metadata: [
            "step": .string("export_csv"),
            "count": .stringConvertible(rows.count),
            "result": .string("success")
        ])
        return content
    }

    /// 返回 6 个已 `escapeCSV` 的字段：礼品名称、礼品估值、帮忙说明、宴请地点、宴请宾客、宴请额外费用。
    private static func flatTypeColumnsForExport(_ record: Record) -> [String] {
        switch record.recordType {
        case .monetary:
            return Array(repeating: "", count: 6)
        case .gift:
            let g = record.giftData
            let name = g?.giftName ?? ""
            let estStr: String
            if let est = g?.estimatedValue {
                estStr = String(format: "%.2f", est)
            } else {
                estStr = ""
            }
            return [
                escapeCSV(name),
                escapeCSV(estStr),
                "", "", "", "",
            ]
        case .favor:
            let d = record.favorData?.description ?? ""
            return [
                "", "",
                escapeCSV(d),
                "", "", "",
            ]
        case .banquet:
            let b = record.banquetData
            return [
                "", "", "",
                escapeCSV(b?.location ?? ""),
                escapeCSV(b?.attendeeList ?? ""),
                escapeCSV(b?.extraCostNotes ?? ""),
            ]
        }
    }

    static func escapeCSV(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return value
    }

    // MARK: - CSV Import

    static func importCSV(url: URL, context: ModelContext) throws -> ImportResult {
        importLogger.notice("Starting CSV import", metadata: [
            "step": .string("import_csv"),
            "source": .string(url.lastPathComponent)
        ])
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let content = try String(contentsOf: url, encoding: .utf8)
        let rows = parseCSVRows(content)

        guard rows.count > 1 else {
            importLogger.warning("CSV import finished without data rows", metadata: [
                "step": .string("import_csv"),
                "source": .string(url.lastPathComponent),
                "reason": .string("empty_rows")
            ])
            return ImportResult()
        }

        let headerRow = rows[0]
        let columnIndex = buildCSVColumnIndexMap(headerRow)
        guard columnIndex["联系人"] != nil else {
            var r = ImportResult()
            r.errors = rows.count - 1
            importLogger.error("CSV import failed validation", metadata: [
                "step": .string("import_csv"),
                "source": .string(url.lastPathComponent),
                "reason": .string("missing_contact_column"),
                "count": .stringConvertible(r.errors)
            ])
            return r
        }

        let hasRecordTypeColumn = columnIndex["记录类型"] != nil
        /// 仅在表头含「记录类型」且存在任一类型平铺列名时，按平铺列参与 Gift/Favor/Banquet 组装。
        let hasFlatTypeData = hasRecordTypeColumn && csvImportHasFlatTypeColumns(columnIndex)

        var result = ImportResult()

        for (rowIndex, rawFields) in rows.dropFirst().enumerated() {
            if rawFields.allSatisfy({ $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
                continue
            }

            let fields = alignFieldsToHeader(rawFields, headerColumnCount: headerRow.count)

            let contactName = csvCell(fields, columnIndex: columnIndex, column: "联系人")
            guard !contactName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                result.errors += 1
                importLogger.warning("Skipped CSV row", metadata: [
                    "step": .string("import_csv"),
                    "source": .string(url.lastPathComponent),
                    "reason": .string("missing_contact_name"),
                    "count": .stringConvertible(rowIndex + 2)
                ])
                continue
            }

            let eventName = csvCell(fields, columnIndex: columnIndex, column: "事件")
            let eventTypeStr = csvCell(fields, columnIndex: columnIndex, column: "事件类型")
            let amountStr = csvCell(fields, columnIndex: columnIndex, column: "金额")
            let directionStr = csvCell(fields, columnIndex: columnIndex, column: "方向")
            let paymentStr = csvCell(fields, columnIndex: columnIndex, column: "支付方式")
            let returnedStr = csvCell(fields, columnIndex: columnIndex, column: "已退金额")
            let dateStr = csvCell(fields, columnIndex: columnIndex, column: "日期")

            let recordType: RecordType
            let relationshipWeight: RelationshipWeight
            let favorDescription: String
            let note: String
            var giftName: String = ""
            var giftEstimatedValueStr: String = ""
            var favorHelp: String = ""
            var banquetLocation: String = ""
            var banquetAttendees: String = ""
            var banquetExtra: String = ""

            if !hasRecordTypeColumn {
                recordType = .monetary
                relationshipWeight = .reciprocal
                favorDescription = ""
                giftName = ""
                giftEstimatedValueStr = ""
                favorHelp = ""
                banquetLocation = ""
                banquetAttendees = ""
                banquetExtra = ""
                note = csvCell(fields, columnIndex: columnIndex, column: "备注")
            } else {
                recordType = parseRecordType(csvCell(fields, columnIndex: columnIndex, column: "记录类型"))
                if columnIndex["情分分量"] != nil {
                    relationshipWeight = parseRelationshipWeight(csvCell(fields, columnIndex: columnIndex, column: "情分分量"))
                } else {
                    relationshipWeight = .reciprocal
                }
                favorDescription = csvCell(fields, columnIndex: columnIndex, column: "人情描述")
                note = csvCell(fields, columnIndex: columnIndex, column: "备注")
                giftName = csvCell(fields, columnIndex: columnIndex, column: "礼品名称")
                giftEstimatedValueStr = csvCell(fields, columnIndex: columnIndex, column: "礼品估值")
                favorHelp = csvCell(fields, columnIndex: columnIndex, column: "帮忙说明")
                banquetLocation = csvCell(fields, columnIndex: columnIndex, column: "宴请地点")
                banquetAttendees = csvCell(fields, columnIndex: columnIndex, column: "宴请宾客")
                banquetExtra = csvCell(fields, columnIndex: columnIndex, column: "宴请额外费用")
            }

            let amount = UserEnteredDecimal.parse(amountStr) ?? 0

            if recordType.isMonetary {
                guard amount > 0 else {
                    result.errors += 1
                    importLogger.warning("Skipped CSV row", metadata: [
                        "step": .string("import_csv"),
                        "source": .string(url.lastPathComponent),
                        "reason": .string("invalid_monetary_amount"),
                        "count": .stringConvertible(rowIndex + 2)
                    ])
                    continue
                }
            } else {
                guard nonMonetaryImportHasPayload(
                    recordType: recordType,
                    humanDesc: favorDescription,
                    giftName: giftName,
                    giftEstStr: giftEstimatedValueStr,
                    favorHelp: favorHelp,
                    banquetLoc: banquetLocation,
                    banquetAtt: banquetAttendees,
                    banquetExtra: banquetExtra,
                    amount: amount
                ) else {
                    result.errors += 1
                    importLogger.warning("Skipped CSV row", metadata: [
                        "step": .string("import_csv"),
                        "source": .string(url.lastPathComponent),
                        "reason": .string("missing_non_monetary_payload"),
                        "count": .stringConvertible(rowIndex + 2)
                    ])
                    continue
                }
            }

            let contact = findOrCreateContact(name: contactName, context: context)
            let eventType = parseEventType(eventTypeStr)
            let event = findOrCreateEventIfNeeded(name: eventName, type: eventType, context: context)
            let direction = parseDirection(directionStr)
            let paymentMethod = parsePaymentMethod(paymentStr)
            let returnedAmount = recordType.isMonetary ? (UserEnteredDecimal.parse(returnedStr) ?? 0) : 0
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

            let typeData = buildTypeDataForImport(
                recordType: recordType,
                amount: amount,
                paymentMethod: paymentMethod,
                returnedAmount: returnedAmount,
                humanDesc: favorDescription,
                giftName: giftName,
                giftEstStr: giftEstimatedValueStr,
                favorHelp: favorHelp,
                banquetLoc: banquetLocation,
                banquetAtt: banquetAttendees,
                banquetExtra: banquetExtra,
                hasFlatColumns: hasFlatTypeData
            )
            record.applyTypeData(typeData)

            context.insert(record)
            result.imported += 1
        }

        try context.save()
        importLogger.notice("Finished CSV import", metadata: [
            "step": .string("import_csv"),
            "source": .string(url.lastPathComponent),
            "count": .stringConvertible(result.imported),
            "result": .string("success"),
            "errors": .stringConvertible(result.errors)
        ])
        return result
    }

    /// 表头列名 → 列下标（同名取第一次出现）。
    private static func buildCSVColumnIndexMap(_ headerRow: [String]) -> [String: Int] {
        var map: [String: Int] = [:]
        for (i, raw) in headerRow.enumerated() {
            let key = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty else { continue }
            if map[key] == nil {
                map[key] = i
            }
        }
        return map
    }

    /// 将数据行对齐到表头列数：不足补空串，多余截断（仅与表头对齐，不再按固定列数推断语义）。
    private static func alignFieldsToHeader(_ fields: [String], headerColumnCount: Int) -> [String] {
        if fields.count >= headerColumnCount {
            return Array(fields.prefix(headerColumnCount))
        }
        return fields + Array(repeating: "", count: headerColumnCount - fields.count)
    }

    private static func csvCell(_ row: [String], columnIndex: [String: Int], column: String) -> String {
        let key = column.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let idx = columnIndex[key], idx < row.count else { return "" }
        return row[idx]
    }

    private static let csvFlatTypeColumnNames: [String] = [
        "礼品名称", "礼品估值", "帮忙说明", "宴请地点", "宴请宾客", "宴请额外费用",
    ]

    private static func csvImportHasFlatTypeColumns(_ columnIndex: [String: Int]) -> Bool {
        csvFlatTypeColumnNames.contains { columnIndex[$0] != nil }
    }

    private static func nonMonetaryImportHasPayload(
        recordType: RecordType,
        humanDesc: String,
        giftName: String,
        giftEstStr: String,
        favorHelp: String,
        banquetLoc: String,
        banquetAtt: String,
        banquetExtra: String,
        amount: Double
    ) -> Bool {
        let h = humanDesc.trimmingCharacters(in: .whitespacesAndNewlines)
        switch recordType {
        case .monetary:
            return true
        case .gift:
            let g = giftName.trimmingCharacters(in: .whitespacesAndNewlines)
            let e = giftEstStr.trimmingCharacters(in: .whitespacesAndNewlines)
            return !g.isEmpty || !h.isEmpty || amount > 0 || !e.isEmpty
        case .favor:
            let f = favorHelp.trimmingCharacters(in: .whitespacesAndNewlines)
            return !f.isEmpty || !h.isEmpty
        case .banquet:
            return !banquetLoc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || !banquetAtt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || !banquetExtra.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || !h.isEmpty
        }
    }

    private static func buildTypeDataForImport(
        recordType: RecordType,
        amount: Double,
        paymentMethod: PaymentMethod,
        returnedAmount: Double,
        humanDesc: String,
        giftName: String,
        giftEstStr: String,
        favorHelp: String,
        banquetLoc: String,
        banquetAtt: String,
        banquetExtra: String,
        hasFlatColumns: Bool
    ) -> RecordTypeData {
        let h = humanDesc.trimmingCharacters(in: .whitespacesAndNewlines)
        switch recordType {
        case .monetary:
            return .monetary(MonetaryData(amount: amount, paymentMethod: paymentMethod.rawValue, returnedAmount: returnedAmount))
        case .gift:
            let name: String
            if hasFlatColumns {
                let g = giftName.trimmingCharacters(in: .whitespacesAndNewlines)
                name = g.isEmpty ? h : g
            } else {
                name = h
            }
            let estFromFlat = UserEnteredDecimal.parse(giftEstStr)
            let estimatedValue: Double?
            if hasFlatColumns {
                if let v = estFromFlat, v > 0 {
                    estimatedValue = v
                } else if amount > 0 {
                    estimatedValue = amount
                } else {
                    estimatedValue = nil
                }
            } else {
                estimatedValue = amount > 0 ? amount : nil
            }
            return .gift(GiftData(giftName: name, estimatedValue: estimatedValue))
        case .favor:
            let desc: String
            if hasFlatColumns {
                let f = favorHelp.trimmingCharacters(in: .whitespacesAndNewlines)
                desc = f.isEmpty ? h : f
            } else {
                desc = h
            }
            return .favor(FavorData(description: desc))
        case .banquet:
            if hasFlatColumns {
                let loc = banquetLoc.trimmingCharacters(in: .whitespacesAndNewlines)
                let att = banquetAtt.trimmingCharacters(in: .whitespacesAndNewlines)
                let ex = banquetExtra.trimmingCharacters(in: .whitespacesAndNewlines)
                let location = loc.isEmpty ? h : loc
                return .banquet(BanquetData(location: location, attendeeList: att, extraCostNotes: ex))
            }
            return .banquet(BanquetData(location: h, attendeeList: "", extraCostNotes: ""))
        }
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
            importLogger.info("Reused contact during import", metadata: [
                "step": .string("find_or_create_contact"),
                "result": .string("existing"),
                "contact_id": .string(String(describing: existing.persistentModelID))
            ])
            return existing
        }
        let contact = Contact(name: trimmed)
        context.insert(contact)
        importLogger.info("Created contact during import", metadata: [
            "step": .string("find_or_create_contact"),
            "result": .string("created"),
            "target": .string(trimmed)
        ])
        return contact
    }

    static func findOrCreateEvent(name: String, type: EventType, context: ModelContext) -> Event {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let typeRaw = type.rawValue
        let predicate = #Predicate<Event> { $0.name == trimmed && $0.typeRaw == typeRaw }
        var descriptor = FetchDescriptor<Event>(predicate: predicate)
        descriptor.fetchLimit = 1

        if let existing = try? context.fetch(descriptor).first {
            importLogger.info("Reused event during import", metadata: [
                "step": .string("find_or_create_event"),
                "result": .string("existing"),
                "event_id": .string(String(describing: existing.persistentModelID))
            ])
            return existing
        }
        let event = Event(name: trimmed, type: type)
        context.insert(event)
        importLogger.info("Created event during import", metadata: [
            "step": .string("find_or_create_event"),
            "result": .string("created"),
            "target": .string(trimmed)
        ])
        return event
    }

    static func findOrCreateEventIfNeeded(name: String, type: EventType, context: ModelContext) -> Event? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return findOrCreateEvent(name: trimmed, type: type, context: context)
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

// MARK: - Export Value Extensions

private extension RecordDirection {
    var csvValue: String {
        switch self {
        case .given: return String(localized: "record.direction.given")
        case .received: return String(localized: "record.direction.received")
        }
    }
}

private extension PaymentMethod {
    var csvValue: String {
        switch self {
        case .cash: return String(localized: "payment.cash")
        case .wechat: return String(localized: "payment.wechat")
        case .alipay: return String(localized: "payment.alipay")
        }
    }
}
