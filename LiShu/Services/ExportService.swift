import Foundation
import Logging
import SwiftData

enum ExportService {
    nonisolated static let exportLogger = PulseDiagnostics.makeLogger(label: AppLogLabel.export)
    nonisolated static let importLogger = PulseDiagnostics.makeLogger(label: AppLogLabel.importFlow)
    nonisolated static let csvDateFormat = "yyyy-MM-dd"
    nonisolated static let csvLegacyDateFormat = "yyyy-MM-dd HH:mm"
    nonisolated static let commonColumns = ["联系人", "事件", "事件类型", "场景标签", "方向", "日期", "备注", "情分分量"]
    nonisolated static let ledgerColumns = ["联系人", "日期", "备注", "情分分量", "金额", "支付方式"]
    nonisolated static let typeSpecificColumns: [RecordType: [String]] = [
        .monetary: ["金额", "支付方式", "已退金额"],
        .gift: ["礼品名称", "礼品估值", "人情描述"],
        .favor: ["帮忙说明", "人情描述"],
        .banquet: ["宴请地点", "宴请宾客", "宴请额外费用", "人情描述"],
    ]

    nonisolated static let allowedColumns = Set(commonColumns + ledgerColumns + typeSpecificColumns.values.flatMap(\.self))

    nonisolated static var csvDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans")
        formatter.dateFormat = csvDateFormat
        return formatter
    }

    nonisolated static var csvLegacyDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans")
        formatter.dateFormat = csvLegacyDateFormat
        return formatter
    }

    nonisolated static func uiTestDelayNanoseconds(environmentKey: String) -> UInt64? {
        guard CommandLine.arguments.contains("--uitesting") else { return nil }
        guard let delayString = ProcessInfo.processInfo.environment[environmentKey],
              let delayMilliseconds = UInt64(delayString)
        else {
            return nil
        }
        return delayMilliseconds * 1_000_000
    }

    nonisolated static func resolveExportContext(
        for record: Record
    ) -> (eventName: String, eventTypeName: String, sceneTag: String)? {
        if let event = record.event {
            return (event.name, event.type.importExportName, "")
        }

        let trimmedSceneTag = record.contextTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSceneTag.isEmpty else {
            return nil
        }
        return ("", "", trimmedSceneTag)
    }

    nonisolated static func hostLedgerEvent(
        id: PersistentIdentifier,
        context: ModelContext
    ) throws -> Event {
        guard let event = context.model(for: id) as? Event, event.hostMode == .host else {
            throw ImportError.invalidFormat
        }
        return event
    }
}
