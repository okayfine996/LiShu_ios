import Foundation
import Logging
import SwiftData

// MARK: - Contact XLSX

extension ExportService {
    private nonisolated static let contactExportColumns = ["姓名", "手机号", "关系标签", "关系分类", "亲密圈层", "生日", "所在地", "备注"]
    private nonisolated static let contactTemplateColumns = ["姓名", "手机号", "生日", "所在地", "备注"]

    // MARK: Export

    nonisolated static func exportContactXLSXAsync(container: ModelContainer) async throws -> URL {
        try await Task.detached(priority: .userInitiated) {
            let context = ModelContext(container)
            return try exportContactXLSX(context: context)
        }.value
    }

    nonisolated static func exportContactXLSX(context: ModelContext) throws -> URL {
        exportLogger.notice("Starting contact XLSX export", metadata: [
            "step": .string("export_contact_xlsx"),
        ])
        let descriptor = FetchDescriptor<Contact>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        let contacts = try context.fetch(descriptor)
        let rows: [[String: XLSXCellValue]] = contacts.map { contact in
            [
                "姓名": .string(contact.name),
                "手机号": .string(contact.phone),
                "关系标签": .string(contact.relation),
                "关系分类": .string(contact.category),
                "亲密圈层": .number(Double(contact.circle)),
                "生日": .string(contact.birthday.map { dateFormatter.string(from: $0) } ?? ""),
                "所在地": .string(contact.location),
                "备注": .string(contact.note),
            ]
        }
        let fileName = "contacts_\(dateFormatter.string(from: Date())).xlsx"
        let url = try XLSXWriter.write(fileName: fileName, headers: contactExportColumns, rows: rows)
        exportLogger.notice("Finished contact XLSX export", metadata: [
            "step": .string("export_contact_xlsx"),
            "count": .stringConvertible(contacts.count),
        ])
        return url
    }

    // MARK: Template

    nonisolated static func contactXLSXTemplate() throws -> URL {
        let rows: [[String: XLSXCellValue]] = [
            ["姓名": .string("张三"), "手机号": .string("13800138000"), "生日": .string("1990-01-15"), "所在地": .string("北京"), "备注": .string("同事兼好友")],
            ["姓名": .string("李四"), "手机号": .string("13900139000"), "生日": .string("1995-06-20"), "所在地": .string("上海"), "备注": .string("")],
        ]
        return try XLSXWriter.write(
            fileName: "contacts_template.xlsx",
            headers: contactTemplateColumns,
            rows: rows
        )
    }

    // MARK: Import Preview

    nonisolated static func previewContactXLSXAsync(url: URL) async throws -> ContactPreviewResult {
        try await Task.detached(priority: .userInitiated) {
            try previewContactXLSX(url: url)
        }.value
    }

