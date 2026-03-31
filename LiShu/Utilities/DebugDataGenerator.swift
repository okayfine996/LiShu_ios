#if DEBUG
import Foundation
import SwiftData

@MainActor
enum DebugDataGenerator {

    // MARK: - Public

    static func generateSampleData(context: ModelContext) {
        let contacts = createContacts()
        for contact in contacts {
            context.insert(contact)
        }

        let events = createEvents()
        for event in events {
            context.insert(event)
        }

        let records = createRecords(contacts: contacts, events: events)
        for record in records {
            context.insert(record)
        }

        try? context.save()
    }

    static func clearAllData(context: ModelContext) {
        do {
            try context.delete(model: Record.self)
            try context.delete(model: RecordPhoto.self)
            try context.delete(model: Event.self)
            try context.delete(model: Contact.self)
            try context.save()
        } catch {
            print("[DebugDataGenerator] clearAllData failed: \(error)")
        }
    }

    // MARK: - Contacts

    private static func createContacts() -> [Contact] {
        let calendar = Calendar.current

        return [
            Contact(
                name: "张伟",
                phone: "13800138001",
                relation: "配偶",
                category: RelationshipCategory.family.rawValue,
                circle: 1,
                birthday: calendar.date(from: DateComponents(year: 1990, month: 5, day: 12)),
                location: "北京"
            ),
            Contact(
                name: "李娜",
                phone: "13900139002",
                relation: "母亲",
                category: RelationshipCategory.family.rawValue,
                circle: 1,
                birthday: calendar.date(from: DateComponents(year: 1965, month: 8, day: 3)),
                location: "上海"
            ),
            Contact(
                name: "王强",
                phone: "13700137003",
                relation: "父亲",
                category: RelationshipCategory.family.rawValue,
                circle: 1,
                birthday: calendar.date(from: DateComponents(year: 1963, month: 11, day: 20)),
                location: "上海"
            ),
            Contact(
                name: "刘芳",
                phone: "13600136004",
                relation: "姐妹",
                category: RelationshipCategory.family.rawValue,
                circle: 1,
                location: "广州"
            ),
            Contact(
                name: "陈明",
                phone: "13500135005",
                relation: "舅舅",
                category: RelationshipCategory.relative.rawValue,
                circle: 2,
                location: "深圳"
            ),
            Contact(
                name: "赵丽",
                phone: "13400134006",
                relation: "姑姑",
                category: RelationshipCategory.relative.rawValue,
                circle: 2,
                birthday: calendar.date(from: DateComponents(year: 1970, month: 3, day: 15)),
                location: "杭州"
            ),
            Contact(
                name: "杨磊",
                relation: "表兄弟",
                category: RelationshipCategory.relative.rawValue,
                circle: 2,
                location: "成都"
            ),
            Contact(
                name: "周婷",
                phone: "13200132008",
                relation: "堂姐妹",
                category: RelationshipCategory.relative.rawValue,
                circle: 2,
                location: "武汉"
            ),
            Contact(
                name: "吴刚",
                phone: "13100131009",
                relation: "同事",
                category: RelationshipCategory.social.rawValue,
                circle: 3,
                location: "北京"
            ),
            Contact(
                name: "孙敏",
                relation: "同学",
                category: RelationshipCategory.social.rawValue,
                circle: 3,
                location: "南京"
            ),
            Contact(
                name: "黄杰",
                phone: "15000150011",
                relation: "朋友",
                category: RelationshipCategory.social.rawValue,
                circle: 3,
                location: "重庆",
                note: "大学室友"
            ),
            Contact(
                name: "马红",
                relation: "邻居",
                category: RelationshipCategory.social.rawValue,
                circle: 3,
                location: "北京"
            ),
        ]
    }

    // MARK: - Events

    private static func createEvents() -> [Event] {
        let now = Date.now
        let calendar = Calendar.current

        func date(byAddingMonths months: Int, day: Int = 15) -> Date {
            var comps = calendar.dateComponents([.year, .month], from: now)
            comps.month = (comps.month ?? 1) + months
            comps.day = day
            return calendar.date(from: comps) ?? now
        }

        return [
            Event(name: "张伟的婚礼", type: .wedding, date: date(byAddingMonths: -10, day: 8), location: "北京国贸大酒店"),
            Event(name: "李娜六十大寿", type: .birthday, date: date(byAddingMonths: -6, day: 3), location: "上海外滩花园"),
            Event(name: "王强乔迁新居", type: .property, date: date(byAddingMonths: -4, day: 20), location: "上海浦东"),
            Event(name: "刘芳宝宝满月", type: .birth, date: date(byAddingMonths: -2, day: 12), location: "广州天河"),
            Event(name: "陈明之父丧事", type: .funeral, date: date(byAddingMonths: -8, day: 5), location: "深圳南山殡仪馆"),
            Event(name: "春节聚会", type: .festival, date: date(byAddingMonths: -1, day: 28), location: "老家"),
            Event(name: "黄杰孩子升学宴", type: .education, date: date(byAddingMonths: 1, day: 10), location: "重庆解放碑"),
            Event(name: "赵丽的婚礼", type: .wedding, date: date(byAddingMonths: 1, day: 25), location: "杭州西湖国宾馆"),
            Event(name: "吴刚生日聚餐", type: .birthday, date: date(byAddingMonths: 2, day: 6), location: "北京三里屯"),
        ]
    }

