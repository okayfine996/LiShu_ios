import Foundation
import SwiftData
import UIKit

/// 调试菜单与 App Store 截图（`-FASTLANE_SNAPSHOT`）共用的示例数据；截图模式下使用内存库并调用 `insertSampleData`。
@MainActor
enum DemoDataSeeding {
    static var isFastlaneSnapshotMode: Bool {
        CommandLine.arguments.contains("-FASTLANE_SNAPSHOT")
    }

    /// - Parameters:
    ///   - attachDemoMedia: 为联系人设置头像、为部分记录插入 `RecordPhoto`。优先使用 `ScreenshotDemo` 目录下 PNG（见 `LiShu/Resources/ScreenshotDemo/`），缺失时回退为程序化生成。
    static func insertSampleData(context: ModelContext, attachDemoMedia: Bool) {
        var contacts = createContacts()
        if attachDemoMedia {
            applyAvatarData(to: &contacts)
        }
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

        if attachDemoMedia {
            applyEventCoverImages(to: events)
            attachRecordPhotos(to: records, context: context)
        }

        try? context.save()
    }

    // MARK: - Demo images (Bundle PNG + fallback)

    private enum ScreenshotDemoBundle {
        /// 与 `screenshot_demo_avatar_01` … `screenshot_demo_avatar_16.png` 对应；缺省按索引回退程序化头像。
        static let avatarResourceCount = 16
        // 与 `screenshot_demo_scene_<EventType.rawValue>.png` 对应（共 13 种事件场景）。

        static func sceneResourceName(for eventType: EventType) -> String {
            "screenshot_demo_scene_\(eventType.rawValue)"
        }

        /// 优先 `screenshot_demo_avatar_01`，兼容旧资源名 `screenshot_demo_avatar_1`。
        static func pngDataAvatar(index: Int) -> Data? {
            let n = (index % avatarResourceCount) + 1
            let padded = String(format: "screenshot_demo_avatar_%02d", n)
            if let d = pngData(named: padded) { return d }
            return pngData(named: "screenshot_demo_avatar_\(n)")
        }

