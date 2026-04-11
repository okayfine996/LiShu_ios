import Foundation
@testable import LiShu
import SwiftData
import Testing

@MainActor
struct ExportImportIntegrationTests {
    @Test func previewCSVParsesRowsWithoutImporting() throws {
        let tempURL = try writeCSV(
            """
            联系人,事件,事件类型,场景标签,方向,日期,备注,情分分量,金额,支付方式,已退金额
            张三,婚礼,婚礼,,送出,2026-04-09,事件记录,礼尚往来,888.00,微信,0.00
            李四,,,节日看望,送出,2026-04-10 10:30,日常记录,点滴之恩,200.00,现金,0.00
            王五,,,,送出,2026-04-11 10:30,无上下文,礼尚往来,100.00,现金,0.00
            """,
            named: "test_preview_parse.csv"
        )
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let preview = try ExportService.previewCSV(url: tempURL)

        #expect(preview.items.count == 3)
        #expect(preview.skipped == 1)
        #expect(preview.errors == 0)
        #expect(preview.items[0].isImportable == true)
        #expect(preview.items[0].isSelected == true)
        #expect(preview.items[1].sceneTag == "节日看望")
        #expect(preview.items[1].isImportable == true)
        #expect(preview.items[2].isImportable == false)
        #expect(preview.items[2].statusMessage == String(localized: "csv.import.preview.invalid.missingContext"))
    }

    @Test func importPreviewItemsOnlyImportsSelectedRows() throws {
        let tempURL = try writeCSV(
            """
            联系人,事件,事件类型,场景标签,方向,日期,备注,情分分量,金额,支付方式,已退金额
            张三,婚礼,婚礼,,送出,2026-04-09,事件记录,礼尚往来,888.00,微信,0.00
            李四,,,节日看望,送出,2026-04-10 10:30,日常记录,点滴之恩,200.00,现金,0.00
            """,
            named: "test_preview_import_selected.csv"
        )
        defer { try? FileManager.default.removeItem(at: tempURL) }

        var preview = try ExportService.previewCSV(url: tempURL)
        preview.items[1].isSelected = false

        let db = try TestDB()
        let result = try ExportService.importPreviewItems(
            preview.items,
            baseResult: ImportResult(imported: 0, skipped: preview.skipped, errors: preview.errors),
            sourceFileName: preview.sourceFileName,
            context: db.context
        )

        #expect(result.imported == 1)
        #expect(result.skipped == 0)
        #expect(result.errors == 0)

        let importedRecords = try db.context.fetch(FetchDescriptor<Record>())
        #expect(importedRecords.count == 1)
        #expect(importedRecords[0].contact?.name == "张三")
    }

    @Test func monetaryExportImportRoundTrip() throws {
        let db = try TestDB()
        let contact = SampleData.contact(name: "张三")
        let event = SampleData.event(name: "婚礼", type: .wedding)
        db.context.insert(contact)
        db.context.insert(event)

        let record = Record(
            contact: contact,
            event: event,
            direction: .given,
            note: "新婚快乐",
            date: Date(timeIntervalSince1970: 1_772_000_000),
            recordType: .monetary,
            relationshipWeight: .support
        )
        record.applyTypeData(.monetary(MonetaryData(amount: 888, paymentMethod: PaymentMethod.wechat.rawValue, returnedAmount: 0)))
        db.context.insert(record)
        try db.context.save()

        let csv = try ExportService.exportCSV(context: db.context, recordType: .monetary)
        let tempURL = try writeCSV(csv, named: "test_roundtrip_monetary.csv")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let importDB = try TestDB()
        let result = try ExportService.importCSV(url: tempURL, context: importDB.context)

        #expect(result.imported == 1)
        #expect(result.errors == 0)

        let importedRecords = try importDB.context.fetch(FetchDescriptor<Record>())
        #expect(importedRecords.count == 1)
        #expect(importedRecords[0].recordType == .monetary)
        #expect(importedRecords[0].monetaryAmount == 888)
        #expect(importedRecords[0].contact?.name == "张三")
    }

