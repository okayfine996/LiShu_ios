import Foundation
import SwiftData

enum RecordFilter: String, CaseIterable, Hashable {
    case all = "all"
    case given = "given"
    case received = "received"
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

            if filter == .given {
                descriptor.predicate = #Predicate<Record> { record in
                    record.directionRaw == "given"
                }
            } else if filter == .received {
                descriptor.predicate = #Predicate<Record> { record in
                    record.directionRaw == "received"
                }
            }

            var records = try context.fetch(descriptor)

            // Apply search filter in memory
            if !searchText.isEmpty {
                let query = searchText.lowercased()
                records = records.filter { record in
                    let contactMatch = (record.contact?.name ?? "").lowercased().contains(query)
                    let eventMatch = (record.event?.name ?? "").lowercased().contains(query)
                    return contactMatch || eventMatch
                }
            }

            let grouped = groupByMonth(records)
            state = .loaded(grouped)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func deleteRecord(_ record: Record, context: ModelContext) {
        context.delete(record)
        do {
            try context.save()
            load(context: context)
        } catch {
            deleteError = error.localizedDescription
            load(context: context)
        }
    }

    private func groupByMonth(_ records: [Record]) -> [String: [Record]] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans")
        formatter.dateFormat = "yyyy年M月"

        var result: [String: [Record]] = [:]
        for record in records {
            let key = formatter.string(from: record.date)
            result[key, default: []].append(record)
        }
        return result
    }

    private func parseMonthKey(_ key: String) -> Date {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans")
        formatter.dateFormat = "yyyy年M月"
        return formatter.date(from: key) ?? .distantPast
    }
}
