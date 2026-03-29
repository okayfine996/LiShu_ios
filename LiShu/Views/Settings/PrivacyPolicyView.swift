import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var policy: PrivacyPolicyContent? = PrivacyPolicyContent.load()

    var body: some View {
        ScrollView(showsIndicators: false) {
            if let policy {
                VStack(alignment: .leading, spacing: 20) {
                    heroSection
                    introSection(policy.intro)
                    ForEach(Array(policy.sections.enumerated()), id: \.offset) { index, section in
                        sectionCard(index: index + 1, section: section)
                    }
                    footerSection(policy)
                }
                .padding(.bottom, 80)
            } else {
                loadFailedView
            }
        }
        .background(DesignSystem.Colors.bgPage)
        .navigationTitle(String(localized: "settings.about.privacy"))
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(String(localized: "privacy.heroTitle"))
                .font(DesignSystem.Typography.title1)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: - Intro

    private func introSection(_ intro: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.textOnPrimary)
                    .frame(width: 28, height: 28)
                    .background(DesignSystem.Colors.primary)
                    .clipShape(Circle())

                Text(String(localized: "privacy.introBadge"))
                    .font(DesignSystem.Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(DesignSystem.Colors.primary)
            }

            Text(intro)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .background(DesignSystem.Colors.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        .padding(.horizontal, 16)
    }

    // MARK: - Section Card

    private func sectionCard(index: Int, section: PrivacyPolicyContent.PolicySection) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Text("\(index)")
                    .font(DesignSystem.Typography.small)
                    .fontWeight(.bold)
                    .foregroundStyle(DesignSystem.Colors.textOnPrimary)
                    .frame(width: 24, height: 24)
                    .background(DesignSystem.Colors.primary)
                    .clipShape(Circle())

                Text(section.title)
                    .font(DesignSystem.Typography.title3)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
            }

            Rectangle()
                .fill(DesignSystem.Colors.separator)
                .frame(height: 1)

            Text(section.content)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .background(DesignSystem.Colors.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        .padding(.horizontal, 16)
    }

    // MARK: - Footer

    private func footerSection(_ policy: PrivacyPolicyContent) -> some View {
        VStack(spacing: 4) {
            Text(policy.updateDate)
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textTertiary)

        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: - Load Failed

    private var loadFailedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(DesignSystem.Colors.textTertiary)

            Text(String(localized: "privacy.loadFailed"))
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 120)
    }
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}
