import SwiftUI

struct WidgetGallerySegmentedControl: View {
    @Binding var section: WidgetGallerySection
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 0) {
            segmentButton(.home, label: String(localized: "widget.gallery.tab.home"), count: "3")
            segmentButton(.lock, label: String(localized: "widget.gallery.tab.lock"), count: "3")
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color(red: 0.47, green: 0.35, blue: 0.24).opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(
                            colorScheme == .dark ? Color.white.opacity(0.06) : Color(red: 0.47, green: 0.35, blue: 0.24).opacity(0.08),
                            lineWidth: 0.5
                        )
                )
        )
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 4)
    }

    private func segmentButton(_ tab: WidgetGallerySection, label: String, count: String) -> some View {
        let active = section == tab
        return Button { withAnimation(.easeInOut(duration: 0.2)) { section = tab } } label: {
            HStack(spacing: 4) {
                Text(label)
                    .font(.system(size: 13, weight: active ? .bold : .semibold))
                    .foregroundStyle(active ? DesignSystem.Colors.textPrimary : DesignSystem.Colors.textSecondary)
                Text(count)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(active ? DesignSystem.Colors.primary : DesignSystem.Colors.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(active
                        ? (colorScheme == .dark ? Color(red: 0.149, green: 0.118, blue: 0.094).opacity(0.80) : Color.white)
                        : Color.clear)
                    .shadow(
                        color: active ? Color(red: 0.47, green: 0.35, blue: 0.24).opacity(colorScheme == .dark ? 0 : 0.10) : .clear,
                        radius: 6,
                        x: 0,
                        y: 3
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(tab == .home ? "gallery.tab.home" : "gallery.tab.lock")
    }
}

// MARK: - Home widgets

struct WidgetGalleryHomeWidgets: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        VStack(spacing: 0) {
            GallerySectionTitle(label: "systemSmall · 158×158", count: 3)
            widgetCard(
                size: "Small",
                name: String(localized: "widget.gallery.small.reminder.name"),
                desc: String(localized: "widget.gallery.small.reminder.desc"),
                scenarios: [
                    (String(localized: "widget.gallery.scenario.dailyManager"), DesignSystem.Colors.primary),
                    (String(localized: "widget.gallery.scenario.birthdayAlert"), DesignSystem.Colors.accentGold),
                ]
            ) {
                GallerySmallStub(snapshot: snapshot, variant: .reminder)
            }
            widgetCard(
                size: "Small",
                name: String(localized: "widget.countdown.displayName"),
                desc: String(localized: "widget.gallery.small.countdown.desc"),
                scenarios: [
                    (String(localized: "widget.gallery.scenario.weddingWeek"), DesignSystem.Colors.primary),
                    (String(localized: "widget.gallery.scenario.birthdayBanquet"), DesignSystem.Colors.accentGold),
                ]
            ) {
                GallerySmallStub(snapshot: snapshot, variant: .countdown)
            }
            widgetCard(
                size: "Small",
                name: String(localized: "widget.financial.displayName"),
                desc: String(localized: "widget.gallery.small.financial.desc"),
                scenarios: [
                    (String(localized: "widget.gallery.scenario.yearEndReview"), DesignSystem.Colors.accentGold),
                    (String(localized: "widget.gallery.scenario.financeOverview"), DesignSystem.Colors.primary),
                ],
                dotColor: DesignSystem.Colors.accentGold
            ) {
                GallerySmallStub(snapshot: snapshot, variant: .financial)
            }

            GallerySectionTitle(label: "systemMedium · 338×158", count: 3)
            widgetCard(
                size: "Medium",
                name: String(localized: "widget.gallery.medium.reminder.name"),
                desc: String(localized: "widget.gallery.medium.reminder.desc"),
                scenarios: [
                    (String(localized: "widget.gallery.scenario.frequentEntry"), DesignSystem.Colors.primary),
                    (String(localized: "widget.gallery.scenario.weddingWeek"), DesignSystem.Colors.accentGold),
                ]
            ) {
                GalleryMediumStub(snapshot: snapshot, variant: .reminder)
            }
            widgetCard(
                size: "Medium",
                name: String(localized: "widget.gallery.medium.event.name"),
                desc: String(localized: "widget.mediumEvent.description"),
                scenarios: [
                    (String(localized: "widget.gallery.scenario.weddingHost"), DesignSystem.Colors.primary),
                    (String(localized: "widget.gallery.scenario.houseMoving"), DesignSystem.Colors.primaryDark),
                ]
            ) {
                GalleryMediumStub(snapshot: snapshot, variant: .event)
            }
            widgetCard(
                size: "Medium",
                name: String(localized: "widget.mediumFinancial.displayName"),
                desc: String(localized: "widget.mediumFinancial.description"),
                scenarios: [
                    (String(localized: "widget.gallery.scenario.yearEndReview"), DesignSystem.Colors.accentGold),
                    (String(localized: "widget.gallery.scenario.financeOverview"), DesignSystem.Colors.primary),
                ],
                dotColor: DesignSystem.Colors.accentGold
            ) {
                GalleryMediumStub(snapshot: snapshot, variant: .financial)
            }

            GallerySectionTitle(label: "systemLarge · 338×354", count: 1)
            widgetCard(
                size: "Large",
                name: String(localized: "widget.gallery.large.name"),
                desc: String(localized: "widget.gallery.large.desc"),
                scenarios: [
                    (String(localized: "widget.gallery.scenario.recommended"), DesignSystem.Colors.primary),
                    (String(localized: "widget.gallery.scenario.adaptive"), DesignSystem.Colors.primaryDark),
                ]
            ) {
                GalleryLargeStub(snapshot: snapshot)
            }
        }
    }

    private func widgetCard(
        size: String, name: String, desc: String,
        scenarios: [(String, Color)], dotColor: Color = DesignSystem.Colors.primary,
        @ViewBuilder content: @escaping () -> some View
    ) -> some View {
        GalleryWidgetCard(
            size: size, name: name, desc: desc, scenarios: scenarios, dotColor: dotColor,
            isLock: false, lockBg: .lock
        ) { AnyView(WidgetPreviewShell(width: previewWidth(size), height: previewHeight(size)) { content() }) }
    }

    private func previewWidth(_ size: String) -> CGFloat {
        switch size {
        case "Medium": 338
        case "Large": 338
        default: 158
        }
    }

    private func previewHeight(_ size: String) -> CGFloat {
        switch size {
        case "Medium": 158
        case "Large": 354
        default: 158
        }
    }
}

// MARK: - Lock widgets

struct WidgetGalleryLockWidgets: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        VStack(spacing: 0) {
            GallerySectionTitle(label: "accessoryCircular · 76pt", count: 2)
            lockWidgetCard(
                bg: .lock,
                size: "Circular",
                name: String(localized: "widget.gallery.circular.name"),
                desc: String(localized: "widget.gallery.circular.desc"),
                scenarios: [
                    (String(localized: "widget.gallery.scenario.defaultUse"), DesignSystem.Colors.primaryDark),
                    (String(localized: "widget.gallery.scenario.lowFrequency"), DesignSystem.Colors.accentGold),
                ],
                dotColor: DesignSystem.Colors.primaryDark
            ) {
                GalleryCircularStub(count: snapshot.reminderCount)
            }
            lockWidgetCard(
                bg: .dusk,
                size: "Circular",
                name: String(localized: "widget.countdownRing.displayName"),
                desc: String(localized: "widget.countdownRing.description"),
                scenarios: [
                    (String(localized: "widget.gallery.scenario.weddingWeek"), DesignSystem.Colors.primary),
                    (String(localized: "widget.gallery.scenario.birthdayBanquet"), DesignSystem.Colors.accentGold),
                ]
            ) {
                GalleryCircularCountdownStub(daysUntil: snapshot.nextHostingEvent?.daysUntil ?? 7)
            }

            GallerySectionTitle(label: "accessoryRectangular · 172×76pt", count: 1)
            lockWidgetCard(
                bg: .lock,
                size: "Rectangular",
                name: String(localized: "widget.gallery.rectangular.name"),
                desc: String(localized: "widget.gallery.rectangular.desc"),
                scenarios: [
                    (String(localized: "widget.gallery.scenario.recommends"), DesignSystem.Colors.primary),
                    (String(localized: "widget.gallery.scenario.homeTravel"), DesignSystem.Colors.primaryDark),
                ]
            ) {
                GalleryRectangularStub(snapshot: snapshot)
            }

            GallerySectionTitle(label: "accessoryInline · 257×16pt", count: 1)
            lockWidgetCard(
                bg: .lock,
                size: "Inline",
                name: String(localized: "widget.gallery.inline.name"),
                desc: String(localized: "widget.gallery.inline.desc"),
                scenarios: [(String(localized: "widget.gallery.scenario.minimalist"), DesignSystem.Colors.accentGold)],
                dotColor: DesignSystem.Colors.accentGold
            ) {
                GalleryInlineStub(snapshot: snapshot)
            }
        }
    }

    private func lockWidgetCard(
        bg: LockBg, size: String, name: String, desc: String,
        scenarios: [(String, Color)], dotColor: Color = DesignSystem.Colors.primary,
        @ViewBuilder content: @escaping () -> some View
    ) -> some View {
        GalleryWidgetCard(
            size: size, name: name, desc: desc, scenarios: scenarios, dotColor: dotColor,
            isLock: true, lockBg: bg
        ) { AnyView(content()) }
    }
}

private struct WidgetGallerySegmentedControlPreview: View {
    @State private var section: WidgetGallerySection = .home

    var body: some View {
        WidgetGallerySegmentedControl(section: $section)
    }
}

#Preview("Widget Gallery Catalog") {
    ScrollView {
        WidgetGallerySegmentedControlPreview()
        WidgetGalleryHomeWidgets(snapshot: .galleryPreview)
        WidgetGalleryLockWidgets(snapshot: .galleryPreview)
    }
    .background(DesignSystem.Colors.bgPage)
}
