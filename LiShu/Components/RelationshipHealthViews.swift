import SwiftUI

enum RelationshipHealthStyle {
    static func color(for level: RelationshipHealthLevel) -> Color {
        switch level {
        case .close:
            DesignSystem.Colors.accentGold
        case .stable:
            DesignSystem.Colors.primary
        case .distant:
            DesignSystem.Colors.textSecondary
        case .needsAttention:
            DesignSystem.Colors.destructive
        }
    }

    static func background(for level: RelationshipHealthLevel) -> Color {
        color(for: level).opacity(0.14)
    }
}

struct RelationshipHealthDot: View {
    let result: RelationshipHealthResult

    var body: some View {
        Circle()
            .fill(RelationshipHealthStyle.color(for: result.level))
            .frame(width: DesignSystem.Layout.healthDotSize, height: DesignSystem.Layout.healthDotSize)
            .overlay {
                Circle()
                    .stroke(DesignSystem.Colors.bgSurface, lineWidth: DesignSystem.Layout.healthDotStrokeWidth)
            }
            .accessibilityHidden(true)
    }
}

struct RelationshipHealthBadge: View {
    let result: RelationshipHealthResult
    let text: String

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.dense) {
            Circle()
                .fill(RelationshipHealthStyle.color(for: result.level))
                .frame(width: DesignSystem.Layout.healthBadgeDotSize, height: DesignSystem.Layout.healthBadgeDotSize)

            Text(text)
                .font(DesignSystem.Typography.small)
                .foregroundStyle(RelationshipHealthStyle.color(for: result.level))
        }
        .padding(.horizontal, DesignSystem.Spacing.badgePaddingH)
        .padding(.vertical, DesignSystem.Spacing.dense)
        .background(RelationshipHealthStyle.background(for: result.level))
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(text)
    }
}
