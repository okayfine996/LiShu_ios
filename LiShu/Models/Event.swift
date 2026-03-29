import Foundation
import SwiftData

/// 事件（如婚礼、生日、满月酒等）
@Model
final class Event {
    /// 事件名称
    var name: String = ""
    /// 事件类型原始值，通过 `type` 计算属性读写枚举
    var typeRaw: String = "other"
    /// 事件日期
    var date: Date = Date()
    /// 事件地点
    var location: String = ""
    /// 备注
    var note: String = ""
    /// 事件封面图片，外部存储以支持 iCloud 同步
    @Attribute(.externalStorage)
    var coverImage: Data?
    /// 关联的往来记录，有记录时禁止删除事件（应用层检查）
    @Relationship(deleteRule: .nullify, inverse: \Record.event)
    var records: [Record]?
    /// 创建时间
    var createdAt: Date = Date()

    /// 事件类型枚举
    var type: EventType {
        get { EventType(rawValue: typeRaw) ?? .other }
        set { typeRaw = newValue.rawValue }
    }

    init(
        name: String,
        type: EventType = .other,
        date: Date = .now,
        location: String = "",
        note: String = ""
    ) {
        self.name = name
        self.typeRaw = type.rawValue
        self.date = date
        self.location = location
        self.note = note
        self.createdAt = .now
    }
}

/// 事件类型
enum EventType: String, Codable, CaseIterable {
    /// 婚礼
    case wedding = "wedding"
    /// 订婚
    case engagement = "engagement"
    /// 丧事
    case funeral = "funeral"
    /// 满月/新生儿
    case birth = "birth"
    /// 生日
    case birthday = "birthday"
    /// 寿宴
    case longevity = "longevity"
    /// 节日
    case festival = "festival"
    /// 乔迁
    case property = "property"
    /// 升学/毕业
    case education = "education"
    /// 开业
    case business = "business"
    /// 升职/晋升
    case promotion = "promotion"
    /// 探望/慰问
    case visit = "visit"
    /// 其他
    case other = "other"
}
