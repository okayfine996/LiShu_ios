import SwiftUI

struct WidgetGalleryHeroView: View {
    let snapshot: WidgetSnapshot
    @Environment(\.colorScheme) private var colorScheme

    @ViewBuilder
    private var heroHeadline: some View {
        let ink = colorScheme == .dark ? Color(red: 0.961, green: 0.937, blue: 0.902) : Color(red: 0.173, green: 0.173, blue: 0.173)
        (Text(String(localized: "widget.gallery.hero.headline")).foregroundColor(ink)
            + Text(String(localized: "widget.gallery.hero.emphasis")).foregroundColor(DesignSystem.Colors.primary))
            .font(.system(size: 22, weight: .heavy))
            .kerning(-0.5)
            .padding(.top, 10)
    }

    // MARK: - Hero card

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                if colorScheme == .dark {
                    LinearGradient(
                        colors: [Color(red: 0.165, green: 0.114, blue: 0.094),
                                 Color(red: 0.102, green: 0.078, blue: 0.063),
                                 Color(red: 0.149, green: 0.106, blue: 0.086)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                } else {
                    LinearGradient(
                        colors: [Color(red: 1.0, green: 0.914, blue: 0.839),
                                 Color(red: 0.961, green: 0.835, blue: 0.710),
                                 Color(red: 0.910, green: 0.722, blue: 0.604)],
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
                    .fill(Color(red: 0.773, green: 0.627, blue: 0.396))
                    .opacity(0.40)
                    .blur(radius: 40)
                    .frame(width: 180)
                    .offset(x: -30, y: 60)

                HStack(alignment: .center, spacing: 14) {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 5) {
                            LiShuGalleryMark()
                            Text(String(localized: "widget.displayName") + " · Widget")
                                .font(.system(size: 10, weight: .heavy))
                                .kerning(0.8)
                                .textCase(.uppercase)
                                .foregroundStyle(colorScheme == .dark ? Color(red: 0.961, green: 0.835, blue: 0.710) : DesignSystem.Colors
                                    .primary)
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 3)
                        .background(
                            Capsule().fill(colorScheme == .dark ? DesignSystem.Colors.primary.opacity(0.30) : Color.white.opacity(0.55))
                                .overlay(Capsule().strokeBorder(
                                    DesignSystem.Colors.primary.opacity(colorScheme == .dark ? 0.40 : 0.30),
                                    lineWidth: 0.5
                                ))
                        )

                        heroHeadline

                        Text(String(localized: "widget.gallery.hero.subtitle"))
                            .font(.system(size: 12.5))
                            .foregroundStyle(colorScheme == .dark ? Color(red: 0.961, green: 0.937, blue: 0.902).opacity(0.65) : Color(
                                red: 0.478,
                                green: 0.455,
                                blue: 0.431
                            ))
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
                        .shadow(color: Color(red: 0.235, green: 0.118, blue: 0.078).opacity(0.30), radius: 24, x: 0, y: 18)
                }
                .padding(22)
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(
                        colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.6),
                        lineWidth: 0.5
                    )
            )
            .shadow(color: Color(red: 0.718, green: 0.431, blue: 0.353).opacity(0.20), radius: 28, x: 0, y: 12)
        }
        .padding(.horizontal, 16)
        .padding(.top, 18)
        .padding(.bottom, 8)
    }
}

#Preview("Widget Gallery Hero") {
    WidgetGalleryHeroView(snapshot: .galleryPreview)
}
