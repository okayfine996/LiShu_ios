import Foundation
import Pulse

enum DiagnosticsExportService {
    enum ExportFormat {
        case detailedText
        case jsonLines

        var fileExtension: String {
            switch self {
            case .detailedText:
                "log"
            case .jsonLines:
                "jsonl"
            }
        }
    }

    @MainActor
    static func exportDetailedLogs(store: LoggerStore = .shared) throws -> URL {
        let messages = try store.messages()
        let archiveName = archiveBaseName()
        let fileURL = plaintextFileURL(for: .detailedText, archiveName: archiveName)

        let content = messages.map(format(message:)).joined(separator: "\n\n")
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        return try DiagnosticsArchiveService.archiveFile(at: fileURL, archiveName: archiveName)
    }

    @MainActor
    static func exportDetailedJSONLines(store: LoggerStore = .shared) throws -> URL {
        let messages = try store.messages()
        let archiveName = archiveBaseName()
        let fileURL = plaintextFileURL(for: .jsonLines, archiveName: archiveName)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]

        let lines = try messages.map { message -> String in
            let payload = DetailedLogLine(
                timestamp: message.createdAt,
                level: levelString(for: message),
                label: formattedLabel(for: message.label),
                rawLabel: message.label,
                message: message.text,
                metadata: message.metadata
            )
            let data = try encoder.encode(payload)
            return String(decoding: data, as: UTF8.self)
        }

        try lines.joined(separator: "\n").write(to: fileURL, atomically: true, encoding: .utf8)
        return try DiagnosticsArchiveService.archiveFile(at: fileURL, archiveName: archiveName)
    }

    @MainActor
    private static func format(message: LoggerMessageEntity) -> String {
        var lines: [String] = [
            "\(timestampString(from: message.createdAt)) · \(levelString(for: message)) · \(formattedLabel(for: message.label))",
            "–––––––––––––––––––––––––––––––––––––––",
            message.text,
        ]

        let sortedMetadata = message.metadata
            .filter { !$0.value.isEmpty }
            .sorted { $0.key < $1.key }

        if !sortedMetadata.isEmpty {
            lines.append("")
            lines.append("Metadata")
            for (key, value) in sortedMetadata {
                if let prettyJSON = prettifiedJSON(from: value) {
                    lines.append("\(key):")
                    lines.append(prettyJSON)
                } else {
                    lines.append("\(key): \(value)")
                }
            }
        }

        return lines.joined(separator: "\n")
    }

    private static func prettifiedJSON(from value: String) -> String? {
        guard let data = value.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data),
              JSONSerialization.isValidJSONObject(object),
              let prettyData = try? JSONSerialization.data(
                  withJSONObject: object,
                  options: [.prettyPrinted, .sortedKeys]
              ),
              let string = String(data: prettyData, encoding: .utf8)
        else {
            return nil
        }
        return string
    }

    private static func levelString(for message: LoggerMessageEntity) -> String {
        switch LoggerStore.Level(rawValue: message.level) ?? .debug {
        case .trace:
            "TRACE"
        case .debug:
            "DEBUG"
        case .info:
            "INFO"
        case .notice:
            "NOTICE"
        case .warning:
            "WARNING"
        case .error:
            "ERROR"
        case .critical:
            "CRITICAL"
        @unknown default:
            "UNKNOWN"
        }
    }

    private static func formattedLabel(for label: String?) -> String {
        guard let label, !label.isEmpty else { return "Unknown" }
        return label
            .split(separator: ".")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: ".")
    }

    private static func timestampString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: date)
    }

    static func archiveBaseName(suffix: String = timestampSuffix()) -> String {
        "\(DiagnosticsExportConstants.archiveFilePrefix)_\(suffix)"
    }

    static func plaintextFileURL(for format: ExportFormat, archiveName: String) -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("\(archiveName).\(format.fileExtension)")
    }

    private static func timestampSuffix() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter.string(from: Date())
    }
}

private struct DetailedLogLine: Encodable {
    let timestamp: Date
    let level: String
    let label: String
    let rawLabel: String
    let message: String
    let metadata: [String: String]
}
