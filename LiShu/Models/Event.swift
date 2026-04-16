import Foundation
import SwiftData

/// 事件（如婚礼、生日、满月酒等）
@Model
final class Event {
    /// 事件名称
    var name: String = ""
    /// 事件类型原始值，通过 `type` 计算属性读写枚举
    var typeRaw: String = "other"
    /// 事件身份原始值，通过 `hostMode` 计算属性读写枚举
    var hostModeRaw: String = "guest"
    /// 事件日期
    var date: Date = Date()
    /// 事件地点
    var location: String = ""
    /// 备注
    var note: String = ""
    /// 事件封面图片，外部存储以支持 iCloud 同步
    @Attribute(.externalStorage)
    var coverImage: Data?
    /// 关联的往来记录，删除事件时级联删除其关联记录
    @Relationship(deleteRule: .cascade, inverse: \Record.event)
    var records: [Record]?
    /// 创建时间
    var createdAt: Date = Date()

    /// 事件类型枚举
    var type: EventType {
        get { EventType(rawValue: typeRaw) ?? .other }
        set { typeRaw = newValue.rawValue }
    }

    /// 是否为主场礼簿事件
    var hostMode: EventHostMode {
        get { EventHostMode(rawValue: hostModeRaw) ?? .guest }
        set { hostModeRaw = newValue.rawValue }
    }

    init(
        name: String,
        type: EventType = .other,
        hostMode: EventHostMode = .guest,
        date: Date = .now,
        location: String = "",
        note: String = ""
    ) {
        self.name = name
        typeRaw = type.rawValue
        hostModeRaw = hostMode.rawValue
        self.date = date
        self.location = location
        self.note = note
        createdAt = .now
    }
}

enum EventHostMode: String, Codable, CaseIterable {
    case guest
    case host

    nonisolated var displayName: String {
        switch self {
        case .guest: String(localized: "event.hostMode.guest")
        case .host: String(localized: "event.hostMode.host")
        }
    }
}

/// 事件类型
enum EventType: String, Codable, CaseIterable {
    /// 婚礼
    case wedding
    /// 订婚
    case engagement
    /// 丧事
    case funeral
    /// 满月/新生儿
    case birth
    /// 生日
    case birthday
    /// 寿宴
    case longevity
    /// 节日
    case festival
    /// 乔迁
    case property
    /// 升学/毕业
    case education
    /// 开业
    case business
    /// 升职/晋升
    case promotion
    /// 探望/慰问
    case visit
    /// 其他
    case other

    nonisolated var importExportName: String {
        switch self {
        case .wedding: String(localized: "event.type.wedding")
        case .engagement: String(localized: "event.type.engagement")
        case .funeral: String(localized: "event.type.funeral")
        case .birth: String(localized: "event.type.birth")
        case .birthday: String(localized: "event.type.birthday")
        case .longevity: String(localized: "event.type.longevity")
        case .festival: String(localized: "event.type.festival")
        case .property: String(localized: "event.type.property")
        case .education: String(localized: "event.type.education")
        case .business: String(localized: "event.type.business")
        case .promotion: String(localized: "event.type.promotion")
        case .visit: String(localized: "event.type.visit")
        case .other: String(localized: "event.type.other")
        }
    }
}
