import SwiftUI

struct OnboardingView: View {
    @Environment(AppSettings.self) private var settings
    @State private var currentPage = 0

    private let totalPages = 4

    var body: some View {
        ZStack {
            DesignSystem.Colors.bgPage
                .ignoresSafeArea()

            VStack(spacing: 0) {
                if currentPage < totalPages - 1 {
                    skipButton
                }

                TabView(selection: $currentPage) {
                    page1.tag(0)
                    page2.tag(1)
                    page3.tag(2)
                    page4.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                pageIndicatorAndAction
            }
        }
    }

    // MARK: - Skip Button

    private var skipButton: some View {
        HStack {
            Spacer()
            Button(String(localized: "onboarding.skip")) {
                completeOnboarding()
            }
            .font(DesignSystem.Typography.caption)
            .foregroundStyle(DesignSystem.Colors.textSecondary)
            .padding(.trailing, 20)
            .padding(.top, 8)
        }
    }

    // MARK: - Page 1: 记人情，懂礼数

    private var page1: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.bgCard)
                    .frame(width: 200, height: 200)

                Image(systemName: "gift.fill")
                    .font(.system(size: 56))
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

            Spacer().frame(height: 48)

            VStack(spacing: 12) {
                Text(String(localized: "onboarding.page1.title"))
                    .font(DesignSystem.Typography.title2)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .fontWeight(.bold)

                Text(String(localized: "onboarding.page1.subtitle"))
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()
        }
    }

    // MARK: - Page 2: 三件事，帮你记清楚

    private var page2: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.bgCard)
                    .frame(width: 160, height: 160)

                VStack(spacing: -8) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(DesignSystem.Colors.textTertiary.opacity(0.5))
                        .rotationEffect(.degrees(-10))
                        .offset(x: -10)

                    Image(systemName: "magnifyingglass.circle.fill")
                        .font(.system(size: 40))
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
                featureRow(
                    icon: "tray.and.arrow.down.fill",
                    text: String(localized: "onboarding.page2.feature1")
                )
                featureRow(
                    icon: "tray.and.arrow.up.fill",
                    text: String(localized: "onboarding.page2.feature2")
                )
                featureRow(
                    icon: "calendar.badge.clock",
                    text: String(localized: "onboarding.page2.feature3")
                )
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
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

    // MARK: - Page 3: 一份记录，长久陪伴

    private var page3: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.bgCard)
                    .frame(width: 200, height: 200)

                ZStack {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(DesignSystem.Colors.primary.opacity(0.15))
                        .rotationEffect(.degrees(-30))
                        .offset(x: -25, y: 20)

                    Image(systemName: "leaf.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(DesignSystem.Colors.primary.opacity(0.15))
                        .rotationEffect(.degrees(30))
                        .offset(x: 25, y: 20)

                    Image(systemName: "yensign.circle")
                        .font(.system(size: 64, weight: .light))
                        .foregroundStyle(DesignSystem.Colors.primary)

                    Circle()
                        .stroke(DesignSystem.Colors.primary.opacity(0.4), lineWidth: 3)
                        .frame(width: 90, height: 90)
                }
            }

            Spacer().frame(height: 48)

            VStack(spacing: 16) {
                Text(String(localized: "onboarding.page3.title"))
                    .font(DesignSystem.Typography.title2)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(String(localized: "onboarding.page3.subtitle"))
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()
        }
    }

    // MARK: - Page 4: 不仅是账本，更是情感的纽带

    private var page4: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.bgCard)
                    .frame(width: 200, height: 200)

                VStack(spacing: 0) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(DesignSystem.Colors.primary)
                }

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
                valueCard(
                    icon: "heart.fill",
                    label: String(localized: "onboarding.page4.value1")
                )
                valueCard(
                    icon: "point.3.connected.trianglepath.dotted",
                    label: String(localized: "onboarding.page4.value2")
                )
                valueCard(
                    icon: "hourglass",
                    label: String(localized: "onboarding.page4.value3")
                )
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }

    private func valueCard(icon: String, label: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 24))
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

    // MARK: - Page Indicator & Action

    private var pageIndicatorAndAction: some View {
        VStack(spacing: 20) {
            HStack(spacing: 8) {
                ForEach(0..<totalPages, id: \.self) { index in
                    Circle()
                        .fill(
                            index == currentPage
                                ? DesignSystem.Colors.primary
                                : DesignSystem.Colors.textTertiary.opacity(0.3)
                        )
                        .frame(width: 8, height: 8)
                }
            }

            if currentPage == totalPages - 1 {
                Button {
                    completeOnboarding()
                } label: {
                    Text(String(localized: "onboarding.start"))
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 32)
            } else {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentPage += 1
                    }
                } label: {
                    Text(String(localized: "onboarding.next"))
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                        .fontWeight(.medium)
                }
            }
        }
        .padding(.bottom, 40)
    }

    // MARK: - Actions

    private func completeOnboarding() {
        settings.hasSeenOnboarding = true
    }
}

#Preview {
    OnboardingView()
        .environment(AppSettings.shared)
}