    @Test func favorExportImportRoundTrip() throws {
        let db = try TestDB()
        let contact = SampleData.contact(name: "李四")
        let event = SampleData.event(name: "搬家帮忙", type: .other)
        db.context.insert(contact)
        db.context.insert(event)

        let record = Record(
            contact: contact,
            event: event,
            direction: .given,
            note: "",
            date: Date(timeIntervalSince1970: 1_772_000_000),
            recordType: .favor,
            relationshipWeight: .kindness
        )
        record.applyTypeData(.favor(FavorData(description: "帮忙搬家两天")))
        db.context.insert(record)
        try db.context.save()

        let csv = try ExportService.exportCSV(context: db.context, recordType: .favor)
        let tempURL = try writeCSV(csv, named: "test_roundtrip_favor.csv")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let importDB = try TestDB()
        let result = try ExportService.importCSV(url: tempURL, context: importDB.context)

        #expect(result.imported == 1)
        #expect(result.errors == 0)

        let importedRecords = try importDB.context.fetch(FetchDescriptor<Record>())
        #expect(importedRecords.count == 1)
        #expect(importedRecords[0].recordType == .favor)
        #expect(importedRecords[0].resolvedDescription == "帮忙搬家两天")
    }

    @Test func banquetExportImportRoundTrip() throws {
        let db = try TestDB()
        let contact = SampleData.contact(name: "王五")
        db.context.insert(contact)

        let record = Record(
            contact: contact,
            event: nil,
            direction: .given,
            note: "记得下次按同档次回请",
            date: Date(timeIntervalSince1970: 1_772_000_300),
            recordType: .banquet,
            relationshipWeight: .support
        )
        record.contextTag = "接风洗尘"
        record.applyTypeData(.banquet(BanquetData(
            location: "兰亭包厢，商务档次",
            attendeeList: "主客外还有两位同事陪同",
            extraCostNotes: "席间开了两瓶酒"
        )))
        db.context.insert(record)
        try db.context.save()

        let csv = try ExportService.exportCSV(context: db.context, recordType: .banquet)
        let tempURL = try writeCSV(csv, named: "test_roundtrip_banquet.csv")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let importDB = try TestDB()
        let result = try ExportService.importCSV(url: tempURL, context: importDB.context)

        #expect(result.imported == 1)
        #expect(result.errors == 0)

        let importedRecords = try importDB.context.fetch(FetchDescriptor<Record>())
        #expect(importedRecords.count == 1)
        #expect(importedRecords[0].recordType == .banquet)
        #expect(importedRecords[0].event == nil)
        #expect(importedRecords[0].contextTag == "接风洗尘")
        #expect(importedRecords[0].banquetData?.location == "兰亭包厢，商务档次")
        #expect(importedRecords[0].banquetData?.attendeeList == "主客外还有两位同事陪同")
        #expect(importedRecords[0].banquetData?.extraCostNotes == "席间开了两瓶酒")
    }

    @Test func giftExportImportRoundTripPreservesEstimatedValue() throws {
        let db = try TestDB()
        let contact = SampleData.contact(name: "礼品联系人")
        let event = SampleData.event(name: "乔迁", type: .property)
        db.context.insert(contact)
        db.context.insert(event)
        db.context.insert(SampleData.recordGift(
            contact: contact,
            event: event,
            giftName: "景德镇茶具",
            estimatedValue: 880,
            direction: .given,
            date: Date(timeIntervalSince1970: 1_772_000_500),
            relationshipWeight: .reciprocal
        ))
        try db.context.save()

        let csv = try ExportService.exportCSV(context: db.context, recordType: .gift)
        let tempURL = try writeCSV(csv, named: "test_roundtrip_gift.csv")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let importDB = try TestDB()
        let result = try ExportService.importCSV(url: tempURL, context: importDB.context)

        #expect(result.imported == 1)
        #expect(result.errors == 0)

        let importedRecords = try importDB.context.fetch(FetchDescriptor<Record>())
        #expect(importedRecords.count == 1)
        #expect(importedRecords[0].recordType == .gift)
        #expect(importedRecords[0].giftData?.giftName == "景德镇茶具")
        #expect(importedRecords[0].giftData?.estimatedValue == 880)
        #expect(importedRecords[0].monetaryAmount == 0)
    }

