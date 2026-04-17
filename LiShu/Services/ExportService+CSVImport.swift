import Foundation
import Logging
import SwiftData

// MARK: - CSV Import

extension ExportService {
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
        Self.importLogger.notice("Finished CSV import", metadata: [
            "step": .string("import_csv"),
            "source": .string(sourceFileName),
            "count": .stringConvertible(result.imported),
            "result": .string("success"),
            "errors": .stringConvertible(result.errors),
        ])
        return result
    }

    nonisolated static func previewLedgerCSV(url: URL, eventName: String) throws -> LedgerCSVImportPreviewResult {
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let content = try String(contentsOf: url, encoding: .utf8)
        return try previewLedgerCSV(content: content, sourceFileName: url.lastPathComponent, eventName: eventName)
    }

    nonisolated static func previewLedgerCSVAsync(
        url: URL,
        eventName: String
    ) async throws -> LedgerCSVImportPreviewResult {
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        return try await Task.detached(priority: .userInitiated) {
            let content = try String(contentsOf: url, encoding: .utf8)
            return try previewLedgerCSV(content: content, sourceFileName: url.lastPathComponent, eventName: eventName)
        }.value
    }

    nonisolated static func previewLedgerCSV(
        content: String,
        sourceFileName: String,
        eventName: String
    ) throws -> LedgerCSVImportPreviewResult {
        let rows = parseCSVRows(content)

        guard rows.count > 1 else {
            return LedgerCSVImportPreviewResult(sourceFileName: sourceFileName, eventName: eventName, items: [])
        }

        let headerRow = rows[0].map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        try validateLedgerCSVHeader(headerRow)
        let columnIndex = buildCSVColumnIndexMap(headerRow)

        var items: [LedgerCSVImportPreviewItem] = []
        var skipped = 0
        var errors = 0

        for (rowIndex, rawFields) in rows.dropFirst().enumerated() {
            if rawFields.allSatisfy({ $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
                continue
            }

            let item = buildLedgerPreviewItem(
                rawFields: rawFields,
                rowIndex: rowIndex,
                headerColumnCount: headerRow.count,
                columnIndex: columnIndex,
                eventName: eventName
            )
            if case .skipped = item.status {
                skipped += 1
            }
            if case .error = item.status {
                errors += 1
            }
            items.append(item)
        }

        return LedgerCSVImportPreviewResult(
            sourceFileName: sourceFileName,
            eventName: eventName,
            items: items,
            skipped: skipped,
            errors: errors
        )
    }

    nonisolated static func importLedgerPreviewItemsAsync(
        _ items: [LedgerCSVImportPreviewItem],
        baseResult: ImportResult,
        sourceFileName: String = "preview",
        eventID: PersistentIdentifier,
        container: ModelContainer
    ) async throws -> ImportResult {
        try await Task.detached(priority: .userInitiated) {
            let context = ModelContext(container)
            return try importLedgerPreviewItems(
                items,
                baseResult: baseResult,
                sourceFileName: sourceFileName,
                eventID: eventID,
                context: context
            )
        }.value
    }

    nonisolated static func importLedgerPreviewItems(
        _ items: [LedgerCSVImportPreviewItem],
        baseResult: ImportResult,
        sourceFileName: String = "preview",
        eventID: PersistentIdentifier,
        context: ModelContext
    ) throws -> ImportResult {
        let event = try hostLedgerEvent(id: eventID, context: context)
        var result = baseResult
        let importableItems = items.filter { $0.isSelected && $0.isImportable }
        var contactCache: [String: Contact] = [:]

        for item in importableItems {
            guard let payload = item.payload else { continue }

            let contactName = payload.contactName.trimmingCharacters(in: .whitespacesAndNewlines)
            let contact: Contact
            if let cached = contactCache[contactName] {
                contact = cached
            } else {
                let resolvedContact = findOrCreateContact(name: contactName, context: context)
                contactCache[contactName] = resolvedContact
                contact = resolvedContact
            }

            let record = Record(
                contact: contact,
                event: event,
                direction: .received,
                note: payload.note,
                date: payload.date,
                recordType: .monetary,
                relationshipWeight: payload.relationshipWeight
            )
            record.applyTypeData(.monetary(MonetaryData(
                amount: payload.amount,
                paymentMethod: payload.paymentMethod.rawValue,
                returnedAmount: 0
            )))

            context.insert(record)
            result.imported += 1
        }

        try context.save()
        Self.importLogger.notice("Finished ledger CSV import", metadata: [
            "step": .string("import_ledger_csv"),
            "source": .string(sourceFileName),
            "event_id": .string(String(describing: eventID)),
            "count": .stringConvertible(result.imported),
            "result": .string("success"),
        ])
        return result
    }

    nonisolated static func previewCSV(content: String, sourceFileName: String) throws -> CSVImportPreviewResult {
        let rows = parseCSVRows(content)

        guard rows.count > 1 else {
            Self.importLogger.warning("CSV preview finished without data rows", metadata: [
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

        Self.importLogger.notice("Finished CSV preview parse", metadata: [
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

    nonisolated static func findOrCreateContact(name: String, context: ModelContext) -> Contact {
        let trimmed = normalizeImportedText(name)
        let predicate = #Predicate<Contact> { $0.name == trimmed }
        var descriptor = FetchDescriptor<Contact>(predicate: predicate)
        descriptor.fetchLimit = 1

        do {
            if let existing = try context.fetch(descriptor).first {
                Self.importLogger.info("Reused contact during import", metadata: [
                    "step": .string("find_or_create_contact"),
                    "result": .string("existing"),
                    "contact_id": .string(String(describing: existing.persistentModelID)),
                ])
                return existing
            }
        } catch {
            Self.importLogger.warning("Failed to fetch contact, creating new one", metadata: [
                "step": .string("find_or_create_contact"),
                "target": .string(trimmed),
                "error": .string(error.localizedDescription),
            ])
        }
        let contact = Contact(name: trimmed)
        context.insert(contact)
        Self.importLogger.info("Created contact during import", metadata: [
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
            Self.importLogger.info("Reused event during import", metadata: [
                "step": .string("find_or_create_event"),
                "result": .string("existing"),
                "event_id": .string(String(describing: existing.persistentModelID)),
            ])
            return existing
        }
        let event = Event(name: trimmed, type: type)
        context.insert(event)
        Self.importLogger.info("Created event during import", metadata: [
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

    nonisolated static func parseEventType(_ str: String) -> EventType {
        let s = normalizeImportedText(str)
        switch s {
        case "婚礼": return .wedding
        case "订婚": return .engagement
        case "丧葬": return .funeral
        case "满月": return .birth
        case "生日": return .birthday
        case "寿宴": return .longevity
        case "节庆": return .festival
        case "乔迁": return .property
        case "升学": return .education
        case "开业": return .business
        case "升职": return .promotion
        case "探望": return .visit
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

    // MARK: - Private helpers

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

    private nonisolated static func validateLedgerCSVHeader(_ headerRow: [String]) throws {
        guard headerRow.count == ledgerColumns.count else {
            throw ImportError.invalidFormat
        }
        guard headerRow == ledgerColumns else {
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

    private nonisolated static func buildLedgerPreviewItem(
        rawFields: [String],
        rowIndex: Int,
        headerColumnCount: Int,
        columnIndex: [String: Int],
        eventName: String
    ) -> LedgerCSVImportPreviewItem {
        let lineNumber = rowIndex + 2
        let fields = alignFieldsToHeader(rawFields, headerColumnCount: headerColumnCount)
        let contactName = normalizeImportedText(csvCell(fields, columnIndex: columnIndex, column: "联系人"))
        let dateTextRaw = csvCell(fields, columnIndex: columnIndex, column: "日期")
        let trimmedDateTextRaw = dateTextRaw.trimmingCharacters(in: .whitespacesAndNewlines)
        let note = normalizeImportedText(csvCell(fields, columnIndex: columnIndex, column: "备注"))
        let relationshipWeight = parseRelationshipWeight(csvCell(fields, columnIndex: columnIndex, column: "情分分量"))
        let amount = UserEnteredDecimal.parse(csvCell(fields, columnIndex: columnIndex, column: "金额")) ?? 0
        let paymentMethod = parsePaymentMethod(csvCell(fields, columnIndex: columnIndex, column: "支付方式"))
        let parsedDate = if trimmedDateTextRaw.isEmpty {
            Date()
        } else {
            parseDate(dateTextRaw)
        }

        if !trimmedDateTextRaw.isEmpty, parsedDate == nil {
            return LedgerCSVImportPreviewItem(
                rowNumber: lineNumber,
                isSelected: false,
                contactName: contactName.isEmpty ? String(localized: "common.unknown") : contactName,
                contextText: eventName,
                detailText: previewDetailText(dateText: trimmedDateTextRaw, direction: .received, recordType: .monetary),
                trailingText: formatPreviewCurrency(amount),
                status: .error(String(localized: "csv.import.preview.invalid.invalidDate")),
                payload: nil
            )
        }

        let resolvedDate = parsedDate ?? Date()
        let dateText = csvDateFormatter.string(from: resolvedDate)

        guard !contactName.isEmpty else {
            return LedgerCSVImportPreviewItem(
                rowNumber: lineNumber,
                isSelected: false,
                contactName: String(localized: "common.unknown"),
                contextText: eventName,
                detailText: previewDetailText(dateText: dateText, direction: .received, recordType: .monetary),
                trailingText: formatPreviewCurrency(amount),
                status: .error(String(localized: "csv.import.preview.invalid.missingContact")),
                payload: nil
            )
        }

        guard amount > 0 else {
            return LedgerCSVImportPreviewItem(
                rowNumber: lineNumber,
                isSelected: false,
                contactName: contactName,
                contextText: eventName,
                detailText: previewDetailText(dateText: dateText, direction: .received, recordType: .monetary),
                trailingText: formatPreviewCurrency(amount),
                status: .error(String(localized: "csv.import.preview.invalid.invalidAmount")),
                payload: nil
            )
        }

        return LedgerCSVImportPreviewItem(
            rowNumber: lineNumber,
            isSelected: true,
            contactName: contactName,
            contextText: eventName,
            detailText: previewDetailText(dateText: dateText, direction: .received, recordType: .monetary),
            trailingText: formatPreviewCurrency(amount),
            status: .ready,
            payload: LedgerCSVImportPayload(
                contactName: contactName,
                date: resolvedDate,
                note: note,
                relationshipWeight: relationshipWeight,
                amount: amount,
                paymentMethod: paymentMethod
            )
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
}
