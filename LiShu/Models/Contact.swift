import Foundation
import SwiftData

/// 联系人
@Model
final class Contact {
    /// 姓名
    var name: String = ""
    /// 手机号
    var phone: String = ""
    /// 头像图片，外部存储以支持 iCloud 同步
    @Attribute(.externalStorage)
    var avatar: Data?
    /// 关系标签，如"同事"、"朋友"、"亲戚"
    var relation: String = ""
    /// 关系分类，如"家人"、"亲属"、"社交"、"其他"
    var category: String = ""
    /// 亲密圈层 1-4，1=家人 2=亲属 3=社交 4=其他
    var circle: Int = 4
    /// 生日（公历存公历 Date，农历存对应公历 Date；nil 表示未设置）
    var birthday: Date?
    /// 生日是否为农历
    var birthdayIsLunar: Bool = false
    /// 是否开启生日提醒
    var birthdayReminderEnabled: Bool = false
    /// 所在地
    var location: String = ""
    /// 备注
    var note: String = ""
    /// 关联的往来记录，删除联系人时级联删除
    @Relationship(deleteRule: .cascade, inverse: \Record.contact)
    var records: [Record]?
    /// CloudKit 要求所有关系必须有反向关系；删除联系人时置空对应事件的 primaryContact
    @Relationship(deleteRule: .nullify, inverse: \Event.primaryContact)
    var hostedEvents: [Event]?
    /// 创建时间
    var createdAt = Date()

    init(
        name: String,
        phone: String = "",
        avatar: Data? = nil,
        relation: String = "",
        category: String = "",
        circle: Int = 4,
        birthday: Date? = nil,
        birthdayIsLunar: Bool = false,
        birthdayReminderEnabled: Bool = false,
        location: String = "",
        note: String = ""
    ) {
        self.name = name
        self.phone = phone
        self.avatar = avatar
        self.relation = relation
        self.category = category
        self.circle = circle
        self.birthday = birthday
        self.birthdayIsLunar = birthdayIsLunar
        self.birthdayReminderEnabled = birthdayReminderEnabled
        self.location = location
        self.note = note
        createdAt = .now
    }

    /// 人情净值 = 收到总额 - 送出总额（扣除退礼），仅统计金额类型
    var netValue: Double {
        (records ?? [])
            .filter { $0.recordType == .monetary }
            .reduce(0.0) { acc, r in
                let net = r.monetaryAmount - r.resolvedReturnedAmount
                return acc + (r.direction == .received ? net : -net)
            }
    }

    /// 累计送出金额，仅统计金额类型
    var totalGiven: Double {
        (records ?? []).filter { $0.recordType == .monetary && $0.direction == .given }.reduce(0.0) { $0 + $1.monetaryAmount }
    }

    /// 累计收到金额，仅统计金额类型
    var totalReceived: Double {
        (records ?? []).filter { $0.recordType == .monetary && $0.direction == .received }.reduce(0.0) { $0 + $1.monetaryAmount }
    }

    /// 非金额互动次数
    var nonFinancialInteractionCount: Int {
        (records ?? []).filter { $0.recordType != .monetary }.count
    }

    /// 累计退礼金额，仅统计金额类型
    var totalReturned: Double {
        (records ?? []).filter { $0.recordType == .monetary }.reduce(0.0) { $0 + $1.resolvedReturnedAmount }
    }
}
