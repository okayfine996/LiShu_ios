import Foundation
import Logging
import SwiftData

struct QueryLogPayload<Result: Encodable>: Encodable {
    let searchText: String
    let filters: [String: String]
    let sort: String
    let screen: String
    let resultCount: Int
    let results: [Result]
}

struct QueryInputLogPayload: Encodable {
    let searchText: String
    let filters: [String: String]
    let sort: String
    let screen: String
}

struct QuerySummaryLogPayload: Encodable {
    let searchText: String
    let filters: [String: String]
    let sort: String
    let screen: String
    let resultCount: Int
    let sampleIDs: [String]
}

struct AmountLogPayload: Encodable {
    let value: Double
    let display: String
}

struct ContactLogPayload: Encodable {
    let id: String
    let name: String
    let phone: String
    let relation: String
    let category: String
    let circle: Int
    let birthday: Date?
    let location: String
    let note: String
    let avatarPresent: Bool
    let recordCount: Int
    let createdAt: Date
}

struct EventLogPayload: Encodable {
    let id: String
    let name: String
    let type: String
    let date: Date
    let location: String
    let note: String
    let coverImagePresent: Bool
    let recordCount: Int
    let createdAt: Date
}

struct MonetaryTypeDataLogPayload: Encodable {
    let amount: AmountLogPayload
    let paymentMethod: String
    let returnedAmount: AmountLogPayload
}

struct GiftTypeDataLogPayload: Encodable {
    let giftName: String
    let estimatedValue: AmountLogPayload?
}

struct FavorTypeDataLogPayload: Encodable {
    let description: String
}

struct BanquetTypeDataLogPayload: Encodable {
    let location: String
    let attendeeList: String
    let extraCostNotes: String
}

struct RecordTypeDataLogPayload: Encodable {
    let kind: String
    let monetary: MonetaryTypeDataLogPayload?
    let gift: GiftTypeDataLogPayload?
    let favor: FavorTypeDataLogPayload?
    let banquet: BanquetTypeDataLogPayload?
}

struct RecordLogPayload: Encodable {
    let id: String?
    let direction: String
    let recordType: String
    let date: Date
    let note: String
    let contact: ContactLogPayload?
    let event: EventLogPayload?
    let contextSelection: String
    let contextTag: String
    let typeData: RecordTypeDataLogPayload
    let photoCount: Int
    let relationshipWeight: String
}

struct OCRRecordItemLogPayload: Encodable {
    let id: String
    let name: String
    let amount: AmountLogPayload
    let amountText: String
    let confidence: String
    let warningType: String?
    let isSelected: Bool
}

private struct AnyEncodable: Encodable {
    private let encodeImpl: (Encoder) throws -> Void

    nonisolated init(_ wrapped: some Encodable) {
        encodeImpl = wrapped.encode
    }

    nonisolated func encode(to encoder: Encoder) throws {
        try encodeImpl(encoder)
    }
}

enum BusinessDataLogger {
    private static let recordLogger = PulseDiagnostics.makeLogger(label: AppLogLabel.dataRecord)
    private static let mutationLogger = PulseDiagnostics.makeLogger(label: AppLogLabel.dataMutation)
    private static let queryLogger = PulseDiagnostics.makeLogger(label: AppLogLabel.dataQuery)
    private static let ocrLogger = PulseDiagnostics.makeLogger(label: AppLogLabel.dataOCR)

    static func recordMutation(
        screen: String,
        operation: String,
        payload: some Encodable,
        results: [RecordLogPayload] = [],
        error: String? = nil
    ) {
        log(
            logger: recordLogger,
            message: "Business record mutation",
            eventType: "record_mutation",
            domain: "record",
            operation: operation,
            screen: screen,
            queryInput: QueryInputLogPayload(searchText: "", filters: [:], sort: "", screen: screen),
            payload: AnyEncodable(payload),
            results: results.map(AnyEncodable.init),
            error: error
        )
    }

    static func recordQuery(
        screen: String,
        operation: String = "load",
        searchText: String,
        filters: [String: String],
        sort: String,
        records: [Record],
        error: String? = nil
    ) {
        let payloads = records.map { $0.logPayload() }
        #if DEBUG
            let queryPayload = QuerySummaryLogPayload(
                searchText: searchText,
                filters: filters,
                sort: sort,
                screen: screen,
                resultCount: payloads.count,
                sampleIDs: payloads.compactMap(\.id).prefix(5).map(\.self)
            )
            let loggedResults: [AnyEncodable] = []
        #else
            let queryPayload = QueryLogPayload(
                searchText: searchText,
                filters: filters,
                sort: sort,
                screen: screen,
                resultCount: payloads.count,
                results: payloads
            )
            let loggedResults = payloads.map(AnyEncodable.init)
        #endif
        log(
            logger: queryLogger,
            message: "Business query",
            eventType: "record_query",
            domain: "record",
            operation: operation,
            screen: screen,
            queryInput: QueryInputLogPayload(searchText: searchText, filters: filters, sort: sort, screen: screen),
            payload: AnyEncodable(queryPayload),
            results: loggedResults,
            resultCount: payloads.count,
            error: error
        )
    }

