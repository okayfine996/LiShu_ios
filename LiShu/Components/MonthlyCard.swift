import SwiftUI

struct MonthlyCard: View {
    let month: Int
    let income: Double
    let expense: Double

    var body: some View {
        VStack(spacing: 8) {
            Text("\(month)" + String(localized: "statistics.month"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .fontWeight(.semibold)

            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 10))
                        .foregroundStyle(DesignSystem.Colors.accentGold)
                    Text("¥" + String(format: "%.0f", income))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.accentGold)
                }

                HStack(spacing: 4) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 10))
                        .foregroundStyle(DesignSystem.Colors.primary)
                    Text("¥" + String(format: "%.0f", expense))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.primary)
                }
            }
        }
        .frame(width: 90)
        .padding(.vertical, 12)
        .background(DesignSystem.Colors.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
    }
}
