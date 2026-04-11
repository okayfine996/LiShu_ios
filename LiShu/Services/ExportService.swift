import Foundation
import Logging
import SwiftData

private let exportLogger = PulseDiagnostics.makeLogger(label: AppLogLabel.export)
private let importLogger = PulseDiagnostics.makeLogger(label: AppLogLabel.importFlow)

enum ExportService {
    private nonisolated static let csvDateFormat = "yyyy-MM-dd"
    private nonisolated static let csvLegacyDateFormat = "yyyy-MM-dd HH:mm"
    private nonisolated static let commonColumns = ["联系人", "事件", "事件类型", "场景标签", "方向", "日期", "备注", "情分分量"]
    private nonisolated static let typeSpecificColumns: [RecordType: [String]] = [
        .monetary: ["金额", "支付方式", "已退金额"],
        .gift: ["礼品名称", "礼品估值", "人情描述"],
        .favor: ["帮忙说明", "人情描述"],
        .banquet: ["宴请地点", "宴请宾客", "宴请额外费用", "人情描述"],
    ]

    private nonisolated static let allowedColumns = Set(commonColumns + typeSpecificColumns.values.flatMap(\.self))

    // MARK: - CSV Export

    nonisolated static func exportCSV(context: ModelContext, recordType: RecordType) throws -> String {
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

    nonisolated static func previewExportCSV(context: ModelContext, recordType: RecordType) throws -> CSVExportPreviewResult {
        exportLogger.notice("Starting CSV export preview", metadata: [
            "step": .string("preview_export_csv"),
            "record_type": .string(recordType.rawValue),
        ])

        let descriptor = FetchDescriptor<Record>(
            predicate: #Predicate<Record> { $0.recordTypeRaw == recordType.rawValue },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let records = try context.fetch(descriptor)

        var items: [CSVExportPreviewItem] = []
        var skipped = 0

        for (index, record) in records.enumerated() {
            let item = buildExportPreviewItem(for: record, recordType: recordType, rowNumber: index + 2)
            if case .skipped = item.status {
                skipped += 1
            }
            items.append(item)
        }

        exportLogger.notice("Finished CSV export preview", metadata: [
            "step": .string("preview_export_csv"),
            "record_type": .string(recordType.rawValue),
            "count": .stringConvertible(items.count),
            "skipped": .stringConvertible(skipped),
        ])

        return CSVExportPreviewResult(recordType: recordType, items: items, skipped: skipped)
    }

    nonisolated static func previewExportCSVAsync(
        container: ModelContainer,
        recordType: RecordType
    ) async throws -> CSVExportPreviewResult {
        try await Task.detached(priority: .userInitiated) {
            let context = ModelContext(container)
            return try previewExportCSV(context: context, recordType: recordType)
        }.value
    }

    nonisolated static func exportPreviewItems(_ items: [CSVExportPreviewItem], recordType: RecordType) throws -> String {
        let rows = items
            .filter { $0.isSelected && $0.isExportable }
            .compactMap(\.payload?.csvRow)
        return ([csvHeader(for: recordType)] + rows).joined(separator: "\n")
    }

    nonisolated static func exportPreviewItemsToTemporaryFileAsync(
        _ items: [CSVExportPreviewItem],
        recordType: RecordType,
        fileName: String
    ) async throws -> URL {
        try await Task.detached(priority: .userInitiated) {
            if let delayNanoseconds = uiTestDelayNanoseconds(environmentKey: "UITEST_CSV_EXPORT_DELAY_MS") {
                try await Task.sleep(nanoseconds: delayNanoseconds)
            }

            let csv = try exportPreviewItems(items, recordType: recordType)
            guard let data = csv.data(using: .utf8) else {
                throw ImportError.invalidFormat
            }

            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent(fileName)
            try data.write(to: fileURL, options: .atomic)
            return fileURL
        }.value
    }

    nonisolated static func templateCSV(for recordType: RecordType) -> String {
        [csvHeader(for: recordType), templateRow(for: recordType)].joined(separator: "\n")
    }

    private nonisolated static func csvHeader(for recordType: RecordType) -> String {
        (commonColumns + (typeSpecificColumns[recordType] ?? [])).joined(separator: ",")
    }

    private nonisolated static func exportRow(for record: Record, recordType: RecordType) -> String? {
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
            "情分分量": record.relationshipWeight.csvValue,
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

    private nonisolated static func buildExportPreviewItem(
        for record: Record,
        recordType: RecordType,
        rowNumber: Int
    ) -> CSVExportPreviewItem {
        let contactName = record.contact?.name.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let contextText = record.contextDisplayName
        let detailText = previewDetailText(
            dateText: csvDateFormatter.string(from: record.date),
            direction: record.direction,
            recordType: record.recordType
        )

        guard !contactName.isEmpty else {
            return CSVExportPreviewItem(
                rowNumber: rowNumber,
                isSelected: false,
                contactName: String(localized: "common.unknown"),
                contextText: contextText,
                detailText: detailText,
                trailingText: exportPreviewTrailingText(for: record),
                status: .skipped(String(localized: "csv.export.preview.invalid.missingContact")),
                payload: nil
            )
        }

        guard resolveExportContext(for: record) != nil else {
            return CSVExportPreviewItem(
                rowNumber: rowNumber,
                isSelected: false,
                contactName: contactName,
                contextText: contextText,
                detailText: detailText,
                trailingText: exportPreviewTrailingText(for: record),
                status: .skipped(String(localized: "csv.export.preview.invalid.missingContext")),
                payload: nil
            )
        }

        guard let csvRow = exportRow(for: record, recordType: recordType) else {
            return CSVExportPreviewItem(
                rowNumber: rowNumber,
                isSelected: false,
                contactName: contactName,
                contextText: contextText,
                detailText: detailText,
                trailingText: exportPreviewTrailingText(for: record),
                status: .skipped(String(localized: "csv.export.preview.invalid.missingContext")),
                payload: nil
            )
        }

        return CSVExportPreviewItem(
            rowNumber: rowNumber,
            isSelected: true,
            contactName: contactName,
            contextText: contextText,
            detailText: detailText,
            trailingText: exportPreviewTrailingText(for: record),
            status: .ready,
            payload: CSVExportPayload(csvRow: csvRow)
        )
    }

    private nonisolated static func templateRow(for recordType: RecordType) -> String {
        let values: [[String: String]] = switch recordType {
        case .monetary:
            [
                [
                    "联系人": "张三",
                    "事件": "婚礼",
                    "事件类型": "婚礼",
                    "场景标签": "",
                    "方向": "送出",
                    "日期": "2026-04-09",
                    "备注": "示例备注",
                    "情分分量": "礼尚往来",
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
                    "日期": "2026-04-09",
                    "备注": "日常礼金示例",
                    "情分分量": "礼尚往来",
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
                    "日期": "2026-04-09",
                    "备注": "示例备注",
                    "情分分量": "礼尚往来",
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
                    "日期": "2026-04-09",
                    "备注": "日常礼品示例",
                    "情分分量": "礼尚往来",
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
                    "日期": "2026-04-09",
                    "备注": "示例备注",
                    "情分分量": "礼尚往来",
                    "帮忙说明": "帮忙挂号预约",
                    "人情描述": "医院陪同",
                ],
                [
                    "联系人": "赵六",
                    "事件": "",
                    "事件类型": "",
                    "场景标签": "帮忙挂号",
                    "方向": "送出",
                    "日期": "2026-04-09",
                    "备注": "日常帮忙示例",
                    "情分分量": "礼尚往来",
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
                    "日期": "2026-04-09",
                    "备注": "示例备注",
                    "情分分量": "礼尚往来",
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
                    "日期": "2026-04-09",
                    "备注": "日常宴请示例",
                    "情分分量": "礼尚往来",
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

    private nonisolated static func csvValues(for recordType: RecordType) -> [String] {
        commonColumns + (typeSpecificColumns[recordType] ?? [])
    }

    nonisolated static func escapeCSV(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return value
    }

    // MARK: - CSV Import

    nonisolated static func previewCSV(url: URL) throws -> CSVImportPreviewResult {
        importLogger.notice("Starting CSV preview parse", metadata: [
            "step": .string("preview_csv"),
            "source": .string(url.lastPathComponent),
        ])

        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let content = try String(contentsOf: url, encoding: .utf8)
        return try previewCSV(content: content, sourceFileName: url.lastPathComponent)
    }

    nonisolated static func previewCSVAsync(url: URL) async throws -> CSVImportPreviewResult {
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        return try await Task.detached(priority: .userInitiated) {
            let content = try String(contentsOf: url, encoding: .utf8)
            return try previewCSV(content: content, sourceFileName: url.lastPathComponent)
        }.value
    }

    nonisolated static func importCSV(url: URL, context: ModelContext) throws -> ImportResult {
        let preview = try previewCSV(url: url)
        return try importPreviewItems(preview.items, baseResult: ImportResult(
            imported: 0,
            skipped: preview.skipped,
            errors: preview.errors
        ), sourceFileName: preview.sourceFileName, context: context)
    }

    nonisolated static func importPreviewItemsAsync(
        _ items: [CSVImportPreviewItem],
        baseResult: ImportResult,
        sourceFileName: String = "preview",
        container: ModelContainer
    ) async throws -> ImportResult {
        try await Task.detached(priority: .userInitiated) {
            let context = ModelContext(container)
            if let delayNanoseconds = uiTestDelayNanoseconds(environmentKey: "UITEST_CSV_IMPORT_DELAY_MS") {
                try await Task.sleep(nanoseconds: delayNanoseconds)
            }

            return try importPreviewItems(
                items,
                baseResult: baseResult,
                sourceFileName: sourceFileName,
                context: context
            )
        }.value
    }

    nonisolated static func importPreviewItems(
        _ items: [CSVImportPreviewItem],
        baseResult: ImportResult,
        sourceFileName: String = "preview",
        context: ModelContext
    ) throws -> ImportResult {
        importLogger.notice("Starting CSV import", metadata: [
            "step": .string("import_csv"),
            "source": .string(sourceFileName),
        ])

        var result = baseResult
        let importableItems = items.filter { $0.isSelected && $0.isImportable }
        var contactCache: [String: Contact] = [:]
        var eventCache: [String: Event] = [:]

        for item in importableItems {
            guard let payload = item.payload else { continue }

            let contactName = payload.contactName.trimmingCharacters(in: .whitespacesAndNewlines)
            let contact: Contact
            if let cachedContact = contactCache[contactName] {
                contact = cachedContact
            } else {
                let resolvedContact = findOrCreateContact(name: contactName, context: context)
                contactCache[contactName] = resolvedContact
                contact = resolvedContact
            }

            let eventName = payload.eventName.trimmingCharacters(in: .whitespacesAndNewlines)
            let event: Event?
            if eventName.isEmpty {
                event = nil
            } else {
                let eventKey = "\(eventName)|\(payload.eventType.rawValue)"
                if let cachedEvent = eventCache[eventKey] {
                    event = cachedEvent
                } else {
                    let resolvedEvent = findOrCreateEventIfNeeded(name: eventName, type: payload.eventType, context: context)
                    if let resolvedEvent {
                        eventCache[eventKey] = resolvedEvent
                    }
                    event = resolvedEvent
                }
            }
            let returnedAmount = payload.recordType == .monetary ? payload.returnedAmount : 0

            let record = Record(
                contact: contact,
                event: event,
                direction: payload.direction,
                returnedAmount: returnedAmount,
                note: payload.note,
                date: payload.date,
                recordType: payload.recordType,
                relationshipWeight: payload.relationshipWeight
            )
            record.contextTag = payload.eventName.isEmpty ? payload.sceneTag : ""
            record.applyTypeData(payload.typeData)

            context.insert(record)
            result.imported += 1
        }

        try context.save()
        importLogger.notice("Finished CSV import", metadata: [
            "step": .string("import_csv"),
            "source": .string(sourceFileName),
            "count": .stringConvertible(result.imported),
            "result": .string("success"),
            "errors": .stringConvertible(result.errors),
        ])
        return result
    }

    private nonisolated static func validateCSVHeader(_ headerRow: [String]) throws {
        guard Set(commonColumns).isSubset(of: Set(headerRow)) else {
            throw ImportError.invalidFormat
        }

        guard headerRow.allSatisfy({ allowedColumns.contains($0) }) else {
            throw ImportError.invalidFormat
        }

        let typeSpecificHeaderColumns = Set(headerRow).subtracting(commonColumns)
        let matchedRecordType = typeSpecificColumns.first { _, columns in
            Set(columns) == typeSpecificHeaderColumns
        }

        guard matchedRecordType != nil else {
            throw ImportError.invalidFormat
        }
    }

    private nonisolated static func inferRecordType(
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

        let normalizedDescription = normalizeImportedText(humanDescription)
        let hasGiftPayload = !normalizeImportedText(giftName).isEmpty
            || UserEnteredDecimal.parse(giftEstimatedValueStr) != nil
        let hasFavorPayload = !normalizeImportedText(favorHelp).isEmpty
        let hasBanquetPayload = !normalizeImportedText(banquetLocation).isEmpty
            || !normalizeImportedText(banquetAttendees).isEmpty
            || !normalizeImportedText(banquetExtra).isEmpty
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
        if !normalizedDescription.isEmpty {
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
    private nonisolated static func buildCSVColumnIndexMap(_ headerRow: [String]) -> [String: Int] {
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
    private nonisolated static func alignFieldsToHeader(_ fields: [String], headerColumnCount: Int) -> [String] {
        if fields.count >= headerColumnCount {
            return Array(fields.prefix(headerColumnCount))
        }
        return fields + Array(repeating: "", count: headerColumnCount - fields.count)
    }

    private nonisolated static func csvCell(_ row: [String], columnIndex: [String: Int], column: String) -> String {
        let key = column.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let idx = columnIndex[key], idx < row.count else { return "" }
        return row[idx]
    }

    private nonisolated static func buildTypeDataForImport(
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
        let trimmedDescription = normalizeImportedText(humanDesc)

        switch recordType {
        case .monetary:
            return .monetary(MonetaryData(
                amount: amount,
                paymentMethod: paymentMethod.rawValue,
                returnedAmount: returnedAmount
            ))
        case .gift:
            let name = normalizeImportedText(giftName)
            let estimatedValue = UserEnteredDecimal.parse(giftEstStr)
            return .gift(GiftData(
                giftName: name.isEmpty ? trimmedDescription : name,
                estimatedValue: estimatedValue
            ))
        case .favor:
            let description = normalizeImportedText(favorHelp)
            return .favor(FavorData(description: description.isEmpty ? trimmedDescription : description))
        case .banquet:
            let location = normalizeImportedText(banquetLoc)
            return .banquet(BanquetData(
                location: location.isEmpty ? trimmedDescription : location,
                attendeeList: normalizeImportedText(banquetAtt),
                extraCostNotes: normalizeImportedText(banquetExtra)
            ))
        }
    }

    nonisolated static func parseCSVLine(_ line: String) -> [String] {
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

    private nonisolated static func parseCSVRows(_ content: String) -> [[String]] {
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

    nonisolated static func findOrCreateContact(name: String, context: ModelContext) -> Contact {
        let trimmed = normalizeImportedText(name)
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

    nonisolated static func findOrCreateEvent(name: String, type: EventType, context: ModelContext) -> Event {
        let trimmed = normalizeImportedText(name)
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

    nonisolated static func findOrCreateEventIfNeeded(name: String, type: EventType, context: ModelContext) -> Event? {
        let trimmed = normalizeImportedText(name)
        guard !trimmed.isEmpty else { return nil }
        return findOrCreateEvent(name: trimmed, type: type, context: context)
    }

    private nonisolated static func resolveExportContext(
        for record: Record
    ) -> (eventName: String, eventTypeName: String, sceneTag: String)? {
        if let event = record.event {
            return (event.name, event.type.displayName, "")
        }

        let trimmedSceneTag = record.contextTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSceneTag.isEmpty else {
            return nil
        }
        return ("", "", trimmedSceneTag)
    }

    nonisolated static func previewCSV(content: String, sourceFileName: String) throws -> CSVImportPreviewResult {
        let rows = parseCSVRows(content)

        guard rows.count > 1 else {
            importLogger.warning("CSV preview finished without data rows", metadata: [
                "step": .string("preview_csv"),
                "source": .string(sourceFileName),
                "reason": .string("empty_rows"),
            ])
            return CSVImportPreviewResult(sourceFileName: sourceFileName, items: [])
        }

        let headerRow = rows[0].map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        try validateCSVHeader(headerRow)
        let columnIndex = buildCSVColumnIndexMap(headerRow)

        var items: [CSVImportPreviewItem] = []
        var skipped = 0
        var errors = 0

        for (rowIndex, rawFields) in rows.dropFirst().enumerated() {
            if rawFields.allSatisfy({ $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
                continue
            }

            let item = buildPreviewItem(
                rawFields: rawFields,
                rowIndex: rowIndex,
                headerColumnCount: headerRow.count,
                columnIndex: columnIndex
            )
            if case .skipped = item.status {
                skipped += 1
            }
            if case .error = item.status {
                errors += 1
            }
            items.append(item)
        }

        importLogger.notice("Finished CSV preview parse", metadata: [
            "step": .string("preview_csv"),
            "source": .string(sourceFileName),
            "count": .stringConvertible(items.count),
            "errors": .stringConvertible(errors),
        ])

        return CSVImportPreviewResult(
            sourceFileName: sourceFileName,
            items: items,
            skipped: skipped,
            errors: errors
        )
    }

    nonisolated static func previewCSVAsync(content: String, sourceFileName: String) async throws -> CSVImportPreviewResult {
        try await Task.detached(priority: .userInitiated) {
            try previewCSV(content: content, sourceFileName: sourceFileName)
        }.value
    }

    private nonisolated static func buildPreviewItem(
        rawFields: [String],
        rowIndex: Int,
        headerColumnCount: Int,
        columnIndex: [String: Int]
    ) -> CSVImportPreviewItem {
        let lineNumber = rowIndex + 2
        let fields = alignFieldsToHeader(rawFields, headerColumnCount: headerColumnCount)
        let contactName = normalizeImportedText(csvCell(fields, columnIndex: columnIndex, column: "联系人"))
        let eventName = normalizeImportedText(csvCell(fields, columnIndex: columnIndex, column: "事件"))
        let eventTypeName = normalizeImportedText(csvCell(fields, columnIndex: columnIndex, column: "事件类型"))
        let sceneTag = normalizeImportedText(csvCell(fields, columnIndex: columnIndex, column: "场景标签"))
        let direction = parseDirection(csvCell(fields, columnIndex: columnIndex, column: "方向"))
        let dateTextRaw = csvCell(fields, columnIndex: columnIndex, column: "日期")
        let trimmedDateTextRaw = dateTextRaw.trimmingCharacters(in: .whitespacesAndNewlines)
        let note = normalizeImportedText(csvCell(fields, columnIndex: columnIndex, column: "备注"))
        let relationshipWeight = parseRelationshipWeight(csvCell(fields, columnIndex: columnIndex, column: "情分分量"))
        let amountStr = csvCell(fields, columnIndex: columnIndex, column: "金额")
        let amount = UserEnteredDecimal.parse(amountStr) ?? 0
        let returnedAmount = UserEnteredDecimal.parse(csvCell(fields, columnIndex: columnIndex, column: "已退金额")) ?? 0
        let giftName = normalizeImportedText(csvCell(fields, columnIndex: columnIndex, column: "礼品名称"))
        let giftEstimatedValueStr = csvCell(fields, columnIndex: columnIndex, column: "礼品估值")
        let favorHelp = normalizeImportedText(csvCell(fields, columnIndex: columnIndex, column: "帮忙说明"))
        let banquetLocation = normalizeImportedText(csvCell(fields, columnIndex: columnIndex, column: "宴请地点"))
        let banquetAttendees = normalizeImportedText(csvCell(fields, columnIndex: columnIndex, column: "宴请宾客"))
        let banquetExtra = normalizeImportedText(csvCell(fields, columnIndex: columnIndex, column: "宴请额外费用"))
        let humanDescription = normalizeImportedText(csvCell(fields, columnIndex: columnIndex, column: "人情描述"))
        let recordType = inferRecordType(
            amount: amount,
            giftName: giftName,
            giftEstimatedValueStr: giftEstimatedValueStr,
            favorHelp: favorHelp,
            banquetLocation: banquetLocation,
            banquetAttendees: banquetAttendees,
            banquetExtra: banquetExtra,
            humanDescription: humanDescription,
            columnIndex: columnIndex
        )
        let contextText = eventName.isEmpty ? sceneTag : eventName
        let parsedDate = if trimmedDateTextRaw.isEmpty {
            Date()
        } else {
            parseDate(dateTextRaw)
        }
        if !trimmedDateTextRaw.isEmpty, parsedDate == nil {
            return CSVImportPreviewItem(
                rowNumber: lineNumber,
                isSelected: false,
                contactName: contactName.isEmpty ? String(localized: "common.unknown") : contactName,
                eventName: eventName,
                eventTypeName: eventTypeName,
                sceneTag: sceneTag,
                direction: direction,
                date: nil,
                dateText: trimmedDateTextRaw,
                note: note,
                recordType: recordType,
                contextText: contextText,
                trailingText: previewTrailingText(
                    recordType: recordType,
                    amount: amount,
                    giftName: giftName,
                    favorHelp: favorHelp,
                    banquetLocation: banquetLocation,
                    humanDescription: humanDescription
                ),
                detailText: previewDetailText(dateText: trimmedDateTextRaw, direction: direction, recordType: recordType),
                status: .error(String(localized: "csv.import.preview.invalid.invalidDate")),
                payload: nil
            )
        }
        let resolvedDate = parsedDate ?? Date()
        let dateText = csvDateFormatter.string(from: resolvedDate)

        guard !contactName.isEmpty else {
            return CSVImportPreviewItem(
                rowNumber: lineNumber,
                isSelected: false,
                contactName: String(localized: "common.unknown"),
                eventName: eventName,
                eventTypeName: eventTypeName,
                sceneTag: sceneTag,
                direction: direction,
                date: resolvedDate,
                dateText: dateText,
                note: note,
                recordType: recordType,
                contextText: contextText,
                trailingText: previewTrailingText(
                    recordType: recordType,
                    amount: amount,
                    giftName: giftName,
                    favorHelp: favorHelp,
                    banquetLocation: banquetLocation,
                    humanDescription: humanDescription
                ),
                detailText: previewDetailText(dateText: dateText, direction: direction, recordType: recordType),
                status: .error(String(localized: "csv.import.preview.invalid.missingContact")),
                payload: nil
            )
        }

        guard let resolvedRecordType = recordType else {
            return CSVImportPreviewItem(
                rowNumber: lineNumber,
                isSelected: false,
                contactName: contactName,
                eventName: eventName,
                eventTypeName: eventTypeName,
                sceneTag: sceneTag,
                direction: direction,
                date: resolvedDate,
                dateText: dateText,
                note: note,
                recordType: nil,
                contextText: contextText,
                trailingText: "",
                detailText: previewDetailText(dateText: dateText, direction: direction, recordType: nil),
                status: .error(String(localized: "csv.import.preview.invalid.missingPayload")),
                payload: nil
            )
        }

        guard !eventName.isEmpty || !sceneTag.isEmpty else {
            return CSVImportPreviewItem(
                rowNumber: lineNumber,
                isSelected: false,
                contactName: contactName,
                eventName: eventName,
                eventTypeName: eventTypeName,
                sceneTag: sceneTag,
                direction: direction,
                date: resolvedDate,
                dateText: dateText,
                note: note,
                recordType: resolvedRecordType,
                contextText: String(localized: "record.context.daily"),
                trailingText: previewTrailingText(
                    recordType: resolvedRecordType,
                    amount: amount,
                    giftName: giftName,
                    favorHelp: favorHelp,
                    banquetLocation: banquetLocation,
                    humanDescription: humanDescription
                ),
                detailText: previewDetailText(dateText: dateText, direction: direction, recordType: resolvedRecordType),
                status: .skipped(String(localized: "csv.import.preview.invalid.missingContext")),
                payload: nil
            )
        }

        if resolvedRecordType == .monetary, amount <= 0 {
            return CSVImportPreviewItem(
                rowNumber: lineNumber,
                isSelected: false,
                contactName: contactName,
                eventName: eventName,
                eventTypeName: eventTypeName,
                sceneTag: sceneTag,
                direction: direction,
                date: resolvedDate,
                dateText: dateText,
                note: note,
                recordType: resolvedRecordType,
                contextText: eventName.isEmpty ? sceneTag : eventName,
                trailingText: previewTrailingText(
                    recordType: resolvedRecordType,
                    amount: amount,
                    giftName: giftName,
                    favorHelp: favorHelp,
                    banquetLocation: banquetLocation,
                    humanDescription: humanDescription
                ),
                detailText: previewDetailText(dateText: dateText, direction: direction, recordType: resolvedRecordType),
                status: .error(String(localized: "csv.import.preview.invalid.invalidAmount")),
                payload: nil
            )
        }

        let resolvedEventType = eventName.isEmpty ? .other : parseEventType(eventTypeName)
        let payload = CSVImportPayload(
            contactName: contactName,
            eventName: eventName,
            eventType: resolvedEventType,
            sceneTag: eventName.isEmpty ? sceneTag : "",
            direction: direction,
            date: resolvedDate,
            note: note,
            recordType: resolvedRecordType,
            relationshipWeight: relationshipWeight,
            returnedAmount: returnedAmount,
            typeData: buildTypeDataForImport(
                recordType: resolvedRecordType,
                amount: amount,
                paymentMethod: parsePaymentMethod(csvCell(fields, columnIndex: columnIndex, column: "支付方式")),
                returnedAmount: returnedAmount,
                humanDesc: humanDescription,
                giftName: giftName,
                giftEstStr: giftEstimatedValueStr,
                favorHelp: favorHelp,
                banquetLoc: banquetLocation,
                banquetAtt: banquetAttendees,
                banquetExtra: banquetExtra
            )
        )

        return CSVImportPreviewItem(
            rowNumber: lineNumber,
            isSelected: true,
            contactName: contactName,
            eventName: eventName,
            eventTypeName: eventTypeName,
            sceneTag: sceneTag,
            direction: direction,
            date: resolvedDate,
            dateText: dateText,
            note: note,
            recordType: resolvedRecordType,
            contextText: eventName.isEmpty ? sceneTag : eventName,
            trailingText: previewTrailingText(
                recordType: resolvedRecordType,
                amount: amount,
                giftName: giftName,
                favorHelp: favorHelp,
                banquetLocation: banquetLocation,
                humanDescription: humanDescription
            ),
            detailText: previewDetailText(dateText: dateText, direction: direction, recordType: resolvedRecordType),
            status: .ready,
            payload: payload
        )
    }

    private nonisolated static func previewTrailingText(
        recordType: RecordType?,
        amount: Double,
        giftName: String,
        favorHelp: String,
        banquetLocation: String,
        humanDescription: String
    ) -> String {
        guard let recordType else { return "" }
        switch recordType {
        case .monetary:
            return formatPreviewCurrency(amount)
        case .gift:
            return firstNonEmpty(giftName, humanDescription)
        case .favor:
            return firstNonEmpty(favorHelp, humanDescription)
        case .banquet:
            return firstNonEmpty(banquetLocation, humanDescription)
        }
    }

    private nonisolated static func exportPreviewTrailingText(for record: Record) -> String {
        switch record.recordType {
        case .monetary:
            formatPreviewCurrency(record.monetaryAmount)
        case .gift:
            firstNonEmpty(record.giftData?.giftName ?? "", record.resolvedDescription)
        case .favor:
            firstNonEmpty(record.favorData?.description ?? "", record.resolvedDescription)
        case .banquet:
            firstNonEmpty(record.banquetData?.location ?? "", record.resolvedDescription)
        }
    }

    private nonisolated static func previewDetailText(dateText: String, direction: RecordDirection, recordType: RecordType?) -> String {
        var parts = [dateText, direction.csvValue]
        if let recordType {
            parts.append(recordType.displayName)
        }
        return parts.joined(separator: " · ")
    }

    private nonisolated static func formatPreviewCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = amount == Double(Int(amount)) ? 0 : 2
        let formatted = formatter.string(from: NSNumber(value: amount)) ?? String(format: "%.2f", amount)
        return "¥" + formatted
    }

    private nonisolated static func firstNonEmpty(_ values: String...) -> String {
        for value in values {
            let trimmed = normalizeImportedText(value)
            if !trimmed.isEmpty {
                return trimmed
            }
        }
        return ""
    }

    nonisolated static func parseEventType(_ str: String) -> EventType {
        let s = normalizeImportedText(str)
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

    nonisolated static func parseDirection(_ str: String) -> RecordDirection {
        let s = normalizeImportedText(str)
        switch s {
        case "送出", "随礼", "given": return .given
        case "收到", "收礼", "received": return .received
        default: return .given
        }
    }

    nonisolated static func parsePaymentMethod(_ str: String) -> PaymentMethod {
        let s = normalizeImportedText(str)
        switch s {
        case "现金", "cash": return .cash
        case "微信", "wechat": return .wechat
        case "支付宝", "alipay": return .alipay
        default: return .cash
        }
    }

    nonisolated static func parseDate(_ str: String) -> Date? {
        let trimmed = str.trimmingCharacters(in: .whitespaces)
        return csvDateFormatter.date(from: trimmed) ?? csvLegacyDateFormatter.date(from: trimmed)
    }

    nonisolated static func parseRelationshipWeight(_ str: String) -> RelationshipWeight {
        let trimmed = normalizeImportedText(str)
        guard !trimmed.isEmpty else { return .reciprocal }

        switch trimmed {
        case RelationshipWeight.trivial.rawValue, String(localized: "record.relationshipWeight.trivial"):
            return .trivial
        case RelationshipWeight.kindness.rawValue, String(localized: "record.relationshipWeight.kindness"):
            return .kindness
        case RelationshipWeight.support.rawValue, String(localized: "record.relationshipWeight.support"):
            return .support
        case RelationshipWeight.profound.rawValue, String(localized: "record.relationshipWeight.profound"):
            return .profound
        case RelationshipWeight.reciprocal.rawValue, String(localized: "record.relationshipWeight.reciprocal"):
            return .reciprocal
        default:
            return .reciprocal
        }
    }

    nonisolated static func normalizeImportedText(_ value: String) -> String {
        value
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private nonisolated static var csvDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans")
        formatter.dateFormat = csvDateFormat
        return formatter
    }

    private nonisolated static var csvLegacyDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans")
        formatter.dateFormat = csvLegacyDateFormat
        return formatter
    }

    private nonisolated static func uiTestDelayNanoseconds(environmentKey: String) -> UInt64? {
        guard CommandLine.arguments.contains("--uitesting") else { return nil }
        guard let delayString = ProcessInfo.processInfo.environment[environmentKey],
              let delayMilliseconds = UInt64(delayString)
        else {
            return nil
        }
        return delayMilliseconds * 1_000_000
    }
}

// MARK: - Import Types

struct ImportResult {
    var imported: Int = 0
    var skipped: Int = 0
    var errors: Int = 0
}

struct CSVImportPreviewResult {
    let sourceFileName: String
    var items: [CSVImportPreviewItem]
    var skipped: Int = 0
    var errors: Int = 0
}

struct CSVImportPreviewItem: Identifiable {
    let id = UUID()
    let rowNumber: Int
    var isSelected: Bool
    let contactName: String
    let eventName: String
    let eventTypeName: String
    let sceneTag: String
    let direction: RecordDirection
    let date: Date?
    let dateText: String
    let note: String
    let recordType: RecordType?
    let contextText: String
    let trailingText: String
    let detailText: String
    let status: CSVImportPreviewStatus
    let payload: CSVImportPayload?

    var isImportable: Bool {
        switch status {
        case .ready:
            payload != nil
        case .skipped, .error:
            false
        }
    }

    var statusMessage: String? {
        switch status {
        case .ready:
            nil
        case let .skipped(reason), let .error(reason):
            reason
        }
    }
}

struct CSVExportPreviewResult {
    let recordType: RecordType
    var items: [CSVExportPreviewItem]
    var skipped: Int = 0
}

struct CSVExportPreviewItem: Identifiable {
    let id = UUID()
    let rowNumber: Int
    var isSelected: Bool
    let contactName: String
    let contextText: String
    let detailText: String
    let trailingText: String
    let status: CSVExportPreviewStatus
    let payload: CSVExportPayload?

    var isExportable: Bool {
        switch status {
        case .ready:
            payload != nil
        case .skipped:
            false
        }
    }

    var statusMessage: String? {
        switch status {
        case .ready:
            nil
        case let .skipped(reason):
            reason
        }
    }
}

enum CSVExportPreviewStatus: Equatable {
    case ready
    case skipped(String)
}

struct CSVExportPayload {
    let csvRow: String
}

enum CSVImportPreviewStatus: Equatable {
    case ready
    case skipped(String)
    case error(String)
}

struct CSVImportPayload {
    let contactName: String
    let eventName: String
    let eventType: EventType
    let sceneTag: String
    let direction: RecordDirection
    let date: Date
    let note: String
    let recordType: RecordType
    let relationshipWeight: RelationshipWeight
    let returnedAmount: Double
    let typeData: RecordTypeData
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

private extension RelationshipWeight {
    var csvValue: String {
        displayName
    }
}
