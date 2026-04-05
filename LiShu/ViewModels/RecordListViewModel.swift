import Foundation
import Logging
import SwiftData

private let recordListLogger = PulseDiagnostics.makeLogger(label: AppLogLabel.recordsViewModel)

enum RecordFilter: String, CaseIterable, Hashable {
    case all
    case monetary
    case gift
    case favor
    case banquet
}

@Observable
class RecordListViewModel {
    var state: LoadingState<[String: [Record]]> = .idle
    var filter: RecordFilter = .all
    var deleteError: String?
    var searchText: String = ""
    var isSearching: Bool = false

    /// Sorted month keys for display (newest first)
    var sortedMonthKeys: [String] {
        guard let grouped = state.value else { return [] }
        return grouped.keys.sorted { key1, key2 in
            parseMonthKey(key1) > parseMonthKey(key2)
        }
    }

    func load(context: ModelContext) {
        state = .loading
        do {
            var descriptor = FetchDescriptor<Record>(
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )

            switch filter {
            case .all:
                break
            case .monetary:
                descriptor.predicate = #Predicate<Record> { $0.recordTypeRaw == "monetary" }
            case .gift:
                descriptor.predicate = #Predicate<Record> { $0.recordTypeRaw == "gift" }
            case .favor:
                descriptor.predicate = #Predicate<Record> { $0.recordTypeRaw == "favor" }
            case .banquet:
                descriptor.predicate = #Predicate<Record> { $0.recordTypeRaw == "banquet" }
            }

            var records = try context.fetch(descriptor)

            // 搜索：先匹配联系人/事件名（避免对每条记录解码 kv）；再对剩余记录解析 description
            if !searchText.isEmpty {
                let query = searchText.lowercased()
                records = records.filter { record in
                    let contactMatch = (record.contact?.name ?? "").lowercased().contains(query)
                    let eventMatch = (record.event?.name ?? "").lowercased().contains(query)
                    if contactMatch || eventMatch { return true }
                    return record.resolvedDescription.lowercased().contains(query)
                }
            }

            let grouped = groupByMonth(records)
            state = .loaded(grouped)
            BusinessDataLogger.recordQuery(
                screen: "records.list",
                operation: "load",
                searchText: searchText.trimmingCharacters(in: .whitespacesAndNewlines),
                filters: ["recordType": filter.rawValue],
                sort: "date_desc",
                records: records
            )
            recordListLogger.notice("Loaded records", metadata: [
                "step": .string("load"),
                "count": .stringConvertible(records.count),
                "result": .string("success"),
                "reason": .string(filter.rawValue),
            ])
        } catch {
            state = .error(error.localizedDescription)
            BusinessDataLogger.recordQuery(
                screen: "records.list",
                operation: "load_failed",
                searchText: searchText.trimmingCharacters(in: .whitespacesAndNewlines),
                filters: ["recordType": filter.rawValue],
                sort: "date_desc",
                records: [],
                error: error.localizedDescription
            )
            recordListLogger.error("Failed to load records", metadata: [
                "step": .string("load"),
                "error": .string(error.localizedDescription),
            ])
        }
    }

    func deleteRecord(_ record: Record, context: ModelContext) {
        let deletedPayload = record.logPayload()
        recordListLogger.notice("Deleting record", metadata: [
            "step": .string("delete"),
            "record_id": .string(String(describing: record.persistentModelID)),
        ])
        context.delete(record)
        do {
            try context.save()
            BusinessDataLogger.recordMutation(
                screen: "records.list",
                operation: "delete",
                payload: deletedPayload,
                results: [deletedPayload]
            )
            recordListLogger.notice("Deleted record", metadata: [
                "step": .string("delete"),
                "record_id": .string(String(describing: record.persistentModelID)),
                "result": .string("success"),
            ])
            load(context: context)
        } catch {
            deleteError = error.localizedDescription
            BusinessDataLogger.recordMutation(
                screen: "records.list",
                operation: "delete_failed",
                payload: deletedPayload,
                error: error.localizedDescription
            )
            recordListLogger.error("Failed to delete record", metadata: [
                "step": .string("delete"),
                "record_id": .string(String(describing: record.persistentModelID)),
                "error": .string(error.localizedDescription),
            ])
            load(context: context)
        }
    }

    private func groupByMonth(_ records: [Record]) -> [String: [Record]] {
        let formatter = DateFormatters.recordListMonthKey
        var result: [String: [Record]] = [:]
        for record in records {
            let key = formatter.string(from: record.date)
            result[key, default: []].append(record)
        }
        return result
    }

    private func parseMonthKey(_ key: String) -> Date {
        DateFormatters.recordListMonthKey.date(from: key) ?? .distantPast
    }
}
