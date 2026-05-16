import SwiftUI

private enum GalleryPreviewSize {
    case small
    case medium
    case large

    var label: String {
        switch self {
        case .small: String(localized: "widget.gallery.size.small")
        case .medium: String(localized: "widget.gallery.size.medium")
        case .large: String(localized: "widget.gallery.size.large")
        }
    }

    var previewWidth: CGFloat {
        switch self {
        case .small: 158
        case .medium, .large: 338
        }
    }

    var previewHeight: CGFloat {
        switch self {
        case .small, .medium: 158
        case .large: 354
        }
    }
}

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
                .fill(colorScheme == .dark ? DesignSystem.Colors.textOnPrimary.opacity(0.06) : DesignSystem.Colors.bgCard.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(
                            colorScheme == .dark ? DesignSystem.Colors.textOnPrimary.opacity(0.06) : DesignSystem.Colors.bgCard
                                .opacity(0.08),
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
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(active ? DesignSystem.Colors.textPrimary : DesignSystem.Colors.textSecondary)
                Text(count)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(active ? DesignSystem.Colors.primary : DesignSystem.Colors.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(active
                        ? (colorScheme == .dark ? DesignSystem.Colors.bgCard.opacity(0.80) : DesignSystem.Colors.textOnPrimary)
                        : Color.clear)
                    .shadow(
                        color: active ? DesignSystem.Colors.bgCard.opacity(colorScheme == .dark ? 0 : 0.10) : .clear,
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
            GallerySectionTitle(label: String(localized: "widget.gallery.spec.systemSmall"), count: 3)
            widgetCard(
                size: .small,
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
                size: .small,
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
                size: .small,
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

            GallerySectionTitle(label: String(localized: "widget.gallery.spec.systemMedium"), count: 3)
            widgetCard(
                size: .medium,
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
                size: .medium,
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
                size: .medium,
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

            GallerySectionTitle(label: String(localized: "widget.gallery.spec.systemLarge"), count: 1)
            widgetCard(
                size: .large,
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
        size: GalleryPreviewSize, name: String, desc: String,
        scenarios: [(String, Color)], dotColor: Color = DesignSystem.Colors.primary,
        @ViewBuilder content: @escaping () -> some View
    ) -> some View {
        GalleryWidgetCard(
            size: size.label, name: name, desc: desc, scenarios: scenarios, dotColor: dotColor,
            isLock: false, lockBg: .lock
        ) { AnyView(WidgetPreviewShell(width: size.previewWidth, height: size.previewHeight) { content() }) }
    }
}

// MARK: - Lock widgets

struct WidgetGalleryLockWidgets: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        VStack(spacing: 0) {
            GallerySectionTitle(label: String(localized: "widget.gallery.spec.accessoryCircular"), count: 2)
            lockWidgetCard(
                bg: .lock,
                size: String(localized: "widget.gallery.size.circular"),
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
                size: String(localized: "widget.gallery.size.circular"),
                name: String(localized: "widget.countdownRing.displayName"),
                desc: String(localized: "widget.countdownRing.description"),
                scenarios: [
                    (String(localized: "widget.gallery.scenario.weddingWeek"), DesignSystem.Colors.primary),
                    (String(localized: "widget.gallery.scenario.birthdayBanquet"), DesignSystem.Colors.accentGold),
                ]
            ) {
                GalleryCircularCountdownStub(daysUntil: snapshot.nextHostingEvent?.daysUntil ?? 7)
            }

            GallerySectionTitle(label: String(localized: "widget.gallery.spec.accessoryRectangular"), count: 1)
            lockWidgetCard(
                bg: .lock,
                size: String(localized: "widget.gallery.size.rectangular"),
                name: String(localized: "widget.gallery.rectangular.name"),
                desc: String(localized: "widget.gallery.rectangular.desc"),
                scenarios: [
                    (String(localized: "widget.gallery.scenario.recommends"), DesignSystem.Colors.primary),
                    (String(localized: "widget.gallery.scenario.homeTravel"), DesignSystem.Colors.primaryDark),
                ]
            ) {
                GalleryRectangularStub(snapshot: snapshot)
            }

            GallerySectionTitle(label: String(localized: "widget.gallery.spec.accessoryInline"), count: 1)
            lockWidgetCard(
                bg: .lock,
                size: String(localized: "widget.gallery.size.inline"),
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