    // MARK: - Records

    private static func makeRecord(
        contact: Contact,
        event: Event? = nil,
        direction: RecordDirection = .given,
        returnedAmount: Double = 0,
        note: String = "",
        date: Date,
        recordType: RecordType,
        relationshipWeight: RelationshipWeight = .reciprocal,
        typeData: RecordTypeData
    ) -> Record {
        let record = Record(
            contact: contact,
            event: event,
            direction: direction,
            returnedAmount: returnedAmount,
            note: note,
            date: date,
            recordType: recordType,
            relationshipWeight: relationshipWeight
        )
        record.applyTypeData(typeData)
        record.updateStatus()
        return record
    }

    private static func createRecords(contacts: [Contact], events: [Event]) -> [Record] {
        guard contacts.count >= 12, events.count >= 9 else { return [] }

        let c = contacts
        let e = events

        return [
            // 张伟婚礼 — 多人送礼
            Record(contact: c[4], event: e[0], amount: 2000, direction: .received, paymentMethod: .wechat, date: e[0].date),
            Record(contact: c[5], event: e[0], amount: 1000, direction: .received, paymentMethod: .cash, date: e[0].date),
            Record(contact: c[8], event: e[0], amount: 600, direction: .received, paymentMethod: .alipay, date: e[0].date),
            Record(contact: c[9], event: e[0], amount: 500, direction: .received, paymentMethod: .wechat, date: e[0].date),
            Record(contact: c[10], event: e[0], amount: 800, direction: .received, paymentMethod: .cash, date: e[0].date),
            Record(contact: c[11], event: e[0], amount: 200, direction: .received, paymentMethod: .cash, note: "送了一套餐具", date: e[0].date),

            // 李娜六十大寿 — 送礼
            Record(contact: c[1], event: e[1], amount: 5000, direction: .given, paymentMethod: .cash, date: e[1].date),
            Record(contact: c[5], event: e[1], amount: 1000, direction: .given, paymentMethod: .wechat, date: e[1].date),

            // 王强乔迁新居 — 送礼
            Record(contact: c[2], event: e[2], amount: 2000, direction: .given, paymentMethod: .alipay, date: e[2].date),

            // 刘芳宝宝满月 — 送礼
            Record(contact: c[3], event: e[3], amount: 1600, direction: .given, paymentMethod: .cash, date: e[3].date),

            // 陈明之父丧事 — 送礼
            Record(contact: c[4], event: e[4], amount: 1000, direction: .given, paymentMethod: .cash, date: e[4].date),

            // 春节聚会 — 收发红包
            Record(contact: c[6], event: e[5], amount: 500, direction: .received, paymentMethod: .wechat, date: e[5].date),
            Record(contact: c[7], event: e[5], amount: 500, direction: .received, paymentMethod: .wechat, date: e[5].date),
            Record(contact: c[6], event: e[5], amount: 600, direction: .given, paymentMethod: .wechat, date: e[5].date),

            // 部分退礼 — 测试 partial 状态
            Record(contact: c[8], event: e[1], amount: 800, direction: .given, paymentMethod: .cash, returnedAmount: 300, date: e[1].date),

            // 已清退礼 — 测试 settled 状态
            Record(contact: c[10], event: e[2], amount: 500, direction: .given, paymentMethod: .wechat, returnedAmount: 500, date: e[2].date),

            // 大额往来
            Record(contact: c[0], event: e[0], amount: 10000, direction: .given, paymentMethod: .cash, note: "婚礼份子钱", date: e[0].date),

            // 小额实物
            Record(contact: c[11], event: e[5], amount: 200, direction: .given, paymentMethod: .cash, note: "送了一箱水果", date: e[5].date),

            // 多方向同一联系人
            Record(contact: c[5], event: e[5], amount: 300, direction: .received, paymentMethod: .wechat, date: e[5].date),
            Record(contact: c[5], event: e[3], amount: 800, direction: .given, paymentMethod: .cash, date: e[3].date),

            // 礼品场景
            makeRecord(
                contact: c[9],
                event: e[8],
                direction: .given,
                note: "生日聚餐带去的伴手礼",
                date: e[8].date,
                recordType: .gift,
                relationshipWeight: .kindness,
                typeData: .gift(GiftData(giftName: "茶叶礼盒", estimatedValue: 368))
            ),

            // 帮忙场景
            makeRecord(
                contact: c[11],
                event: nil,
                direction: .given,
                note: "日常照应记录",
                date: Date.now,
                recordType: .favor,
                relationshipWeight: .support,
                typeData: .favor(FavorData(description: "临时帮忙接孩子放学并送回家"))
            ),

            // 宴请场景
            makeRecord(
                contact: c[10],
                event: e[8],
                direction: .received,
                note: "下次回请要按差不多的规格安排",
                date: e[8].date,
                recordType: .banquet,
                relationshipWeight: .reciprocal,
                typeData: .banquet(BanquetData(
                    location: "外婆家包厢，中档宴请",
                    attendeeList: "主客外还有两位老同学陪同",
                    extraCostNotes: "席间开了两瓶红酒，另加一条烟"
                ))
            )
        ]
    }
}
#endif
