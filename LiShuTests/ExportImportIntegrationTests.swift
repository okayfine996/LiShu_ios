import Foundation
@testable import LiShu
import SwiftData
import Testing

@MainActor
struct ExportImportIntegrationTests {
    // MARK: - XLSX Round Trip

    @Test func monetaryExportImportRoundTrip() async throws {
        let db = try TestDB()
        let contact = SampleData.contact(name: "张三")
        let event = SampleData.event(name: "婚礼", type: .wedding)
        db.context.insert(contact)
        db.context.insert(event)
        db.context.insert(SampleData.record(
            contact: contact,
            event: event,
            amount: 888,
            direction: .given,
            returnedAmount: 100,
            date: Date(timeIntervalSince1970: 1_772_000_000), // 2026-02-23
            relationshipWeight: .reciprocal
        ))
        try db.context.save()

        // Export
        let previewExport = try ExportService.previewExportXLSX(context: db.context, recordType: .monetary)
        let url = try await ExportService.exportPreviewItemsToTemporaryFileAsync(
            previewExport.items,
            recordType: .monetary,
            fileName: "test_monetary_roundtrip.xlsx"
        )
        defer { try? FileManager.default.removeItem(at: url) }

        // Import
        let previewImport = try await ExportService.previewXLSXAsync(url: url)
        #expect(previewImport.items.count == 1)
        #expect(previewImport.items[0].isImportable)

        let importDB = try TestDB()
        let result = try await ExportService.importPreviewItemsAsync(
            previewImport.items,
            baseResult: ImportResult(),
            sourceFileName: "test",
            container: importDB.container
        )

        #expect(result.imported == 1)
        let importedRecords = try importDB.context.fetch(FetchDescriptor<Record>())
        #expect(importedRecords.count == 1)
        #expect(importedRecords[0].monetaryAmount == 888)
        #expect(importedRecords[0].resolvedReturnedAmount == 100)
        #expect(importedRecords[0].contact?.name == "张三")
        #expect(importedRecords[0].event?.name == "婚礼")
        #expect(importedRecords[0].relationshipWeight == .reciprocal)
    }

    @Test func giftExportImportRoundTrip() async throws {
        let db = try TestDB()
        let contact = SampleData.contact(name: "李四")
        let event = SampleData.event(name: "乔迁", type: .property)
        db.context.insert(contact)
        db.context.insert(event)
        db.context.insert(SampleData.recordGift(
            contact: contact,
            event: event,
            giftName: "景德镇茶具",
            estimatedValue: 880,
            direction: .given,
            date: Date(timeIntervalSince1970: 1_772_000_000)
        ))
        try db.context.save()

        let previewExport = try ExportService.previewExportXLSX(context: db.context, recordType: .gift)
        let url = try await ExportService.exportPreviewItemsToTemporaryFileAsync(
            previewExport.items,
            recordType: .gift,
            fileName: "test_gift_roundtrip.xlsx"
        )
        defer { try? FileManager.default.removeItem(at: url) }

        let previewImport = try await ExportService.previewXLSXAsync(url: url)
        let importDB = try TestDB()
        let result = try await ExportService.importPreviewItemsAsync(
            previewImport.items,
            baseResult: ImportResult(),
            container: importDB.container
        )

        #expect(result.imported == 1)
        let imported = try importDB.context.fetch(FetchDescriptor<Record>())
        #expect(imported[0].recordType == .gift)
        #expect(imported[0].giftData?.giftName == "景德镇茶具")
        #expect(imported[0].giftData?.estimatedValue == 880)
    }

    @Test func favorExportImportRoundTrip() async throws {
        let db = try TestDB()
        let contact = SampleData.contact(name: "王五")
        db.context.insert(contact)
        db.context.insert(SampleData.recordFavor(
            contact: contact,
            event: nil,
            description: "帮忙挂号预约",
            direction: .given
        ))
        // Daily records use contextTag
        let records = try db.context.fetch(FetchDescriptor<Record>())
        records[0].contextTag = "帮忙挂号"
        try db.context.save()

        let previewExport = try ExportService.previewExportXLSX(context: db.context, recordType: .favor)
        let url = try await ExportService.exportPreviewItemsToTemporaryFileAsync(
            previewExport.items,
            recordType: .favor,
            fileName: "test_favor_roundtrip.xlsx"
        )
        defer { try? FileManager.default.removeItem(at: url) }

        let previewImport = try await ExportService.previewXLSXAsync(url: url)
        let importDB = try TestDB()
        let result = try await ExportService.importPreviewItemsAsync(
            previewImport.items,
            baseResult: ImportResult(),
            container: importDB.container
        )

        #expect(result.imported == 1)
        let imported = try importDB.context.fetch(FetchDescriptor<Record>())
        #expect(imported[0].recordType == .favor)
        #expect(imported[0].favorData?.description == "帮忙挂号预约")
        #expect(imported[0].contextTag == "帮忙挂号")
    }

