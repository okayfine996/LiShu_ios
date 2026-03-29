import SwiftUI

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                updateDate
                mainContent
                footer
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .background(DesignSystem.Colors.bgPage)
        .navigationTitle(String(localized: "settings.about.terms"))
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Update date

    private var updateDate: some View {
        Text(String(localized: "terms.updateDate"))
            .font(DesignSystem.Typography.small)
            .foregroundStyle(DesignSystem.Colors.textTertiary)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.bottom, 12)
    }

    // MARK: - Main content card

    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(String(localized: "terms.fullTitle"))
                .font(DesignSystem.Typography.title2)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Text(String(localized: "terms.intro"))
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .lineSpacing(6)

            Divider().background(DesignSystem.Colors.separator)

            numberedSection(
                number: "一",
                title: String(localized: "terms.section.scope"),
                content: String(localized: "terms.section.scope.content")
            )

            numberedSection(
                number: "二",
                title: String(localized: "terms.section.usage"),
                content: String(localized: "terms.section.usage.content")
            )

            numberedSection(
                number: "三",
                title: String(localized: "terms.section.privacy"),
                content: String(localized: "terms.section.privacy.content")
            )

            numberedSection(
                number: "四",
                title: String(localized: "terms.section.ip"),
                content: String(localized: "terms.section.ip.content")
            )

            numberedSection(
                number: "五",
                title: String(localized: "terms.section.disclaimer"),
                content: String(localized: "terms.section.disclaimer.content")
            )

            numberedSection(
                number: "六",
                title: String(localized: "terms.section.liability"),
                content: String(localized: "terms.section.liability.content")
            )

            numberedSection(
                number: "七",
                title: String(localized: "terms.section.dataSecurity"),
                content: String(localized: "terms.section.dataSecurity.content")
            )

            numberedSection(
                number: "八",
                title: String(localized: "terms.section.subscription"),
                content: String(localized: "terms.section.subscription.content")
            )

            numberedSection(
                number: "九",
                title: String(localized: "terms.section.changes"),
                content: String(localized: "terms.section.changes.content")
            )

            numberedSection(
                number: "十",
                title: String(localized: "terms.section.termination"),
                content: String(localized: "terms.section.termination.content")
            )

            numberedSection(
                number: "十一",
                title: String(localized: "terms.section.other"),
                content: String(localized: "terms.section.other.content")
            )
        }
        .padding(20)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
    }

    // MARK: - Footer

    private var footer: some View {
        Text(String(localized: "terms.footer"))
            .font(DesignSystem.Typography.small)
            .foregroundStyle(DesignSystem.Colors.textTertiary)
            .frame(maxWidth: .infinity)
            .padding(.top, 24)
    }

    // MARK: - Helpers

    private func numberedSection(number: String, title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(number)、\(title)")
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Text(content)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .lineSpacing(6)
        }
    }
}

#Preview {
    NavigationStack {
        TermsOfServiceView()
    }
}
