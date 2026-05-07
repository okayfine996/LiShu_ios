import Foundation
@testable import LiShu
import SwiftData
import Testing

@MainActor
struct ExportServiceTests {
    // MARK: - Parse Helpers

    @Test func testParseEventType() {
        #expect(ExportService.parseEventType("婚礼") == .wedding)
        #expect(ExportService.parseEventType("丧葬") == .funeral)
        #expect(ExportService.parseEventType("满月") == .birth)
        #expect(ExportService.parseEventType("生日") == .birthday)
        #expect(ExportService.parseEventType("节庆") == .festival)
        #expect(ExportService.parseEventType("乔迁") == .property)
        #expect(ExportService.parseEventType("升学") == .education)
        #expect(ExportService.parseEventType("其他") == .other)
        #expect(ExportService.parseEventType("未知类型") == .other)
    }

    @Test func testParseDirection() {
        #expect(ExportService.parseDirection("送出") == .given)
        #expect(ExportService.parseDirection("随礼") == .given)
        #expect(ExportService.parseDirection("given") == .given)
        #expect(ExportService.parseDirection("收到") == .received)
        #expect(ExportService.parseDirection("收礼") == .received)
        #expect(ExportService.parseDirection("received") == .received)
        #expect(ExportService.parseDirection("未知") == .given)
    }

    @Test func testParsePaymentMethod() {
        #expect(ExportService.parsePaymentMethod("现金") == .cash)
        #expect(ExportService.parsePaymentMethod("cash") == .cash)
        #expect(ExportService.parsePaymentMethod("微信") == .wechat)
        #expect(ExportService.parsePaymentMethod("wechat") == .wechat)
        #expect(ExportService.parsePaymentMethod("支付宝") == .alipay)
        #expect(ExportService.parsePaymentMethod("alipay") == .alipay)
        #expect(ExportService.parsePaymentMethod("实物") == .cash)
        #expect(ExportService.parsePaymentMethod("item") == .cash)
        #expect(ExportService.parsePaymentMethod("未知") == .cash)
    }

    @Test func testParseDate() {
        let date = ExportService.parseDate("2026-03-15")
        #expect(date != nil)

        let invalidDate = ExportService.parseDate("not-a-date")
        #expect(invalidDate == nil)

        let emptyDate = ExportService.parseDate("")
        #expect(emptyDate == nil)
    }

    @Test func normalizeImportedTextTrimsAndCollapsesWhitespace() {
        #expect(ExportService.normalizeImportedText("  张   三  ") == "张 三")
        #expect(ExportService.normalizeImportedText("\n婚礼\t\t宴请  ") == "婚礼 宴请")
        #expect(ExportService.normalizeImportedText("   \n\t ") == "")
    }

    // MARK: - Template Export

    @Test(arguments: [RecordType.monetary, .gift, .favor, .banquet])
    func templateXLSXCreatesValidFile(for recordType: RecordType) throws {
        let url = try ExportService.templateXLSX(for: recordType)
        let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
        let size = attrs[.size] as? Int ?? 0
        #expect(size > 0)
    }

    // MARK: - Type Export Preview

    @Test func previewExportMonetaryOnlyIncludesMonetaryRows() throws {
        let db = try TestDB()
        let contact = SampleData.contact(name: "李四")
        let event = SampleData.event(name: "生日宴", type: .birthday)
        db.context.insert(contact)
        db.context.insert(event)

        db.context.insert(SampleData.record(contact: contact, event: event, amount: 300, direction: .received))
        db.context.insert(SampleData.recordGift(contact: contact, event: event, giftName: "茶具", estimatedValue: 200))
        try db.context.save()

        let preview = try ExportService.previewExportXLSX(context: db.context, recordType: .monetary)

        #expect(preview.items.count == 1)
        let row = preview.items[0].payload?.rowValues
        #expect(row?["金额"] == .number(300.00))
        #expect(row?["联系人"] == .string("李四"))
    }

    @Test func previewExportGiftUsesEstimatedValueColumn() throws {
        let db = try TestDB()
        let contact = SampleData.contact(name: "礼品联系人")
        let event = SampleData.event(name: "乔迁", type: .property)
        db.context.insert(contact)
        db.context.insert(event)
        db.context.insert(SampleData.recordGift(contact: contact, event: event, giftName: "景德镇茶具", estimatedValue: 880))
        try db.context.save()

        let preview = try ExportService.previewExportXLSX(context: db.context, recordType: .gift)

        #expect(preview.items.count == 1)
        let row = preview.items[0].payload?.rowValues
        #expect(row?["礼品名称"] == .string("景德镇茶具"))
        #expect(row?["礼品估值"] == .number(880.00))
        #expect(row?["金额"] == nil)
    }

