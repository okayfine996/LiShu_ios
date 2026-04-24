import Foundation
import SwiftData

// MARK: - Import Result Types

nonisolated struct ImportResult {
    var imported: Int = 0
    var skipped: Int = 0
    var errors: Int = 0
}

nonisolated struct ContactImportResult {
    var created: Int = 0
    var updated: Int = 0
    var failed: Int = 0
}

// MARK: - Import Preview Results

nonisolated struct CSVImportPreviewResult {
    let sourceFileName: String
    var items: [CSVImportPreviewItem]
    var skipped: Int = 0
    var errors: Int = 0
}

nonisolated struct LedgerCSVImportPreviewResult {
    let sourceFileName: String
    let eventName: String
    var items: [LedgerCSVImportPreviewItem]
    var skipped: Int = 0
    var errors: Int = 0
}

nonisolated struct ContactCSVPreviewResult {
    let sourceFileName: String
    var items: [ContactCSVPreviewItem]
    var errors: Int = 0
}

// MARK: - Import Preview Items

nonisolated struct CSVImportPreviewItem: Identifiable {
    let id = UUID()
    let rowNumber: Int
    var isSelected: Bool
    let contactName: String
    let eventName: String
    let eventTypeName: String
    let sceneTag: String
    let direction: RecordDirection
    let date: Date?
    let dateText: String
    let note: String
    let recordType: RecordType?
    let contextText: String
    let trailingText: String
    let detailText: String
    let status: CSVImportPreviewStatus
    let payload: CSVImportPayload?

    nonisolated var isImportable: Bool {
        switch status {
        case .ready:
            payload != nil
        case .skipped, .error:
            false
        }
    }

    nonisolated var statusMessage: String? {
        switch status {
        case .ready:
            nil
        case let .skipped(reason), let .error(reason):
            reason
        }
    }
}

nonisolated struct LedgerCSVImportPreviewItem: Identifiable {
    let id = UUID()
    let rowNumber: Int
    var isSelected: Bool
    let contactName: String
    let contextText: String
    let detailText: String
    let trailingText: String
    let status: CSVImportPreviewStatus
    let payload: LedgerCSVImportPayload?

    nonisolated var isImportable: Bool {
        switch status {
        case .ready:
            payload != nil
        case .skipped, .error:
            false
        }
    }

    nonisolated var statusMessage: String? {
        switch status {
        case .ready:
            nil
        case let .skipped(reason), let .error(reason):
            reason
        }
    }
}

nonisolated struct ContactCSVPreviewItem: Identifiable {
    let id = UUID()
    let rowNumber: Int
    var isSelected: Bool
    let name: String
    let detailText: String
    let status: CSVImportPreviewStatus
    let payload: ContactCSVPayload?

    init(
        rowNumber: Int,
        isSelected: Bool,
        name: String,
        detailText: String,
        status: CSVImportPreviewStatus,
        payload: ContactCSVPayload? = nil
    ) {
        self.rowNumber = rowNumber
        self.isSelected = isSelected
        self.name = name
        self.detailText = detailText
        self.status = status
        self.payload = payload
    }

    var isImportable: Bool {
        if case .ready = status, payload != nil { return true }
        return false
    }

    var statusMessage: String? {
        switch status {
        case .ready: nil
        case let .skipped(msg): msg
        case let .error(msg): msg
        }
    }
}

// MARK: - Export Preview Results

nonisolated struct CSVExportPreviewResult {
    let recordType: RecordType
    var items: [CSVExportPreviewItem]
    var skipped: Int = 0
}

nonisolated struct LedgerCSVExportPreviewResult {
    let eventID: PersistentIdentifier
    let eventName: String
    var items: [LedgerCSVExportPreviewItem]
    var skipped: Int = 0
}

// MARK: - Export Preview Items

nonisolated struct CSVExportPreviewItem: Identifiable {
    let id = UUID()
    let rowNumber: Int
    var isSelected: Bool
    let contactName: String
    let contextText: String
    let detailText: String
    let trailingText: String
    let status: CSVExportPreviewStatus
    let payload: CSVExportPayload?

    nonisolated var isExportable: Bool {
        switch status {
        case .ready:
            payload != nil
        case .skipped:
            false
        }
    }

    nonisolated var statusMessage: String? {
        switch status {
        case .ready:
            nil
        case let .skipped(reason):
            reason
        }
    }
}

nonisolated struct LedgerCSVExportPreviewItem: Identifiable {
    let id = UUID()
    let rowNumber: Int
    var isSelected: Bool
    let contactName: String
    let contextText: String
    let detailText: String
    let trailingText: String
    let status: CSVExportPreviewStatus
    let payload: LedgerCSVExportPayload?

    nonisolated var isExportable: Bool {
        switch status {
        case .ready:
            payload != nil
        case .skipped:
            false
        }
    }

    nonisolated var statusMessage: String? {
        switch status {
        case .ready:
            nil
        case let .skipped(reason):
            reason
        }
    }
}

// MARK: - Status Enums

nonisolated enum CSVExportPreviewStatus: Equatable {
    case ready
    case skipped(String)
}

nonisolated enum CSVImportPreviewStatus: Equatable {
    case ready
    case skipped(String)
    case error(String)
}

// MARK: - Payloads

nonisolated struct CSVExportPayload {
    let csvRow: String
}

nonisolated struct LedgerCSVExportPayload {
    let csvRow: String
}

nonisolated struct CSVImportPayload {
    let contactName: String
    let eventName: String
    let eventType: EventType
    let sceneTag: String
    let direction: RecordDirection
    let date: Date
    let note: String
    let recordType: RecordType
    let relationshipWeight: RelationshipWeight
    let returnedAmount: Double
    let typeData: RecordTypeData
}

nonisolated struct LedgerCSVImportPayload {
    let contactName: String
    let date: Date
    let note: String
    let relationshipWeight: RelationshipWeight
    let amount: Double
    let paymentMethod: PaymentMethod
}

nonisolated struct ContactCSVPayload {
    let name: String
    var phone: String?
    var relation: String?
    var category: String?
    var circle: Int?
    var birthday: Date?
    var location: String?
    var note: String?
}

// MARK: - Errors

nonisolated enum ImportError: LocalizedError {
    case accessDenied
    case invalidFormat

    var errorDescription: String? {
        switch self {
        case .accessDenied: String(localized: "import.error.accessDenied")
        case .invalidFormat: String(localized: "import.error.invalidFormat")
        }
    }
}
