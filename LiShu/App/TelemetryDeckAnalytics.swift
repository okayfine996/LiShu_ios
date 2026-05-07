import Foundation
import TelemetryDeck

/// Thin adapter between the app's logging system and TelemetryDeck.
/// This is the only file that imports TelemetryDeck directly.
/// All signal names are defined here; nothing else in the app touches TelemetryDeck APIs.
nonisolated enum TelemetryDeckAnalytics {
    // MARK: - Signal Names

    nonisolated enum Signal {
        /// Screen views
        static let screenView = "screen.view"

        // Core entity creates / deletes
        static let recordCreated = "record.created"
        static let recordDeleted = "record.deleted"
        static let contactCreated = "contact.created"
        static let contactDeleted = "contact.deleted"
        static let eventCreated = "event.created"
        static let eventDeleted = "event.deleted"

        // Import / export
        static let ocrImported = "data.ocr.imported"
        static let xlsxImported = "data.xlsx.imported"
        static let xlsxExported = "data.xlsx.exported"
        static let contactXlsxImported = "data.contact.xlsx.imported"
        static let contactXlsxExported = "data.contact.xlsx.exported"

        // Subscriptions
        static let proPurchaseClicked = "pro.purchase.clicked"
        static let proPurchaseCompleted = "pro.purchase.completed"
    }

    // MARK: - Bootstrap

    private nonisolated(unsafe) static var isConfigured = false
    private nonisolated static let lock = NSLock()

    /// Initializes TelemetryDeck. Safe to call multiple times.
    /// No-ops if appID is empty or if running under UI tests.
    nonisolated static func configureIfNeeded() {
        let appID = TelemetryDeckConfig.appID
        guard !appID.isEmpty else { return }
        guard !CommandLine.arguments.contains("--uitesting") else { return }
        lock.lock()
        defer { lock.unlock() }
        guard !isConfigured else { return }
        isConfigured = true
        TelemetryDeck.initialize(config: TelemetryDeck.Config(appID: appID))
    }

    // MARK: - Fire

    nonisolated static func signal(_ name: String, parameters: [String: String] = [:]) {
        guard isConfigured else { return }
        TelemetryDeck.signal(name, parameters: parameters)
    }
}