    @Test func previewExportSkipsRecordWithoutEventAndSceneTag() throws {
        let db = try TestDB()
        let contact = SampleData.contact(name: "无效联系人")
        db.context.insert(contact)

        let invalidRecord = SampleData.record(contact: contact, event: nil, amount: 200)
        db.context.insert(invalidRecord)
        try db.context.save()

        let preview = try ExportService.previewExportXLSX(context: db.context, recordType: .monetary)

        #expect(preview.items.count == 1)
        #expect(preview.items[0].isExportable == false)
        #expect(preview.skipped == 1)
    }

    @Test func previewExportMarksContextlessRowsAsSkipped() throws {
        let db = try TestDB()
        let validContact = SampleData.contact(name: "张三")
        let invalidContact = SampleData.contact(name: "李四")
        let event = SampleData.event(name: "婚礼", type: .wedding)
        db.context.insert(validContact)
        db.context.insert(invalidContact)
        db.context.insert(event)

        let validRecord = SampleData.record(contact: validContact, event: event, amount: 500, direction: .given)
        let invalidRecord = SampleData.record(contact: invalidContact, event: nil, amount: 300, direction: .given)
        db.context.insert(validRecord)
        db.context.insert(invalidRecord)
        try db.context.save()

        let preview = try ExportService.previewExportXLSX(context: db.context, recordType: .monetary)

        #expect(preview.items.count == 2)
        #expect(preview.skipped == 1)
        #expect(preview.items[0].isExportable == false)
        #expect(preview.items[0].statusMessage == String(localized: "csv.export.preview.invalid.missingContext"))
        #expect(preview.items[1].isExportable == true)
        #expect(preview.items[1].isSelected == true)
    }

    @Test func previewExportSelectionFiltersCorrectly() throws {
        let db = try TestDB()
        let contactA = SampleData.contact(name: "张三")
        let contactB = SampleData.contact(name: "李四")
        let event = SampleData.event(name: "婚礼", type: .wedding)
        db.context.insert(contactA)
        db.context.insert(contactB)
        db.context.insert(event)
        db.context.insert(SampleData.record(contact: contactA, event: event, amount: 500, direction: .given))
        db.context.insert(SampleData.record(contact: contactB, event: event, amount: 600, direction: .given))
        try db.context.save()

        var preview = try ExportService.previewExportXLSX(context: db.context, recordType: .monetary)
        // Deselect by contact name to avoid relying on non-deterministic createdAt ordering
        if let idx = preview.items.firstIndex(where: { $0.contactName == "张三" }) {
            preview.items[idx].isSelected = false
        }

        let selectedItems = preview.items.filter { $0.isSelected && $0.isExportable }
        #expect(selectedItems.count == 1)
        #expect(selectedItems[0].payload?.rowValues["联系人"] == .string("李四"))
        #expect(selectedItems[0].payload?.rowValues["金额"] == .number(600.00))
    }

    @Test func ledgerTemplateXLSXCreatesValidFile() throws {
        let url = try ExportService.ledgerTemplateXLSX()
        let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
        let size = attrs[.size] as? Int ?? 0
        #expect(size > 0)
    }

    @Test func ledgerExportOnlyIncludesReceivedMonetaryRowsForHostEvent() throws {
        let db = try TestDB()
        let hostEvent = SampleData.event(name: "我的婚礼", hostMode: .host)
        let contactA = SampleData.contact(name: "张三")
        let contactB = SampleData.contact(name: "李四")
        let contactC = SampleData.contact(name: "王五")
        db.context.insert(hostEvent)
        db.context.insert(contactA)
        db.context.insert(contactB)
        db.context.insert(contactC)

        db.context.insert(SampleData.record(contact: contactA, event: hostEvent, amount: 1200, direction: .received))
        db.context.insert(SampleData.record(contact: contactB, event: hostEvent, amount: 600, direction: .given))
        db.context.insert(
            SampleData.recordGift(
                contact: contactC,
                event: hostEvent,
                giftName: "茶具",
                estimatedValue: 880,
                direction: .received
            )
        )
        try db.context.save()

        let preview = try ExportService.previewLedgerExportXLSX(
            context: db.context,
            eventID: hostEvent.persistentModelID
        )

        #expect(preview.items.count == 1)
        #expect(preview.skipped == 0)
        let row = preview.items[0].payload?.rowValues
        #expect(row?["联系人"] == .string("张三"))
        #expect(row?["金额"] == .number(1200.00))
    }

    // MARK: - Contact XLSX Template

    @Test func contactXLSXTemplateCreatesValidFile() throws {
        let url = try ExportService.contactXLSXTemplate()
        let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
        let size = attrs[.size] as? Int ?? 0
        #expect(size > 0)
    }

    // MARK: - Contact XLSX Export

    @Test func exportContactXLSXCreatesNonEmptyFile() throws {
        let db = try TestDB()
        let contact = Contact(name: "张三", phone: "13800138000", location: "北京")
        db.context.insert(contact)
        try db.context.save()

        let url = try ExportService.exportContactXLSX(context: db.context)
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
        let size = attrs[.size] as? Int ?? 0
        #expect(size > 0)
    }

