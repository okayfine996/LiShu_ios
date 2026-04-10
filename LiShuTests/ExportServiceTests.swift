import Foundation
@testable import LiShu
import SwiftData
import Testing

@MainActor
struct ExportServiceTests {
    // MARK: - CSV Parsing

    @Test func parseCSVLineSimple() {
        let result = ExportService.parseCSVLine("张三,婚礼,wedding,500,送出,现金,0,未还,2026-03-01 12:00,备注")
        #expect(result.count == 10)
        #expect(result[0] == "张三")
        #expect(result[3] == "500")
        #expect(result[9] == "备注")
    }

    @Test func parseCSVLineWithQuotedComma() {
        let result = ExportService.parseCSVLine("\"张三,李四\",婚礼,wedding,500")
        #expect(result.count == 4)
        #expect(result[0] == "张三,李四")
    }

    @Test func parseCSVLineWithEscapedQuotes() {
        let result = ExportService.parseCSVLine("\"说了\"\"你好\"\"\",婚礼")
        #expect(result.count == 2)
        #expect(result[0] == "说了\"你好\"")
        #expect(result[1] == "婚礼")
    }

    // MARK: - Escape CSV

    @Test func escapeCSVPlainText() {
        #expect(ExportService.escapeCSV("张三") == "张三")
    }

    @Test func escapeCSVWithComma() {
        #expect(ExportService.escapeCSV("张三,李四") == "\"张三,李四\"")
    }

    @Test func escapeCSVWithQuotes() {
        #expect(ExportService.escapeCSV("说了\"你好\"") == "\"说了\"\"你好\"\"\"")
    }

    @Test func escapeCSVWithNewline() {
        #expect(ExportService.escapeCSV("第一行\n第二行") == "\"第一行\n第二行\"")
    }

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
        let date = ExportService.parseDate("2026-03-15 14:30")
        #expect(date != nil)

        let invalidDate = ExportService.parseDate("not-a-date")
        #expect(invalidDate == nil)

        let emptyDate = ExportService.parseDate("")
        #expect(emptyDate == nil)
    }

    // MARK: - Template Export

    @Test(arguments: [RecordType.monetary, .gift, .favor, .banquet])
    func templateCSVContainsDateAndExample(for recordType: RecordType) {
        let csv = ExportService.templateCSV(for: recordType)
        let lines = csv.components(separatedBy: "\n")

        #expect(lines.count == 3)
        #expect(lines[0].contains("日期"))
        #expect(lines[0].contains("场景标签"))
        #expect(lines[1].contains("2026-04-09 10:30"))
        #expect(lines[2].contains("2026-04-09 10:30"))
    }

    // MARK: - Type Export

    @Test func exportMonetaryCSVOnlyIncludesMonetaryColumns() throws {
        let db = try TestDB()
        let contact = SampleData.contact(name: "李四")
        let event = SampleData.event(name: "生日宴", type: .birthday)
        db.context.insert(contact)
        db.context.insert(event)

        db.context.insert(SampleData.record(contact: contact, event: event, amount: 300, direction: .received))
        db.context.insert(SampleData.recordGift(contact: contact, event: event, giftName: "茶具", estimatedValue: 200))
        try db.context.save()

        let csv = try ExportService.exportCSV(context: db.context, recordType: .monetary)
        let lines = csv.components(separatedBy: "\n")

        #expect(lines.count == 2)
        #expect(lines[0] == "联系人,事件,事件类型,场景标签,方向,日期,备注,情分分量,金额,支付方式,已退金额")
        #expect(lines[1].contains("300.00"))
        #expect(!lines[1].contains("茶具"))
    }

    @Test func exportGiftCSVUsesEstimatedValueInsteadOfAmountColumn() throws {
        let db = try TestDB()
        let contact = SampleData.contact(name: "礼品联系人")
        let event = SampleData.event(name: "乔迁", type: .property)
        db.context.insert(contact)
        db.context.insert(event)
        db.context.insert(SampleData.recordGift(contact: contact, event: event, giftName: "景德镇茶具", estimatedValue: 880))
        try db.context.save()

        let csv = try ExportService.exportCSV(context: db.context, recordType: .gift)
        let lines = csv.components(separatedBy: "\n")

        #expect(lines.count == 2)
        #expect(lines[0] == "联系人,事件,事件类型,场景标签,方向,日期,备注,情分分量,礼品名称,礼品估值,人情描述")
        #expect(lines[0].contains("礼品估值"))
        #expect(!lines[0].contains("金额"))
        #expect(lines[1].contains("景德镇茶具"))
        #expect(lines[1].contains("880.00"))
    }

    @Test func exportSkipsRecordWithoutEventAndSceneTag() throws {
        let db = try TestDB()
        let contact = SampleData.contact(name: "无效联系人")
        db.context.insert(contact)

        let invalidRecord = SampleData.record(contact: contact, event: nil, amount: 200)
        db.context.insert(invalidRecord)
        try db.context.save()

        let csv = try ExportService.exportCSV(context: db.context, recordType: .monetary)
        let lines = csv.components(separatedBy: "\n")

        #expect(lines.count == 1)
        #expect(lines[0] == "联系人,事件,事件类型,场景标签,方向,日期,备注,情分分量,金额,支付方式,已退金额")
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

        let preview = try ExportService.previewExportCSV(context: db.context, recordType: .monetary)

        #expect(preview.items.count == 2)
        #expect(preview.skipped == 1)
        #expect(preview.items[0].isExportable == false)
        #expect(preview.items[0].statusMessage == String(localized: "csv.export.preview.invalid.missingContext"))
        #expect(preview.items[1].isExportable == true)
        #expect(preview.items[1].isSelected == true)
    }

    @Test func exportPreviewItemsOnlyExportsSelectedRows() throws {
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

        var preview = try ExportService.previewExportCSV(context: db.context, recordType: .monetary)
        preview.items[1].isSelected = false

        let csv = try ExportService.exportPreviewItems(preview.items, recordType: .monetary)
        let lines = csv.components(separatedBy: "\n")

        #expect(lines.count == 2)
        #expect(lines[0] == "联系人,事件,事件类型,场景标签,方向,日期,备注,情分分量,金额,支付方式,已退金额")
        #expect(lines[1].contains("李四"))
        #expect(lines[1].contains("600.00"))
        #expect(!lines[1].contains("张三"))
    }
}
