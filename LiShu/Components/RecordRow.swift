import SwiftUI
import SwiftData

struct RecordRow: View {
    let avatar: Data?
    let contactName: String
    let eventName: String
    let amount: Double
    let direction: RecordDirection
    let date: Date

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(imageData: avatar, name: contactName, size: 48)

            VStack(alignment: .leading, spacing: 3) {
                Text(contactName)
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Text(eventName)
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                Text(dateText)
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }

            Spacer()

            Text(amountText)
                .font(DesignSystem.Typography.body)
                .fontWeight(.semibold)
                .foregroundStyle(amountColor)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }

    private var amountText: String {
        let prefix = direction == .received ? "+ " : "- "
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        let formatted = formatter.string(from: NSNumber(value: amount)) ?? String(format: "%.0f", amount)
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
}
