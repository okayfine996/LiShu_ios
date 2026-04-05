import Foundation
@testable import LiShu
import Logging
import Pulse
import SwiftData
import Testing
import ZipArchive

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
        let configuration = PulseDiagnostics.makeLoggerStoreConfiguration(isDebugBuild: false)

        #expect(configuration.sizeLimit == PulseDiagnostics.Constants.storeSizeLimit)
    }

    @Test("logging system writes messages into Pulse store")
    func loggingSystemWritesMessages() throws {
        PulseDiagnostics.configureIfNeeded(arguments: [], environment: [:])
        LoggerStore.shared.removeAll()

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

    @Test("ui interaction logger writes structured metadata into Pulse store")
    func uiInteractionLoggerWritesStructuredMetadata() throws {
        PulseDiagnostics.configureIfNeeded(arguments: [], environment: [:])
        LoggerStore.shared.removeAll()

        InteractionLogger.tap(
            screen: "settings.root",
            target: "settings.rateApp",
            route: "app_store_review",
            presentation: .push,
            metadata: ["result": "submitted"]
        )

        let messages = try waitForMessages(label: AppLogLabel.uiInteraction)
        let message = try #require(messages.last)

        #expect(message.text == "UI interaction")
        #expect(message.metadata["event_type"] == UILogEventType.tap.rawValue)
        #expect(message.metadata["screen"] == "settings.root")
        #expect(message.metadata["target"] == "settings.rateApp")
        #expect(message.metadata["route"] == "app_store_review")
        #expect(message.metadata["presentation"] == UILogPresentation.push.rawValue)
        #expect(message.metadata["result"] == "submitted")
    }

    @Test("screen view logger writes screen event into Pulse store")
    func screenViewLoggerWritesStructuredMetadata() throws {
        PulseDiagnostics.configureIfNeeded(arguments: [], environment: [:])
        LoggerStore.shared.removeAll()

        InteractionLogger.screenView("records.list", metadata: ["presentation": UILogPresentation.tab.rawValue])

        let messages = try waitForMessages(label: AppLogLabel.uiInteraction)
        let message = try #require(messages.last)

        #expect(message.metadata["event_type"] == UILogEventType.screenView.rawValue)
        #expect(message.metadata["screen"] == "records.list")
        #expect(message.metadata["target"] == "records.list")
        #expect(message.metadata["action"] == UILogAction.open.rawValue)
    }

    @MainActor
    @Test("business record query logger writes raw record payloads into Pulse store")
    func businessRecordQueryLoggerWritesRawRecordPayloads() throws {
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
        LoggerStore.shared.removeAll()

        BusinessDataLogger.recordQuery(
            screen: "records.list",
            operation: "load",
            searchText: "张",
            filters: ["recordType": "all"],
            sort: "date_desc",
            records: [record]
        )

        let messages = try waitForMessages(label: AppLogLabel.dataQuery)
        let message = try #require(messages.last)

        #expect(message.metadata["event_type"] == "record_query")
        #expect(message.metadata["domain"] == "record")
        #expect(message.metadata["screen"] == "records.list")
        #expect(message.metadata["result_count"] == "1")
        #expect(message.metadata["query_input"]?.contains("\"searchText\":\"张\"") == true)
        #expect(message.metadata["raw_results"]?.contains("\"name\":\"张三\"") == true)
        #expect(message.metadata["raw_results"]?.contains("\"photoCount\":1") == true)
    }

    @Test("business query logger records empty result sets")
    func businessQueryLoggerRecordsEmptyResultSets() throws {
        PulseDiagnostics.configureIfNeeded(arguments: [], environment: [:])
        LoggerStore.shared.removeAll()

        BusinessDataLogger.entityQuery(
            domain: "contact",
            screen: "contacts.list",
            operation: "search_change",
            searchText: "不存在",
            filters: ["circleFilter": "all"],
            sort: "name_asc",
            results: [ContactLogPayload]()
        )

        let messages = try waitForMessages(label: AppLogLabel.dataQuery)
        let message = try #require(messages.last)

        #expect(message.metadata["event_type"] == "entity_query")
        #expect(message.metadata["domain"] == "contact")
        #expect(message.metadata["result_count"] == "0")
        #expect(message.metadata["raw_results"] == "[]")
    }

    @Test("business entity mutation logger uses mutation semantics")
    func businessEntityMutationLoggerUsesMutationSemantics() throws {
        PulseDiagnostics.configureIfNeeded(arguments: [], environment: [:])
        LoggerStore.shared.removeAll()

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

        let messages = try waitForMessages(label: AppLogLabel.dataMutation)
        let message = try #require(messages.last)

        #expect(message.text == "Business entity mutation")
        #expect(message.metadata["event_type"] == "entity_mutation")
        #expect(message.metadata["domain"] == "contact")
        #expect(message.metadata["operation"] == "create")
        #expect(message.metadata["raw_results"]?.contains("\"name\":\"赵六\"") == true)
    }

    @MainActor
    @Test("detailed diagnostics export includes business metadata payloads")
    func detailedDiagnosticsExportIncludesBusinessMetadataPayloads() throws {
        let db = try TestDB()
        let contact = SampleData.contact(name: "李四", relation: "同事")
        db.context.insert(contact)
        try db.context.save()

        PulseDiagnostics.configureIfNeeded(arguments: [], environment: [:])
        LoggerStore.shared.removeAll()

        BusinessDataLogger.entityQuery(
            domain: "contact",
            screen: "contacts.list",
            operation: "load",
            searchText: "李",
            filters: ["circleFilter": "all"],
            sort: "name_asc",
            results: [contact.logPayload()]
        )

        _ = try waitForMessages(label: AppLogLabel.dataQuery)
        let fileURL = try DiagnosticsExportService.exportDetailedLogs()
        #expect(fileURL.pathExtension == "zip")

        let extractedFileURL = try unzipDiagnosticsArchive(at: fileURL)
        let content = try String(contentsOf: extractedFileURL, encoding: .utf8)

        #expect(content.contains("Metadata"))
        #expect(content.contains("query_input:"))
        #expect(content.contains("\"searchText\" : \"李\""))
        #expect(content.contains("raw_results:"))
        #expect(content.contains("\"name\" : \"李四\""))
        let plaintextURL = plaintextSiblingURL(for: fileURL, extension: "log")
        #expect(!FileManager.default.fileExists(atPath: plaintextURL.path))
        try? FileManager.default.removeItem(at: extractedFileURL.deletingLastPathComponent())
        try? FileManager.default.removeItem(at: fileURL)
    }

    @MainActor
    @Test("json lines diagnostics export includes business metadata payloads")
    func jsonLinesDiagnosticsExportIncludesBusinessMetadataPayloads() throws {
        let db = try TestDB()
        let contact = SampleData.contact(name: "王五", relation: "亲戚")
        db.context.insert(contact)
        try db.context.save()

        PulseDiagnostics.configureIfNeeded(arguments: [], environment: [:])
        LoggerStore.shared.removeAll()

        BusinessDataLogger.entityQuery(
            domain: "contact",
            screen: "contacts.list",
            operation: "load",
            searchText: "王",
            filters: ["circleFilter": "family"],
            sort: "name_asc",
            results: [contact.logPayload()]
        )

        _ = try waitForMessages(label: AppLogLabel.dataQuery)
        let fileURL = try DiagnosticsExportService.exportDetailedJSONLines()
        #expect(fileURL.pathExtension == "zip")

        let extractedFileURL = try unzipDiagnosticsArchive(at: fileURL)
        let content = try String(contentsOf: extractedFileURL, encoding: .utf8)

        #expect(content.contains("\"message\":\"Business query\""))
        #expect(content.contains("\"rawLabel\":\"data.query\""))
        #expect(content.contains("\"searchText\":\"王\""))
        #expect(content.contains("\"name\":\"王五\""))
        let plaintextURL = plaintextSiblingURL(for: fileURL, extension: "jsonl")
        #expect(!FileManager.default.fileExists(atPath: plaintextURL.path))
        try? FileManager.default.removeItem(at: extractedFileURL.deletingLastPathComponent())
        try? FileManager.default.removeItem(at: fileURL)
    }

    private func waitForMessages(label: String, timeout: TimeInterval = 2.0) throws -> [LoggerMessageEntity] {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            let messages = try LoggerStore.shared.allMessages().filter { $0.label == label }
            if !messages.isEmpty {
                return messages
            }
            Thread.sleep(forTimeInterval: 0.05)
        }
        return try LoggerStore.shared.allMessages().filter { $0.label == label }
    }

    private func unzipDiagnosticsArchive(at archiveURL: URL) throws -> URL {
        let destinationURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true)

        let success = SSZipArchive.unzipFile(
            atPath: archiveURL.path,
            toDestination: destinationURL.path,
            overwrite: true,
            password: DiagnosticsExportConstants.archivePassword
        )
        #expect(success)

        let extractedFiles = try FileManager.default.contentsOfDirectory(
            at: destinationURL,
            includingPropertiesForKeys: nil
        )
        return try #require(extractedFiles.first)
    }

    private func plaintextSiblingURL(for archiveURL: URL, extension fileExtension: String) -> URL {
        archiveURL.deletingPathExtension().appendingPathExtension(fileExtension)
    }
}
