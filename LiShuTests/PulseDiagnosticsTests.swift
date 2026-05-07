import Foundation
@testable import LiShu
import Logging
import SwiftData
import Testing
import ZIPFoundation

private let pulseDiagnosticsLoggerStoreLock = NSLock()

@Suite(.serialized)
struct PulseDiagnosticsTests {
    @Test("monitoring enabled by default")
    func monitoringEnabledByDefault() {
        #expect(PulseDiagnostics.monitoringEnabled(arguments: [], environment: [:]))
    }

    @Test("monitoring disabled for UI tests")
    func monitoringDisabledForUITests() {
        #expect(!PulseDiagnostics.monitoringEnabled(
            arguments: [PulseDiagnostics.Constants.uiTestingArgument],
            environment: [:]
        ))
    }

    @Test("monitoring disabled by environment variable")
    func monitoringDisabledByEnvironment() {
        #expect(!PulseDiagnostics.monitoringEnabled(
            arguments: [],
            environment: [PulseDiagnostics.Constants.disabledEnvironmentKey: "1"]
        ))
    }

    @Test("hidden console availability follows monitoring gate")
    func hiddenConsoleAvailability() {
        #expect(PulseDiagnostics.hiddenConsoleAvailable(arguments: [], environment: [:]))
        #expect(!PulseDiagnostics.hiddenConsoleAvailable(
            arguments: [PulseDiagnostics.Constants.uiTestingArgument],
            environment: [:]
        ))
    }

    @Test("logger store configuration preserves size cap")
    func releaseStoreConfiguration() {
        let sizeLimit = PulseDiagnostics.loggerStoreSizeLimit(isDebugBuild: false)

        #expect(sizeLimit == PulseDiagnostics.Constants.storeSizeLimit)
    }

    @Test("logging system writes messages into Pulse store")
    func loggingSystemWritesMessages() throws {
        try withLoggerStoreIsolation {
            PulseDiagnostics.configureIfNeeded(arguments: [], environment: [:])
            PulseDiagnostics.clearStoredMessages()

            var logger = Logger(label: "tests.pulse")
            logger.logLevel = .trace
            logger.notice("Pulse logging integration works", metadata: [
                "feature": .string("text_logs"),
                "count": .string("1"),
            ])

            let messages = try waitForMessages(label: "tests.pulse")
            let message = try #require(messages.last)

            #expect(message.text == "Pulse logging integration works")
            #expect(message.label == "tests.pulse")
            #expect(message.metadata["feature"] == "text_logs")
            #expect(message.metadata["count"] == "1")
            #expect(PulseDiagnostics.didBootstrapLoggingSystem)
        }
    }

    @Test("ui interaction logger writes structured metadata into Pulse store")
    func uiInteractionLoggerWritesStructuredMetadata() throws {
        try withLoggerStoreIsolation {
            PulseDiagnostics.configureIfNeeded(arguments: [], environment: [:])
            PulseDiagnostics.clearStoredMessages()

            InteractionLogger.tap(
                screen: "settings.root",
                target: "settings.rateApp",
                route: "app_store_review",
                presentation: .push,
                metadata: ["result": "submitted"]
            )

            let message = try waitForMessage(label: AppLogLabel.uiInteraction) { message in
                message.metadata["event_type"] == UILogEventType.tap.rawValue &&
                    message.metadata["screen"] == "settings.root" &&
                    message.metadata["target"] == "settings.rateApp"
            }

            #expect(message.text == "UI interaction")
            #expect(message.metadata["event_type"] == UILogEventType.tap.rawValue)
            #expect(message.metadata["screen"] == "settings.root")
            #expect(message.metadata["target"] == "settings.rateApp")
            #expect(message.metadata["route"] == "app_store_review")
            #expect(message.metadata["presentation"] == UILogPresentation.push.rawValue)
            #expect(message.metadata["result"] == "submitted")
        }
    }

    @Test("screen view logger writes screen event into Pulse store")
    func screenViewLoggerWritesStructuredMetadata() throws {
        try withLoggerStoreIsolation {
            PulseDiagnostics.configureIfNeeded(arguments: [], environment: [:])
            PulseDiagnostics.clearStoredMessages()

            InteractionLogger.screenView("records.list", metadata: ["presentation": UILogPresentation.tab.rawValue])

            let message = try waitForMessage(label: AppLogLabel.uiInteraction) { message in
                message.metadata["event_type"] == UILogEventType.screenView.rawValue &&
                    message.metadata["screen"] == "records.list"
            }

            #expect(message.metadata["event_type"] == UILogEventType.screenView.rawValue)
            #expect(message.metadata["screen"] == "records.list")
            #expect(message.metadata["target"] == "records.list")
            #expect(message.metadata["action"] == UILogAction.open.rawValue)
        }
    }

    @MainActor
    @Test("business record query logger writes summarized record payloads into Pulse store")
    func businessRecordQueryLoggerWritesSummarizedRecordPayloads() throws {
        try withLoggerStoreIsolation {
            let runID = UUID().uuidString
            let screen = "records.list.\(runID)"
            let operation = "load_\(runID)"
            let searchText = "张\(runID)"
            let db = try TestDB()
            let contact = SampleData.contact(name: "张三", relation: "朋友")
            let event = SampleData.event(name: "婚礼", type: .wedding)
            db.context.insert(contact)
            db.context.insert(event)
            let record = SampleData.record(contact: contact, event: event, amount: 888)
            db.context.insert(record)
            db.context.insert(SampleData.recordPhoto(record: record))
            try db.context.save()

            PulseDiagnostics.configureIfNeeded(arguments: [], environment: [:])
            PulseDiagnostics.clearStoredMessages()

            BusinessDataLogger.recordQuery(
                screen: screen,
                operation: operation,
                searchText: searchText,
                filters: ["recordType": "all"],
                sort: "date_desc",
                records: [record]
            )

            let expectedRecordID = try #require(record.logPayload().id)
            let message = try waitForMessage(label: AppLogLabel.dataQuery) { message in
                message.metadata["event_type"] == "record_query" &&
                    message.metadata["screen"] == screen &&
                    message.metadata["operation"] == operation &&
                    message.metadata["query_input"]?.contains("\"searchText\":\"\(searchText)\"") == true
            }

            #expect(message.metadata["event_type"] == "record_query")
            #expect(message.metadata["domain"] == "record")
            #expect(message.metadata["screen"] == screen)
            #expect(message.metadata["result_count"] == "1")
            #expect(message.metadata["query_input"]?.contains("\"searchText\":\"\(searchText)\"") == true)
            #expect(message.metadata["raw_payload"]?.contains("\"searchText\":\"\(searchText)\"") == true)
            #expect(message.metadata["raw_payload"]?.contains("\"resultCount\":1") == true)
            #expect(containsNormalized(message.metadata["raw_payload"], expectedRecordID))
            #expect(message.metadata["raw_results"] == "[]")
        }
    }

    @Test("business query logger records empty result sets")
    func businessQueryLoggerRecordsEmptyResultSets() throws {
        try withLoggerStoreIsolation {
            let runID = UUID().uuidString
            let screen = "contacts.list.\(runID)"
            let operation = "search_change_\(runID)"
            let searchText = "不存在\(runID)"
            PulseDiagnostics.configureIfNeeded(arguments: [], environment: [:])
            PulseDiagnostics.clearStoredMessages()

            BusinessDataLogger.entityQuery(
                domain: "contact",
                screen: screen,
                operation: operation,
                searchText: searchText,
                filters: ["circleFilter": "all"],
                sort: "name_asc",
                results: [ContactLogPayload]()
            )

            let message = try waitForMessage(label: AppLogLabel.dataQuery) { message in
                message.metadata["event_type"] == "entity_query" &&
                    message.metadata["screen"] == screen &&
                    message.metadata["operation"] == operation &&
                    message.metadata["query_input"]?.contains("\"searchText\":\"\(searchText)\"") == true
            }

            #expect(message.metadata["event_type"] == "entity_query")
            #expect(message.metadata["domain"] == "contact")
            #expect(message.metadata["result_count"] == "0")
            #expect(message.metadata["raw_payload"]?.contains("\"resultCount\":0") == true)
            #expect(message.metadata["raw_results"] == "[]")
        }
    }

    @Test("business entity mutation logger uses mutation semantics")
    func businessEntityMutationLoggerUsesMutationSemantics() throws {
        try withLoggerStoreIsolation {
            PulseDiagnostics.configureIfNeeded(arguments: [], environment: [:])
            PulseDiagnostics.clearStoredMessages()

            let payload = ContactLogPayload(
                id: "contact-1",
                name: "赵六",
                phone: "",
                relation: "朋友",
                category: "social",
                circle: 3,
                birthday: nil,
                location: "",
                note: "",
                avatarPresent: false,
                recordCount: 0,
                createdAt: .now
            )

            BusinessDataLogger.entityMutation(
                domain: "contact",
                screen: "contacts.form",
                operation: "create",
                payload: payload,
                results: [payload]
            )

            let message = try waitForMessage(label: AppLogLabel.dataMutation) { message in
                message.metadata["event_type"] == "entity_mutation" &&
                    message.metadata["screen"] == "contacts.form" &&
                    message.metadata["operation"] == "create"
            }

            #expect(message.text == "Business entity mutation")
            #expect(message.metadata["event_type"] == "entity_mutation")
            #expect(message.metadata["domain"] == "contact")
            #expect(message.metadata["operation"] == "create")
            #expect(message.metadata["raw_results"]?.contains("\"name\":\"赵六\"") == true)
        }
    }

    @Test("business entity mutation logger preserves zero-result attempts")
    func businessEntityMutationLoggerPreservesZeroResultAttempts() throws {
        try withLoggerStoreIsolation {
            PulseDiagnostics.configureIfNeeded(arguments: [], environment: [:])
            PulseDiagnostics.clearStoredMessages()

            let payload = ContactLogPayload(
                id: "contact-2",
                name: "未保存",
                phone: "",
                relation: "",
                category: "",
                circle: 4,
                birthday: nil,
                location: "",
                note: "",
                avatarPresent: false,
                recordCount: 0,
                createdAt: .now
            )

            BusinessDataLogger.entityMutation(
                domain: "contact",
                screen: "contacts.form",
                operation: "create_failed",
                payload: payload,
                error: "validation_failed"
            )

            let message = try waitForMessage(label: AppLogLabel.dataMutation) { message in
                message.metadata["event_type"] == "entity_mutation" &&
                    message.metadata["screen"] == "contacts.form" &&
                    message.metadata["operation"] == "create_failed"
            }

            #expect(message.metadata["result_count"] == "0")
            #expect(message.metadata["raw_results"] == "[]")
        }
    }

    @MainActor
    @Test("detailed diagnostics export includes business metadata payloads")
    func detailedDiagnosticsExportIncludesBusinessMetadataPayloads() throws {
        try withLoggerStoreIsolation {
            let db = try TestDB()
            let contact = SampleData.contact(name: "李四", relation: "同事")
            db.context.insert(contact)
            try db.context.save()

            PulseDiagnostics.configureIfNeeded(arguments: [], environment: [:])
            PulseDiagnostics.clearStoredMessages()

            BusinessDataLogger.entityQuery(
                domain: "contact",
                screen: "contacts.list",
                operation: "load",
                searchText: "李",
                filters: ["circleFilter": "all"],
                sort: "name_asc",
                results: [contact.logPayload()]
            )

            _ = try waitForMessage(label: AppLogLabel.dataQuery) { message in
                message.metadata["event_type"] == "entity_query" &&
                    message.metadata["screen"] == "contacts.list" &&
                    message.metadata["query_input"]?.contains("\"searchText\":\"李\"") == true
            }
            let fileURL = try DiagnosticsExportService.exportDetailedLogs()
            #expect(fileURL.pathExtension == "zip")

            let extractedFileURL = try unzipDiagnosticsArchive(at: fileURL)
            let content = try String(contentsOf: extractedFileURL, encoding: .utf8)

            #expect(content.contains("Metadata"))
            #expect(content.contains("query_input:"))
            #expect(content.contains("\"searchText\" : \"李\""))
            #expect(content.contains("raw_payload:"))
            #expect(content.contains("\"resultCount\" : 1"))
            #expect(containsNormalized(content, contact.logPayload().id))
            #expect(content.contains("raw_results:"))
            #expect(content.contains("[]") || content.contains("[\n\n]"))
            let plaintextURL = plaintextSiblingURL(for: fileURL, extension: "log")
            #expect(!FileManager.default.fileExists(atPath: plaintextURL.path))
            try? FileManager.default.removeItem(at: extractedFileURL.deletingLastPathComponent())
            try? FileManager.default.removeItem(at: fileURL)
        }
    }

    @MainActor
    @Test("json lines diagnostics export includes business metadata payloads")
    func jsonLinesDiagnosticsExportIncludesBusinessMetadataPayloads() throws {
        try withLoggerStoreIsolation {
            let db = try TestDB()
            let contact = SampleData.contact(name: "王五", relation: "亲戚")
            db.context.insert(contact)
            try db.context.save()

            PulseDiagnostics.configureIfNeeded(arguments: [], environment: [:])
            PulseDiagnostics.clearStoredMessages()

            BusinessDataLogger.entityQuery(
                domain: "contact",
                screen: "contacts.list",
                operation: "load",
                searchText: "王",
                filters: ["circleFilter": "family"],
                sort: "name_asc",
                results: [contact.logPayload()]
            )

            _ = try waitForMessage(label: AppLogLabel.dataQuery) { message in
                message.metadata["event_type"] == "entity_query" &&
                    message.metadata["screen"] == "contacts.list" &&
                    message.metadata["query_input"]?.contains("\"searchText\":\"王\"") == true
            }
            let fileURL = try DiagnosticsExportService.exportDetailedJSONLines()
            #expect(fileURL.pathExtension == "zip")

            let extractedFileURL = try unzipDiagnosticsArchive(at: fileURL)
            let content = try String(contentsOf: extractedFileURL, encoding: .utf8)

            #expect(content.contains("\"message\":\"Business query\""))
            #expect(content.contains("\"rawLabel\":\"data.query\""))
            #expect(content.contains("\\\"searchText\\\":\\\"王\\\""))
            #expect(content.contains("\\\"resultCount\\\":1"))
            #expect(containsNormalized(content, contact.logPayload().id))
            #expect(content.contains("\"raw_results\":\"[]\""))
            let plaintextURL = plaintextSiblingURL(for: fileURL, extension: "jsonl")
            #expect(!FileManager.default.fileExists(atPath: plaintextURL.path))
            try? FileManager.default.removeItem(at: extractedFileURL.deletingLastPathComponent())
            try? FileManager.default.removeItem(at: fileURL)
        }
    }

    private func withLoggerStoreIsolation<T>(_ body: () throws -> T) rethrows -> T {
        pulseDiagnosticsLoggerStoreLock.lock()
        defer { pulseDiagnosticsLoggerStoreLock.unlock() }
        return try body()
    }

    private func waitForMessages(
        label: String,
        timeout: TimeInterval = 2.0
    ) throws -> [PulseDiagnosticsMessageSnapshot] {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            let messages = try PulseDiagnostics.messageSnapshots(label: label)
            if !messages.isEmpty {
                return messages
            }
            Thread.sleep(forTimeInterval: 0.05)
        }
        return try PulseDiagnostics.messageSnapshots(label: label)
    }

    private func waitForMessage(
        label: String,
        timeout: TimeInterval = 2.0,
        matching predicate: (PulseDiagnosticsMessageSnapshot) -> Bool
    ) throws -> PulseDiagnosticsMessageSnapshot {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            let messages = try PulseDiagnostics.messageSnapshots(label: label)
            if let message = messages.last(where: predicate) {
                return message
            }
            Thread.sleep(forTimeInterval: 0.05)
        }

        let messages = try PulseDiagnostics.messageSnapshots(label: label)
        let matchedMessage = messages.last(where: predicate)
        return try #require(matchedMessage)
    }

    private func unzipDiagnosticsArchive(at archiveURL: URL) throws -> URL {
        let destinationURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true)
        try FileManager.default.unzipItem(at: archiveURL, to: destinationURL)

        let extractedFiles = try FileManager.default.contentsOfDirectory(
            at: destinationURL,
            includingPropertiesForKeys: nil
        )
        return try #require(extractedFiles.first)
    }

    private func plaintextSiblingURL(for archiveURL: URL, extension fileExtension: String) -> URL {
        archiveURL.deletingPathExtension().appendingPathExtension(fileExtension)
    }

    private func containsNormalized(_ haystack: String?, _ needle: String) -> Bool {
        guard let haystack else { return false }
        return normalizedLogText(haystack).contains(normalizedLogText(needle))
    }

    private func normalizedLogText(_ value: String) -> String {
        value
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\\", with: "")
            .replacingOccurrences(of: "\n", with: "")
    }
}
