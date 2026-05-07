import Foundation
import Logging
import SwiftData

// MARK: - XLSX Export

extension ExportService {
    nonisolated static func previewExportXLSX(context: ModelContext, recordType: RecordType) throws -> ExportPreviewResult {
        exportLogger.notice("Starting XLSX export preview", metadata: [
            "step": .string("preview_export_xlsx"),
            "record_type": .string(recordType.rawValue),
        ])

        let descriptor = FetchDescriptor<Record>(
            predicate: #Predicate<Record> { $0.recordTypeRaw == recordType.rawValue },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let records = try context.fetch(descriptor)

        var items: [ExportPreviewItem] = []
        var skipped = 0

        for (index, record) in records.enumerated() {
            let item = buildExportPreviewItem(for: record, recordType: recordType, rowNumber: index + 2)
            if case .skipped = item.status {
                skipped += 1
            }
            items.append(item)
        }

        exportLogger.notice("Finished XLSX export preview", metadata: [
            "step": .string("preview_export_xlsx"),
            "record_type": .string(recordType.rawValue),
            "count": .stringConvertible(items.count),
            "skipped": .stringConvertible(skipped),
        ])

        return ExportPreviewResult(recordType: recordType, items: items, skipped: skipped)
    }

    nonisolated static func previewExportXLSXAsync(
        container: ModelContainer,
        recordType: RecordType
    ) async throws -> ExportPreviewResult {
        try await Task.detached(priority: .userInitiated) {
            let context = ModelContext(container)
            return try previewExportXLSX(context: context, recordType: recordType)
        }.value
    }

    nonisolated static func exportPreviewItemsToTemporaryFileAsync(
        _ items: [ExportPreviewItem],
        recordType: RecordType,
        fileName: String
    ) async throws -> URL {
        try await Task.detached(priority: .userInitiated) {
            if let delayNanoseconds = uiTestDelayNanoseconds(environmentKey: "UITEST_XLSX_EXPORT_DELAY_MS") {
                try await Task.sleep(nanoseconds: delayNanoseconds)
            }

            let selectedRows = items
                .filter { $0.isSelected && $0.isExportable }
                .compactMap(\.payload?.rowValues)
            let headers = exportColumns(for: recordType)
            return try XLSXWriter.write(fileName: fileName, headers: headers, rows: selectedRows)
        }.value
    }

    nonisolated static func previewLedgerExportXLSX(
        context: ModelContext,
        eventID: PersistentIdentifier
    ) throws -> LedgerExportPreviewResult {
        let event = try hostLedgerEvent(id: eventID, context: context)
        let records = (event.records ?? [])
            .filter { $0.direction == .received && $0.recordType == .monetary }
            .sorted { $0.date > $1.date }

        var items: [LedgerExportPreviewItem] = []
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

        return LedgerExportPreviewResult(
            eventID: eventID,
            eventName: event.name,
            items: items,
            skipped: skipped
        )
    }

    nonisolated static func previewLedgerExportXLSXAsync(
        container: ModelContainer,
        eventID: PersistentIdentifier
    ) async throws -> LedgerExportPreviewResult {
        try await Task.detached(priority: .userInitiated) {
            let context = ModelContext(container)
            return try previewLedgerExportXLSX(context: context, eventID: eventID)
        }.value
    }

    nonisolated static func exportLedgerPreviewItemsToTemporaryFileAsync(
        _ items: [LedgerExportPreviewItem],
        fileName: String
    ) async throws -> URL {
        try await Task.detached(priority: .userInitiated) {
            if let delayNanoseconds = uiTestDelayNanoseconds(environmentKey: "UITEST_XLSX_EXPORT_DELAY_MS") {
                try await Task.sleep(nanoseconds: delayNanoseconds)
            }
            let selectedRows = items
                .filter { $0.isSelected && $0.isExportable }
                .compactMap(\.payload?.rowValues)
            return try XLSXWriter.write(fileName: fileName, headers: ledgerExportColumns(), rows: selectedRows)
        }.value
    }

    nonisolated static func templateXLSX(for recordType: RecordType) throws -> URL {
        let fileName = "lishu_\(recordType.rawValue)_template.xlsx"
        let headers = exportColumns(for: recordType)
        let rows = templateRows(for: recordType)
        return try XLSXWriter.write(fileName: fileName, headers: headers, rows: rows)
    }

    nonisolated static func ledgerTemplateXLSX() throws -> URL {
        let rows = ledgerTemplateRowDicts()
        return try XLSXWriter.write(
            fileName: "lishu_ledger_template.xlsx",
            headers: ledgerExportColumns(),
            rows: rows
        )
    }

    // MARK: - Private helpers

    private nonisolated static func exportColumns(for recordType: RecordType) -> [String] {
        commonColumns + (typeSpecificColumns[recordType] ?? [])
    }

    private nonisolated static func ledgerExportColumns() -> [String] {
        ledgerColumns
    }

    nonisolated static func exportRow(for record: Record, recordType: RecordType) -> [String: XLSXCellValue]? {
        guard record.recordType == recordType, let contact = record.contact else { return nil }
        guard let context = resolveExportContext(for: record) else { return nil }

        var values: [String: XLSXCellValue] = [
            "联系人": .string(contact.name),
            "事件": .string(context.eventName),
            "事件类型": .string(context.eventTypeName),
            "场景标签": .string(context.sceneTag),
            "方向": .string(record.direction.csvValue),
            "日期": .string(dateFormatter.string(from: record.date)),
            "备注": .string(record.note),
            "情分分量": .string(record.relationshipWeight.csvValue),
        ]

        switch recordType {
        case .monetary:
            values["金额"] = .number(record.monetaryAmount)
            values["支付方式"] = .string(record.resolvedPaymentMethod.csvValue)
            values["已退金额"] = .number(record.resolvedReturnedAmount)
        case .gift:
            let giftName = record.giftData?.giftName ?? ""
            values["礼品名称"] = .string(giftName)
            values["礼品估值"] = if let estimatedValue = record.giftData?.estimatedValue {
                .number(estimatedValue)
            } else {
                .empty
            }
            values["人情描述"] = .string(record.note.isEmpty ? giftName : record.note)
        case .favor:
            let favorDesc = record.favorData?.description ?? ""
            values["帮忙说明"] = .string(favorDesc)
            values["人情描述"] = .string(record.note.isEmpty ? favorDesc : record.note)
        case .banquet:
            let banquetLocation = record.banquetData?.location ?? ""
            values["宴请地点"] = .string(banquetLocation)
            values["宴请宾客"] = .string(record.banquetData?.attendeeList ?? "")
            values["宴请额外费用"] = .string(record.banquetData?.extraCostNotes ?? "")
            values["人情描述"] = .string(record.note.isEmpty ? banquetLocation : record.note)
        }

        return values
    }

    private nonisolated static func ledgerExportRow(for record: Record) -> [String: XLSXCellValue]? {
        guard record.recordType == .monetary,
              record.direction == .received,
              let contact = record.contact
        else {
            return nil
        }

        return [
            "联系人": .string(contact.name),
            "日期": .string(dateFormatter.string(from: record.date)),
            "备注": .string(record.note),
            "情分分量": .string(record.relationshipWeight.csvValue),
            "金额": .number(record.monetaryAmount),
            "支付方式": .string(record.resolvedPaymentMethod.csvValue),
        ]
    }

    nonisolated static func buildExportPreviewItem(
        for record: Record,
        recordType: RecordType,
        rowNumber: Int
    ) -> ExportPreviewItem {
        let contactName = record.contact?.name.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let contextText = record.contextDisplayName
        let detailText = previewDetailText(
            dateText: dateFormatter.string(from: record.date),
            direction: record.direction,
            recordType: record.recordType
        )

        guard !contactName.isEmpty else {
            return ExportPreviewItem(
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
            return ExportPreviewItem(
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

        guard let rowValues = exportRow(for: record, recordType: recordType) else {
            return ExportPreviewItem(
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

        return ExportPreviewItem(
            rowNumber: rowNumber,
            isSelected: true,
            contactName: contactName,
            contextText: contextText,
            detailText: detailText,
            trailingText: exportPreviewTrailingText(for: record),
            status: .ready,
            payload: ExportPayload(rowValues: rowValues)
        )
    }

    nonisolated static func buildLedgerExportPreviewItem(
        for record: Record,
        rowNumber: Int,
        eventName: String
    ) -> LedgerExportPreviewItem {
        let contactName = record.contact?.name.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let detailText = previewDetailText(
            dateText: dateFormatter.string(from: record.date),
            direction: .received,
            recordType: .monetary
        )

        guard !contactName.isEmpty else {
            return LedgerExportPreviewItem(
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

        guard let rowValues = ledgerExportRow(for: record) else {
            return LedgerExportPreviewItem(
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

        return LedgerExportPreviewItem(
            rowNumber: rowNumber,
            isSelected: true,
            contactName: contactName,
            contextText: eventName,
            detailText: detailText,
            trailingText: formatPreviewCurrency(record.monetaryAmount),
            status: .ready,
            payload: LedgerExportPayload(rowValues: rowValues)
        )
    }

    private nonisolated static func templateRows(for recordType: RecordType) -> [[String: XLSXCellValue]] {
        let today = dateFormatter.string(from: Date())
        switch recordType {
        case .monetary:
            return [
                [
                    "联系人": .string("张三"), "事件": .string("婚礼"), "事件类型": .string("婚礼"), "场景标签": .string(""),
                    "方向": .string("送出"), "日期": .string(today), "备注": .string("示例备注"), "情分分量": .string("礼尚往来"),
                    "金额": .number(800.00), "支付方式": .string("微信"), "已退金额": .number(0.00),
                ],
                [
                    "联系人": .string("李四"), "事件": .string(""), "事件类型": .string(""), "场景标签": .string("节日看望"),
                    "方向": .string("送出"), "日期": .string(today), "备注": .string("日常礼金示例"), "情分分量": .string("礼尚往来"),
                    "金额": .number(300.00), "支付方式": .string("现金"), "已退金额": .number(0.00),
                ],
            ]
        case .gift:
            return [
                [
                    "联系人": .string("李四"), "事件": .string("乔迁"), "事件类型": .string("乔迁"), "场景标签": .string(""),
                    "方向": .string("送出"), "日期": .string(today), "备注": .string("示例备注"), "情分分量": .string("礼尚往来"),
                    "礼品名称": .string("景德镇茶具"), "礼品估值": .number(880.00), "人情描述": .string("乔迁随礼品"),
                ],
                [
                    "联系人": .string("王五"), "事件": .string(""), "事件类型": .string(""), "场景标签": .string("出差带特产"),
                    "方向": .string("送出"), "日期": .string(today), "备注": .string("日常礼品示例"), "情分分量": .string("礼尚往来"),
                    "礼品名称": .string("地方特产礼盒"), "礼品估值": .number(260.00), "人情描述": .string("出差顺手带回"),
                ],
            ]
        case .favor:
            return [
                [
                    "联系人": .string("王五"), "事件": .string("探望"), "事件类型": .string("探望"), "场景标签": .string(""),
                    "方向": .string("送出"), "日期": .string(today), "备注": .string("示例备注"), "情分分量": .string("礼尚往来"),
                    "帮忙说明": .string("帮忙挂号预约"), "人情描述": .string("医院陪同"),
                ],
                [
                    "联系人": .string("赵六"), "事件": .string(""), "事件类型": .string(""), "场景标签": .string("帮忙挂号"),
                    "方向": .string("送出"), "日期": .string(today), "备注": .string("日常帮忙示例"), "情分分量": .string("礼尚往来"),
                    "帮忙说明": .string("帮忙代取检查报告"), "人情描述": .string("顺路代办"),
                ],
            ]
        case .banquet:
            return [
                [
                    "联系人": .string("赵六"), "事件": .string("商务宴请"), "事件类型": .string("其他"), "场景标签": .string(""),
                    "方向": .string("送出"), "日期": .string(today), "备注": .string("示例备注"), "情分分量": .string("礼尚往来"),
                    "宴请地点": .string("兰亭包厢"), "宴请宾客": .string("张三、李四"), "宴请额外费用": .string("两瓶酒水"), "人情描述": .string("商务答谢宴"),
                ],
                [
                    "联系人": .string("孙七"), "事件": .string(""), "事件类型": .string(""), "场景标签": .string("接风洗尘"),
                    "方向": .string("送出"), "日期": .string(today), "备注": .string("日常宴请示例"), "情分分量": .string("礼尚往来"),
                    "宴请地点": .string("家常馆包间"), "宴请宾客": .string("老同学两位"), "宴请额外费用": .string("带了两瓶红酒"), "人情描述": .string("朋友聚餐接风"),
                ],
            ]
        }
    }

    private nonisolated static func ledgerTemplateRowDicts() -> [[String: XLSXCellValue]] {
        let today = dateFormatter.string(from: Date())
        return [
            [
                "联系人": .string("张三"), "日期": .string(today), "备注": .string("婚礼签到时登记"),
                "情分分量": .string("礼尚往来"), "金额": .number(1000.00), "支付方式": .string("微信"),
            ],
            [
                "联系人": .string("李四"), "日期": .string(today), "备注": .string("亲友到场随礼"),
                "情分分量": .string("情深义重"), "金额": .number(2000.00), "支付方式": .string("现金"),
            ],
        ]
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
        let isWhole = amount == Double(Int(amount))
        let formatter = isWhole ? currencyPreviewIntFormatter : currencyPreviewDecFormatter
        let formatted = formatter.string(from: NSNumber(value: amount)) ?? String(format: "%.2f", amount)
        return "¥" + formatted
    }

    private nonisolated static let currencyPreviewIntFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f
    }()

    private nonisolated static let currencyPreviewDecFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 2
        return f
    }()

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
