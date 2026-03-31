import SwiftUI
import SwiftData

struct RecordRow: View {
    let avatar: Data?
    let contactName: String
    let eventName: String
    let amount: Double
    let direction: RecordDirection
    let date: Date
    var recordType: RecordType = .monetary
    var favorDescription: String = ""
    var paymentMethodRaw: String = "cash"
    var kvData: String = "{}"
    var contextTag: String = ""

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(imageData: avatar, name: contactName, size: 48)

            VStack(alignment: .leading, spacing: 3) {
                Text(contactName)
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Text(contextName)
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                Text(dateText)
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }

            Spacer()

            if recordType.isMonetary {
                Text(amountText)
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(amountColor)
            } else {
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(recordType.iconEmoji)
                            .font(DesignSystem.Typography.caption)
                        Text(displayDescription)
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .frame(maxWidth: 140, alignment: .trailing)
                    if resolvedAmount > 0 {
                        Text(amountText)
                            .font(DesignSystem.Typography.small)
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }

    private var resolvedTypeData: RecordTypeData {
        guard let data = kvData.data(using: .utf8) else {
            return legacyTypeData
        }

        let decoder = JSONDecoder()
        switch recordType {
        case .monetary:
            return (try? decoder.decode(MonetaryData.self, from: data)).map { .monetary($0) } ?? legacyTypeData
        case .gift:
            return (try? decoder.decode(GiftData.self, from: data)).map { .gift($0) } ?? legacyTypeData
        case .favor:
            return (try? decoder.decode(FavorData.self, from: data)).map { .favor($0) } ?? legacyTypeData
        case .banquet:
            return (try? decoder.decode(BanquetData.self, from: data)).map { .banquet($0) } ?? legacyTypeData
        }
    }

    private var legacyTypeData: RecordTypeData {
        switch recordType {
        case .monetary:
            return .monetary(MonetaryData(amount: amount, paymentMethod: paymentMethodRaw))
        case .gift:
            return .gift(GiftData(giftName: favorDescription, estimatedValue: amount > 0 ? amount : nil))
        case .favor:
            return .favor(FavorData(description: favorDescription))
        case .banquet:
            return .banquet(BanquetData(location: favorDescription))
        }
    }

    private var displayDescription: String {
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

    private var resolvedAmount: Double {
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

    private var amountText: String {
        let prefix = direction == .received ? "+ " : "- "
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        let formatted = formatter.string(from: NSNumber(value: resolvedAmount)) ?? String(format: "%.0f", resolvedAmount)
        return prefix + "¥" + formatted
    }

    private var amountColor: Color {
        direction == .received
            ? DesignSystem.Colors.accentGold
            : DesignSystem.Colors.primary
    }

    private var dateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }

    private var contextName: String {
        if !eventName.isEmpty { return eventName }
        if !contextTag.isEmpty { return contextTag }
        return String(localized: "record.context.daily")
    }
}
