import Foundation
import Logging
import SwiftData

private nonisolated(unsafe) var recordTypeStorageLogger: Logger { PulseDiagnostics.makeLogger(label: "storage.record-type") }

/// 将 `recordTypeRaw` 规范为 `RecordType` 的 canonical rawValue，使 `#Predicate { $0.recordTypeRaw == "…" }` 与业务解析一致。
enum RecordTypeStorageNormalizer {
    static let userDefaultsKey = "didNormalizeRecordTypeRaw2026"

    /// 一次性迁移：全量规范化后写入 UserDefaults，失败时不写入以便下次启动重试。
    static func runMigrationIfNeeded(context: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: userDefaultsKey) else { return }
        do {
            try normalizeAllRecords(context: context)
            UserDefaults.standard.set(true, forKey: userDefaultsKey)
            recordTypeStorageLogger.notice("Record type normalization finished")
        } catch {
            recordTypeStorageLogger.error("Record type normalization failed", metadata: [
                "error": .string(error.localizedDescription)
            ])
        }
    }

    /// 测试与手动修复：对每条记录执行 `record.recordType = record.recordType` 并保存。
    static func normalizeAllRecords(context: ModelContext) throws {
        let descriptor = FetchDescriptor<Record>()
        let records = try context.fetch(descriptor)
        for record in records {
            record.recordType = record.recordType
        }
        try context.save()
    }
}
