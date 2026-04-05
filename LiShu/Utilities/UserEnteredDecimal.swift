import Foundation

/// 用户输入或粘贴的金额字符串解析（去空白、千分位逗号）。
enum UserEnteredDecimal {
    static func parse(_ string: String) -> Double? {
        let cleaned = string
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "，", with: "")
        guard !cleaned.isEmpty else { return nil }
        return Double(cleaned)
    }
}
