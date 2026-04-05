import Foundation

extension Calendar {
    /// 由年/月/日构造日期，用于预览与示例数据；无效时回退到 `Date.now`。
    func liShuDate(year: Int, month: Int, day: Int) -> Date {
        date(from: DateComponents(year: year, month: month, day: day)) ?? .now
    }

    /// 预览/夹具用：`date(byAdding: .day, …)` 无强制解包。
    func liShuDateByAddingDays(_ days: Int, to base: Date = .now) -> Date {
        date(byAdding: .day, value: days, to: base) ?? base
    }

    /// 预览/夹具用：`date(byAdding: .month, …)` 无强制解包。
    func liShuDateByAddingMonths(_ months: Int, to base: Date = .now) -> Date {
        date(byAdding: .month, value: months, to: base) ?? base
    }
}