    // MARK: - Contact XLSX Preview

    @Test func previewContactXLSXParsesItems() throws {
        let db = try TestDB()
        db.context.insert(Contact(name: "张三", phone: "13800138000", location: "北京"))
        db.context.insert(Contact(name: "李四", phone: "13900139000", location: "上海"))
        try db.context.save()

        let url = try ExportService.exportContactXLSX(context: db.context)
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        let preview = try ExportService.previewContactXLSX(url: url)
        #expect(preview.items.count == 2)
        #expect(preview.items.allSatisfy(\.isImportable))
    }

    @Test func previewContactXLSXMissingNameHeaderReturnsNoImportable() throws {
        // Use ledger template as a file that has no 姓名 column
        let url = try ExportService.ledgerTemplateXLSX()
        defer { try? FileManager.default.removeItem(at: url) }

        let preview = try ExportService.previewContactXLSX(url: url)
        let importable = preview.items.filter(\.isImportable)
        #expect(importable.isEmpty)
    }

    @Test func previewContactXLSXTemplateHasTwoExampleRows() throws {
        let url = try ExportService.contactXLSXTemplate()
        defer { try? FileManager.default.removeItem(at: url) }

        let preview = try ExportService.previewContactXLSX(url: url)
        #expect(preview.items.count == 2)
    }

    // MARK: - Contact XLSX Import (via preview)

    @Test func importContactXLSXCreatesNewContacts() throws {
        let db = try TestDB()
        db.context.insert(Contact(name: "张三", phone: "13800138000", location: "北京", note: "好友"))
        db.context.insert(Contact(name: "李四", phone: "13900139000"))
        try db.context.save()

        let url = try ExportService.exportContactXLSX(context: db.context)
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        let importDB = try TestDB()
        let preview = try ExportService.previewContactXLSX(url: url)
        let result = try ExportService.importContactPreviewItems(preview.items, context: importDB.context)

        #expect(result.created == 2)
        #expect(result.updated == 0)
    }

    @Test func importContactXLSXWithAllColumns() throws {
        let db = try TestDB()
        let contact = Contact(
            name: "张三",
            phone: "13800138000",
            relation: "朋友",
            category: "社交",
            circle: 3,
            location: "北京",
            note: "老同学"
        )
        db.context.insert(contact)
        try db.context.save()

        let url = try ExportService.exportContactXLSX(context: db.context)
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        let importDB = try TestDB()
        let preview = try ExportService.previewContactXLSX(url: url)
        let result = try ExportService.importContactPreviewItems(preview.items, context: importDB.context)

        #expect(result.created == 1)
        let imported = try importDB.context.fetch(FetchDescriptor<Contact>())
        #expect(imported[0].relation == "朋友")
        #expect(imported[0].category == "社交")
        #expect(imported[0].circle == 3)
        #expect(imported[0].location == "北京")
        #expect(imported[0].note == "老同学")
    }

    @Test func importContactXLSXUpdatesExisting() throws {
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

    @Test func importContactXLSXSkipsUnselected() throws {
        let db = try TestDB()
        db.context.insert(Contact(name: "张三", phone: "13800138000"))
        db.context.insert(Contact(name: "李四", phone: "13900139000"))
        try db.context.save()

        let url = try ExportService.exportContactXLSX(context: db.context)
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        var preview = try ExportService.previewContactXLSX(url: url)
        preview.items[0].isSelected = false

        let importDB = try TestDB()
        let result = try ExportService.importContactPreviewItems(preview.items, context: importDB.context)

        #expect(result.created == 1)
        let contacts = try importDB.context.fetch(FetchDescriptor<Contact>())
        #expect(contacts.count == 1)
    }

    @Test func importContactXLSXInvalidCircleKeepsDefault() throws {
        let db = try TestDB()
        // circle=9 is out of range (1-4), export will store 9, preview should reject it
        // Contact init allows any Int, but import clamps to 1-4 range
        let contact = Contact(name: "张三")
        contact.circle = 9
        db.context.insert(contact)
        try db.context.save()

        let url = try ExportService.exportContactXLSX(context: db.context)
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        let preview = try ExportService.previewContactXLSX(url: url)
        // circle=9 will not be applied (out of range 1-4), so payload.circle is nil
        // Import will leave circle at Contact's default (4)
        let importDB = try TestDB()
        let result = try ExportService.importContactPreviewItems(preview.items, context: importDB.context)

        #expect(result.created == 1)
        let contacts = try importDB.context.fetch(FetchDescriptor<Contact>())
        #expect(contacts[0].circle == 4) // default, since 9 was rejected
    }

    // MARK: - ImportError

    @Test func importErrorTooManyRowsHasLocalizedDescription() {
        let error = ImportError.tooManyRows
        #expect(error.errorDescription != nil)
        #expect(!(error.errorDescription?.isEmpty ?? true))
    }

    @Test func maxImportRowsConstantIs5000() {
        #expect(ExportService.maxImportRows == 5000)
    }
}
