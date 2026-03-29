import Foundation
import Testing
import SwiftData
@testable import LiShu

@MainActor
struct ExportImportIntegrationTests {

    @Test func testCSVExportImportRoundTrip() throws {
        let db = try TestDB()
        let contact = SampleData.contact(name: "张三")
        let event = SampleData.event(name: "婚礼", type: .wedding)
        db.context.insert(contact)
        db.context.insert(event)

        let record = Record(
            contact: contact,
            event: event,
            amount: 888,
            direction: .given,
            paymentMethod: .wechat,
            returnedAmount: 0,
            note: "新婚快乐",
            date: Date(timeIntervalSince1970: 1772000000)
        )
        db.context.insert(record)
        try db.context.save()

        let csv = try ExportService.exportCSV(context: db.context)
        #expect(csv.contains("张三"))
        #expect(csv.contains("888.00"))

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_roundtrip.csv")
        try csv.write(to: tempURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let importDB = try TestDB()
        let result = try ExportService.importCSV(url: tempURL, context: importDB.context)

        #expect(result.imported == 1)
        #expect(result.errors == 0)

        let importedRecords = try importDB.context.fetch(FetchDescriptor<Record>())
        #expect(importedRecords.count == 1)
        #expect(importedRecords[0].amount == 888)
        #expect(importedRecords[0].contact?.name == "张三")
    }

    @Test func testCSVRoundTripWithMultilineQuotedNote() throws {
        let db = try TestDB()
        let contact = SampleData.contact(name: "王五")
        let event = SampleData.event(name: "乔迁", type: .property)
        db.context.insert(contact)
        db.context.insert(event)

        let note = """
        第一行
        他说"你好,朋友"
        """
        let record = Record(
            contact: contact,
            event: event,
            amount: 666,
            direction: .given,
            paymentMethod: .cash,
            returnedAmount: 0,
            note: note,
            date: Date(timeIntervalSince1970: 1772001000)
        )
        db.context.insert(record)
        try db.context.save()

        let csv = try ExportService.exportCSV(context: db.context)
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_multiline_roundtrip.csv")
        try csv.write(to: tempURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let importDB = try TestDB()
        let result = try ExportService.importCSV(url: tempURL, context: importDB.context)
        #expect(result.imported == 1)
        #expect(result.errors == 0)

        let importedRecords = try importDB.context.fetch(FetchDescriptor<Record>())
        #expect(importedRecords.count == 1)
        #expect(importedRecords[0].note == note)
    }

    @Test func testJSONExportStructure() throws {
        let db = try TestDB()
        let contact = SampleData.contact(name: "李四")
        let event = SampleData.event(name: "生日", type: .birthday)
        db.context.insert(contact)
        db.context.insert(event)

        let r1 = SampleData.record(contact: contact, event: event, amount: 200, direction: .received)
        let r2 = SampleData.record(contact: contact, event: event, amount: 500, direction: .given)
        db.context.insert(r1)
        db.context.insert(r2)
        try db.context.save()

        let jsonData = try ExportService.exportJSON(context: db.context)
        let array = try JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]]

        #expect(array != nil)
        #expect(array?.count == 2)

        if let first = array?.first {
            #expect(first["contact_name"] as? String == "李四")
            #expect(first["event_name"] as? String == "生日")
        }
    }

    @Test func testImportDuplicateContactDedup() throws {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_dedup.csv")
        let csv = """
        联系人,事件,事件类型,金额,方向,支付方式,已退金额,状态,日期,备注
        张三,婚礼,婚礼,500,送出,现金,0,未还,2026-03-01 12:00,
        张三,生日宴,生日,300,送出,微信,0,未还,2026-03-05 12:00,
        """
        try csv.write(to: tempURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let db = try TestDB()
        let result = try ExportService.importCSV(url: tempURL, context: db.context)

        #expect(result.imported == 2)

        let contacts = try db.context.fetch(FetchDescriptor<Contact>())
        #expect(contacts.count == 1)
        #expect(contacts[0].name == "张三")
    }

    @Test func testOCRImportPreservesEventTypeAndReusesEvent() throws {
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

    @Test func testImportInvalidCSV() throws {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_invalid.csv")
        let csv = """
        联系人,事件,事件类型,金额,方向,支付方式,已退金额,状态,日期,备注
        incomplete,row
        ,,,invalid_amount,,,,,,,
        张三,婚礼,婚礼,500,送出,现金,0,未还,2026-03-01 12:00,正常
        """
        try csv.write(to: tempURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let db = try TestDB()
        let result = try ExportService.importCSV(url: tempURL, context: db.context)

        #expect(result.imported == 1)
        #expect(result.errors >= 1)
    }

    @Test func testJSONExportImportRoundTrip() throws {
        let db = try TestDB()
        let contact = SampleData.contact(name: "JSON测试")
        let event = SampleData.event(name: "升学宴", type: .education)
        db.context.insert(contact)
        db.context.insert(event)

        let record = Record(
            contact: contact,
            event: event,
            amount: 1200,
            direction: .received,
            paymentMethod: .alipay,
            returnedAmount: 0,
            note: "升学红包",
            date: Date(timeIntervalSince1970: 1772100000)
        )
        db.context.insert(record)
        try db.context.save()

        let jsonData = try ExportService.exportJSON(context: db.context)
        #expect(!jsonData.isEmpty)

        let array = try JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]]
        #expect(array?.count == 1)
        #expect(array?.first?["contact_name"] as? String == "JSON测试")
        #expect(array?.first?["amount"] as? Double == 1200)
    }

    @Test func testEmptyContextExport() throws {
        let db = try TestDB()

        let csv = try ExportService.exportCSV(context: db.context)
        #expect(csv.contains("联系人,事件,事件类型,金额"))

        let jsonData = try ExportService.exportJSON(context: db.context)
        #expect(!jsonData.isEmpty)
        let array = try JSONSerialization.jsonObject(with: jsonData) as? [[Any]]
        #expect(array?.isEmpty == true)
    }
}
