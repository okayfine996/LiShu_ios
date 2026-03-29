import Foundation
import SwiftData

/// 往来记录（一笔送礼或收礼）
@Model
final class Record {
    /// 关联联系人
    var contact: Contact?
    /// 关联事件
    var event: Event?
    /// 金额
    var amount: Double = 0
    /// 方向原始值，通过 `direction` 计算属性读写枚举
    var directionRaw: String = "given"
    /// 支付方式原始值，通过 `paymentMethod` 计算属性读写枚举
    var paymentMethodRaw: String = "cash"
    /// 已退礼金额
    var returnedAmount: Double = 0
    /// 备注
    var note: String = ""
    /// 记录日期
    var date: Date = Date()
    /// 状态原始值，通过 `status` 计算属性读写枚举
    var statusRaw: String = "open"
    /// 附属照片（如参加婚礼的留念照）
    @Relationship(deleteRule: .cascade, inverse: \RecordPhoto.record)
    var photos: [RecordPhoto]?
    /// 创建时间
    var createdAt: Date = Date()

    /// 送出/收到方向
    var direction: RecordDirection {
        get { RecordDirection(rawValue: directionRaw) ?? .given }
        set { directionRaw = newValue.rawValue }
    }

    /// 支付方式
    var paymentMethod: PaymentMethod {
        get { PaymentMethod(rawValue: paymentMethodRaw) ?? .cash }
        set { paymentMethodRaw = newValue.rawValue }
    }

    /// 还礼状态：未还 / 部分 / 已清
    var status: RecordStatus {
        get { RecordStatus(rawValue: statusRaw) ?? .open }
        set { statusRaw = newValue.rawValue }
    }

    init(
        contact: Contact,
        event: Event,
        amount: Double = 0,
        direction: RecordDirection = .given,
        paymentMethod: PaymentMethod = .cash,
        returnedAmount: Double = 0,
        note: String = "",
        date: Date = .now
    ) {
        self.contact = contact
        self.event = event
        self.amount = amount
        self.directionRaw = direction.rawValue
        self.paymentMethodRaw = paymentMethod.rawValue
        self.returnedAmount = returnedAmount
        self.note = note
        self.date = date
        self.statusRaw = RecordStatus.open.rawValue
        self.createdAt = .now
        updateStatus()
    }

    /// 未清金额 = 金额 - 已退礼金额
    var outstandingAmount: Double {
        amount - returnedAmount
    }

    /// 根据退礼金额自动更新状态
    func updateStatus() {
        if returnedAmount <= 0 {
            statusRaw = RecordStatus.open.rawValue
        } else if returnedAmount < amount {
            statusRaw = RecordStatus.partial.rawValue
        } else {
            statusRaw = RecordStatus.settled.rawValue
        }
    }
}

// MARK: - Enums

/// 往来方向
enum RecordDirection: String, Codable, CaseIterable {
    /// 送出
    case given = "given"
    /// 收到
    case received = "received"
}

/// 支付方式
enum PaymentMethod: String, Codable, CaseIterable {
    /// 现金
    case cash = "cash"
    /// 微信
    case wechat = "wechat"
    /// 支付宝
    case alipay = "alipay"
}

/// 还礼状态
enum RecordStatus: String, Codable, CaseIterable {
    /// 未还
    case open = "open"
    /// 部分归还
    case partial = "partial"
    /// 已清
    case settled = "settled"
}
