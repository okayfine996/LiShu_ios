import SwiftUI

// MARK: - Ambient background

struct WidgetGalleryAmbientBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.primary)
                    .opacity(colorScheme == .dark ? 0.18 : 0.10)
                    .blur(radius: 60)
                    .frame(width: geo.size.width * 0.6)
                    .offset(x: -geo.size.width * 0.1, y: -geo.size.height * 0.1)
                Circle()
                    .fill(DesignSystem.Colors.accentGold)
                    .opacity(colorScheme == .dark ? 0.15 : 0.08)
                    .blur(radius: 60)
                    .frame(width: geo.size.width * 0.55)
                    .offset(x: geo.size.width * 0.3, y: geo.size.height * 0.6)
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Preview Shell (wraps widget view for in-app display)

struct WidgetPreviewShell<Content: View>: View {
    let width: CGFloat
    let height: CGFloat
    @ViewBuilder let content: Content

    var body: some View {
        content
            .frame(width: width, height: height)
            .background(WidgetGalleryBackground())
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .allowsHitTesting(false)
            .scaleEffect(previewScale)
            .frame(width: width * previewScale, height: height * previewScale)
            .clipped()
    }

    private var previewScale: CGFloat {
        if width > 200 { return 0.60 }
        return 1.0
    }
}

struct WidgetGalleryBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if colorScheme == .dark {
            LinearGradient(
                colors: [Color(red: 0.110, green: 0.106, blue: 0.098), Color(red: 0.055, green: 0.047, blue: 0.039)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        } else {
            LinearGradient(
                colors: [Color(red: 0.984, green: 0.965, blue: 0.933), Color(red: 0.945, green: 0.898, blue: 0.831)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - Gallery 礼 mark (no DesignTokens dependency issues)

struct LiShuGalleryMark: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [DesignSystem.Colors.primary, DesignSystem.Colors.primaryDark],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            Text("礼")
                .font(.system(size: 11 * 0.62, weight: .heavy))
                .foregroundStyle(.white)
        }
        .frame(width: 11, height: 11)
        .clipShape(RoundedRectangle(cornerRadius: 11 * 0.22, style: .continuous))
    }
}

// MARK: - Gallery section title

struct GallerySectionTitle: View {
    let label: String
    let count: Int
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 8) {
            Text(label.uppercased())
                .font(.system(size: 13, weight: .heavy, design: .monospaced))
                .foregroundStyle(DesignSystem.Colors.textSecondary)
            Text(String(format: String(localized: "widget.gallery.variantCount"), count))
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(DesignSystem.Colors.textTertiary)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 10)
    }
}

// MARK: - Gallery widget card

enum LockBg { case lock, dusk }

