import Foundation

extension Optional where Wrapped == Date {
    /// `Calendar` 在有效分量下通常能构造出日期；若失败则回退到当前时间，避免强制解包。
    var unwrappedOrNow: Date {
        self ?? .now
    }
}
