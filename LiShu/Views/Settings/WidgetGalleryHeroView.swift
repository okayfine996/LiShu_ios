import SwiftUI

struct WidgetGalleryHeroView: View {
    let snapshot: WidgetSnapshot
    @Environment(\.colorScheme) private var colorScheme

    private var heroHeadline: some View {
        (Text(String(localized: "widget.gallery.hero.headline")).foregroundStyle(DesignSystem.Colors.textPrimary)
            + Text(String(localized: "widget.gallery.hero.emphasis")).foregroundStyle(DesignSystem.Colors.primary))
            .font(DesignSystem.Typography.title2)
            .kerning(-0.5)
            .padding(.top, 10)
    }

    // MARK: - Hero card

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                if colorScheme == .dark {
                    LinearGradient(
                        colors: [DesignSystem.Colors.widgetGalleryStageStart,
                                 DesignSystem.Colors.widgetGalleryStageMid,
                                 DesignSystem.Colors.widgetGalleryStageEnd],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                } else {
                    LinearGradient(
                        colors: [DesignSystem.Colors.widgetGalleryStageStart,
                                 DesignSystem.Colors.widgetGalleryStageMid,
                                 DesignSystem.Colors.widgetGalleryStageEnd],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                }
                Circle()
                    .fill(DesignSystem.Colors.primary)
                    .opacity(0.50)
                    .blur(radius: 40)
                    .frame(width: 200)
                    .offset(x: 80, y: -40)
                Circle()
                    .fill(DesignSystem.Colors.accentGold)
                    .opacity(0.40)
                    .blur(radius: 40)
                    .frame(width: 180)
                    .offset(x: -30, y: 60)

                HStack(alignment: .center, spacing: 14) {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 5) {
                            LiShuGalleryMark()
                            Text(String(localized: "widget.displayName") + " · Widget")
                                .font(DesignSystem.Typography.widgetTinyBold)
                                .kerning(0.8)
                                .textCase(.uppercase)
                                .foregroundStyle(colorScheme == .dark ? DesignSystem.Colors.bgCard : DesignSystem.Colors
                                    .primary)
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(colorScheme == .dark ? DesignSystem.Colors.primary.opacity(0.30) : DesignSystem.Colors.textOnPrimary
                                    .opacity(0.55))
                                .overlay(Capsule().strokeBorder(
                                    DesignSystem.Colors.primary.opacity(colorScheme == .dark ? 0.40 : 0.30),
                                    lineWidth: 0.5
                                ))
                        )

                        heroHeadline

                        Text(String(localized: "widget.gallery.hero.subtitle"))
                            .font(DesignSystem.Typography.widgetBody)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                            .lineSpacing(4)
                            .padding(.top, 8)
                    }
                    Spacer(minLength: 0)
                    GallerySmallStub(snapshot: snapshot, variant: .reminder)
                        .frame(width: 158, height: 158)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .allowsHitTesting(false)
                        .rotationEffect(.degrees(-5))
                        .offset(y: -4)
                        .shadow(color: DesignSystem.Colors.bgCard.opacity(0.30), radius: 24, x: 0, y: 18)
                }
                .padding(22)
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(
                        colorScheme == .dark ? DesignSystem.Colors.textOnPrimary.opacity(0.08) : DesignSystem.Colors.textOnPrimary
                            .opacity(0.6),
                        lineWidth: 0.5
                    )
            )
            .shadow(color: DesignSystem.Colors.primary.opacity(0.20), radius: 28, x: 0, y: 12)
        }
        .padding(.horizontal, 16)
        .padding(.top, 18)
        .padding(.bottom, 8)
    }
}

#Preview("Widget Gallery Hero") {
    WidgetGalleryHeroView(snapshot: .galleryPreview)
}
