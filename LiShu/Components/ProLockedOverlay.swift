import SwiftUI

struct ProLockedOverlay: View {
    let isLocked: Bool
    let onTap: () -> Void

    var body: some View {
        if isLocked {
            ZStack {
                RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                    .fill(.ultraThinMaterial)

                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(DesignSystem.Colors.primary.opacity(0.12))
                            .frame(width: 52, height: 52)

                        Image(systemName: "lock.fill")
                            .font(DesignSystem.Typography.title3)
                            .foregroundStyle(DesignSystem.Colors.primary)
                    }

                    VStack(spacing: 4) {
                        Text(String(localized: "pro.unlock.hint"))
                            .font(DesignSystem.Typography.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)

                        Text(String(localized: "pro.unlock.subtitle"))
                            .font(DesignSystem.Typography.small)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }

                    Text(String(localized: "pro.unlock.button"))
                        .font(DesignSystem.Typography.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(DesignSystem.Colors.textOnPrimary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(DesignSystem.Colors.primary)
                        .clipShape(Capsule())
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { onTap() }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        Text(String(localized: "preview.proLockedContent"))
            .frame(maxWidth: .infinity)
            .frame(height: 220)
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
            .overlay {
                ProLockedOverlay(isLocked: true) {}
            }
    }
    .padding()
    .background(DesignSystem.Colors.bgPage)
}
