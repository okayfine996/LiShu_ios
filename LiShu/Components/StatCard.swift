import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    var valueColor: Color = DesignSystem.Colors.textPrimary

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(DesignSystem.Colors.primary)
                .frame(width: 36, height: 36)
                .background(DesignSystem.Colors.bgIconSubtle)
                .clipShape(Circle())

            Text(title)
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Text(value)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(valueColor)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(DesignSystem.Colors.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
    }
}