        static func pngData(named name: String) -> Data? {
            let subdirs = ["ScreenshotDemo", "Resources/ScreenshotDemo"]
            for sub in subdirs {
                if let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: sub),
                   let data = try? Data(contentsOf: url), !data.isEmpty
                {
                    return data
                }
            }
            if let url = Bundle.main.url(forResource: name, withExtension: "png"),
               let data = try? Data(contentsOf: url), !data.isEmpty
            {
                return data
            }
            return nil
        }
    }

    private static let avatarBackgrounds: [UIColor] = [
        UIColor(red: 0.72, green: 0.43, blue: 0.35, alpha: 1),
        UIColor(red: 0.77, green: 0.63, blue: 0.40, alpha: 1),
        UIColor(red: 0.42, green: 0.45, blue: 0.50, alpha: 1),
        UIColor(red: 0.55, green: 0.50, blue: 0.45, alpha: 1),
        UIColor(red: 0.45, green: 0.55, blue: 0.48, alpha: 1),
        UIColor(red: 0.60, green: 0.42, blue: 0.48, alpha: 1),
        UIColor(red: 0.48, green: 0.52, blue: 0.60, alpha: 1),
        UIColor(red: 0.58, green: 0.52, blue: 0.40, alpha: 1),
        UIColor(red: 0.65, green: 0.48, blue: 0.42, alpha: 1),
        UIColor(red: 0.50, green: 0.55, blue: 0.52, alpha: 1),
        UIColor(red: 0.55, green: 0.48, blue: 0.55, alpha: 1),
        UIColor(red: 0.52, green: 0.50, blue: 0.46, alpha: 1),
        UIColor(red: 0.45, green: 0.48, blue: 0.55, alpha: 1),
        UIColor(red: 0.58, green: 0.45, blue: 0.40, alpha: 1),
        UIColor(red: 0.48, green: 0.52, blue: 0.48, alpha: 1),
        UIColor(red: 0.62, green: 0.55, blue: 0.45, alpha: 1),
    ]

    private static func applyAvatarData(to contacts: inout [Contact]) {
        for (index, contact) in contacts.enumerated() {
            if let data = ScreenshotDemoBundle.pngDataAvatar(index: index) {
                contact.avatar = data
            } else {
                let initial = String(contact.name.prefix(1))
                let bg = avatarBackgrounds[index % avatarBackgrounds.count]
                contact.avatar = DemoImageFactory.avatarJPEGData(initial: initial, background: bg, size: 160)
            }
        }
    }

    private static func applyEventCoverImages(to events: [Event]) {
        for event in events {
            let name = ScreenshotDemoBundle.sceneResourceName(for: event.type)
            if let data = ScreenshotDemoBundle.pngData(named: name) {
                event.coverImage = data
            }
        }
    }

    private static func attachRecordPhotos(to records: [Record], context: ModelContext) {
        for record in records {
            guard let event = record.event else { continue }
            let name = ScreenshotDemoBundle.sceneResourceName(for: event.type)
            let data: Data = if let png = ScreenshotDemoBundle.pngData(named: name) {
                png
            } else {
                DemoImageFactory.scenePhotoJPEGData(seed: event.type.rawValue.hashValue)
            }
            let photo = RecordPhoto(record: record, imageData: data)
            context.insert(photo)
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
            Contact(
                name: "林悦",
                phone: "15100151012",
                relation: "同事",
                category: RelationshipCategory.social.rawValue,
                circle: 3,
                location: "深圳"
            ),
            Contact(
                name: "何洁",
                relation: "表妹",
                category: RelationshipCategory.relative.rawValue,
                circle: 2,
                location: "苏州"
            ),
            Contact(
                name: "邓伟",
                relation: "生意伙伴",
                category: RelationshipCategory.social.rawValue,
                circle: 3,
                location: "东莞"
            ),
            Contact(
                name: "彭雪",
                relation: "远房亲戚",
                category: RelationshipCategory.relative.rawValue,
                circle: 2,
                location: "西安"
            ),
        ]
    }

    // MARK: - Events

    private static func demoEventTitle(for type: EventType) -> String {
        switch type {
        case .wedding: "张伟的婚礼"
        case .engagement: "表妹订婚酒"
        case .funeral: "陈明之父丧事"
        case .birth: "刘芳宝宝满月"
        case .birthday: "吴刚生日聚餐"
        case .longevity: "李娜六十大寿"
        case .festival: "春节聚会"
        case .property: "王强乔迁新居"
        case .education: "黄杰孩子升学宴"
        case .business: "朋友新店开业"
        case .promotion: "同事晋升答谢"
        case .visit: "探望生病长辈"
        case .other: "其它往来记事"
        }
    }

    private static func demoEventLocation(for type: EventType) -> String {
        switch type {
        case .wedding: "北京国贸大酒店"
        case .engagement: "杭州"
        case .funeral: "深圳南山殡仪馆"
        case .birth: "广州天河"
        case .birthday: "北京三里屯"
        case .longevity: "上海外滩花园"
        case .festival: "老家"
        case .property: "上海浦东"
        case .education: "重庆解放碑"
        case .business: "深圳南山"
        case .promotion: "北京国贸"
        case .visit: "本地医院"
        case .other: "本地"
        }
    }

    private static func createEvents() -> [Event] {
        let now = Date.now
        let calendar = Calendar.current

        func date(byAddingMonths months: Int, day: Int = 15) -> Date {
            var comps = calendar.dateComponents([.year, .month], from: now)
            comps.month = (comps.month ?? 1) + months
            comps.day = day
            return calendar.date(from: comps) ?? now
        }

        return EventType.allCases.enumerated().map { idx, type in
            let day = min(8 + idx, 28)
            return Event(
                name: demoEventTitle(for: type),
                type: type,
                date: date(byAddingMonths: -11 + idx, day: day),
                location: demoEventLocation(for: type)
            )
        }
    }

    // MARK: - Records

    private static func makeRecord(
        contact: Contact,
        event: Event? = nil,
        direction: RecordDirection = .given,
        returnedAmount: Double = 0,
        note: String = "",
        contextTag: String = "",
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
        record.contextTag = contextTag
        record.applyTypeData(typeData)
        return record
    }

    private static func firstEvent(_ type: EventType, in events: [Event]) -> Event {
        guard let e = events.first(where: { $0.type == type }) else {
            fatalError("DemoDataSeeding: missing event of type \(type.rawValue)")
        }
        return e
    }

    private static func createRecords(contacts: [Contact], events: [Event]) -> [Record] {
        guard contacts.count >= 12, events.count >= EventType.allCases.count else { return [] }

        let c = contacts
        let w = firstEvent(.wedding, in: events)
        let long = firstEvent(.longevity, in: events)
        let prop = firstEvent(.property, in: events)
        let birth = firstEvent(.birth, in: events)
        let fun = firstEvent(.funeral, in: events)
        let fest = firstEvent(.festival, in: events)
        let edu = firstEvent(.education, in: events)
        let bday = firstEvent(.birthday, in: events)
        let promotion = firstEvent(.promotion, in: events)
        let visit = firstEvent(.visit, in: events)
        let business = firstEvent(.business, in: events)

        let monetaryRecords: [Record] = [
            makeRecord(
                contact: c[4],
                event: w,
                direction: .received,
                note: "",
                date: w.date,
                recordType: .monetary,
                typeData: .monetary(MonetaryData(amount: 2000, paymentMethod: PaymentMethod.wechat.rawValue, returnedAmount: 0))
            ),
            makeRecord(
                contact: c[5],
                event: w,
                direction: .received,
                note: "",
                date: w.date,
                recordType: .monetary,
                typeData: .monetary(MonetaryData(amount: 1000, paymentMethod: PaymentMethod.cash.rawValue, returnedAmount: 0))
            ),
            makeRecord(
                contact: c[8],
                event: w,
                direction: .received,
                note: "",
                date: w.date,
                recordType: .monetary,
                typeData: .monetary(MonetaryData(amount: 600, paymentMethod: PaymentMethod.alipay.rawValue, returnedAmount: 0))
            ),
            makeRecord(
                contact: c[9],
                event: w,
                direction: .received,
                note: "",
                date: w.date,
                recordType: .monetary,
                typeData: .monetary(MonetaryData(amount: 500, paymentMethod: PaymentMethod.wechat.rawValue, returnedAmount: 0))
            ),
            makeRecord(
                contact: c[10],
                event: w,
                direction: .received,
                note: "",
                date: w.date,
                recordType: .monetary,
                typeData: .monetary(MonetaryData(amount: 800, paymentMethod: PaymentMethod.cash.rawValue, returnedAmount: 0))
            ),
            makeRecord(
                contact: c[11],
                event: w,
                direction: .received,
                note: "送了一套餐具",
                date: w.date,
                recordType: .monetary,
                typeData: .monetary(MonetaryData(amount: 200, paymentMethod: PaymentMethod.cash.rawValue, returnedAmount: 0))
            ),
            makeRecord(
                contact: c[1],
                event: long,
                direction: .given,
                note: "",
                date: long.date,
                recordType: .monetary,
                typeData: .monetary(MonetaryData(amount: 5000, paymentMethod: PaymentMethod.cash.rawValue, returnedAmount: 0))
            ),
            makeRecord(
                contact: c[5],
                event: long,
                direction: .given,
                note: "",
                date: long.date,
                recordType: .monetary,
                typeData: .monetary(MonetaryData(amount: 1000, paymentMethod: PaymentMethod.wechat.rawValue, returnedAmount: 0))
            ),
            makeRecord(
                contact: c[2],
                event: prop,
                direction: .given,
                note: "",
                date: prop.date,
                recordType: .monetary,
                typeData: .monetary(MonetaryData(amount: 2000, paymentMethod: PaymentMethod.alipay.rawValue, returnedAmount: 0))
            ),
            makeRecord(
                contact: c[12],
                event: edu,
                direction: .given,
                note: "升学红包",
                date: edu.date,
                recordType: .monetary,
                typeData: .monetary(MonetaryData(amount: 888, paymentMethod: PaymentMethod.wechat.rawValue, returnedAmount: 0))
            ),
            makeRecord(
                contact: c[3],
                event: birth,
                direction: .given,
                note: "",
                date: birth.date,
                recordType: .monetary,
                typeData: .monetary(MonetaryData(amount: 1600, paymentMethod: PaymentMethod.cash.rawValue, returnedAmount: 0))
            ),
            makeRecord(
                contact: c[4],
                event: fun,
                direction: .given,
                note: "",
                date: fun.date,
                recordType: .monetary,
                typeData: .monetary(MonetaryData(amount: 1000, paymentMethod: PaymentMethod.cash.rawValue, returnedAmount: 0))
            ),
            makeRecord(
                contact: c[6],
                event: fest,
                direction: .received,
                note: "",
                date: fest.date,
                recordType: .monetary,
                typeData: .monetary(MonetaryData(amount: 500, paymentMethod: PaymentMethod.wechat.rawValue, returnedAmount: 0))
            ),
            makeRecord(
                contact: c[7],
                event: fest,
                direction: .received,
                note: "",
                date: fest.date,
                recordType: .monetary,
                typeData: .monetary(MonetaryData(amount: 500, paymentMethod: PaymentMethod.wechat.rawValue, returnedAmount: 0))
            ),
            makeRecord(
                contact: c[6],
                event: fest,
                direction: .given,
                note: "",
                date: fest.date,
                recordType: .monetary,
                typeData: .monetary(MonetaryData(amount: 600, paymentMethod: PaymentMethod.wechat.rawValue, returnedAmount: 0))
            ),
            makeRecord(
                contact: c[8],
                event: long,
                direction: .given,
                note: "",
                date: long.date,
                recordType: .monetary,
                typeData: .monetary(MonetaryData(amount: 800, paymentMethod: PaymentMethod.cash.rawValue, returnedAmount: 300))
            ),
            makeRecord(
                contact: c[10],
                event: prop,
                direction: .given,
                note: "",
                date: prop.date,
                recordType: .monetary,
                typeData: .monetary(MonetaryData(amount: 500, paymentMethod: PaymentMethod.wechat.rawValue, returnedAmount: 500))
            ),
            makeRecord(
                contact: c[0],
                event: w,
                direction: .given,
                note: "婚礼份子钱",
                date: w.date,
                recordType: .monetary,
                typeData: .monetary(MonetaryData(amount: 10000, paymentMethod: PaymentMethod.cash.rawValue, returnedAmount: 0))
            ),
            makeRecord(
                contact: c[11],
                event: fest,
                direction: .given,
                note: "送了一箱水果",
                date: fest.date,
                recordType: .monetary,
                typeData: .monetary(MonetaryData(amount: 200, paymentMethod: PaymentMethod.cash.rawValue, returnedAmount: 0))
            ),
            makeRecord(
                contact: c[5],
                event: fest,
                direction: .received,
                note: "",
                date: fest.date,
                recordType: .monetary,
                typeData: .monetary(MonetaryData(amount: 300, paymentMethod: PaymentMethod.wechat.rawValue, returnedAmount: 0))
            ),
            makeRecord(
                contact: c[5],
                event: birth,
                direction: .given,
                note: "",
                date: birth.date,
                recordType: .monetary,
                typeData: .monetary(MonetaryData(amount: 800, paymentMethod: PaymentMethod.cash.rawValue, returnedAmount: 0))
            ),
            makeRecord(
                contact: c[13],
                event: nil,
                direction: .given,
                note: "住院探望时包了红包",
                contextTag: "探病心意",
                date: visit.date,
                recordType: .monetary,
                relationshipWeight: .kindness,
                typeData: .monetary(MonetaryData(amount: 300, paymentMethod: PaymentMethod.wechat.rawValue, returnedAmount: 0))
            ),
            makeRecord(
                contact: c[14],
                event: nil,
                direction: .received,
                note: "店里开张时收到了随礼",
                contextTag: "开业随礼",
                date: business.date,
                recordType: .monetary,
                relationshipWeight: .support,
                typeData: .monetary(MonetaryData(amount: 666, paymentMethod: PaymentMethod.alipay.rawValue, returnedAmount: 0))
            ),
        ]

        let giftRecords: [Record] = [
            makeRecord(
                contact: c[9],
                event: bday,
                direction: .given,
                note: "生日聚餐带去的伴手礼",
                date: bday.date,
                recordType: .gift,
                relationshipWeight: .kindness,
                typeData: .gift(GiftData(giftName: "茶叶礼盒", estimatedValue: 368))
            ),
            makeRecord(
                contact: c[6],
                event: nil,
                direction: .received,
                note: "节后来家里看望时带来的礼盒",
                contextTag: "节日看望",
                date: fest.date,
                recordType: .gift,
                relationshipWeight: .reciprocal,
                typeData: .gift(GiftData(giftName: "家乡糕点礼盒", estimatedValue: nil))
            ),
            makeRecord(
                contact: c[15],
                event: promotion,
                direction: .received,
                note: "庆祝晋升时收到的伴手礼",
                date: promotion.date,
                recordType: .gift,
                relationshipWeight: .support,
                typeData: .gift(GiftData(giftName: "钢笔礼盒", estimatedValue: 520))
            ),
            makeRecord(
                contact: c[2],
                event: nil,
                direction: .given,
                note: "探望长辈顺手带去营养品",
                contextTag: "探望长辈",
                date: visit.date,
                recordType: .gift,
                relationshipWeight: .kindness,
                typeData: .gift(GiftData(giftName: "营养品礼篮", estimatedValue: nil))
            ),
        ]

        let favorRecords: [Record] = [
            makeRecord(
                contact: c[11],
                event: nil,
                direction: .given,
                note: "日常照应记录",
                contextTag: "邻里照应",
                date: Date.now,
                recordType: .favor,
                relationshipWeight: .support,
                typeData: .favor(FavorData(description: "临时帮忙接孩子放学并送回家"))
            ),
            makeRecord(
                contact: c[10],
                event: nil,
                direction: .received,
                note: "装修期间帮忙盯工",
                contextTag: "帮忙盯工",
                date: prop.date,
                recordType: .favor,
                relationshipWeight: .profound,
                typeData: .favor(FavorData(description: "连续两天帮忙协调师傅进场，还代收了快递和建材"))
            ),
            makeRecord(
                contact: c[4],
                event: promotion,
                direction: .given,
                note: "帮忙布置答谢场地",
                date: promotion.date,
                recordType: .favor,
                relationshipWeight: .kindness,
                typeData: .favor(FavorData(description: "提前到场协助签到、引导宾客和收尾清点物资"))
            ),
            makeRecord(
                contact: c[12],
                event: visit,
                direction: .received,
                note: "陪同就医",
                date: visit.date,
                recordType: .favor,
                relationshipWeight: .support,
                typeData: .favor(FavorData(description: "专程请假陪同挂号、取药并送回家"))
            ),
        ]

        let banquetRecords: [Record] = [
            makeRecord(
                contact: c[10],
                event: bday,
                direction: .received,
                note: "下次回请要按差不多的规格安排",
                date: bday.date,
                recordType: .banquet,
                relationshipWeight: .reciprocal,
                typeData: .banquet(BanquetData(
                    location: "外婆家包厢，中档宴请",
                    attendeeList: "主客外还有两位老同学陪同",
                    extraCostNotes: "席间开了两瓶红酒，另加一条烟"
                ))
            ),
            makeRecord(
                contact: c[8],
                event: nil,
                direction: .given,
                note: "项目收尾后请客吃饭",
                contextTag: "聚餐答谢",
                date: business.date,
                recordType: .banquet,
                relationshipWeight: .reciprocal,
                typeData: .banquet(BanquetData(
                    location: "南城小馆",
                    attendeeList: "",
                    extraCostNotes: ""
                ))
            ),
            makeRecord(
                contact: c[3],
                event: long,
                direction: .given,
                note: "寿宴前一晚家宴招待",
                date: long.date,
                recordType: .banquet,
                relationshipWeight: .support,
                typeData: .banquet(BanquetData(
                    location: "家宴包厢",
                    attendeeList: "近亲四桌",
                    extraCostNotes: ""
                ))
            ),
            makeRecord(
                contact: c[14],
                event: nil,
                direction: .received,
                note: "对方请客聊合作",
                contextTag: "商务接待",
                date: business.date,
                recordType: .banquet,
                relationshipWeight: .support,
                typeData: .banquet(BanquetData(
                    location: "福满楼",
                    attendeeList: "",
                    extraCostNotes: "饭后又续了茶位"
                ))
            ),
        ]

        return monetaryRecords + giftRecords + favorRecords + banquetRecords
    }
}