    @Test func giftEstimatedValueDoesNotTriggerMonetaryImport() throws {
        let tempURL = try writeCSV(
            """
            联系人,事件,事件类型,场景标签,方向,日期,备注,情分分量,礼品名称,礼品估值,人情描述
            张三,乔迁,乔迁,,送出,2026-04-09,礼品,礼尚往来,景德镇茶具,880.00,乔迁随礼品
            """,
            named: "test_gift_estimated_value.csv"
        )
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let db = try TestDB()
        let result = try ExportService.importCSV(url: tempURL, context: db.context)

        #expect(result.imported == 1)

        let importedRecords = try db.context.fetch(FetchDescriptor<Record>())
        #expect(importedRecords.count == 1)
        #expect(importedRecords[0].recordType == .gift)
        #expect(importedRecords[0].giftData?.estimatedValue == 880)
    }

    @Test func missingDateFallsBackToCurrentDate() throws {
        let tempURL = try writeCSV(
            """
            联系人,事件,事件类型,场景标签,方向,日期,备注,情分分量,金额,支付方式,已退金额
            张三,婚礼,婚礼,,送出,,缺少日期,礼尚往来,888.00,现金,0.00
            """,
            named: "test_missing_date.csv"
        )
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let before = Date()
        let db = try TestDB()
        let result = try ExportService.importCSV(url: tempURL, context: db.context)
        let after = Date()

        #expect(result.imported == 1)

        let importedRecords = try db.context.fetch(FetchDescriptor<Record>())
        #expect(importedRecords.count == 1)
        #expect(importedRecords[0].date >= before.addingTimeInterval(-1))
        #expect(importedRecords[0].date <= after.addingTimeInterval(1))
    }

    @Test func invalidDateIsRejectedDuringPreview() throws {
        let tempURL = try writeCSV(
            """
            联系人,事件,事件类型,场景标签,方向,日期,备注,情分分量,金额,支付方式,已退金额
            张三,婚礼,婚礼,,送出,not-a-date,非法日期,礼尚往来,888.00,现金,0.00
            """,
            named: "test_invalid_date.csv"
        )
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let preview = try ExportService.previewCSV(url: tempURL)

        #expect(preview.items.count == 1)
        #expect(preview.items[0].isImportable == false)
        #expect(preview.items[0].statusMessage == String(localized: "csv.import.preview.invalid.invalidDate"))
    }

    @Test func oldCSVWithoutSceneTagIsRejected() throws {
        let tempURL = try writeCSV(
            """
            联系人,事件,事件类型,方向,日期,备注,情分分量,金额,支付方式,已退金额
            张三,婚礼,婚礼,送出,2026-03-01 12:00,恭喜,礼尚往来,888,现金,0
            """,
            named: "test_old_csv_without_scene_tag.csv"
        )
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let db = try TestDB()

        #expect(throws: ImportError.invalidFormat) {
            try ExportService.importCSV(url: tempURL, context: db.context)
        }