    nonisolated static func previewContactXLSX(url: URL) throws -> ContactPreviewResult {
        let sourceFileName = url.lastPathComponent
        importLogger.notice("Starting contact XLSX preview", metadata: [
            "step": .string("preview_contact_xlsx"),
            "source": .string(sourceFileName),
        ])

        let rows = try XLSXReader.read(url: url)
        guard rows.count > 1 else {
            return ContactPreviewResult(sourceFileName: sourceFileName, items: [])
        }

        guard rows.count - 1 <= maxImportRows else {
            throw ImportError.tooManyRows
        }

        let headerFields = rows[0].map { normalizeImportedText($0) }
        // Use manual loop so duplicate column names take the first occurrence (no crash)
        var columnIndex: [String: Int] = [:]
        for (i, key) in headerFields.enumerated() where !key.isEmpty {
            if columnIndex[key] == nil { columnIndex[key] = i }
        }

        guard columnIndex["姓名"] != nil else {
            return ContactPreviewResult(sourceFileName: sourceFileName, items: [], errors: rows.count - 1)
        }

        func field(row: [String], column: String) -> String {
            guard let idx = columnIndex[column], row.count > idx else { return "" }
            return normalizeImportedText(row[idx])
        }

        var items: [ContactPreviewItem] = []

        for (rowIndex, row) in rows.dropFirst().enumerated() {
            let name = field(row: row, column: "姓名")
            guard !name.isEmpty else {
                items.append(ContactPreviewItem(
                    rowNumber: rowIndex + 2,
                    isSelected: false,
                    name: "",
                    detailText: "",
                    status: .error(String(localized: "contact.csv.preview.invalid.missingName"))
                ))
                continue
            }

            let phone = field(row: row, column: "手机号")
            let location = field(row: row, column: "所在地")
            let relation = field(row: row, column: "关系标签")
            let details = [phone, location, relation].filter { !$0.isEmpty }.joined(separator: " · ")

            var payload = ContactPayload(name: name)
            if !phone.isEmpty { payload.phone = phone }
            if !relation.isEmpty { payload.relation = relation }
            let category = field(row: row, column: "关系分类")
            if !category.isEmpty { payload.category = category }
            let circleStr = field(row: row, column: "亲密圈层")
            if let circle = Int(circleStr), (1...4).contains(circle) { payload.circle = circle }
            let birthdayStr = field(row: row, column: "生日")
            if !birthdayStr.isEmpty { payload.birthday = dateFormatter.date(from: birthdayStr) }
            if !location.isEmpty { payload.location = location }
            let note = field(row: row, column: "备注")
            if !note.isEmpty { payload.note = note }

            items.append(ContactPreviewItem(
                rowNumber: rowIndex + 2,
                isSelected: true,
                name: name,
                detailText: details,
                status: .ready,
                payload: payload
            ))
        }

        importLogger.notice("Finished contact XLSX preview", metadata: [
            "step": .string("preview_contact_xlsx"),
            "total": .stringConvertible(items.count),
            "ready": .stringConvertible(items.filter(\.isImportable).count),
        ])
        return ContactPreviewResult(sourceFileName: sourceFileName, items: items)
    }

    // MARK: Import

    nonisolated static func importContactPreviewItems(
        _ items: [ContactPreviewItem],
        context: ModelContext
    ) throws -> ContactImportResult {
        importLogger.notice("Starting contact XLSX import", metadata: [
            "step": .string("import_contact_xlsx"),
        ])

        var result = ContactImportResult(created: 0, updated: 0, failed: 0)

        for item in items {
            guard item.isSelected, item.isImportable, let payload = item.payload else { continue }

            let trimmedName = payload.name
            let predicate = #Predicate<Contact> { $0.name == trimmedName }
            var descriptor = FetchDescriptor<Contact>(predicate: predicate)
            descriptor.fetchLimit = 1
            let existing = try context.fetch(descriptor).first

            let contact: Contact
            if let existing {
                contact = existing
                result.updated += 1
            } else {
                contact = Contact(name: trimmedName)
                context.insert(contact)
                result.created += 1
            }

            if let v = payload.phone, !v.isEmpty { contact.phone = v }
            if let v = payload.relation, !v.isEmpty { contact.relation = v }
            if let v = payload.category, !v.isEmpty { contact.category = v }
            if let circle = payload.circle { contact.circle = circle }
            if let birthday = payload.birthday { contact.birthday = birthday }
            if let v = payload.location, !v.isEmpty { contact.location = v }
            if let v = payload.note, !v.isEmpty { contact.note = v }
        }

        try context.save()
        importLogger.notice("Finished contact XLSX import", metadata: [
            "step": .string("import_contact_xlsx"),
            "created": .stringConvertible(result.created),
            "updated": .stringConvertible(result.updated),
            "failed": .stringConvertible(result.failed),
        ])
        return result
    }

    nonisolated static func importContactPreviewItemsAsync(
        _ items: [ContactPreviewItem],
        container: ModelContainer
    ) async throws -> ContactImportResult {
        try await Task.detached(priority: .userInitiated) {
            let context = ModelContext(container)
            return try importContactPreviewItems(items, context: context)
        }.value
    }
}