// MARK: - Image factory

private enum DemoImageFactory {
    static func avatarJPEGData(initial: String, background: UIColor, size: CGFloat) -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let image = renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: CGSize(width: size, height: size))
            ctx.cgContext.setFillColor(background.cgColor)
            ctx.cgContext.fillEllipse(in: rect)

            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            let font = UIFont.systemFont(ofSize: size * 0.38, weight: .semibold)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.white,
                .paragraphStyle: paragraph,
            ]
            let text = initial as NSString
            let textRect = rect.insetBy(dx: 4, dy: 4)
            text.draw(in: textRect, withAttributes: attrs)
        }
        return image.jpegData(compressionQuality: 0.88) ?? Data()
    }

    static func scenePhotoJPEGData(seed: Int) -> Data {
        let w: CGFloat = 960
        let h: CGFloat = 540
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: w, height: h))
        let image = renderer.image { ctx in
            let top = UIColor(red: 0.96, green: 0.93, blue: 0.88, alpha: 1)
            let bottom = UIColor(red: 0.88, green: 0.82, blue: 0.76, alpha: 1)
            let colors = [top.cgColor, bottom.cgColor] as CFArray
            let locs: [CGFloat] = [0, 1]
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locs) {
                ctx.cgContext.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: 0, y: 0),
                    end: CGPoint(x: w * 0.3 + CGFloat(seed % 40), y: h),
                    options: []
                )
            }
            let accent = UIColor(red: 0.72, green: 0.43, blue: 0.35, alpha: 0.35)
            ctx.cgContext.setFillColor(accent.cgColor)
            ctx.cgContext.fillEllipse(in: CGRect(x: w * 0.55, y: h * 0.15, width: w * 0.35, height: h * 0.55))
        }
        return image.jpegData(compressionQuality: 0.82) ?? Data()
    }
}