    @Test func banquetExportImportRoundTrip() async throws {
        let db = try TestDB()
        let contact = SampleData.contact(name: "赵六")
        db.context.insert(contact)
        db.context.insert(SampleData.recordBanquet(
            contact: contact,
            location: "兰亭包厢",
            attendeeList: "主客外还有两位同事陪同",
            extraCostNotes: "两瓶红酒"
        ))
        let records = try db.context.fetch(FetchDescriptor<Record>())
        records[0].contextTag = "接风洗尘"
        try db.context.save()

        let previewExport = try ExportService.previewExportXLSX(context: db.context, recordType: .banquet)
        let url = try await ExportService.exportPreviewItemsToTemporaryFileAsync(
            previewExport.items,
            recordType: .banquet,
            fileName: "test_banquet_roundtrip.xlsx"
        )
        defer { try? FileManager.default.removeItem(at: url) }

        let previewImport = try await ExportService.previewXLSXAsync(url: url)
        let importDB = try TestDB()
        let result = try await ExportService.importPreviewItemsAsync(
            previewImport.items,
            baseResult: ImportResult(),
            container: importDB.container
        )

        #expect(result.imported == 1)
        let imported = try importDB.context.fetch(FetchDescriptor<Record>())
        #expect(imported[0].recordType == .banquet)
        #expect(imported[0].banquetData?.location == "兰亭包厢")
        #expect(imported[0].banquetData?.attendeeList == "主客外还有两位同事陪同")
        #expect(imported[0].contextTag == "接风洗尘")
    }

    @Test func importDuplicateContactDedup() async throws {
        let db = try TestDB()
        let contact = SampleData.contact(name: "张三")
        let event = SampleData.event(name: "婚礼", type: .wedding)
        db.context.insert(contact)
        db.context.insert(event)
        db.context.insert(SampleData.record(contact: contact, event: event, amount: 500))
        db.context.insert(SampleData.record(contact: contact, event: event, amount: 300))
        try db.context.save()

        let previewExport = try ExportService.previewExportXLSX(context: db.context, recordType: .monetary)
        let url = try await ExportService.exportPreviewItemsToTemporaryFileAsync(
            previewExport.items,
            recordType: .monetary,
            fileName: "test_dedup.xlsx"
        )
        defer { try? FileManager.default.removeItem(at: url) }

        let previewImport = try await ExportService.previewXLSXAsync(url: url)
        let importDB = try TestDB()
        let result = try await ExportService.importPreviewItemsAsync(
            previewImport.items,
            baseResult: ImportResult(),
            container: importDB.container
        )

        #expect(result.imported == 2)
        let contacts = try importDB.context.fetch(FetchDescriptor<Contact>())
        #expect(contacts.count == 1)
        #expect(contacts[0].name == "张三")
    }

    @Test func importNormalizesWhitespace() async throws {
        let db = try TestDB()
        let contact = SampleData.contact(name: "  张   三  ")
        let event = SampleData.event(name: "  婚礼  ")
        db.context.insert(contact)
        db.context.insert(event)
        db.context.insert(SampleData.record(contact: contact, event: event, amount: 500))
        try db.context.save()

        let previewExport = try ExportService.previewExportXLSX(context: db.context, recordType: .monetary)
        let url = try await ExportService.exportPreviewItemsToTemporaryFileAsync(
            previewExport.items,
            recordType: .monetary,
            fileName: "test_whitespace.xlsx"
        )
        defer { try? FileManager.default.removeItem(at: url) }

        let previewImport = try await ExportService.previewXLSXAsync(url: url)
        let importDB = try TestDB()
        let result = try await ExportService.importPreviewItemsAsync(
            previewImport.items,
            baseResult: ImportResult(),
            container: importDB.container
        )

        #expect(result.imported == 1)
        let contacts = try importDB.context.fetch(FetchDescriptor<Contact>())
        #expect(contacts[0].name == "张 三")
        let events = try importDB.context.fetch(FetchDescriptor<Event>())
        #expect(events[0].name == "婚礼")
    }

    // MARK: - OCR Import

