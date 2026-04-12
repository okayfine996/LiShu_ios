import Foundation
import Logging
import SwiftData

private let eventHostModeLogger = PulseDiagnostics.makeLogger(label: "storage.event-host-mode")

/// 持续归一化旧事件的 hostMode，兼容首启后才从 iCloud 同步进来的历史数据。
enum EventHostModeNormalizer {
    static func run(context: ModelContext) {
        do {
            let updatedCount = try normalizeEvents(context: context)
            eventHostModeLogger.notice("Event host mode normalization finished", metadata: [
                "updated_count": .stringConvertible(updatedCount),
            ])
        } catch {
            eventHostModeLogger.error("Event host mode normalization failed", metadata: [
                "error": .string(error.localizedDescription),
            ])
        }
    }

    @discardableResult
    static func normalizeEvents(context: ModelContext) throws -> Int {
        let events = try context.fetch(FetchDescriptor<Event>())
        var updatedCount = 0

        for event in events where event.hostMode != .host {
            let receivedMonetaryCount = (event.records ?? []).reduce(into: 0) { count, record in
                if record.recordType == .monetary, record.direction == .received {
                    count += 1
                }
            }

            guard receivedMonetaryCount >= 2 else { continue }
            event.hostMode = .host
            updatedCount += 1
        }

        if updatedCount > 0 {
            try context.save()
        }

        return updatedCount
    }
}
