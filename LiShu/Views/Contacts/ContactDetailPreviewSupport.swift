import Foundation
import SwiftData

@MainActor
func makeContactDetailPreviewContainer() -> (container: ModelContainer, contactID: PersistentIdentifier)? {
    guard let container = try? ModelContainer(
        for: Contact.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    ) else { return nil }

    let context = container.mainContext
    let contact = Contact(
        name: "张敬轩",
        phone: "138-8888-6666",
        relation: "大学同学",
        category: "社交",
        circle: 3,
        birthday: Date(timeIntervalSince1970: 643_334_400),
        location: "浙江 · 杭州"
    )
    context.insert(contact)

    let calendar = Calendar.current

    let weddingEvent = Event(
        name: "参加张三婚礼",
        type: .wedding,
        date: calendar.liShuDate(year: 2025, month: 2, day: 15),
        location: "西湖国宾馆"
    )
    context.insert(weddingEvent)

    let monetaryRecord = Record(
        contact: contact,
        event: weddingEvent,
        direction: .given,
        date: calendar.liShuDate(year: 2025, month: 2, day: 15),
        recordType: .monetary
    )
    monetaryRecord.applyTypeData(
        RecordTypeData.monetary(MonetaryData(amount: 1000, paymentMethod: "wechat"))
    )
    monetaryRecord.note = "大学同学聚会，随份子表达祝贺。于西湖国宾馆举行。"
    context.insert(monetaryRecord)

    let favorRecord = Record(
        contact: contact,
        direction: .received,
        date: calendar.liShuDate(year: 2025, month: 1, day: 8),
        recordType: .favor
    )
    favorRecord.applyTypeData(RecordTypeData.favor(FavorData(description: "帮忙挂号")))
    favorRecord.note = "协助张敬轩父亲在省人民医院挂专家号，通过老同学关系顺利排上。"
    favorRecord.contextTag = "帮忙挂号"
    context.insert(favorRecord)

    let giftRecord = Record(
        contact: contact,
        direction: .given,
        date: calendar.liShuDate(year: 2024, month: 12, day: 22),
        recordType: .gift
    )
    giftRecord.applyTypeData(
        RecordTypeData.gift(GiftData(giftName: "手工点心和茶叶", estimatedValue: 300))
    )
    giftRecord.note = "冬至带了两盒手工点心和茶叶登门拜访，闲聊两个小时。"
    giftRecord.contextTag = "节日看望"
    context.insert(giftRecord)

    let banquetRecord = Record(
        contact: contact,
        direction: .given,
        date: calendar.liShuDate(year: 2024, month: 10, day: 5),
        recordType: .banquet
    )
    banquetRecord.applyTypeData(
        RecordTypeData.banquet(BanquetData(location: "老杭帮菜馆", attendeeList: "张敬轩、李伟、王芳"))
    )
    banquetRecord.note = "国庆期间张敬轩从北京回来，约了几个老同学一起吃饭叙旧。"
    banquetRecord.contextTag = "接风洗尘"
    context.insert(banquetRecord)

    let birthdayEvent = Event(
        name: "我的生日",
        type: .birthday,
        date: calendar.liShuDate(year: 2024, month: 8, day: 18)
    )
    context.insert(birthdayEvent)

    let birthdayRecord = Record(
        contact: contact,
        event: birthdayEvent,
        direction: .received,
        date: calendar.liShuDate(year: 2024, month: 8, day: 18),
        recordType: .monetary
    )
    birthdayRecord.applyTypeData(
        RecordTypeData.monetary(MonetaryData(amount: 520, paymentMethod: "wechat"))
    )
    birthdayRecord.note = "生日当天收到微信红包，附言「生日快乐老同学」。"
    context.insert(birthdayRecord)

    let moveRecord = Record(
        contact: contact,
        direction: .received,
        date: calendar.liShuDate(year: 2024, month: 6, day: 1),
        recordType: .favor
    )
    moveRecord.applyTypeData(RecordTypeData.favor(FavorData(description: "帮忙搬家")))
    moveRecord.note = "新房搬家时主动开车来帮忙搬运，忙了一整天。"
    moveRecord.contextTag = "帮忙搬家"
    context.insert(moveRecord)

    let pastryRecord = Record(
        contact: contact,
        direction: .received,
        date: calendar.liShuDate(year: 2024, month: 4, day: 10),
        recordType: .gift
    )
    pastryRecord.applyTypeData(
        RecordTypeData.gift(GiftData(giftName: "北京稻香村糕点", estimatedValue: 150))
    )
    pastryRecord.note = "出差北京回来带的特产，说是特意给我留的。"
    pastryRecord.contextTag = "出差带特产"
    context.insert(pastryRecord)

    return (container, contact.persistentModelID)
}
