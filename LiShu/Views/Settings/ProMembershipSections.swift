import SwiftUI

struct ProMembershipHeroCard: View {
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(DesignSystem.Colors.accentGold)
                        .font(DesignSystem.Typography.caption)
                    Text("PRO MEMBER")
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.accentGold)
                        .fontWeight(.semibold)
                        .tracking(1)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "pro.title"))
                        .font(DesignSystem.Typography.title1)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                        .fontWeight(.bold)

                    Text(String(localized: "pro.heroSubtitle"))
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)

            Image(systemName: "crown.fill")
                .font(.system(size: 90))
                .foregroundStyle(DesignSystem.Colors.textPrimary.opacity(0.05))
                .padding(.trailing, 16)
                .padding(.bottom, 8)
        }
        .background(
            LinearGradient(
                colors: [DesignSystem.Colors.proGradientStart, DesignSystem.Colors.proGradientEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                .stroke(DesignSystem.Colors.accentGold.opacity(0.2), lineWidth: 1)
        )
    }
}

struct ProMembershipFeaturesSection: View {
    let isUnlocked: Bool

    private var features: [ProMembershipFeature] {
        [
            .init(
                icon: "infinity",
                title: String(localized: "pro.feature.unlimited"),
                subtitle: String(localized: "pro.feature.unlimited.desc")
            ),
            .init(
                icon: "chart.bar.fill",
                title: String(localized: "pro.feature.stats"),
                subtitle: String(localized: "pro.feature.stats.desc")
            ),
            .init(
                icon: "arrow.up.arrow.down.circle.fill",
                title: String(localized: "pro.feature.export"),
                subtitle: String(localized: "pro.feature.export.desc")
            ),
            .init(
                icon: "doc.viewfinder",
                title: String(localized: "pro.feature.ocr"),
                subtitle: String(localized: "pro.feature.ocr.desc")
            ),
            .init(
                icon: "icloud.fill",
                title: String(localized: "pro.feature.sync"),
                subtitle: String(localized: "pro.feature.sync.desc")
            ),
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "pro.features.title"))
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            VStack(spacing: 0) {
                ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                    ProMembershipFeatureRow(feature: feature, isUnlocked: isUnlocked)

                    if index < features.count - 1 {
                        Divider()
                            .foregroundStyle(DesignSystem.Colors.separator)
                            .padding(.leading, 56)
                    }
                }
            }
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        }
    }
}

struct ProMembershipActiveSubscriptionCard: View {
    let planName: String?
    let onDebugClearPurchases: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 48))
                .foregroundStyle(DesignSystem.Colors.accentGold)

            Text(String(localized: "pro.status.active"))
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            if let planName {
                Text(planName)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }

            #if DEBUG
                if let onDebugClearPurchases {
                    Button(String(localized: "DEBUG: 清除购买状态"), action: onDebugClearPurchases)
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(.red)
                        .padding(.top, 8)
                }
            #endif
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
    }
}

struct ProMembershipTermsFooter: View {
    var body: some View {
        VStack(spacing: 8) {
            VStack(spacing: 4) {
                Text(String(localized: "pro.terms.payment"))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                    .multilineTextAlignment(.center)

                Text(String(localized: "pro.terms.autoRenew"))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                    .multilineTextAlignment(.center)

                Text(String(localized: "pro.terms.manage"))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 16)

            HStack(spacing: 12) {
                NavigationLink {
                    PrivacyPolicyView()
                } label: {
                    Text(String(localized: "pro.terms.privacy"))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .contentShape(Rectangle())
                }

                Text("·")
                    .foregroundStyle(DesignSystem.Colors.textTertiary)

                NavigationLink {
                    TermsOfServiceView()
                } label: {
                    Text(String(localized: "pro.terms.terms"))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .contentShape(Rectangle())
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ProMembershipFeatureRow: View {
    let feature: ProMembershipFeature
    let isUnlocked: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: feature.icon)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.accentGold)
                .frame(width: 36, height: 36)
                .background(DesignSystem.Colors.accentGold.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(feature.title)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .fontWeight(.medium)

                Text(feature.subtitle)
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }

            Spacer()

            Image(systemName: isUnlocked ? "checkmark.circle.fill" : "lock.fill")
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.accentGold)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

private struct ProMembershipFeature {
    let icon: String
    let title: String
    let subtitle: String
}
