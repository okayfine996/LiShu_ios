import Foundation
import Logging
import SwiftData

private nonisolated(unsafe) var recordKVDataLogger: Logger { PulseDiagnostics.makeLogger(label: "storage.record-kv") }

/// 往来记录（一笔送礼或收礼）
@Model
final class Record {
    /// 关联联系人
    var contact: Contact?
    /// 关联事件
    var event: Event?
    /// 金额（遗留列，仅无 kv 时回退；真源见 kvData）
    var amount: Double = 0
    /// 方向原始值，通过 `direction` 计算属性读写枚举
    var directionRaw: String = "given"
    /// 支付方式原始值（遗留列，仅无 kv 时回退）
    var paymentMethodRaw: String = "cash"
    /// 已退礼金额（遗留列，仅无 kv 时回退）
    var returnedAmount: Double = 0
    /// 备注
    var note: String = ""
    /// 记录日期
    var date: Date = Date()
    /// 记录类型原始值，通过 `recordType` 计算属性读写枚举
    var recordTypeRaw: String = "monetary"
    /// 情分分量原始值，通过 `relationshipWeight` 计算属性读写枚举
    var relationshipWeightRaw: String = "reciprocal"
    /// 日常往来标签（如"日常走动"、"节日问候"等）
    var contextTag: String = ""
    /// 类型专属数据 (JSON)
    var kvData: String = "{}"
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

    /// 支付方式（真源在 kvData，不落列）
    var paymentMethod: PaymentMethod {
        resolvedPaymentMethod
    }

    /// 金额类：是否已有退礼（任意已退金额 > 0）
    var hasReturnedGift: Bool {
        guard recordType == .monetary else { return false }
        return resolvedReturnedAmount > 0
    }

    /// 详情页退礼角标：收到 / 金额送出未退与已退 / 其它类型不展示
    var returnGiftBadge: RecordReturnGiftBadge {
        if direction == .received { return .received }
        guard recordType == .monetary, direction == .given else { return .omitted }
        return hasReturnedGift ? .returned : .notReturned
    }

    /// 记录类型
    var recordType: RecordType {
        get {
            let raw = recordTypeRaw.trimmingCharacters(in: .whitespacesAndNewlines)
            return RecordType(rawValue: raw) ?? .monetary
        }
        set { recordTypeRaw = newValue.rawValue }
    }

    /// 情分分量
    var relationshipWeight: RelationshipWeight {
        get { RelationshipWeight(rawValue: relationshipWeightRaw) ?? .reciprocal }
        set { relationshipWeightRaw = newValue.rawValue }
    }

    /// 是否为金额类型记录
    var isMonetary: Bool {
        recordType == .monetary
    }

    /// 是否为日常往来（未关联特定事件）
    var isDailyInteraction: Bool {
        event == nil
    }

    /// 展示用场景名称
    var contextDisplayName: String {
        if let eventName = event?.name { return eventName }
        if !contextTag.isEmpty { return contextTag }
        return String(localized: "record.context.daily")
    }

    /// 新建一条记录（仅在你写 `Record(...)` 时调用；从 SwiftData 取回已保存的记录**不会**走此初始化方法，而是由框架按存储属性还原，含 `kvData`）。
    /// - Parameter kvData: 若已有序列化好的类型 JSON（如导入），传入则直接使用；为 `nil` 或空/`{}` 时，金额类会从 `amount` / `paymentMethod` / `returnedAmount` 编码写入，其它类型为 `"{}"`。
    init(
        contact: Contact,
        event: Event? = nil,
        amount: Double = 0,
        direction: RecordDirection = .given,
        paymentMethod: PaymentMethod = .cash,
        returnedAmount: Double = 0,
        note: String = "",
        date: Date = .now,
        recordType: RecordType = .monetary,
        relationshipWeight: RelationshipWeight = .reciprocal,
        kvData: String? = nil
    ) {
        self.contact = contact
        self.event = event
        self.directionRaw = direction.rawValue
        self.note = note
        self.date = date
        self.recordTypeRaw = recordType.rawValue
        self.relationshipWeightRaw = relationshipWeight.rawValue
        self.createdAt = .now

        if let trimmed = kvData?.trimmingCharacters(in: .whitespacesAndNewlines),
           !trimmed.isEmpty, trimmed != "{}" {
            self.kvData = trimmed
        } else if recordType == .monetary {
            let monetary = MonetaryData(amount: amount, paymentMethod: paymentMethod.rawValue, returnedAmount: returnedAmount)
            let encoder = JSONEncoder()
            if let data = try? encoder.encode(monetary),
               let json = String(data: data, encoding: .utf8) {
                self.kvData = json
            } else {
                self.kvData = "{}"
            }
        } else {
            self.kvData = "{}"
        }
    }

