import CoreXLSX
import Foundation
import UniformTypeIdentifiers
import xlsxwriter

extension UTType {
    static let xlsx = UTType(filenameExtension: "xlsx")
        ?? UTType(importedAs: "org.openxmlformats.spreadsheetml.sheet")
}

// MARK: - XLSX Writer

/// Represents a value that can be written to an XLSX cell.
enum XLSXCellValue: Equatable {
    case string(String)
    case number(Double)
    case empty
}

/// Writes data rows to an .xlsx file in the temp directory.
nonisolated enum XLSXWriter {
    /// Creates an .xlsx file at a temp URL with the given headers and rows.
    /// - Parameters:
    ///   - fileName: Output file name (e.g. "export.xlsx")
    ///   - headers: Ordered column headers (row 0)
    ///   - rows: Data rows as column-name → cell-value dicts
    /// - Returns: URL of the written .xlsx file in the temp directory
    static func write(
        fileName: String,
        headers: [String],
        rows: [[String: XLSXCellValue]]
    ) throws -> URL {
        // Each call writes into its own UUID subdirectory so concurrent downloads
        // (e.g. two template requests) never overwrite each other's temp file.
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let tempURL = dir.appendingPathComponent(fileName)
        let workbook = Workbook(name: tempURL.path)
        let worksheet = workbook.addWorksheet()

        // Write header row
        worksheet.write(row: headers.map { Value.string($0) }, [0, 0])

        // Write data rows
        for (rowIdx, rowDict) in rows.enumerated() {
            let row = rowIdx + 1
            for (colIdx, header) in headers.enumerated() {
                let value = rowDict[header] ?? .empty
                let cell: xlsxwriter.Cell = [row, colIdx]
                switch value {
                case let .string(str):
                    worksheet.write(.string(str), cell)
                case let .number(num):
                    worksheet.write(.number(num), cell)
                case .empty:
                    worksheet.write(.string(""), cell)
                }
            }
        }

        workbook.close()
        return tempURL
    }
}

// MARK: - XLSX Reader

/// Reads an .xlsx file and returns its contents as a 2D string array.
nonisolated enum XLSXReader {
    /// Reads the first worksheet of an .xlsx file.
    /// - Parameter url: Security-scoped URL from a file importer
    /// - Returns: `[[String]]` where index 0 is the header row; empty cells are ""
    /// - Throws: `ImportError.invalidFormat` if file cannot be parsed
    static func read(url: URL) throws -> [[String]] {
        let didStart = url.startAccessingSecurityScopedResource()
        defer { if didStart { url.stopAccessingSecurityScopedResource() } }

        // Copy to a temp location so CoreXLSX can access freely
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".xlsx")
        try FileManager.default.copyItem(at: url, to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        guard let file = XLSXFile(filepath: tempURL.path) else {
            throw ImportError.invalidFormat
        }

        let sharedStrings = try file.parseSharedStrings()
        let worksheetPaths = try file.parseWorksheetPaths()
        guard let firstPath = worksheetPaths.first else {
            throw ImportError.invalidFormat
        }

        let worksheet = try file.parseWorksheet(at: firstPath)
        var result: [[String]] = []

        for row in worksheet.data?.rows ?? [] {
            var rowValues: [String] = []
            var lastCol = -1

            for cell in row.cells {
                let colIdx = columnIndex(from: cell.reference.column.value)
                // Fill sparse gaps with empty strings
                while lastCol < colIdx - 1 {
                    rowValues.append("")
                    lastCol += 1
                }
                let cellValue: String = if let ss = sharedStrings {
                    cell.stringValue(ss) ?? ""
                } else {
                    cell.value ?? ""
                }
                rowValues.append(cellValue)
                lastCol = colIdx
            }

            result.append(rowValues)
        }

        return result
    }

    /// Converts a column letter (e.g. "A", "B", "AA") to a 0-based index.
    private static func columnIndex(from column: String) -> Int {
        var result = 0
        for char in column.uppercased() {
            guard let ascii = char.asciiValue else { continue }
            result = result * 26 + Int(ascii - 65) + 1
        }
        return result - 1
    }
}
