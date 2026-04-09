import Foundation
import Logging
import SwiftData

private let exportLogger = PulseDiagnostics.makeLogger(label: AppLogLabel.export)
private let importLogger = PulseDiagnostics.makeLogger(label: AppLogLabel.importFlow)

enum ExportService {
    private static let csvDateFormat = "yyyy-MM-dd HH:mm"
    private static let commonColumns = ["联系人", "事件", "事件类型", "场景标签", "方向", "日期", "备注"]
    private static let typeSpecificColumns: [RecordType: [String]] = [
        .monetary: ["金额", "支付方式", "已退金额"],
        .gift: ["礼品名称", "礼品估值", "人情描述"],
        .favor: ["帮忙说明", "人情描述"],
        .banquet: ["宴请地点", "宴请宾客", "宴请额外费用", "人情描述"],
    ]

    private static let allowedColumns = Set(commonColumns + typeSpecificColumns.values.flatMap(\.self))

    // MARK: - CSV Export

    static func exportCSV(context: ModelContext, recordType: RecordType) throws -> String {
        exportLogger.notice("Starting CSV export", metadata: [
            "step": .string("export_csv"),
            "record_type": .string(recordType.rawValue),
        ])

        let descriptor = FetchDescriptor<Record>(
            predicate: #Predicate<Record> { $0.recordTypeRaw == recordType.rawValue },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let records = try context.fetch(descriptor)
        let rows = records.compactMap { exportRow(for: $0, recordType: recordType) }
        let content = ([csvHeader(for: recordType)] + rows).joined(separator: "\n")

        exportLogger.notice("Finished CSV export", metadata: [
            "step": .string("export_csv"),
            "record_type": .string(recordType.rawValue),
            "count": .stringConvertible(rows.count),
            "result": .string("success"),
        ])
        return content
    }

    static func templateCSV(for recordType: RecordType) -> String {
        [csvHeader(for: recordType), templateRow(for: recordType)].joined(separator: "\n")
    }

    private static func csvHeader(for recordType: RecordType) -> String {
        (commonColumns + (typeSpecificColumns[recordType] ?? [])).joined(separator: ",")
    }

    private static func exportRow(for record: Record, recordType: RecordType) -> String? {
        guard record.recordType == recordType, let contact = record.contact else { return nil }
        guard let context = resolveExportContext(for: record) else {
            return nil
        }

        var values: [String: String] = [
            "联系人": contact.name,
            "事件": context.eventName,
            "事件类型": context.eventTypeName,
            "场景标签": context.sceneTag,
            "方向": record.direction.csvValue,
            "日期": csvDateFormatter.string(from: record.date),
            "备注": record.note,
        ]

        switch recordType {
        case .monetary:
            values["金额"] = String(format: "%.2f", record.monetaryAmount)
            values["支付方式"] = record.resolvedPaymentMethod.csvValue
            values["已退金额"] = String(format: "%.2f", record.resolvedReturnedAmount)
        case .gift:
            values["礼品名称"] = record.giftData?.giftName ?? ""
            values["礼品估值"] = if let estimatedValue = record.giftData?.estimatedValue {
                String(format: "%.2f", estimatedValue)
            } else {
                ""
            }
            values["人情描述"] = record.giftData?.giftName ?? ""
        case .favor:
            values["帮忙说明"] = record.favorData?.description ?? ""
            values["人情描述"] = record.favorData?.description ?? ""
        case .banquet:
            values["宴请地点"] = record.banquetData?.location ?? ""
            values["宴请宾客"] = record.banquetData?.attendeeList ?? ""
            values["宴请额外费用"] = record.banquetData?.extraCostNotes ?? ""
            values["人情描述"] = record.banquetData?.location ?? ""
        }

        return csvValues(for: recordType).map { escapeCSV(values[$0] ?? "") }.joined(separator: ",")
    }

    private static func templateRow(for recordType: RecordType) -> String {
        let values: [[String: String]] = switch recordType {
        case .monetary:
            [
                [
                    "联系人": "张三",
                    "事件": "婚礼",
                    "事件类型": "婚礼",
                    "场景标签": "",
                    "方向": "送出",
                    "日期": "2026-04-09 10:30",
                    "备注": "示例备注",
                    "金额": "800.00",
                    "支付方式": "微信",
                    "已退金额": "0.00",
                ],
                [
                    "联系人": "李四",
                    "事件": "",
                    "事件类型": "",
                    "场景标签": "节日看望",
                    "方向": "送出",
                    "日期": "2026-04-09 10:30",
                    "备注": "日常礼金示例",
                    "金额": "300.00",
                    "支付方式": "现金",
                    "已退金额": "0.00",
                ],
            ]
        case .gift:
            [
                [
                    "联系人": "李四",
                    "事件": "乔迁",
                    "事件类型": "乔迁",
                    "场景标签": "",
                    "方向": "送出",
                    "日期": "2026-04-09 10:30",
                    "备注": "示例备注",
                    "礼品名称": "景德镇茶具",
                    "礼品估值": "880.00",
                    "人情描述": "乔迁随礼品",
                ],
                [
                    "联系人": "王五",
                    "事件": "",
                    "事件类型": "",
                    "场景标签": "出差带特产",
                    "方向": "送出",
                    "日期": "2026-04-09 10:30",
                    "备注": "日常礼品示例",
                    "礼品名称": "地方特产礼盒",
                    "礼品估值": "260.00",
                    "人情描述": "出差顺手带回",
                ],
            ]
        case .favor:
            [
                [
                    "联系人": "王五",
                    "事件": "探望",
                    "事件类型": "探望",
                    "场景标签": "",
                    "方向": "送出",
                    "日期": "2026-04-09 10:30",
                    "备注": "示例备注",
                    "帮忙说明": "帮忙挂号预约",
                    "人情描述": "医院陪同",
                ],
                [
                    "联系人": "赵六",
                    "事件": "",
                    "事件类型": "",
                    "场景标签": "帮忙挂号",
                    "方向": "送出",
                    "日期": "2026-04-09 10:30",
                    "备注": "日常帮忙示例",
                    "帮忙说明": "帮忙代取检查报告",
                    "人情描述": "顺路代办",
                ],
            ]
        case .banquet:
            [
                [
                    "联系人": "赵六",
                    "事件": "商务宴请",
                    "事件类型": "其他",
                    "场景标签": "",
                    "方向": "送出",
                    "日期": "2026-04-09 10:30",
                    "备注": "示例备注",
                    "宴请地点": "兰亭包厢",
                    "宴请宾客": "张三、李四",
                    "宴请额外费用": "两瓶酒水",
                    "人情描述": "商务答谢宴",
                ],
                [
                    "联系人": "孙七",
                    "事件": "",
                    "事件类型": "",
                    "场景标签": "接风洗尘",
                    "方向": "送出",
                    "日期": "2026-04-09 10:30",
                    "备注": "日常宴请示例",
                    "宴请地点": "家常馆包间",
                    "宴请宾客": "老同学两位",
                    "宴请额外费用": "带了两瓶红酒",
                    "人情描述": "朋友聚餐接风",
                ],
            ]
        }

        return values
            .map { row in
                csvValues(for: recordType).map { escapeCSV(row[$0] ?? "") }.joined(separator: ",")
            }
            .joined(separator: "\n")
    }

    private static func csvValues(for recordType: RecordType) -> [String] {
        commonColumns + (typeSpecificColumns[recordType] ?? [])
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
            "source": .string(url.lastPathComponent),
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
                "reason": .string("empty_rows"),
            ])
            return ImportResult()
        }

        let headerRow = rows[0].map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        try validateCSVHeader(headerRow)
        let columnIndex = buildCSVColumnIndexMap(headerRow)

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
                    "count": .stringConvertible(rowIndex + 2),
                ])
                continue
            }

            let amountStr = csvCell(fields, columnIndex: columnIndex, column: "金额")
            let amount = UserEnteredDecimal.parse(amountStr) ?? 0
            let giftName = csvCell(fields, columnIndex: columnIndex, column: "礼品名称")
            let giftEstimatedValueStr = csvCell(fields, columnIndex: columnIndex, column: "礼品估值")
            let favorHelp = csvCell(fields, columnIndex: columnIndex, column: "帮忙说明")
            let banquetLocation = csvCell(fields, columnIndex: columnIndex, column: "宴请地点")
            let banquetAttendees = csvCell(fields, columnIndex: columnIndex, column: "宴请宾客")
            let banquetExtra = csvCell(fields, columnIndex: columnIndex, column: "宴请额外费用")
            let humanDescription = csvCell(fields, columnIndex: columnIndex, column: "人情描述")

            guard let inferredType = inferRecordType(
                amount: amount,
                giftName: giftName,
                giftEstimatedValueStr: giftEstimatedValueStr,
                favorHelp: favorHelp,
                banquetLocation: banquetLocation,
                banquetAttendees: banquetAttendees,
                banquetExtra: banquetExtra,
                humanDescription: humanDescription,
                columnIndex: columnIndex
            ) else {
                result.errors += 1
                importLogger.warning("Skipped CSV row", metadata: [
                    "step": .string("import_csv"),
                    "source": .string(url.lastPathComponent),
                    "reason": .string("missing_payload"),
                    "count": .stringConvertible(rowIndex + 2),
                ])
                continue
            }

            let eventName = csvCell(fields, columnIndex: columnIndex, column: "事件")
            let eventTypeStr = csvCell(fields, columnIndex: columnIndex, column: "事件类型")
            let sceneTag = csvCell(fields, columnIndex: columnIndex, column: "场景标签")
            let directionStr = csvCell(fields, columnIndex: columnIndex, column: "方向")
            let paymentStr = csvCell(fields, columnIndex: columnIndex, column: "支付方式")
            let returnedStr = csvCell(fields, columnIndex: columnIndex, column: "已退金额")
            let dateStr = csvCell(fields, columnIndex: columnIndex, column: "日期")
            let note = csvCell(fields, columnIndex: columnIndex, column: "备注")

            let trimmedEventName = eventName.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedSceneTag = sceneTag.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedEventName.isEmpty || !trimmedSceneTag.isEmpty else {
                result.skipped += 1
                importLogger.warning("Skipped CSV row", metadata: [
                    "step": .string("import_csv"),
                    "source": .string(url.lastPathComponent),
                    "reason": .string("missing_context"),
                    "count": .stringConvertible(rowIndex + 2),
                ])
                continue
            }

            if inferredType == .monetary, amount <= 0 {
                result.errors += 1
                importLogger.warning("Skipped CSV row", metadata: [
                    "step": .string("import_csv"),
                    "source": .string(url.lastPathComponent),
                    "reason": .string("invalid_monetary_amount"),
                    "count": .stringConvertible(rowIndex + 2),
                ])
                continue
            }

            let date = parseDate(dateStr) ?? Date()
            if parseDate(dateStr) == nil, !dateStr.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                importLogger.info("Fell back to current date during CSV import", metadata: [
                    "step": .string("import_csv"),
                    "source": .string(url.lastPathComponent),
                    "reason": .string("invalid_date_fallback"),
                    "count": .stringConvertible(rowIndex + 2),
                ])
            }

            if parseDate(dateStr) == nil, dateStr.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                importLogger.info("Fell back to current date during CSV import", metadata: [
                    "step": .string("import_csv"),
                    "source": .string(url.lastPathComponent),
                    "reason": .string("missing_date_fallback"),
                    "count": .stringConvertible(rowIndex + 2),
                ])
            }

            let contact = findOrCreateContact(name: contactName, context: context)
            let eventType = trimmedEventName.isEmpty ? .other : parseEventType(eventTypeStr)
            let event = findOrCreateEventIfNeeded(name: trimmedEventName, type: eventType, context: context)
            let direction = parseDirection(directionStr)
            let paymentMethod = parsePaymentMethod(paymentStr)
            let returnedAmount = inferredType == .monetary ? (UserEnteredDecimal.parse(returnedStr) ?? 0) : 0

            let record = Record(
                contact: contact,
                event: event,
                direction: direction,
                returnedAmount: returnedAmount,
                note: note,
                date: date,
                recordType: inferredType,
                relationshipWeight: .reciprocal
            )
            record.contextTag = trimmedEventName.isEmpty ? trimmedSceneTag : ""
            record.applyTypeData(buildTypeDataForImport(
                recordType: inferredType,
                amount: amount,
                paymentMethod: paymentMethod,
                returnedAmount: returnedAmount,
                humanDesc: humanDescription,
                giftName: giftName,
                giftEstStr: giftEstimatedValueStr,
                favorHelp: favorHelp,
                banquetLoc: banquetLocation,
                banquetAtt: banquetAttendees,
                banquetExtra: banquetExtra
            ))

            context.insert(record)
            result.imported += 1
        }

        try context.save()
        importLogger.notice("Finished CSV import", metadata: [
            "step": .string("import_csv"),
            "source": .string(url.lastPathComponent),
            "count": .stringConvertible(result.imported),
            "result": .string("success"),
            "errors": .stringConvertible(result.errors),
        ])
        return result
    }

    private static func validateCSVHeader(_ headerRow: [String]) throws {
        guard Set(commonColumns).isSubset(of: Set(headerRow)) else {
            throw ImportError.invalidFormat
        }

        guard headerRow.allSatisfy({ allowedColumns.contains($0) }) else {
            throw ImportError.invalidFormat
        }

        let hasTypeSpecificColumn = typeSpecificColumns.values
            .flatMap(\.self)
            .contains { Set(headerRow).contains($0) }
        guard hasTypeSpecificColumn else {
            throw ImportError.invalidFormat
        }
    }

    private static func inferRecordType(
        amount: Double,
        giftName: String,
        giftEstimatedValueStr: String,
        favorHelp: String,
        banquetLocation: String,
        banquetAttendees: String,
        banquetExtra: String,
        humanDescription: String,
        columnIndex: [String: Int]
    ) -> RecordType? {
        if amount > 0 {
            return .monetary
        }

        let trimmedDescription = humanDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasGiftPayload = !giftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || UserEnteredDecimal.parse(giftEstimatedValueStr) != nil
        let hasFavorPayload = !favorHelp.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasBanquetPayload = !banquetLocation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !banquetAttendees.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !banquetExtra.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasGiftColumns = columnIndex["礼品名称"] != nil || columnIndex["礼品估值"] != nil
        let hasFavorColumns = columnIndex["帮忙说明"] != nil
        let hasBanquetColumns = columnIndex["宴请地点"] != nil
            || columnIndex["宴请宾客"] != nil
            || columnIndex["宴请额外费用"] != nil

        if hasGiftPayload {
            return .gift
        }
        if hasFavorPayload {
            return .favor
        }
        if hasBanquetPayload {
            return .banquet
        }
        if !trimmedDescription.isEmpty {
            if hasFavorColumns {
                return .favor
            }
            if hasBanquetColumns {
                return .banquet
            }
            if hasGiftColumns {
                return .gift
            }
        }

        return nil
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
        banquetExtra: String
    ) -> RecordTypeData {
        let trimmedDescription = humanDesc.trimmingCharacters(in: .whitespacesAndNewlines)

        switch recordType {
        case .monetary:
            return .monetary(MonetaryData(
                amount: amount,
                paymentMethod: paymentMethod.rawValue,
                returnedAmount: returnedAmount
            ))
        case .gift:
            let name = giftName.trimmingCharacters(in: .whitespacesAndNewlines)
            let estimatedValue = UserEnteredDecimal.parse(giftEstStr)
            return .gift(GiftData(
                giftName: name.isEmpty ? trimmedDescription : name,
                estimatedValue: estimatedValue
            ))
        case .favor:
            let description = favorHelp.trimmingCharacters(in: .whitespacesAndNewlines)
            return .favor(FavorData(description: description.isEmpty ? trimmedDescription : description))
        case .banquet:
            let location = banquetLoc.trimmingCharacters(in: .whitespacesAndNewlines)
            return .banquet(BanquetData(
                location: location.isEmpty ? trimmedDescription : location,
                attendeeList: banquetAtt.trimmingCharacters(in: .whitespacesAndNewlines),
                extraCostNotes: banquetExtra.trimmingCharacters(in: .whitespacesAndNewlines)
            ))
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
                    if next < line.endIndex, line[next] == "\"" {
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
            if row.count == 1, row[0].isEmpty {
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
                    if next < content.endIndex, content[next] == "\"" {
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
                    if next < content.endIndex, content[next] == "\n" {
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
                "contact_id": .string(String(describing: existing.persistentModelID)),
            ])
            return existing
        }
        let contact = Contact(name: trimmed)
        context.insert(contact)
        importLogger.info("Created contact during import", metadata: [
            "step": .string("find_or_create_contact"),
            "result": .string("created"),
            "target": .string(trimmed),
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
                "event_id": .string(String(describing: existing.persistentModelID)),
            ])
            return existing
        }
        let event = Event(name: trimmed, type: type)
        context.insert(event)
        importLogger.info("Created event during import", metadata: [
            "step": .string("find_or_create_event"),
            "result": .string("created"),
            "target": .string(trimmed),
        ])
        return event
    }

    static func findOrCreateEventIfNeeded(name: String, type: EventType, context: ModelContext) -> Event? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return findOrCreateEvent(name: trimmed, type: type, context: context)
    }

    private static func resolveExportContext(for record: Record) -> (eventName: String, eventTypeName: String, sceneTag: String)? {
        if let event = record.event {
            return (event.name, event.type.displayName, "")
        }

        let trimmedSceneTag = record.contextTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSceneTag.isEmpty else {
            return nil
        }
        return ("", "", trimmedSceneTag)
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
        csvDateFormatter.date(from: str.trimmingCharacters(in: .whitespaces))
    }

    private static var csvDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans")
        formatter.dateFormat = csvDateFormat
        return formatter
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
        case .accessDenied: String(localized: "import.error.accessDenied")
        case .invalidFormat: String(localized: "import.error.invalidFormat")
        }
    }
}

// MARK: - Export Value Extensions

private extension RecordDirection {
    var csvValue: String {
        switch self {
        case .given: String(localized: "record.direction.given")
        case .received: String(localized: "record.direction.received")
        }
    }
}

private extension PaymentMethod {
    var csvValue: String {
        switch self {
        case .cash: String(localized: "payment.cash")
        case .wechat: String(localized: "payment.wechat")
        case .alipay: String(localized: "payment.alipay")
        }
    }
}
