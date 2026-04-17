import Foundation
import Logging
import SwiftData

// MARK: - Contact CSV

extension ExportService {
    private nonisolated static let contactExportColumns = ["姓名", "手机号", "关系标签", "关系分类", "亲密圈层", "生日", "所在地", "备注"]
    private nonisolated static let contactTemplateColumns = ["姓名", "手机号", "生日", "所在地", "备注"]

    nonisolated static func exportContactCSV(context: ModelContext) throws -> String {
        exportLogger.notice("Starting contact CSV export", metadata: [
            "step": .string("export_contact_csv"),
        ])

        let descriptor = FetchDescriptor<Contact>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        let contacts = try context.fetch(descriptor)
        let header = contactExportColumns.joined(separator: ",")
        let rows = contacts.map { contact -> String in
            let birthdayStr = contact.birthday.map { csvDateFormatter.string(from: $0) } ?? ""
            return [
                escapeCSV(contact.name),
                escapeCSV(contact.phone),
                escapeCSV(contact.relation),
                escapeCSV(contact.category),
                "\(contact.circle)",
                birthdayStr,
                escapeCSV(contact.location),
                escapeCSV(contact.note),
            ].joined(separator: ",")
        }

        exportLogger.notice("Finished contact CSV export", metadata: [
            "step": .string("export_contact_csv"),
            "count": .stringConvertible(contacts.count),
        ])
        return ([header] + rows).joined(separator: "\n")
    }

    nonisolated static func contactCSVTemplate() -> String {
        let header = contactTemplateColumns.joined(separator: ",")
        let example1 = "张三,13800138000,1990-01-15,北京,同事兼好友"
        let example2 = "李四,13900139000,1995-06-20,上海,"
        return [header, example1, example2].joined(separator: "\n")
    }

    nonisolated static func previewContactCSV(content: String, sourceFileName: String = "") -> ContactCSVPreviewResult {
        importLogger.notice("Starting contact CSV preview", metadata: [
            "step": .string("preview_contact_csv"),
            "source": .string(sourceFileName),
        ])

        let lines = content.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard lines.count > 1 else {
            return ContactCSVPreviewResult(sourceFileName: sourceFileName, items: [])
        }

        let headerFields = parseCSVLine(lines[0]).map { normalizeImportedText($0) }
        let columnIndex: [String: Int] = Dictionary(uniqueKeysWithValues: headerFields.enumerated().map { ($1, $0) })

        guard let nameIdx = columnIndex["姓名"] else {
            return ContactCSVPreviewResult(sourceFileName: sourceFileName, items: [], errors: lines.count - 1)
        }

        var items: [ContactCSVPreviewItem] = []

        for (rowIndex, line) in lines.dropFirst().enumerated() {
            let fields = parseCSVLine(line)

            guard fields.count > nameIdx else {
                items.append(ContactCSVPreviewItem(
                    rowNumber: rowIndex + 2,
                    isSelected: false,
                    name: "",
                    detailText: "",
                    status: .error(String(localized: "contact.csv.preview.invalid.missingName"))
                ))
                continue
            }

            let trimmedName = normalizeImportedText(fields[nameIdx])
            guard !trimmedName.isEmpty else {
                items.append(ContactCSVPreviewItem(
                    rowNumber: rowIndex + 2,
                    isSelected: false,
                    name: "",
                    detailText: "",
                    status: .error(String(localized: "contact.csv.preview.invalid.missingName"))
                ))
                continue
            }

            var details: [String] = []
            if let idx = columnIndex["手机号"], fields.count > idx {
                let v = normalizeImportedText(fields[idx])
                if !v.isEmpty { details.append(v) }
            }
            if let idx = columnIndex["所在地"], fields.count > idx {
                let v = normalizeImportedText(fields[idx])
                if !v.isEmpty { details.append(v) }
            }
            if let idx = columnIndex["关系标签"], fields.count > idx {
                let v = normalizeImportedText(fields[idx])
                if !v.isEmpty { details.append(v) }
            }

            var payload = ContactCSVPayload(name: trimmedName)
            if let idx = columnIndex["手机号"], fields.count > idx {
                let v = normalizeImportedText(fields[idx])
                if !v.isEmpty { payload.phone = v }
            }
            if let idx = columnIndex["关系标签"], fields.count > idx {
                let v = normalizeImportedText(fields[idx])
                if !v.isEmpty { payload.relation = v }
            }
            if let idx = columnIndex["关系分类"], fields.count > idx {
                let v = normalizeImportedText(fields[idx])
                if !v.isEmpty { payload.category = v }
            }
            if let idx = columnIndex["亲密圈层"], fields.count > idx,
               let circle = Int(normalizeImportedText(fields[idx])), (1 ... 4).contains(circle)
            {
                payload.circle = circle
            }
            if let idx = columnIndex["生日"], fields.count > idx {
                let v = normalizeImportedText(fields[idx])
                if !v.isEmpty { payload.birthday = csvDateFormatter.date(from: v) }
            }
            if let idx = columnIndex["所在地"], fields.count > idx {
                let v = normalizeImportedText(fields[idx])
                if !v.isEmpty { payload.location = v }
            }
            if let idx = columnIndex["备注"], fields.count > idx {
                let v = normalizeImportedText(fields[idx])
                if !v.isEmpty { payload.note = v }
            }

            items.append(ContactCSVPreviewItem(
                rowNumber: rowIndex + 2,
                isSelected: true,
                name: trimmedName,
                detailText: details.joined(separator: " · "),
                status: .ready,
                payload: payload
            ))
        }

        importLogger.notice("Finished contact CSV preview", metadata: [
            "step": .string("preview_contact_csv"),
            "total": .stringConvertible(items.count),
            "ready": .stringConvertible(items.filter(\.isImportable).count),
        ])
        return ContactCSVPreviewResult(sourceFileName: sourceFileName, items: items)
    }

    nonisolated static func importContactPreviewItems(
        _ items: [ContactCSVPreviewItem],
        context: ModelContext
    ) throws -> ContactImportResult {
        importLogger.notice("Starting contact CSV import", metadata: [
            "step": .string("import_contact_csv"),
        ])

        var result = ContactImportResult(created: 0, updated: 0, failed: 0)

        for item in items {
            guard item.isSelected, item.isImportable, let payload = item.payload else { continue }

            let trimmedName = payload.name
            let predicate = #Predicate<Contact> { $0.name == trimmedName }
            var descriptor = FetchDescriptor<Contact>(predicate: predicate)
            descriptor.fetchLimit = 1
            let existing = try? context.fetch(descriptor).first

            let contact = existing ?? Contact(name: trimmedName)
            if existing == nil {
                context.insert(contact)
                result.created += 1
            } else {
                result.updated += 1
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
        importLogger.notice("Finished contact CSV import", metadata: [
            "step": .string("import_contact_csv"),
            "created": .stringConvertible(result.created),
            "updated": .stringConvertible(result.updated),
            "failed": .stringConvertible(result.failed),
        ])
        return result
    }

    nonisolated static func importContactPreviewItemsAsync(
        _ items: [ContactCSVPreviewItem],
        container: ModelContainer
    ) async throws -> ContactImportResult {
        try await Task.detached(priority: .userInitiated) {
            let context = ModelContext(container)
            return try importContactPreviewItems(items, context: context)
        }.value
    }
}
