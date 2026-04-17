import Foundation
import Logging
import SwiftData

// MARK: - CSV Export

extension ExportService {
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

    nonisolated static func previewLedgerExportCSV(
        context: ModelContext,
        eventID: PersistentIdentifier
    ) throws -> LedgerCSVExportPreviewResult {
        let event = try hostLedgerEvent(id: eventID, context: context)
        let records = (event.records ?? [])
            .filter { $0.direction == .received && $0.recordType == .monetary }
            .sorted { $0.date > $1.date }

        var items: [LedgerCSVExportPreviewItem] = []
        var skipped = 0

        for (index, record) in records.enumerated() {
            let item = buildLedgerExportPreviewItem(
                for: record,
                rowNumber: index + 2,
                eventName: event.name
            )
            if case .skipped = item.status {
                skipped += 1
            }
            items.append(item)
        }

        return LedgerCSVExportPreviewResult(
            eventID: eventID,
            eventName: event.name,
            items: items,
            skipped: skipped
        )
    }

    nonisolated static func previewLedgerExportCSVAsync(
        container: ModelContainer,
        eventID: PersistentIdentifier
    ) async throws -> LedgerCSVExportPreviewResult {
        try await Task.detached(priority: .userInitiated) {
            let context = ModelContext(container)
            return try previewLedgerExportCSV(context: context, eventID: eventID)
        }.value
    }

    nonisolated static func exportLedgerPreviewItems(_ items: [LedgerCSVExportPreviewItem]) throws -> String {
        let rows = items
            .filter { $0.isSelected && $0.isExportable }
            .compactMap(\.payload?.csvRow)
        return ([ledgerCSVHeader()] + rows).joined(separator: "\n")
    }

    nonisolated static func exportLedgerPreviewItemsToTemporaryFileAsync(
        _ items: [LedgerCSVExportPreviewItem],
        fileName: String
    ) async throws -> URL {
        try await Task.detached(priority: .userInitiated) {
            let csv = try exportLedgerPreviewItems(items)
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

    nonisolated static func ledgerTemplateCSV() -> String {
        [ledgerCSVHeader(), ledgerTemplateRows()].joined(separator: "\n")
    }

    nonisolated static func escapeCSV(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return value
    }

    // MARK: - Private helpers

    private nonisolated static func csvHeader(for recordType: RecordType) -> String {
        (commonColumns + (typeSpecificColumns[recordType] ?? [])).joined(separator: ",")
    }

    private nonisolated static func ledgerCSVHeader() -> String {
        ledgerColumns.joined(separator: ",")
    }

    private nonisolated static func csvValues(for recordType: RecordType) -> [String] {
        commonColumns + (typeSpecificColumns[recordType] ?? [])
    }

    nonisolated static func exportRow(for record: Record, recordType: RecordType) -> String? {
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

    private nonisolated static func ledgerExportRow(for record: Record) -> String? {
        guard record.recordType == .monetary,
              record.direction == .received,
              let contact = record.contact
        else {
            return nil
        }

        let values: [String: String] = [
            "联系人": contact.name,
            "日期": csvDateFormatter.string(from: record.date),
            "备注": record.note,
            "情分分量": record.relationshipWeight.csvValue,
            "金额": String(format: "%.2f", record.monetaryAmount),
            "支付方式": record.resolvedPaymentMethod.csvValue,
        ]

        return ledgerColumns.map { escapeCSV(values[$0] ?? "") }.joined(separator: ",")
    }

    nonisolated static func buildExportPreviewItem(
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

    nonisolated static func buildLedgerExportPreviewItem(
        for record: Record,
        rowNumber: Int,
        eventName: String
    ) -> LedgerCSVExportPreviewItem {
        let contactName = record.contact?.name.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let detailText = previewDetailText(
            dateText: csvDateFormatter.string(from: record.date),
            direction: .received,
            recordType: .monetary
        )

        guard !contactName.isEmpty else {
            return LedgerCSVExportPreviewItem(
                rowNumber: rowNumber,
                isSelected: false,
                contactName: String(localized: "common.unknown"),
                contextText: eventName,
                detailText: detailText,
                trailingText: formatPreviewCurrency(record.monetaryAmount),
                status: .skipped(String(localized: "csv.export.preview.invalid.missingContact")),
                payload: nil
            )
        }

        guard let csvRow = ledgerExportRow(for: record) else {
            return LedgerCSVExportPreviewItem(
                rowNumber: rowNumber,
                isSelected: false,
                contactName: contactName,
                contextText: eventName,
                detailText: detailText,
                trailingText: formatPreviewCurrency(record.monetaryAmount),
                status: .skipped(String(localized: "csv.export.preview.invalid.missingContext")),
                payload: nil
            )
        }

        return LedgerCSVExportPreviewItem(
            rowNumber: rowNumber,
            isSelected: true,
            contactName: contactName,
            contextText: eventName,
            detailText: detailText,
            trailingText: formatPreviewCurrency(record.monetaryAmount),
            status: .ready,
            payload: LedgerCSVExportPayload(csvRow: csvRow)
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

    private nonisolated static func ledgerTemplateRows() -> String {
        let values = [
            [
                "联系人": "张三",
                "日期": "2026-04-09",
                "备注": "婚礼签到时登记",
                "情分分量": "礼尚往来",
                "金额": "1000.00",
                "支付方式": "微信",
            ],
            [
                "联系人": "李四",
                "日期": "2026-04-09",
                "备注": "亲友到场随礼",
                "情分分量": "情深义重",
                "金额": "2000.00",
                "支付方式": "现金",
            ],
        ]

        return values
            .map { row in
                ledgerColumns.map { escapeCSV(row[$0] ?? "") }.joined(separator: ",")
            }
            .joined(separator: "\n")
    }

    // MARK: - Preview text helpers (shared with import)

    nonisolated static func previewDetailText(dateText: String, direction: RecordDirection, recordType: RecordType?) -> String {
        var parts = [dateText, direction.csvValue]
        if let recordType {
            parts.append(recordType.displayName)
        }
        return parts.joined(separator: " · ")
    }

    nonisolated static func formatPreviewCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = amount == Double(Int(amount)) ? 0 : 2
        let formatted = formatter.string(from: NSNumber(value: amount)) ?? String(format: "%.2f", amount)
        return "¥" + formatted
    }

    nonisolated static func firstNonEmpty(_ values: String...) -> String {
        for value in values {
            let trimmed = normalizeImportedText(value)
            if !trimmed.isEmpty {
                return trimmed
            }
        }
        return ""
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
}
