import SwiftUI

struct OnboardingWelcomePage: View {
    var body: some View {
        OnboardingIllustrationPage(
            illustration: {
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.bgCard)
                        .frame(width: 200, height: 200)

                    Image(systemName: "gift.fill")
                        .font(DesignSystem.Typography.title1)
                        .fontWeight(.bold)
                        .foregroundStyle(DesignSystem.Colors.primary)

                    Circle()
                        .fill(DesignSystem.Colors.primary.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .offset(x: 100, y: -60)

                    Circle()
                        .fill(DesignSystem.Colors.textTertiary.opacity(0.4))
                        .frame(width: 10, height: 10)
                        .offset(x: -80, y: 70)
                }
            },
            spacingAfterIllustration: 48,
            title: String(localized: "onboarding.page1.title"),
            subtitle: String(localized: "onboarding.page1.subtitle")
        )
    }
}

struct OnboardingFeaturesPage: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.bgCard)
                    .frame(width: 160, height: 160)

                VStack(spacing: -8) {
                    Image(systemName: "doc.text.fill")
                        .font(DesignSystem.Typography.title1)
                        .foregroundStyle(DesignSystem.Colors.textTertiary.opacity(0.5))
                        .rotationEffect(.degrees(-10))
                        .offset(x: -10)

                    Image(systemName: "magnifyingglass.circle.fill")
                        .font(DesignSystem.Typography.title2)
                        .foregroundStyle(DesignSystem.Colors.primary)
                        .offset(x: 25, y: -10)
                }
            }

            Spacer().frame(height: 36)

            Text(String(localized: "onboarding.page2.title"))
                .font(DesignSystem.Typography.title2)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .fontWeight(.bold)

            Spacer().frame(height: 24)

            VStack(spacing: 10) {
                OnboardingFeatureRow(
                    icon: "tray.and.arrow.down.fill",
                    text: String(localized: "onboarding.page2.feature1")
                )
                OnboardingFeatureRow(
                    icon: "tray.and.arrow.up.fill",
                    text: String(localized: "onboarding.page2.feature2")
                )
                OnboardingFeatureRow(
                    icon: "calendar.badge.clock",
                    text: String(localized: "onboarding.page2.feature3")
                )
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }
}

private struct OnboardingFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.primary)
                .frame(width: 40, height: 40)
                .background(DesignSystem.Colors.primary.opacity(0.1))
                .clipShape(Circle())

            Text(text)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .fontWeight(.medium)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
    }
}

struct OnboardingValuePage: View {
    var body: some View {
        OnboardingIllustrationPage(
            illustration: {
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.bgCard)
                        .frame(width: 200, height: 200)

                    ZStack {
                        Image(systemName: "leaf.fill")
                            .font(DesignSystem.Typography.title1)
                            .foregroundStyle(DesignSystem.Colors.primary.opacity(0.15))
                            .rotationEffect(.degrees(-30))
                            .offset(x: -25, y: 20)

                        Image(systemName: "leaf.fill")
                            .font(DesignSystem.Typography.title1)
                            .foregroundStyle(DesignSystem.Colors.primary.opacity(0.15))
                            .rotationEffect(.degrees(30))
                            .offset(x: 25, y: 20)

                        Image(systemName: "yensign.circle")
                            .font(DesignSystem.Typography.title1)
                            .fontWeight(.light)
                            .foregroundStyle(DesignSystem.Colors.primary)

                        Circle()
                            .stroke(DesignSystem.Colors.primary.opacity(0.4), lineWidth: 3)
                            .frame(width: 90, height: 90)
                    }
                }
            },
            spacingAfterIllustration: 48,
            title: String(localized: "onboarding.page3.title"),
            subtitle: String(localized: "onboarding.page3.subtitle")
        )
    }
}

struct OnboardingRelationshipPage: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.bgCard)
                    .frame(width: 200, height: 200)

                Image(systemName: "person.3.fill")
                    .font(DesignSystem.Typography.title1)
                    .fontWeight(.bold)
                    .foregroundStyle(DesignSystem.Colors.primary)

                Circle()
                    .fill(DesignSystem.Colors.primary.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .offset(x: 90, y: -70)

                Circle()
                    .fill(DesignSystem.Colors.textTertiary.opacity(0.4))
                    .frame(width: 10, height: 10)
                    .offset(x: -95, y: 20)
            }

            Spacer().frame(height: 36)

            Text(String(localized: "onboarding.page4.title"))
                .font(DesignSystem.Typography.title2)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer().frame(height: 24)

            HStack(spacing: 16) {
                OnboardingValueCard(icon: "heart.fill", label: String(localized: "onboarding.page4.value1"))
                OnboardingValueCard(
                    icon: "point.3.connected.trianglepath.dotted",
                    label: String(localized: "onboarding.page4.value2")
                )
                OnboardingValueCard(icon: "hourglass", label: String(localized: "onboarding.page4.value3"))
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }
}

private struct OnboardingValueCard: View {
    let icon: String
    let label: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.primary)

            Text(label)
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
    }
}