    static func entityMutation(
        domain: String,
        screen: String,
        operation: String,
        payload: some Encodable,
        error: String? = nil
    ) {
        log(
            logger: mutationLogger,
            message: "Business entity mutation",
            eventType: "entity_mutation",
            domain: domain,
            operation: operation,
            screen: screen,
            queryInput: QueryInputLogPayload(searchText: "", filters: [:], sort: "", screen: screen),
            payload: AnyEncodable(payload),
            results: [],
            resultCount: 0,
            error: error
        )
    }

    static func entityMutation(
        domain: String,
        screen: String,
        operation: String,
        payload: some Encodable,
        results: [some Encodable],
        error: String? = nil
    ) {
        log(
            logger: mutationLogger,
            message: "Business entity mutation",
            eventType: "entity_mutation",
            domain: domain,
            operation: operation,
            screen: screen,
            queryInput: QueryInputLogPayload(searchText: "", filters: [:], sort: "", screen: screen),
            payload: AnyEncodable(payload),
            results: results.map(AnyEncodable.init),
            error: error
        )
    }

    static func entityQuery(
        domain: String,
        screen: String,
        operation: String = "load",
        searchText: String,
        filters: [String: String],
        sort: String,
        results: [some Encodable],
        error: String? = nil
    ) {
        #if DEBUG
            let sampleIDs = results.prefix(5).compactMap { item -> String? in
                let mirror = Mirror(reflecting: item)
                return mirror.children.first(where: { $0.label == "id" })?.value as? String
            }
            let queryPayload = QuerySummaryLogPayload(
                searchText: searchText,
                filters: filters,
                sort: sort,
                screen: screen,
                resultCount: results.count,
                sampleIDs: sampleIDs
            )
            let loggedResults: [AnyEncodable] = []
        #else
            let queryPayload = QueryLogPayload(
                searchText: searchText,
                filters: filters,
                sort: sort,
                screen: screen,
                resultCount: results.count,
                results: results
            )
            let loggedResults = results.map(AnyEncodable.init)
        #endif
        log(
            logger: queryLogger,
            message: "Business query",
            eventType: "entity_query",
            domain: domain,
            operation: operation,
            screen: screen,
            queryInput: QueryInputLogPayload(searchText: searchText, filters: filters, sort: sort, screen: screen),
            payload: AnyEncodable(queryPayload),
            results: loggedResults,
            resultCount: results.count,
            error: error
        )
    }

    static func ocrQuery(
        screen: String,
        operation: String,
        searchText: String = "",
        filters: [String: String] = [:],
        sort: String = "",
        payload: some Encodable,
        results: [some Encodable],
        error: String? = nil
    ) {
        log(
            logger: ocrLogger,
            message: "OCR business query",
            eventType: "ocr_query",
            domain: "ocr",
            operation: operation,
            screen: screen,
            queryInput: QueryInputLogPayload(searchText: searchText, filters: filters, sort: sort, screen: screen),
            payload: AnyEncodable(payload),
            results: results.map(AnyEncodable.init),
            error: error
        )
    }

    private static func log(
        logger: Logger,
        message: Logger.Message,
        eventType: String,
        domain: String,
        operation: String,
        screen: String,
        queryInput: QueryInputLogPayload,
        payload: AnyEncodable,
        results: [AnyEncodable],
        resultCount: Int? = nil,
        error: String?
    ) {
        let encodedQueryInput = encodeJSONString(queryInput, fallbackLabel: "query_input", logger: logger)
        let encodedPayload = encodeJSONString(payload, fallbackLabel: "raw_payload", logger: logger)
        let encodedResults = encodeJSONString(results, fallbackLabel: "raw_results", logger: logger)

        var metadata: Logger.Metadata = [
            "event_type": .string(eventType),
            "domain": .string(domain),
            "operation": .string(operation),
            "screen": .string(screen),
            "query_input": .string(encodedQueryInput),
            "result_count": .stringConvertible(resultCount ?? results.count),
            "raw_payload": .string(encodedPayload),
            "raw_results": .string(encodedResults),
        ]

        if let error, !error.isEmpty {
            metadata["error"] = .string(error)
            logger.error(message, metadata: metadata)
        } else {
            logger.notice(message, metadata: metadata)
        }
    }

