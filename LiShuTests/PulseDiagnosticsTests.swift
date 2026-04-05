import Foundation
import Logging
import Pulse
import Testing
@testable import LiShu

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

    @Test("network logger configuration redacts sensitive values")
    func networkLoggerConfiguration() {
        let configuration = PulseDiagnostics.makeNetworkLoggerConfiguration()

        #expect(configuration.excludedHosts.contains("*.apple.com"))
        #expect(configuration.excludedHosts.contains("*.icloud.com"))
        #expect(configuration.sensitiveHeaders.contains("Authorization"))
        #expect(configuration.sensitiveHeaders.contains("X-*"))
        #expect(configuration.sensitiveQueryItems.contains("access_token"))
        #expect(configuration.sensitiveQueryItems.contains("password"))
        #expect(configuration.sensitiveDataFields.contains("token"))
        #expect(configuration.sensitiveDataFields.contains("email"))
    }

    @Test("release logger store configuration uses capped body storage")
    func releaseStoreConfiguration() {
        let configuration = PulseDiagnostics.makeLoggerStoreConfiguration(isDebugBuild: false)

        #expect(configuration.sizeLimit == PulseDiagnostics.Constants.storeSizeLimit)
        #expect(configuration.responseBodySizeLimit == PulseDiagnostics.Constants.releaseResponseBodySizeLimit)
    }

    @Test("logging system writes messages into Pulse store")
    func loggingSystemWritesMessages() throws {
        PulseDiagnostics.configureIfNeeded(arguments: [], environment: [:])
        LoggerStore.shared.removeAll()

        var logger = Logger(label: "tests.pulse")
        logger.logLevel = .trace
        logger.notice("Pulse logging integration works", metadata: [
            "feature": .string("text_logs"),
            "count": .string("1")
        ])

        let messages = try waitForMessages(label: "tests.pulse")
        let message = try #require(messages.last)

        #expect(message.text == "Pulse logging integration works")
        #expect(message.label == "tests.pulse")
        #expect(message.metadata["feature"] == "text_logs")
        #expect(message.metadata["count"] == "1")
        #expect(PulseDiagnostics.didBootstrapLoggingSystem)
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
}
