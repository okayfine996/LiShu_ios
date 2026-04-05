import Foundation
import SwiftData

/// 记录附属照片（如婚礼留念、宴席现场等）
@Model
final class RecordPhoto {
    /// 所属记录
    var record: Record?
    /// 图片数据，外部存储以支持 iCloud 同步
    @Attribute(.externalStorage)
    var imageData: Data = Data()
    /// 创建时间
    var createdAt: Date = Date()

    init(record: Record, imageData: Data) {
        self.record = record
        self.imageData = imageData
        createdAt = .now
    }
}