    private static func encodeJSONString(
        _ value: some Encodable,
        fallbackLabel: String,
        logger: Logger
    ) -> String {
        do {
            let data = try PulseDiagnostics.businessDataJSONEncoder.encode(value)
            return String(decoding: data, as: UTF8.self)
        } catch {
            logger.error("Failed to encode business log payload", metadata: [
                "field": .string(fallbackLabel),
                "error": .string(error.localizedDescription),
            ])
            return "{}"
        }
    }
}

extension PulseDiagnostics {
    nonisolated static var businessDataJSONEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }
}

extension Contact {
    func logPayload() -> ContactLogPayload {
        ContactLogPayload(
            id: logIdentifier,
            name: name,
            phone: phone,
            relation: relation,
            category: category,
            circle: circle,
            birthday: birthday,
            location: location,
            note: note,
            avatarPresent: avatar != nil,
            recordCount: records?.count ?? 0,
            createdAt: createdAt
        )
    }
}

extension Event {
    func logPayload() -> EventLogPayload {
        EventLogPayload(
            id: logIdentifier,
            name: name,
            type: type.rawValue,
            date: date,
            location: location,
            note: note,
            coverImagePresent: coverImage != nil,
            recordCount: records?.count ?? 0,
            createdAt: createdAt
        )
    }
}

extension Record {
    func logPayload() -> RecordLogPayload {
        RecordLogPayload(
            id: logIdentifier,
            direction: direction.rawValue,
            recordType: recordType.rawValue,
            date: date,
            note: note,
            contact: contact?.logPayload(),
            event: event?.logPayload(),
            contextSelection: event == nil ? RecordContextSelection.daily.rawValue : RecordContextSelection.event.rawValue,
            contextTag: contextTag,
            typeData: resolvedTypeData.logPayload(),
            photoCount: photos?.count ?? 0,
            relationshipWeight: relationshipWeight.rawValue
        )
    }
}

extension OCRRecordItem {
    func logPayload() -> OCRRecordItemLogPayload {
        OCRRecordItemLogPayload(
            id: id.uuidString,
            name: name,
            amount: .init(value: amount, display: amount.logDisplayString()),
            amountText: amountText,
            confidence: confidence.rawValue,
            warningType: warningType?.rawValue,
            isSelected: isSelected
        )
    }
}

extension RecordTypeData {
    func logPayload() -> RecordTypeDataLogPayload {
        switch self {
        case let .monetary(data):
            RecordTypeDataLogPayload(
                kind: RecordType.monetary.rawValue,
                monetary: MonetaryTypeDataLogPayload(
                    amount: .init(value: data.amount, display: data.amount.logDisplayString()),
                    paymentMethod: data.paymentMethod,
                    returnedAmount: .init(value: data.returnedAmount, display: data.returnedAmount.logDisplayString())
                ),
                gift: nil,
                favor: nil,
                banquet: nil
            )
        case let .gift(data):
            RecordTypeDataLogPayload(
                kind: RecordType.gift.rawValue,
                monetary: nil,
                gift: GiftTypeDataLogPayload(
                    giftName: data.giftName,
                    estimatedValue: data.estimatedValue.map { .init(value: $0, display: $0.logDisplayString()) }
                ),
                favor: nil,
                banquet: nil
            )
        case let .favor(data):
            RecordTypeDataLogPayload(
                kind: RecordType.favor.rawValue,
                monetary: nil,
                gift: nil,
                favor: FavorTypeDataLogPayload(description: data.description),
                banquet: nil
            )
        case let .banquet(data):
            RecordTypeDataLogPayload(
                kind: RecordType.banquet.rawValue,
                monetary: nil,
                gift: nil,
                favor: nil,
                banquet: BanquetTypeDataLogPayload(
                    location: data.location,
                    attendeeList: data.attendeeList,
                    extraCostNotes: data.extraCostNotes
                )
            )
        }
    }
}

private extension Contact {
    var logIdentifier: String {
        String(describing: persistentModelID)
    }
}

private extension Event {
    var logIdentifier: String {
        String(describing: persistentModelID)
    }
}

private extension Record {
    var logIdentifier: String? {
        String(describing: persistentModelID)
    }
}

private extension Double {
    func logDisplayString() -> String {
        if self == Double(Int(self)) {
            return String(Int(self))
        }
        return String(format: "%.2f", self)
    }
}