    /// 已退礼金额（优先 kvData 中 `MonetaryData.returnedAmount`，否则回退旧列）
    var resolvedReturnedAmount: Double {
        guard recordType == .monetary else { return 0 }
        if case .monetary(let d) = resolvedTypeData {
            return d.returnedAmount
        }
        return returnedAmount
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

/// 退礼角标（仅区分是否发生过退礼，不区分程度）
enum RecordReturnGiftBadge: Equatable {
    /// 方向为收到
    case received
    /// 金额送出且尚未退礼
    case notReturned
    /// 金额送出且已有退礼
    case returned
    /// 非金额送出等：不展示退礼角标
    case omitted
}

/// 情分分量
enum RelationshipWeight: String, Codable, CaseIterable {
    /// 举手之劳
    case trivial = "trivial"
    /// 点滴之恩
    case kindness = "kindness"
    /// 礼尚往来
    case reciprocal = "reciprocal"
    /// 倾力相助
    case support = "support"
    /// 重如泰山
    case profound = "profound"

    var displayName: String {
        switch self {
        case .trivial: return String(localized: "record.relationshipWeight.trivial")
        case .kindness: return String(localized: "record.relationshipWeight.kindness")
        case .reciprocal: return String(localized: "record.relationshipWeight.reciprocal")
        case .support: return String(localized: "record.relationshipWeight.support")
        case .profound: return String(localized: "record.relationshipWeight.profound")
        }
    }
}

/// 记录类型
enum RecordType: String, Codable, CaseIterable {
    /// 金额
    case monetary = "monetary"
    /// 礼品
    case gift = "gift"
    /// 帮忙
    case favor = "favor"
    /// 宴请
    case banquet = "banquet"

    var displayName: String {
        switch self {
        case .monetary: return String(localized: "record.type.monetary")
        case .gift: return String(localized: "record.type.gift")
        case .favor: return String(localized: "record.type.favor")
        case .banquet: return String(localized: "record.type.banquet")
        }
    }

    var iconEmoji: String {
        switch self {
        case .monetary: return "💰"
        case .gift: return "🎁"
        case .favor: return "🤝"
        case .banquet: return "🍽️"
        }
    }

    var iconName: String {
        switch self {
        case .monetary: return "yensign.circle"
        case .gift: return "gift"
        case .favor: return "hands.sparkles"
        case .banquet: return "fork.knife"
        }
    }

    var isMonetary: Bool {
        self == .monetary
    }
}

// MARK: - Record Type Data

enum RecordTypeData {
    case monetary(MonetaryData)
    case gift(GiftData)
    case favor(FavorData)
    case banquet(BanquetData)
}

nonisolated struct MonetaryData: Codable {
    var amount: Double = 0
    var paymentMethod: String = "cash"
    /// 已退礼金额（真源在 kvData；列仅作旧数据回退）
    var returnedAmount: Double = 0
}

nonisolated struct GiftData: Codable {
    var giftName: String = ""
    var estimatedValue: Double?
}

nonisolated struct FavorData: Codable {
    var description: String = ""
}

nonisolated struct BanquetData: Codable {
    var location: String = ""
    var attendeeList: String = ""
    var extraCostNotes: String = ""
}

// MARK: - Record kvData Helpers

extension Record {
    /// 统一业务读取：按 `recordType` 从 kvData 解码；金额类仅在 kv 有实质 JSON 时使用解码结果，否则用列构造；其它类型解码失败时用空占位
    /// - Note: 若 kv 解码出的 `amount` 为 0 但遗留列 `amount` 仍大于 0，则回退列（升级迁移 / CloudKit 合并等场景下 kv 占位为 0 而旧库金额在列上）。
    var resolvedTypeData: RecordTypeData {
        let decoder = JSONDecoder()
        // 与 `recordType` 一致：无法解析的 raw 按 `.monetary` 分支处理，避免旧库无类型列时走错 gift/favor 等分支。
        let kind = RecordType(rawValue: recordTypeRaw.trimmingCharacters(in: .whitespacesAndNewlines)) ?? .monetary
        switch kind {
        case .monetary:
            let columnFallback = MonetaryData(amount: amount, paymentMethod: paymentMethodRaw, returnedAmount: returnedAmount)
            if hasSubstantiveKVJSON,
               let data = kvData.data(using: .utf8),
               let m = try? decoder.decode(MonetaryData.self, from: data) {
                // 含 recordTypeRaw 已为合法 "monetary" 时：kv 中 0 不得覆盖遗留列上的真实金额
                if amount > 0, m.amount == 0 {
                    return .monetary(columnFallback)
                }
                return .monetary(m)
            }
            return .monetary(columnFallback)
        case .gift:
            if let data = kvData.data(using: .utf8),
               let g = try? decoder.decode(GiftData.self, from: data) {
                return .gift(g)
            }
            return .gift(GiftData())
        case .favor:
            if let data = kvData.data(using: .utf8),
               let f = try? decoder.decode(FavorData.self, from: data) {
                return .favor(f)
            }
            return .favor(FavorData())
        case .banquet:
            if let data = kvData.data(using: .utf8),
               let b = try? decoder.decode(BanquetData.self, from: data) {
                return .banquet(b)
            }
            return .banquet(BanquetData())
        }
    }

    /// 非空且非裸 `{}`，避免把「无 kv」误解码成全 0 的 `MonetaryData` 而覆盖列上的金额
    private var hasSubstantiveKVJSON: Bool {
        let t = kvData.trimmingCharacters(in: .whitespacesAndNewlines)
        return !t.isEmpty && t != "{}"
    }

    var monetaryData: MonetaryData? {
        guard case .monetary(let data) = resolvedTypeData else { return nil }
        return data
    }

    var giftData: GiftData? {
        guard case .gift(let data) = resolvedTypeData else { return nil }
        return data
    }

    var favorData: FavorData? {
        guard case .favor(let data) = resolvedTypeData else { return nil }
        return data
    }

    var banquetData: BanquetData? {
        guard case .banquet(let data) = resolvedTypeData else { return nil }
        return data
    }

    var monetaryAmount: Double {
        monetaryData?.amount ?? 0
    }

    var resolvedPaymentMethod: PaymentMethod {
        guard let monetaryData else { return PaymentMethod(rawValue: paymentMethodRaw) ?? .cash }
        return PaymentMethod(rawValue: monetaryData.paymentMethod) ?? .cash
    }

    var resolvedDisplayAmount: Double {
        switch resolvedTypeData {
        case .monetary(let data):
            return data.amount
        case .gift(let data):
            return data.estimatedValue ?? 0
        case .favor:
            return 0
        case .banquet:
            return 0
        }
    }

    var resolvedDescription: String {
        switch resolvedTypeData {
        case .monetary:
            return ""
        case .gift(let data):
            return data.giftName
        case .favor(let data):
            return data.description
        case .banquet(let data):
            if !data.location.isEmpty { return data.location }
            return data.attendeeList
        }
    }

    var resolvedEstimatedValue: Double? {
        switch resolvedTypeData {
        case .gift(let data):
            return data.estimatedValue
        default:
            return nil
        }
    }

    /// 编码类型数据到 kvData，作为唯一业务写入真源
    func applyTypeData(_ typeData: RecordTypeData) {
        let encoder = JSONEncoder()
        switch typeData {
        case .monetary(let d):
            guard let json = try? encoder.encode(d) else {
                recordKVDataLogger.error("Failed to encode MonetaryData for kvData")
                return
            }
            kvData = String(data: json, encoding: .utf8) ?? "{}"
        case .gift(let d):
            guard let json = try? encoder.encode(d) else {
                recordKVDataLogger.error("Failed to encode GiftData for kvData")
                return
            }
            kvData = String(data: json, encoding: .utf8) ?? "{}"
        case .favor(let d):
            guard let json = try? encoder.encode(d) else {
                recordKVDataLogger.error("Failed to encode FavorData for kvData")
                return
            }
            kvData = String(data: json, encoding: .utf8) ?? "{}"
        case .banquet(let d):
            guard let json = try? encoder.encode(d) else {
                recordKVDataLogger.error("Failed to encode BanquetData for kvData")
                return
            }
            kvData = String(data: json, encoding: .utf8) ?? "{}"
        }
    }

    /// 与 `AddRecordViewModel.save` 一致：预览与种子数据中新建金额类记录的推荐写法。
    static func makeMonetaryRecord(
        contact: Contact,
        event: Event? = nil,
        amount: Double,
        direction: RecordDirection = .given,
        paymentMethod: PaymentMethod = .cash,
        returnedAmount: Double = 0,
        note: String = "",
        date: Date = .now,
        relationshipWeight: RelationshipWeight = .reciprocal
    ) -> Record {
        let record = Record(
            contact: contact,
            event: event,
            direction: direction,
            note: note,
            date: date,
            recordType: .monetary,
            relationshipWeight: relationshipWeight
        )
        record.applyTypeData(.monetary(MonetaryData(
            amount: amount,
            paymentMethod: paymentMethod.rawValue,
            returnedAmount: returnedAmount
        )))
        return record
    }
}
