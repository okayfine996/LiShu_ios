import Foundation

/// 共享 `DateFormatter`，避免在列表/分组等热路径重复创建。
enum DateFormatters {
    /// 按当前 locale 的月+日（用于记录列表行等短日期）。
    static let monthDayCurrentLocale: DateFormatter = {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("Md")
        f.locale = .current
        return f
    }()

    /// 记录列表按月分组 key（与 `RecordListViewModel` 一致，中文环境「yyyy年M月」）。
    static let recordListMonthKey: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_Hans")
        f.dateFormat = "yyyy年M月"
        return f
    }()
}
