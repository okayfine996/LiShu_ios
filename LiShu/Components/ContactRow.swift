import SwiftUI

struct ContactRow: View {
    let avatar: Data?
    let name: String
    let relation: String
    let netValue: Double
    let relationshipHealth: RelationshipHealthResult?

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(imageData: avatar, name: name)
                .overlay(alignment: .bottomTrailing) {
                    if let relationshipHealth, relationshipHealth.hasRecords {
                        RelationshipHealthDot(result: relationshipHealth)
                    }
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .fontWeight(.semibold)

                Text(relation)
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }

            Spacer()

            Text(netValueText)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(netValueColor)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }

    private var netValueText: String {
        let prefix = netValue >= 0 ? "+" : ""
        return prefix + "¥" + String(format: "%.0f", netValue)
    }

    private var netValueColor: Color {
        netValue >= 0
            ? DesignSystem.Colors.accentGold
            : DesignSystem.Colors.primary
    }
}
