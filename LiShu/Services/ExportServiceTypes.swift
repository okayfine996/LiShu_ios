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

nonisolated struct ImportPreviewResult {
    let sourceFileName: String
    var items: [ImportPreviewItem]
    var skipped: Int = 0
    var errors: Int = 0
}

nonisolated struct LedgerImportPreviewResult {
    let sourceFileName: String
    let eventName: String
    var items: [LedgerImportPreviewItem]
    var skipped: Int = 0
    var errors: Int = 0
}

nonisolated struct ContactPreviewResult {
    let sourceFileName: String
    var items: [ContactPreviewItem]
    var errors: Int = 0
}

// MARK: - Import Preview Items

nonisolated struct ImportPreviewItem: Identifiable {
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
    let status: ImportPreviewStatus
    let payload: ImportPayload?

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

nonisolated struct LedgerImportPreviewItem: Identifiable {
    let id = UUID()
    let rowNumber: Int
    var isSelected: Bool
    let contactName: String
    let contextText: String
    let detailText: String
    let trailingText: String
    let status: ImportPreviewStatus
    let payload: LedgerImportPayload?

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

nonisolated struct ContactPreviewItem: Identifiable {
    let id = UUID()
    let rowNumber: Int
    var isSelected: Bool
    let name: String
    let detailText: String
    let status: ImportPreviewStatus
    let payload: ContactPayload?

    init(
        rowNumber: Int,
        isSelected: Bool,
        name: String,
        detailText: String,
        status: ImportPreviewStatus,
        payload: ContactPayload? = nil
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

nonisolated struct ExportPreviewResult {
    let recordType: RecordType
    var items: [ExportPreviewItem]
    var skipped: Int = 0
}

nonisolated struct LedgerExportPreviewResult {
    let eventID: PersistentIdentifier
    let eventName: String
    var items: [LedgerExportPreviewItem]
    var skipped: Int = 0
}

// MARK: - Export Preview Items

nonisolated struct ExportPreviewItem: Identifiable {
    let id = UUID()
    let rowNumber: Int
    var isSelected: Bool
    let contactName: String
    let contextText: String
    let detailText: String
    let trailingText: String
    let status: ExportPreviewStatus
    let payload: ExportPayload?

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

nonisolated struct LedgerExportPreviewItem: Identifiable {
    let id = UUID()
    let rowNumber: Int
    var isSelected: Bool
    let contactName: String
    let contextText: String
    let detailText: String
    let trailingText: String
    let status: ExportPreviewStatus
    let payload: LedgerExportPayload?

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

nonisolated enum ExportPreviewStatus: Equatable {
    case ready
    case skipped(String)
}

nonisolated enum ImportPreviewStatus: Equatable {
    case ready
    case skipped(String)
    case error(String)
}

// MARK: - Payloads

nonisolated struct ExportPayload {
    let rowValues: [String: XLSXCellValue]
}

nonisolated struct LedgerExportPayload {
    let rowValues: [String: XLSXCellValue]
}

nonisolated struct ImportPayload {
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

nonisolated struct LedgerImportPayload {
    let contactName: String
    let date: Date
    let note: String
    let relationshipWeight: RelationshipWeight
    let amount: Double
    let paymentMethod: PaymentMethod
}

nonisolated struct ContactPayload {
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
    case tooManyRows

    var errorDescription: String? {
        switch self {
        case .accessDenied: String(localized: "import.error.accessDenied")
        case .invalidFormat: String(localized: "import.error.invalidFormat")
        case .tooManyRows: String(localized: "import.error.tooManyRows")
        }
    }
}
