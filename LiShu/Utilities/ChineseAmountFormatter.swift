import Foundation

enum ChineseAmountFormatter {
    private static let digits = ["零", "壹", "贰", "叁", "肆", "伍", "陆", "柒", "捌", "玖"]
    private static let units = ["", "拾", "佰", "仟"]
    private static let bigUnits = ["", "万", "亿"]

    /// 将金额转为中文大写，如 200 → "贰佰元整"，1234.56 → "壹仟贰佰叁拾肆元伍角陆分"
    static func chineseUppercase(_ amount: Double) -> String {
        guard amount > 0, amount < 1_000_000_000_000 else { return "" }

        let rounded = (amount * 100).rounded() / 100
        let integerPart = Int(rounded)
        let decimalPart = Int(((rounded - Double(integerPart)) * 100).rounded())

        let jiao = decimalPart / 10
        let fen = decimalPart % 10

        var result = ""

        if integerPart > 0 {
            result = convertInteger(integerPart) + "元"
            if jiao == 0 && fen == 0 {
                result += "整"
            } else {
                if jiao > 0 {
                    result += digits[jiao] + "角"
                } else {
                    result += "零"
                }
                if fen > 0 {
                    result += digits[fen] + "分"
                }
            }
        } else {
            if jiao > 0 {
                result = digits[jiao] + "角"
                if fen > 0 {
                    result += digits[fen] + "分"
                }
            } else if fen > 0 {
                result = digits[fen] + "分"
            }
        }

        return result
    }

    private static func convertInteger(_ num: Int) -> String {
        guard num > 0 else { return digits[0] }

        var remaining = num
        var parts: [String] = []
        var groupIndex = 0

        while remaining > 0 {
            let group = remaining % 10000
            remaining /= 10000

            let groupStr = convertGroup(group)
            if groupIndex > 0 && group > 0 {
                var part = groupStr + bigUnits[groupIndex]
                if group < 1000 && remaining > 0 {
                    part = "零" + part
                }
                parts.insert(part, at: 0)
            } else if group > 0 {
                parts.insert(groupStr, at: 0)
            } else if !parts.isEmpty {
                // group is 0, but higher groups exist — need "零" prefix handled by next group
            }

            groupIndex += 1
        }

        return parts.joined()
    }

    private static func convertGroup(_ num: Int) -> String {
        guard num > 0 else { return "" }

        var result = ""
        var remaining = num
        var zeroFlag = false

        for i in stride(from: 3, through: 0, by: -1) {
            let divisor = Int(pow(10.0, Double(i)))
            let digit = remaining / divisor
            remaining %= divisor

            if digit > 0 {
                if zeroFlag {
                    result += "零"
                    zeroFlag = false
                }
                result += digits[digit] + units[i]
            } else if !result.isEmpty {
                zeroFlag = true
            }
        }

        return result
    }
}
