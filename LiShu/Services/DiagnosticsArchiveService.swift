import Foundation
import ZipArchive

enum DiagnosticsExportConstants {
    static let archivePassword = "LiShuDiagnostics_2026"
    static let archiveFilePrefix = "lishu_diagnostics_detailed"
}

enum DiagnosticsArchiveService {
    enum ArchiveError: LocalizedError {
        case archiveCreationFailed

        var errorDescription: String? {
            switch self {
            case .archiveCreationFailed:
                "无法创建加密诊断压缩包。"
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

        let success = SSZipArchive.createZipFile(
            atPath: archiveURL.path,
            withFilesAtPaths: [sourceURL.path],
            withPassword: DiagnosticsExportConstants.archivePassword
        )

        guard success else {
            try? FileManager.default.removeItem(at: archiveURL)
            throw ArchiveError.archiveCreationFailed
        }

        return archiveURL
    }
}