struct GalleryWidgetCard: View {
    let size: String
    let name: String
    let desc: String
    let scenarios: [(String, Color)]
    let dotColor: Color
    let isLock: Bool
    let lockBg: LockBg
    let widgetPreview: () -> AnyView

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            stageArea
            metaArea
        }
        .background(colorScheme == .dark ? Color(red: 0.149, green: 0.118, blue: 0.094).opacity(0.55) : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(
                    colorScheme == .dark ? Color.white.opacity(0.06) : Color(red: 0.47, green: 0.35, blue: 0.24).opacity(0.10),
                    lineWidth: 0.5
                )
        )
        .shadow(
            color: colorScheme == .dark ? Color.black.opacity(0.32) : Color(red: 0.47, green: 0.35, blue: 0.24).opacity(0.10),
            radius: 22,
            x: 0,
            y: 8
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 14)
    }

    private var stageArea: some View {
        ZStack {
            stageBackground
            if isLock, lockBg == .lock {
                lockStarDots
            }
            widgetPreview()
                .padding(.vertical, 24)
        }
        .frame(maxWidth: .infinity)
        .clipped()
    }

    private var lockStarDots: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                Circle().fill(Color.white.opacity(0.50)).frame(width: 2, height: 2)
                    .position(x: w * 0.09, y: h * 0.38)
                Circle().fill(Color.white.opacity(0.60)).frame(width: 3, height: 3)
                    .position(x: w * 0.28, y: h * 0.62)
                Circle().fill(Color.white.opacity(0.55)).frame(width: 2, height: 2)
                    .position(x: w * 0.62, y: h * 0.28)
                Circle().fill(Color.white.opacity(0.45)).frame(width: 2, height: 2)
                    .position(x: w * 0.87, y: h * 0.52)
            }
            .opacity(0.7)
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private var stageBackground: some View {
        if isLock {
            if lockBg == .lock {
                RadialGradient(
                    colors: [Color(red: 0.227, green: 0.290, blue: 0.471),
                             Color(red: 0.122, green: 0.165, blue: 0.290),
                             Color(red: 0.039, green: 0.055, blue: 0.122)],
                    center: UnitPoint(x: 0.3, y: 0.3), startRadius: 0, endRadius: 250
                )
            } else {
                RadialGradient(
                    colors: [Color(red: 1.0, green: 0.847, blue: 0.690),
                             Color(red: 0.910, green: 0.604, blue: 0.522),
                             DesignSystem.Colors.primary,
                             Color(red: 0.227, green: 0.114, blue: 0.094)],
                    center: UnitPoint(x: 0.7, y: 0.25), startRadius: 0, endRadius: 280
                )
            }
        } else {
            if colorScheme == .dark {
                LinearGradient(
                    colors: [Color(red: 0.165, green: 0.125, blue: 0.094),
                             Color(red: 0.122, green: 0.094, blue: 0.071),
                             Color(red: 0.165, green: 0.122, blue: 0.090)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            } else {
                LinearGradient(
                    colors: [Color(red: 0.984, green: 0.965, blue: 0.933),
                             Color(red: 0.941, green: 0.878, blue: 0.800),
                             Color(red: 0.910, green: 0.831, blue: 0.698)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            }
        }
    }

    private var metaArea: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 8) {
                Text(size.uppercased())
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(colorScheme == .dark ? Color.white.opacity(0.10) : Color(red: 0.47, green: 0.35, blue: 0.24)
                                .opacity(0.10))
                    )
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                Spacer()
                Circle().fill(dotColor).frame(width: 5, height: 5)
            }
            .padding(.bottom, 6)

            Text(name)
                .font(.system(size: 16, weight: .heavy))
                .kerning(-0.3)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Text(desc)
                .font(.system(size: 12.5))
                .lineSpacing(4)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .padding(.top, 4)

            if !scenarios.isEmpty {
                HStack(spacing: 6) {
                    ForEach(scenarios.indices, id: \.self) { i in
                        let (label, color) = scenarios[i]
                        Text(label)
                            .font(.system(size: 10.5, weight: .semibold))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(colorScheme == .dark ? color.opacity(0.30) : color.opacity(0.18))
                                    .overlay(Capsule().strokeBorder(color.opacity(colorScheme == .dark ? 0.40 : 0.30), lineWidth: 0.5))
                            )
                            .foregroundStyle(colorScheme == .dark ? Color.white : color)
                    }
                }
                .padding(.top, 10)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - How to add accordion

struct HowToAddAccordion: View {
    let section: WidgetGallerySection
    @State private var isExpanded = true
    @Environment(\.colorScheme) private var colorScheme

    private var isLock: Bool {
        section == .lock
    }

    private var steps: [(String, String)] {
        if isLock {
            return [
                (String(localized: "widget.gallery.howto.lock.step1.title"), String(localized: "widget.gallery.howto.lock.step1.desc")),
                (String(localized: "widget.gallery.howto.lock.step2.title"), String(localized: "widget.gallery.howto.lock.step2.desc")),
                (String(localized: "widget.gallery.howto.lock.step3.title"), String(localized: "widget.gallery.howto.lock.step3.desc")),
                (String(localized: "widget.gallery.howto.lock.step4.title"), String(localized: "widget.gallery.howto.lock.step4.desc")),
                (String(localized: "widget.gallery.howto.lock.step5.title"), String(localized: "widget.gallery.howto.lock.step5.desc")),
            ]
        }
        return [
            (String(localized: "widget.gallery.howto.home.step1.title"), String(localized: "widget.gallery.howto.home.step1.desc")),
            (String(localized: "widget.gallery.howto.home.step2.title"), String(localized: "widget.gallery.howto.home.step2.desc")),
            (String(localized: "widget.gallery.howto.home.step3.title"), String(localized: "widget.gallery.howto.home.step3.desc")),
            (String(localized: "widget.gallery.howto.home.step4.title"), String(localized: "widget.gallery.howto.home.step4.desc")),
            (String(localized: "widget.gallery.howto.home.step5.title"), String(localized: "widget.gallery.howto.home.step5.desc")),
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            Button { withAnimation(.easeInOut(duration: 0.22)) { isExpanded.toggle() } } label: {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(LinearGradient(
                                colors: [DesignSystem.Colors.primary, DesignSystem.Colors.primaryDark],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ))
                            .shadow(color: DesignSystem.Colors.primary.opacity(0.55), radius: 8, x: 0, y: 3)
                        Image(systemName: "info.circle")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 32, height: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(isLock ? String(localized: "widget.gallery.howToAdd.lock.title") :
                            String(localized: "widget.gallery.howToAdd.home.title"))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                        Text(String(localized: "widget.gallery.howto.tagline"))
                            .font(.system(size: 11.5))
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(14)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color(red: 0.47, green: 0.35, blue: 0.24).opacity(0.08))
                        .frame(height: 0.5)
                    ForEach(steps.indices, id: \.self) { i in
                        HStack(alignment: .top, spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(colorScheme == .dark ? DesignSystem.Colors.primary.opacity(0.20) : DesignSystem.Colors.primary
                                        .opacity(0.14))
                                    .overlay(Circle().strokeBorder(DesignSystem.Colors.primary.opacity(0.30), lineWidth: 0.5))
                                Text("\(i + 1)")
                                    .font(.system(size: 11, weight: .heavy))
                                    .foregroundStyle(DesignSystem.Colors.primary)
                            }
                            .frame(width: 24, height: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(steps[i].0)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                                Text(steps[i].1)
                                    .font(.system(size: 12))
                                    .lineSpacing(3)
                                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        if i < steps.count - 1 {
                            Rectangle()
                                .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color(red: 0.47, green: 0.35, blue: 0.24)
                                    .opacity(0.06))
                                .frame(height: 0.5)
                                .padding(.leading, 52)
                        }
                    }
                    tipBox
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                        .padding(.top, 8)
                }
            }
        }
        .background(colorScheme == .dark ? Color(red: 0.149, green: 0.118, blue: 0.094).opacity(0.60) : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(
                    colorScheme == .dark ? Color.white.opacity(0.06) : Color(red: 0.47, green: 0.35, blue: 0.24).opacity(0.10),
                    lineWidth: 0.5
                )
        )
        .shadow(
            color: colorScheme == .dark ? Color.black.opacity(0.32) : Color(red: 0.47, green: 0.35, blue: 0.24).opacity(0.08),
            radius: 18,
            x: 0,
            y: 6
        )
    }

    private var tipBox: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 12))
                .foregroundStyle(DesignSystem.Colors.accentGold)
            Text(String(localized: "widget.gallery.editTip"))
                .font(.system(size: 11.5))
                .lineSpacing(3)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(DesignSystem.Colors.accentGold.opacity(colorScheme == .dark ? 0.14 : 0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(DesignSystem.Colors.accentGold.opacity(0.30), lineWidth: 0.5)
                )
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Footer

struct WidgetGalleryFooter: View {
    @Environment(\.colorScheme) private var colorScheme

    private static let appleTutorialURL = URL(string: "https://support.apple.com/HT207122")

    var body: some View {
        VStack(spacing: 8) {
            if let tutorialURL = Self.appleTutorialURL {
                Link(destination: tutorialURL) {
                    HStack(spacing: 5) {
                        Text(String(localized: "widget.gallery.footer.tutorial"))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.primary)
                }
            }
            Text(String(localized: "widget.gallery.footer"))
                .font(.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
        .padding(.top, 20)
        .frame(maxWidth: .infinity)
    }
}

#Preview("Widget Gallery Components") {
    ScrollView {
        GallerySectionTitle(label: "systemSmall · 158×158", count: 3)
        GalleryWidgetCard(
            size: "Small",
            name: String(localized: "widget.gallery.small.reminder.name"),
            desc: String(localized: "widget.gallery.small.reminder.desc"),
            scenarios: [(String(localized: "widget.gallery.scenario.dailyManager"), DesignSystem.Colors.primary)],
            dotColor: DesignSystem.Colors.primary,
            isLock: false,
            lockBg: .lock
        ) {
            AnyView(WidgetPreviewShell(width: 158, height: 158) {
                GallerySmallStub(snapshot: .galleryPreview, variant: .reminder)
            })
        }
        HowToAddAccordion(section: .home)
            .padding(.horizontal, 16)
        WidgetGalleryFooter()
    }
    .background(DesignSystem.Colors.bgPage)
}
