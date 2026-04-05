import Foundation
import Testing
import SwiftData
@testable import LiShu

@MainActor
struct ExportServiceTests {

    // MARK: - CSV Parsing

    @Test func testParseCSVLineSimple() {
        let result = ExportService.parseCSVLine("张三,婚礼,wedding,500,送出,现金,0,未还,2026-03-01 12:00,备注")
        #expect(result.count == 10)
        #expect(result[0] == "张三")
        #expect(result[3] == "500")
        #expect(result[9] == "备注")
    }

    @Test func testParseCSVLineWithQuotedComma() {
        let result = ExportService.parseCSVLine("\"张三,李四\",婚礼,wedding,500")
        #expect(result.count == 4)
        #expect(result[0] == "张三,李四")
    }

    @Test func testParseCSVLineWithEscapedQuotes() {
        let result = ExportService.parseCSVLine("\"说了\"\"你好\"\"\",婚礼")
        #expect(result.count == 2)
        #expect(result[0] == "说了\"你好\"")
        #expect(result[1] == "婚礼")
    }

    // MARK: - Escape CSV

    @Test func testEscapeCSVPlainText() {
        #expect(ExportService.escapeCSV("张三") == "张三")
    }

    @Test func testEscapeCSVWithComma() {
        #expect(ExportService.escapeCSV("张三,李四") == "\"张三,李四\"")
    }

    @Test func testEscapeCSVWithQuotes() {
        #expect(ExportService.escapeCSV("说了\"你好\"") == "\"说了\"\"你好\"\"\"")
    }

    @Test func testEscapeCSVWithNewline() {
        #expect(ExportService.escapeCSV("第一行\n第二行") == "\"第一行\n第二行\"")
    }

    // MARK: - Parse Event Type

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

    // MARK: - Parse Direction

    @Test func testParseDirection() {
        #expect(ExportService.parseDirection("送出") == .given)
        #expect(ExportService.parseDirection("随礼") == .given)
        #expect(ExportService.parseDirection("given") == .given)
        #expect(ExportService.parseDirection("收到") == .received)
        #expect(ExportService.parseDirection("收礼") == .received)
        #expect(ExportService.parseDirection("received") == .received)
        #expect(ExportService.parseDirection("未知") == .given)
    }

    // MARK: - Parse Payment Method

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

    // MARK: - Parse Date

    @Test func testParseDate() {
        let date = ExportService.parseDate("2026-03-15 14:30")
        #expect(date != nil)

        let invalidDate = ExportService.parseDate("not-a-date")
        #expect(invalidDate == nil)

        let emptyDate = ExportService.parseDate("")
        #expect(emptyDate == nil)
    }

    @Test func testParseRelationshipWeight() {
        #expect(ExportService.parseRelationshipWeight("举手之劳") == .trivial)
        #expect(ExportService.parseRelationshipWeight("礼尚往来") == .reciprocal)
        #expect(ExportService.parseRelationshipWeight("profound") == .profound)
        #expect(ExportService.parseRelationshipWeight("未知") == .reciprocal)
    }

    @Test func testParseRecordTypeBanquet() {
        #expect(ExportService.parseRecordType("宴请") == .banquet)
        #expect(ExportService.parseRecordType("banquet") == .banquet)
    }

    // MARK: - CSV Export

    @Test func testExportCSV() throws {
        let db = try TestDB()
        let contact = SampleData.contact(name: "李四")
        let event = SampleData.event(name: "生日宴", type: .birthday)
        db.context.insert(contact)
        db.context.insert(event)

        let record = SampleData.record(contact: contact, event: event, amount: 300, direction: .received)
        db.context.insert(record)
        try db.context.save()

        let csv = try ExportService.exportCSV(context: db.context)
        let lines = csv.components(separatedBy: "\n")

        #expect(lines.count == 2)
        #expect(lines[0].contains("联系人"))
        #expect(lines[0].contains("情分分量"))
        #expect(lines[0].contains("礼品名称"))
        #expect(lines[0].contains("宴请额外费用"))
        #expect(!lines[0].contains("kvData"))
        #expect(lines[1].contains("李四"))
        #expect(lines[1].contains("300.00"))
    }
}
