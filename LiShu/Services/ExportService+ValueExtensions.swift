import Foundation

// MARK: - Export Value Extensions

extension RecordDirection {
    nonisolated var csvValue: String {
        switch self {
        case .given: String(localized: "record.direction.given")
        case .received: String(localized: "record.direction.received")
        }
    }
}

extension PaymentMethod {
    nonisolated var csvValue: String {
        switch self {
        case .cash: String(localized: "payment.cash")
        case .wechat: String(localized: "payment.wechat")
        case .alipay: String(localized: "payment.alipay")
        }
    }
}

extension RelationshipWeight {
    nonisolated var csvValue: String {
        displayName
    }
}