    @Test func oCRImportUsesCurrentLedgerEventAndReceivedDirection() throws {
        let db = try TestDB()
        let hostEvent = SampleData.event(name: "王家婚礼", hostMode: .host)
        db.context.insert(hostEvent)
        let viewModel = OCRImportViewModel(eventID: hostEvent.persistentModelID)
        viewModel.items = [
            OCRRecordItem(
                name: "张三",
                amount: 500,
                amountText: "500",
                confidence: .high
            ),
            OCRRecordItem(
                name: "李四",
                amount: 300,
                amountText: "300",
                confidence: .high
            ),
        ]

        let succeeded = viewModel.performImport(context: db.context)
        #expect(succeeded)

        let events = try db.context.fetch(FetchDescriptor<Event>())
        let records = try db.context.fetch(FetchDescriptor<Record>())

        #expect(events.count == 1)
        #expect(events[0].persistentModelID == hostEvent.persistentModelID)
        #expect(records.count == 2)
        #expect(records.allSatisfy { $0.event?.persistentModelID == hostEvent.persistentModelID })
        #expect(records.allSatisfy { $0.direction == .received })
    }

    // MARK: - Contact XLSX Import/Export

    @Test func contactXLSXRoundTrip() throws {
        let db = try TestDB()
        let contact = Contact(
            name: "赵六",
            phone: "13700137000",
            relation: "同事",
            category: "社交",
            circle: 2,
            location: "深圳",
            note: "项目搭档"
        )
        db.context.insert(contact)
        try db.context.save()

        let url = try ExportService.exportContactXLSX(context: db.context)
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        let db2 = try TestDB()
        let preview = try ExportService.previewContactXLSX(url: url)
        let result = try ExportService.importContactPreviewItems(preview.items, context: db2.context)

        #expect(result.created == 1)
        let imported = try db2.context.fetch(FetchDescriptor<Contact>())
        #expect(imported[0].name == "赵六")
        #expect(imported[0].phone == "13700137000")
        #expect(imported[0].relation == "同事")
        #expect(imported[0].category == "社交")
        #expect(imported[0].circle == 2)
        #expect(imported[0].location == "深圳")
        #expect(imported[0].note == "项目搭档")
    }

    @Test func contactXLSXImportUpdatesExisting() throws {
        let db = try TestDB()
        let existing = Contact(name: "张三", phone: "11111111111", location: "广州")
        db.context.insert(existing)
        try db.context.save()

        let exportDB = try TestDB()
        exportDB.context.insert(Contact(name: "张三", phone: "13800138000", location: "北京"))
        try exportDB.context.save()

        let url = try ExportService.exportContactXLSX(context: exportDB.context)
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        let preview = try ExportService.previewContactXLSX(url: url)
        let result = try ExportService.importContactPreviewItems(preview.items, context: db.context)

        #expect(result.created == 0)
        #expect(result.updated == 1)
        let contacts = try db.context.fetch(FetchDescriptor<Contact>())
        #expect(contacts.count == 1)
        #expect(contacts[0].phone == "13800138000")
        #expect(contacts[0].location == "北京")
    }

    @Test func eventNameWithPipeCharDoesNotCauseDuplication() async throws {
        // Validates EventCacheKey (struct) correctly deduplicates when event names contain '|'
        let db = try TestDB()
        let contact = SampleData.contact(name: "张三")
        let event = SampleData.event(name: "婚礼|喜宴", type: .wedding)
        db.context.insert(contact)
        db.context.insert(event)
        db.context.insert(SampleData.record(contact: contact, event: event, amount: 500))
        db.context.insert(SampleData.record(contact: contact, event: event, amount: 300))
        try db.context.save()

        let previewExport = try ExportService.previewExportXLSX(context: db.context, recordType: .monetary)
        let url = try await ExportService.exportPreviewItemsToTemporaryFileAsync(
            previewExport.items,
            recordType: .monetary,
            fileName: "test_pipe_char.xlsx"
        )
        defer { try? FileManager.default.removeItem(at: url) }

        let previewImport = try await ExportService.previewXLSXAsync(url: url)
        let importDB = try TestDB()
        let result = try await ExportService.importPreviewItemsAsync(
            previewImport.items,
            baseResult: ImportResult(),
            container: importDB.container
        )

        #expect(result.imported == 2)
        let events = try importDB.context.fetch(FetchDescriptor<Event>())
        #expect(events.count == 1) // both records share the same event, no duplication
        #expect(events[0].name == "婚礼|喜宴")
    }
}
