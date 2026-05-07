import Foundation
import ZIPFoundation

enum DiagnosticsExportConstants {
    static let archiveFilePrefix = "lishu_diagnostics_detailed"
}

enum DiagnosticsArchiveService {
    enum ArchiveError: LocalizedError {
        case archiveCreationFailed

        var errorDescription: String? {
            switch self {
            case .archiveCreationFailed:
                "无法创建诊断压缩包。"
            }
        }
    }

    static func archiveFile(at sourceURL: URL, archiveName: String) throws -> URL {
        let archiveURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(archiveName).zip")

        defer {
            try? FileManager.default.removeItem(at: sourceURL)
        }

        if FileManager.default.fileExists(atPath: archiveURL.path) {
            try? FileManager.default.removeItem(at: archiveURL)
        }

        let archive = try Archive(url: archiveURL, accessMode: .create)
        try archive.addEntry(
            with: sourceURL.lastPathComponent,
            fileURL: sourceURL,
            compressionMethod: .deflate
        )

        return archiveURL
    }
}
