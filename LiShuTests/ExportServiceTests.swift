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
    func templateCSVContainsDateAndExample(for recordType: RecordType) {
        let csv = ExportService.templateCSV(for: recordType)
        let lines = csv.components(separatedBy: "\n")

        #expect(lines.count == 3)
        #expect(lines[0].contains("日期"))
        #expect(lines[0].contains("场景标签"))
        #expect(lines[1].contains("2026-04-09"))
        #expect(lines[2].contains("2026-04-09"))
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

    @Test func ledgerTemplateCSVUsesLedgerColumnsOnly() {
        let csv = ExportService.ledgerTemplateCSV()
        let lines = csv.components(separatedBy: "\n")

        #expect(lines.count == 3)
        #expect(lines[0] == "联系人,日期,备注,情分分量,金额,支付方式")
        #expect(!lines[0].contains("事件"))
        #expect(lines[1].contains("2026-04-09"))
        #expect(lines[2].contains("2026-04-09"))
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

        let preview = try ExportService.previewLedgerExportCSV(
            context: db.context,
            eventID: hostEvent.persistentModelID
        )
        let csv = try ExportService.exportLedgerPreviewItems(preview.items)
        let lines = csv.components(separatedBy: "\n")

        #expect(preview.items.count == 1)
        #expect(preview.skipped == 0)
        #expect(lines.count == 2)
        #expect(lines[0] == "联系人,日期,备注,情分分量,金额,支付方式")
        #expect(lines[1].contains("张三"))
        #expect(lines[1].contains("1200.00"))
        #expect(!lines[1].contains("李四"))
        #expect(!lines[1].contains("茶具"))
    }

    // MARK: - Contact CSV Export

    @Test func exportContactCSVHeader() throws {
        let db = try TestDB()
        let csv = try ExportService.exportContactCSV(context: db.context)
        let lines = csv.components(separatedBy: "\n")
        #expect(lines[0] == "姓名,手机号,关系标签,关系分类,亲密圈层,生日,所在地,备注")
    }

    @Test func exportContactCSVWithData() throws {
        let db = try TestDB()
        let contact = Contact(
            name: "张三",
            phone: "13800138000",
            relation: "朋友",
            category: "社交",
            circle: 3,
            birthday: {
                var comps = DateComponents()
                comps.year = 1990
                comps.month = 6
                comps.day = 15
                return Calendar.current.date(from: comps)! // swiftlint:disable:this force_unwrapping
            }(),
            location: "北京",
            note: "老同学"
        )
        db.context.insert(contact)
        try db.context.save()

        let csv = try ExportService.exportContactCSV(context: db.context)
        let lines = csv.components(separatedBy: "\n")
        #expect(lines.count == 2)
        #expect(lines[1].contains("张三"))
        #expect(lines[1].contains("13800138000"))
        #expect(lines[1].contains("朋友"))
        #expect(lines[1].contains("社交"))
        #expect(lines[1].contains("3"))
        #expect(lines[1].contains("1990-06-15"))
        #expect(lines[1].contains("北京"))
        #expect(lines[1].contains("老同学"))
    }

    @Test func exportContactCSVNoBirthday() throws {
        let db = try TestDB()
        let contact = Contact(name: "李四", phone: "13900139000")
        db.context.insert(contact)
        try db.context.save()

        let csv = try ExportService.exportContactCSV(context: db.context)
        let lines = csv.components(separatedBy: "\n")
        #expect(lines.count == 2)
        #expect(lines[1].contains("李四"))
        #expect(lines[1].contains("13900139000"))
    }

    @Test func exportContactCSVEscapesSpecialChars() throws {
        let db = try TestDB()
        let contact = Contact(name: "王五", note: "备注里有,逗号")
        db.context.insert(contact)
        try db.context.save()

        let csv = try ExportService.exportContactCSV(context: db.context)
        let lines = csv.components(separatedBy: "\n")
        #expect(lines[1].contains("\"备注里有,逗号\""))
    }

    // MARK: - Contact CSV Template

    @Test func contactCSVTemplateHasNoRelationColumns() {
        let csv = ExportService.contactCSVTemplate()
        let lines = csv.components(separatedBy: "\n")
        #expect(lines.count == 3)
        #expect(lines[0] == "姓名,手机号,生日,所在地,备注")
        #expect(!lines[0].contains("关系标签"))
        #expect(!lines[0].contains("关系分类"))
        #expect(!lines[0].contains("亲密圈层"))
    }

    @Test func contactCSVTemplateExampleRows() {
        let csv = ExportService.contactCSVTemplate()
        let lines = csv.components(separatedBy: "\n")
        #expect(lines[1].contains("张三"))
        #expect(lines[2].contains("李四"))
    }

    // MARK: - Contact CSV Preview

    @Test func previewContactCSVParsesItems() {
        let csv = "姓名,手机号,所在地\n张三,13800138000,北京\n李四,13900139000,上海"
        let preview = ExportService.previewContactCSV(content: csv, sourceFileName: "test.csv")

        #expect(preview.items.count == 2)
        #expect(preview.items[0].name == "张三")
        #expect(preview.items[0].isImportable)
        #expect(preview.items[0].isSelected)
        #expect(preview.items[0].detailText.contains("13800138000"))
        #expect(preview.items[0].detailText.contains("北京"))
        #expect(preview.items[1].name == "李四")
    }

    @Test func previewContactCSVEmptyNameMarkedError() {
        let csv = "姓名,手机号\n,13800138000\n张三,13900139000"
        let preview = ExportService.previewContactCSV(content: csv)

        #expect(preview.items.count == 2)
        #expect(!preview.items[0].isImportable)
        #expect(preview.items[0].statusMessage != nil)
        #expect(preview.items[1].isImportable)
    }

    @Test func previewContactCSVMissingNameHeader() {
        let csv = "手机号,所在地\n13800138000,北京"
        let preview = ExportService.previewContactCSV(content: csv)

        #expect(preview.items.isEmpty)
        #expect(preview.errors == 1)
    }

    @Test func previewContactCSVEmptyContent() {
        let csv = "姓名,手机号"
        let preview = ExportService.previewContactCSV(content: csv)

        #expect(preview.items.isEmpty)
    }

    // MARK: - Contact CSV Import (via preview)

    @Test func importContactCSVFromTemplate() throws {
        let db = try TestDB()
        let csv = "姓名,手机号,生日,所在地,备注\n张三,13800138000,1990-01-15,北京,好友\n李四,13900139000,,上海,"
        let preview = ExportService.previewContactCSV(content: csv)
        let result = try ExportService.importContactPreviewItems(preview.items, context: db.context)

        #expect(result.created == 2)
        #expect(result.updated == 0)

        let contacts = try db.context.fetch(FetchDescriptor<Contact>())
        #expect(contacts.count == 2)

        let zhangsan = contacts.first { $0.name == "张三" }
        #expect(zhangsan?.phone == "13800138000")
        #expect(zhangsan?.location == "北京")
        #expect(zhangsan?.note == "好友")
        #expect(zhangsan?.circle == 4)
        #expect(zhangsan?.relation == "")
        #expect(zhangsan?.category == "")
    }

    @Test func importContactCSVWithAllColumns() throws {
        let db = try TestDB()
        let csv = "姓名,手机号,关系标签,关系分类,亲密圈层,生日,所在地,备注\n张三,13800138000,朋友,社交,3,1990-01-15,北京,老同学"
        let preview = ExportService.previewContactCSV(content: csv)
        let result = try ExportService.importContactPreviewItems(preview.items, context: db.context)

        #expect(result.created == 1)

        let contacts = try db.context.fetch(FetchDescriptor<Contact>())
        let contact = contacts[0]
        #expect(contact.relation == "朋友")
        #expect(contact.category == "社交")
        #expect(contact.circle == 3)
        #expect(contact.location == "北京")
    }

    @Test func importContactCSVColumnsInDifferentOrder() throws {
        let db = try TestDB()
        let csv = "备注,姓名,所在地,手机号\n好友,张三,北京,13800138000"
        let preview = ExportService.previewContactCSV(content: csv)
        let result = try ExportService.importContactPreviewItems(preview.items, context: db.context)

        #expect(result.created == 1)

        let contacts = try db.context.fetch(FetchDescriptor<Contact>())
        let contact = contacts[0]
        #expect(contact.name == "张三")
        #expect(contact.phone == "13800138000")
        #expect(contact.location == "北京")
        #expect(contact.note == "好友")
    }

    @Test func importContactCSVUpdatesExisting() throws {
        let db = try TestDB()
        let existing = Contact(name: "张三", phone: "11111111111", location: "广州")
        db.context.insert(existing)
        try db.context.save()

        let csv = "姓名,手机号,所在地\n张三,13800138000,北京"
        let preview = ExportService.previewContactCSV(content: csv)
        let result = try ExportService.importContactPreviewItems(preview.items, context: db.context)

        #expect(result.created == 0)
        #expect(result.updated == 1)

        let contacts = try db.context.fetch(FetchDescriptor<Contact>())
        #expect(contacts.count == 1)
        #expect(contacts[0].phone == "13800138000")
        #expect(contacts[0].location == "北京")
    }

    @Test func importContactCSVSkipsUnselected() throws {
        let db = try TestDB()
        let csv = "姓名,手机号\n张三,13800138000\n李四,13900139000"
        var preview = ExportService.previewContactCSV(content: csv)
        preview.items[1].isSelected = false

        let result = try ExportService.importContactPreviewItems(preview.items, context: db.context)

        #expect(result.created == 1)
        let contacts = try db.context.fetch(FetchDescriptor<Contact>())
        #expect(contacts.count == 1)
        #expect(contacts[0].name == "张三")
    }

    @Test func importContactCSVInvalidCircleUsesDefault() throws {
        let db = try TestDB()
        let csv = "姓名,亲密圈层\n张三,9"
        let preview = ExportService.previewContactCSV(content: csv)
        let result = try ExportService.importContactPreviewItems(preview.items, context: db.context)

        #expect(result.created == 1)
        let contacts = try db.context.fetch(FetchDescriptor<Contact>())
        #expect(contacts[0].circle == 4)
    }

    @Test func importContactCSVRoundTrip() throws {
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

        let exported = try ExportService.exportContactCSV(context: db.context)

        let db2 = try TestDB()
        let preview = ExportService.previewContactCSV(content: exported)
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
}