        let importedRecords = try db.context.fetch(FetchDescriptor<Record>())
        #expect(importedRecords.isEmpty)
    }

    @Test func importDuplicateContactDedup() throws {
        let tempURL = try writeCSV(
            """
            联系人,事件,事件类型,场景标签,方向,日期,备注,情分分量,金额,支付方式,已退金额
            张三,婚礼,婚礼,,送出,2026-03-01 12:00,,礼尚往来,500.00,现金,0.00
            张三,生日宴,生日,,送出,2026-03-05 12:00,,点滴之恩,300.00,微信,0.00
            """,
            named: "test_dedup.csv"
        )
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let db = try TestDB()
        let result = try ExportService.importCSV(url: tempURL, context: db.context)

        #expect(result.imported == 2)

        let contacts = try db.context.fetch(FetchDescriptor<Contact>())
        #expect(contacts.count == 1)
        #expect(contacts[0].name == "张三")
    }

    @Test func importSceneTagRowCreatesDailyRecord() throws {
        let tempURL = try writeCSV(
            """
            联系人,事件,事件类型,场景标签,方向,日期,备注,情分分量,帮忙说明,人情描述
            张三,,,帮忙挂号,送出,2026-04-09,日常帮忙,礼尚往来,帮忙挂号预约,医院陪同
            """,
            named: "test_scene_tag_import.csv"
        )
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let db = try TestDB()
        let result = try ExportService.importCSV(url: tempURL, context: db.context)

        #expect(result.imported == 1)
        #expect(result.skipped == 0)

        let importedRecords = try db.context.fetch(FetchDescriptor<Record>())
        #expect(importedRecords.count == 1)
        #expect(importedRecords[0].event == nil)
        #expect(importedRecords[0].contextTag == "帮忙挂号")
    }

    @Test func importMissingContextRowIsSkipped() throws {
        let tempURL = try writeCSV(
            """
            联系人,事件,事件类型,场景标签,方向,日期,备注,情分分量,金额,支付方式,已退金额
            张三,,,,送出,2026-04-09,无上下文,礼尚往来,888.00,现金,0.00
            """,
            named: "test_missing_context.csv"
        )
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let db = try TestDB()
        let result = try ExportService.importCSV(url: tempURL, context: db.context)

        #expect(result.imported == 0)
        #expect(result.skipped == 1)
        #expect(result.errors == 0)

        let importedRecords = try db.context.fetch(FetchDescriptor<Record>())
        #expect(importedRecords.isEmpty)
    }

    @Test func eventWinsWhenEventAndSceneTagCoexist() throws {
        let tempURL = try writeCSV(
            """
            联系人,事件,事件类型,场景标签,方向,日期,备注,情分分量,金额,支付方式,已退金额
            张三,婚礼,婚礼,节日看望,送出,2026-04-09,事件优先,礼尚往来,888.00,现金,0.00
            """,
            named: "test_event_priority.csv"
        )
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let db = try TestDB()
        let result = try ExportService.importCSV(url: tempURL, context: db.context)

        #expect(result.imported == 1)

        let importedRecords = try db.context.fetch(FetchDescriptor<Record>())
        #expect(importedRecords.count == 1)
        #expect(importedRecords[0].event?.name == "婚礼")
        #expect(importedRecords[0].contextTag.isEmpty)
    }

    @Test func mixedTypeSpecificColumnsAreRejected() throws {
        let tempURL = try writeCSV(
            """
            联系人,事件,事件类型,场景标签,方向,日期,备注,情分分量,金额,支付方式,已退金额,礼品名称,礼品估值
            张三,婚礼,婚礼,,送出,2026-04-09,混合模板,礼尚往来,888.00,现金,0.00,茶具,300.00
            """,
            named: "test_mixed_type_headers.csv"
        )
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let db = try TestDB()

        #expect(throws: ImportError.invalidFormat) {
            try ExportService.importCSV(url: tempURL, context: db.context)
        }
    }

    @Test func relationshipWeightRoundTripPreservesValue() throws {
        let db = try TestDB()
        let contact = SampleData.contact(name: "张三")
        let event = SampleData.event(name: "婚礼", type: .wedding)
        db.context.insert(contact)
        db.context.insert(event)

        let record = SampleData.record(
            contact: contact,
            event: event,
            amount: 520,
            direction: .given,
            relationshipWeight: .support
        )
        db.context.insert(record)
        try db.context.save()

        let csv = try ExportService.exportCSV(context: db.context, recordType: .monetary)
        let tempURL = try writeCSV(csv, named: "test_relationship_weight_roundtrip.csv")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let importDB = try TestDB()
        let result = try ExportService.importCSV(url: tempURL, context: importDB.context)

        #expect(result.imported == 1)

        let importedRecords = try importDB.context.fetch(FetchDescriptor<Record>())
        #expect(importedRecords.count == 1)
        #expect(importedRecords[0].relationshipWeight == .support)
    }

    @Test func oCRImportPreservesEventTypeAndReusesEvent() throws {
        let db = try TestDB()
        let viewModel = OCRImportViewModel()
        viewModel.items = [
            OCRRecordItem(
                name: "张三",
                amount: 500,
                amountText: "500",
                confidence: .high,
                eventType: .wedding,
                eventName: "王家婚礼"
            ),
            OCRRecordItem(
                name: "李四",
                amount: 300,
                amountText: "300",
                confidence: .high,
                eventType: .wedding,
                eventName: "王家婚礼"
            ),
        ]

        let succeeded = viewModel.performImport(context: db.context)
        #expect(succeeded)

        let events = try db.context.fetch(FetchDescriptor<Event>())
        let records = try db.context.fetch(FetchDescriptor<Record>())

        #expect(events.count == 1)
        #expect(events[0].name == "王家婚礼")
        #expect(events[0].type == .wedding)
        #expect(records.count == 2)
        #expect(records.allSatisfy { $0.event?.name == "王家婚礼" })
        #expect(records.allSatisfy { $0.event?.type == .wedding })
    }

    private func writeCSV(_ content: String, named name: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        try content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
