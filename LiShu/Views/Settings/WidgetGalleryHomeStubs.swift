import SwiftUI

struct GallerySmallStub: View {
    let snapshot: WidgetSnapshot
    let variant: GallerySmallVariant
    @Environment(\.colorScheme) private var cs

    private var ink: Color {
        DesignSystem.Colors.textPrimary
    }

    private var inkSub: Color {
        DesignSystem.Colors.textSecondary
    }

    var body: some View {
        ZStack {
            GalleryWidgetBg()
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    GalleryMark(size: 14)
                    Text(String(localized: "widget.displayName")).font(DesignSystem.Typography.widgetBodyBold).foregroundStyle(ink)
                    Spacer()
                    if variant == .reminder, snapshot.reminderCount > 0 {
                        Text(String(format: String(localized: "widget.reminderCount"), snapshot.reminderCount))
                            .font(DesignSystem.Typography.widgetMetaBold)
                            .padding(.horizontal, 7).padding(.vertical, 2)
                            .background(Capsule().fill(DesignSystem.Colors.primary.opacity(cs == .dark ? 0.28 : 0.14)))
                            .foregroundStyle(ink)
                    }
                }
                Spacer()
                switch variant {
                case .reminder: reminderContent
                case .countdown: countdownContent
                case .financial: financialContent
                }
            }
            .padding(14)
        }
        .frame(width: 158, height: 158)
    }

    @ViewBuilder private var reminderContent: some View {
        if let item = snapshot.reminders.first {
            let color = galleryKindColor(item.kind)
            Text("\(String(localized: "widget.small.nextItem")) · \(galleryKindName(item.kind))")
                .font(DesignSystem.Typography.widgetTinyBold).kerning(0.8)
                .foregroundStyle(color)
                .textCase(.uppercase)
                .lineLimit(1)
                .padding(.bottom, 4)
            Text(item.title)
                .font(DesignSystem.Typography.widgetTitle).kerning(-0.3)
                .foregroundStyle(ink).lineLimit(2)
            if let eventDate = item.eventDateLabel {
                Text("\(eventDate) · \(item.subtitle)")
                    .font(DesignSystem.Typography.widgetMeta).foregroundStyle(inkSub)
                    .lineLimit(1).padding(.top, 2)
            }
            HStack(spacing: 6) {
                Text(item.dateLabel)
                    .font(DesignSystem.Typography.widgetMetaBold).foregroundStyle(DesignSystem.Colors.textOnPrimary)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Capsule().fill(color))
                if snapshot.reminderCount > 1 {
                    Text(String(format: String(localized: "widget.more.items"), snapshot.reminderCount - 1))
                        .font(DesignSystem.Typography.widgetMeta).foregroundStyle(inkSub)
                }
            }
            .padding(.top, 10)
        }
    }

    @ViewBuilder private var countdownContent: some View {
        if let ev = snapshot.nextHostingEvent {
            Text(String(format: String(localized: "widget.hosting.status"), ev.typeName))
                .font(DesignSystem.Typography.widgetTinyBold).kerning(0.8)
                .foregroundStyle(DesignSystem.Colors.accentGold)
                .textCase(.uppercase)
                .lineLimit(1)
                .padding(.bottom, 4)
            Text(ev.name).font(DesignSystem.Typography.widgetTitle).foregroundStyle(ink).lineLimit(1)
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("D–")
                    .font(DesignSystem.Typography.widgetBodyBold)
                    .foregroundStyle(ink)
                    .padding(.bottom, 2)
                Text("\(ev.daysUntil)")
                    .font(DesignSystem.Typography.widgetCountdown).kerning(-2.5)
                    .foregroundStyle(ink)
                    .lineLimit(1)
            }
            .padding(.top, 4)
            Text(ev.dateLine).font(DesignSystem.Typography.widgetMeta).foregroundStyle(inkSub).lineLimit(1)
        }
    }

    @ViewBuilder private var financialContent: some View {
        let net = snapshot.yearlyIncome - snapshot.yearlyExpense
        let total = snapshot.yearlyIncome + snapshot.yearlyExpense
        let accent = DesignSystem.Colors.primary
        let gold = DesignSystem.Colors.accentGold
        let incomeRatio = total > 0 ? CGFloat(snapshot.yearlyIncome / total) : 0
        let expenseRatio = total > 0 ? CGFloat(snapshot.yearlyExpense / total) : 0

        Text("\(String(localized: "widget.netAmount")) · \(chineseYear(snapshot.currentYear))")
            .font(DesignSystem.Typography.widgetTinyBold).kerning(0.8)
            .foregroundStyle(inkSub)
            .textCase(.uppercase)
            .padding(.bottom, 2)
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text(net >= 0 ? "+¥" : "-¥")
                .font(DesignSystem.Typography.widgetBodyBold)
                .foregroundStyle(ink)
            Text(abs(net), format: .number.precision(.fractionLength(0)))
                .font(DesignSystem.Typography.widgetMetric).kerning(-1.2)
                .foregroundStyle(ink)
        }
        VStack(alignment: .leading, spacing: 6) {
            smallFinancialBar(
                label: String(localized: "widget.income"),
                value: snapshot.yearlyIncome,
                ratio: incomeRatio, color: gold
            )
            smallFinancialBar(
                label: String(localized: "widget.expense"),
                value: snapshot.yearlyExpense,
                ratio: expenseRatio, color: accent
            )
        }
        .padding(.top, 12)
        Text(String(format: String(localized: "widget.stats.footer"), snapshot.yearlyRecordCount, snapshot.yearlyContactCount))
            .font(DesignSystem.Typography.widgetMeta)
            .foregroundStyle(inkSub)
            .padding(.top, 8)
    }

    private func smallFinancialBar(label: String, value: Double, ratio: CGFloat, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(label)
                    .font(DesignSystem.Typography.widgetMeta).foregroundStyle(inkSub)
                Spacer(minLength: 0)
                Text("¥\(value, format: .number.notation(.compactName).precision(.significantDigits(2)))")
                    .font(DesignSystem.Typography.widgetMeta).foregroundStyle(inkSub)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(cs == .dark ? DesignSystem.Colors.textOnPrimary.opacity(0.08) : DesignSystem.Colors.bgCard.opacity(0.10))
                    Capsule().fill(color).frame(width: geo.size.width * ratio)
                }
            }
            .frame(height: 4)
        }
    }
}

struct GalleryMediumStub: View {
    let snapshot: WidgetSnapshot
    let variant: GalleryMediumVariant
    @Environment(\.colorScheme) private var cs

    private var ink: Color {
        DesignSystem.Colors.textPrimary
    }

    private var inkSub: Color {
        DesignSystem.Colors.textSecondary
    }

    private var incomeRatio: CGFloat {
        let t = snapshot.yearlyIncome + snapshot.yearlyExpense
        return t > 0 ? CGFloat(snapshot.yearlyIncome / t) : 0
    }

    private var expenseRatio: CGFloat {
        let t = snapshot.yearlyIncome + snapshot.yearlyExpense
        return t > 0 ? CGFloat(snapshot.yearlyExpense / t) : 0
    }

    var body: some View {
        ZStack {
            GalleryWidgetBg()
            switch variant {
            case .reminder: reminderLayout
            case .event: eventLayout
            case .financial: financialLayout
            }
        }
        .frame(width: 338, height: 158)
    }

    private var reminderLayout: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                GalleryMark(size: 16)
                Text(String(localized: "widget.displayName")).font(DesignSystem.Typography.widgetBodyBold).foregroundStyle(ink)
                Spacer()
                Text(String(format: String(localized: "widget.reminderCount"), snapshot.reminderCount))
                    .font(DesignSystem.Typography.widgetMetaBold)
                    .padding(.horizontal, 7).padding(.vertical, 2)
                    .background(
                        Capsule().fill(DesignSystem.Colors.primary.opacity(cs == .dark ? 0.28 : 0.14))
                    )
                    .foregroundStyle(ink)
            }
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(snapshot.reminders.prefix(3).enumerated()), id: \.offset) { _, item in
                    let color = galleryKindColor(item.kind)
                    HStack(alignment: .center, spacing: 8) {
                        Circle().fill(color).frame(width: 6, height: 6)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.title)
                                .font(DesignSystem.Typography.widgetBodyBold).foregroundStyle(ink).lineLimit(1)
                            Text(item.subtitle)
                                .font(DesignSystem.Typography.widgetMeta).foregroundStyle(inkSub).lineLimit(1)
                        }
                        Spacer(minLength: 0)
                        Text(item.dateLabel)
                            .font(DesignSystem.Typography.widgetMetaBold).foregroundStyle(color)
                            .padding(.horizontal, 7).padding(.vertical, 2)
                            .background(Capsule().fill(color.opacity(cs == .dark ? 0.30 : 0.18)))
                    }
                }
            }
            .padding(.top, 8)
            Spacer(minLength: 0)
            Rectangle()
                .fill(cs == .dark ? DesignSystem.Colors.textOnPrimary.opacity(0.08) : DesignSystem.Colors.bgCard.opacity(0.12))
                .frame(height: 0.5)
            HStack(spacing: 6) {
                Image(systemName: "plus").font(DesignSystem.Typography.widgetMetaBold).foregroundStyle(DesignSystem.Colors.textOnPrimary)
                    .frame(width: 22, height: 22)
                    .background(RoundedRectangle(cornerRadius: 7).fill(
                        LinearGradient(
                            colors: [DesignSystem.Colors.primary, DesignSystem.Colors.primaryDark],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    ))
                Text(String(localized: "widget.quickAdd")).font(DesignSystem.Typography.widgetMetaBold).foregroundStyle(ink)
                Spacer(minLength: 0)
            }
            .padding(.top, 6)
        }
        .padding(14)
    }

    private var eventLayout: some View {
        HStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                LinearGradient(
                    colors: [
                        DesignSystem.Colors.widgetGalleryPhotoSky,
                        DesignSystem.Colors.widgetGalleryDuskMid,
                        DesignSystem.Colors.primary,
                    ],
                    startPoint: .top, endPoint: .bottom
                )
                Circle()
                    .fill(DesignSystem.Colors.bgCard)
                    .frame(width: 22, height: 22)
                    .shadow(color: DesignSystem.Colors.bgCard.opacity(0.7), radius: 9)
                    .offset(x: 62, y: 16)
                GeometryReader { geo in
                    let w = geo.size.width, h = geo.size.height
                    Path { p in
                        p.move(to: .init(x: 0, y: h * 0.615))
                        p.addLine(to: .init(x: w * 0.25, y: h * 0.385))
                        p.addLine(to: .init(x: w * 0.45, y: h * 0.538))
                        p.addLine(to: .init(x: w * 0.65, y: h * 0.346))
                        p.addLine(to: .init(x: w * 0.85, y: h * 0.500))
                        p.addLine(to: .init(x: w, y: h * 0.423))
                        p.addLine(to: .init(x: w, y: h))
                        p.addLine(to: .init(x: 0, y: h))
                        p.closeSubpath()
                    }
                    .fill(DesignSystem.Colors.widgetGalleryPhotoHill.opacity(0.55))
                    Path { p in
                        p.move(to: .init(x: 0, y: h * 0.769))
                        p.addLine(to: .init(x: w * 0.20, y: h * 0.615))
                        p.addLine(to: .init(x: w * 0.40, y: h * 0.731))
                        p.addLine(to: .init(x: w * 0.60, y: h * 0.577))
                        p.addLine(to: .init(x: w * 0.80, y: h * 0.708))
                        p.addLine(to: .init(x: w, y: h * 0.631))
                        p.addLine(to: .init(x: w, y: h))
                        p.addLine(to: .init(x: 0, y: h))
                        p.closeSubpath()
                    }
                    .fill(DesignSystem.Colors.widgetGalleryPhotoHillDeep.opacity(0.65))
                }
                if let ev = snapshot.nextHostingEvent {
                    Text("D–\(ev.daysUntil)")
                        .font(DesignSystem.Typography.widgetTinyBold)
                        .foregroundStyle(DesignSystem.Colors.textOnPrimary)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(
                            Capsule().fill(DesignSystem.Colors.overlayDark.opacity(0.30))
                                .overlay(Capsule().strokeBorder(DesignSystem.Colors.textOnPrimary.opacity(0.35), lineWidth: 0.5))
                        )
                        .padding(8)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .frame(width: 100)
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    GalleryMark(size: 14)
                    Text(String(localized: "widget.displayName")).font(DesignSystem.Typography.widgetBodyBold).foregroundStyle(ink)
                }
                if let ev = snapshot.nextHostingEvent {
                    Text(String(format: String(localized: "widget.hosting.status"), ev.typeName))
                        .font(DesignSystem.Typography.widgetTinyBold).kerning(0.8)
                        .foregroundStyle(DesignSystem.Colors.accentGold)
                        .textCase(.uppercase).padding(.top, 6)
                    Text(ev.name).font(DesignSystem.Typography.widgetTitleLarge).foregroundStyle(ink).lineLimit(1).padding(.top, 1)
                    Text(ev.dateLine).font(DesignSystem.Typography.widgetMeta).foregroundStyle(inkSub).lineLimit(1).padding(.top, 2)
                    Spacer(minLength: 0)
                    if let total = ev.giftReceivedTotal {
                        HStack(spacing: 0) {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(String(localized: "widget.event.giftReceived")).font(DesignSystem.Typography.widgetTiny)
                                    .foregroundStyle(inkSub)
                                Text("¥\(total, format: .number.precision(.fractionLength(0)))")
                                    .font(DesignSystem.Typography.caption).kerning(-0.6)
                                    .foregroundStyle(ink)
                            }
                            if let g = ev.guestCount {
                                Rectangle().fill(inkSub.opacity(0.20)).frame(width: 0.5, height: 28).padding(.horizontal, 10)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(String(localized: "widget.event.guestCount")).font(DesignSystem.Typography.widgetTiny)
                                        .foregroundStyle(inkSub)
                                    Text("\(g)").font(DesignSystem.Typography.caption).kerning(-0.6).foregroundStyle(ink)
                                }
                            }
                            Spacer(minLength: 0)
                            HStack(spacing: 4) {
                                Image(systemName: "plus").font(DesignSystem.Typography.caption)
                                Text(String(localized: "widget.event.register")).font(DesignSystem.Typography.caption)
                            }
                            .foregroundStyle(DesignSystem.Colors.primary)
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(DesignSystem.Colors.primary.opacity(cs == .dark ? 0.15 : 0.10))
                                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .strokeBorder(DesignSystem.Colors.primary.opacity(0.30), lineWidth: 0.5))
                            )
                        }
                    }
                }
            }
            .padding(14)
            Spacer(minLength: 0)
        }
    }

    private var financialLayout: some View {
        let net = snapshot.yearlyIncome - snapshot.yearlyExpense
        let accent = DesignSystem.Colors.primary
        let gold = DesignSystem.Colors.accentGold
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                GalleryMark(size: 14)
                Text(String(localized: "widget.medium.financial.header"))
                    .font(DesignSystem.Typography.caption).foregroundStyle(ink)
            }
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(net >= 0 ? "+¥" : "-¥")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(ink)
                Text(abs(net), format: .number.precision(.fractionLength(0)))
                    .font(DesignSystem.Typography.caption).kerning(-1.5)
                    .foregroundStyle(ink)
            }
            .padding(.top, 8)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                mediumFinancialBar(
                    label: String(localized: "widget.income"),
                    value: snapshot.yearlyIncome,
                    ratio: incomeRatio, color: gold
                )
                mediumFinancialBar(
                    label: String(localized: "widget.expense"),
                    value: snapshot.yearlyExpense,
                    ratio: expenseRatio, color: accent
                )
            }
            .padding(.top, 10)
            Rectangle()
                .fill(cs == .dark ? DesignSystem.Colors.textOnPrimary.opacity(0.08) : DesignSystem.Colors.bgCard.opacity(0.12))
                .frame(height: 0.5)
                .padding(.top, 8)
            HStack(spacing: 10) {
                galleryStatBadge(
                    dot: DesignSystem.Colors.primary,
                    label: String(localized: "widget.stat.interactions"),
                    value: "\(snapshot.yearlyRecordCount)",
                    unit: String(localized: "widget.stat.unit.records")
                )
                galleryStatBadge(
                    dot: DesignSystem.Colors.accentGold,
                    label: String(localized: "widget.stat.contacts"),
                    value: "\(snapshot.yearlyContactCount)",
                    unit: String(localized: "widget.stat.unit.contacts")
                )
                if snapshot.pendingReturnCount > 0 {
                    galleryStatBadge(
                        dot: DesignSystem.Colors.primaryDark,
                        label: String(localized: "widget.stat.pendingReturn"),
                        value: "\(snapshot.pendingReturnCount)",
                        unit: String(localized: "widget.stat.unit.records")
                    )
                }
            }
            .padding(.top, 6)
        }
        .padding(14)
    }

    private func mediumFinancialBar(label: String, value: Double, ratio: CGFloat, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(inkSub)
                Spacer(minLength: 0)
                Text("¥\(value, format: .number.notation(.compactName).precision(.significantDigits(2)))")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(ink)
                    .kerning(-0.2)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(cs == .dark ? DesignSystem.Colors.textOnPrimary.opacity(0.08) : DesignSystem.Colors.bgCard.opacity(0.10))
                    Capsule().fill(color).frame(width: geo.size.width * ratio)
                }
            }
            .frame(height: 4)
        }
    }

    private func galleryStatBadge(dot: Color, label: String, value: String, unit: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(dot).frame(width: 5, height: 5)
            Text(label).font(DesignSystem.Typography.caption).foregroundStyle(inkSub)
            Text(value).font(DesignSystem.Typography.caption).foregroundStyle(ink)
                + Text(unit).font(DesignSystem.Typography.caption).foregroundStyle(inkSub)
        }
    }
}

struct GalleryLargeStub: View {
    let snapshot: WidgetSnapshot
    @Environment(\.colorScheme) private var cs

    private var ink: Color {
        DesignSystem.Colors.textPrimary
    }

    private var inkSub: Color {
        DesignSystem.Colors.textSecondary
    }

    private var incomeRatio: CGFloat {
        let t = snapshot.yearlyIncome + snapshot.yearlyExpense
        return t > 0 ? CGFloat(snapshot.yearlyIncome / t) : 0
    }

    private var expenseRatio: CGFloat {
        let t = snapshot.yearlyIncome + snapshot.yearlyExpense
        return t > 0 ? CGFloat(snapshot.yearlyExpense / t) : 0
    }

    var body: some View {
        let net = snapshot.yearlyIncome - snapshot.yearlyExpense
        let accent = DesignSystem.Colors.primary
        let gold = DesignSystem.Colors.accentGold
        return ZStack {
            GalleryWidgetBg()
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack(spacing: 6) {
                    GalleryMark(size: 16)
                    Text(String(localized: "widget.displayName"))
                        .font(DesignSystem.Typography.caption).foregroundStyle(ink)
                    Spacer()
                    Text(String(format: String(localized: "widget.reminderCount"), snapshot.reminderCount))
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(ink)
                }
                // Hero strip — matches LiShuLargeWidgetView.heroStrip
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("\(String(localized: "widget.netAmount")) · \(chineseYear(snapshot.currentYear))")
                                .font(DesignSystem.Typography.caption).kerning(0.6)
                                .textCase(.uppercase).foregroundStyle(inkSub)
                            HStack(alignment: .firstTextBaseline, spacing: 2) {
                                Text(net >= 0 ? "+¥" : "-¥")
                                    .font(DesignSystem.Typography.caption).foregroundStyle(ink)
                                Text(abs(net), format: .number.precision(.fractionLength(0)))
                                    .font(DesignSystem.Typography.caption).kerning(-1.2).foregroundStyle(ink)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible())],
                        spacing: 10
                    ) {
                        largeHeroBar(
                            label: String(localized: "widget.income"),
                            value: snapshot.yearlyIncome,
                            ratio: incomeRatio, color: gold
                        )
                        largeHeroBar(
                            label: String(localized: "widget.expense"),
                            value: snapshot.yearlyExpense,
                            ratio: expenseRatio, color: accent
                        )
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            cs == .dark
                                ? LinearGradient(
                                    colors: [accent.opacity(0.22), gold.opacity(0.16)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [accent.opacity(0.10), gold.opacity(0.10)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(accent.opacity(0.25), lineWidth: 0.5)
                        )
                )
                .padding(.top, 10)
                // Section header
                HStack {
                    Text(String(localized: "widget.reminders.sectionTitle"))
                        .font(DesignSystem.Typography.caption).foregroundStyle(ink)
                    Spacer()
                    Text(String(format: String(localized: "widget.reminderCount"), snapshot.reminderCount))
                        .font(DesignSystem.Typography.caption).foregroundStyle(inkSub)
                }
                .padding(.top, 12)
                // Reminder rows
                VStack(alignment: .leading, spacing: 7) {
                    ForEach(Array(snapshot.reminders.prefix(5).enumerated()), id: \.offset) { _, item in
                        HStack(spacing: 6) {
                            Circle().fill(galleryKindColor(item.kind)).frame(width: 6, height: 6)
                            VStack(alignment: .leading, spacing: 0) {
                                Text(item.title)
                                    .font(DesignSystem.Typography.caption).foregroundStyle(ink).lineLimit(1)
                                Text(item.subtitle)
                                    .font(DesignSystem.Typography.caption).foregroundStyle(inkSub).lineLimit(1)
                            }
                            Spacer()
                            Text(item.dateLabel).font(DesignSystem.Typography.caption).foregroundStyle(galleryKindColor(item.kind))
                        }
                    }
                }
                .padding(.top, 6)
                Spacer()
                // CTA
                Rectangle()
                    .fill(cs == .dark ? DesignSystem.Colors.textOnPrimary.opacity(0.08) : DesignSystem.Colors.bgCard.opacity(0.12))
                    .frame(height: 0.5).padding(.top, 10)
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill").font(DesignSystem.Typography.widgetMetaBold)
                        .foregroundStyle(DesignSystem.Colors.textOnPrimary.opacity(0.85))
                    Text(String(localized: "widget.quickAdd")).font(DesignSystem.Typography.widgetMetaBold)
                        .foregroundStyle(DesignSystem.Colors.textOnPrimary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(LinearGradient(
                            colors: [accent, DesignSystem.Colors.primaryDark],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                )
                .padding(.top, 10)
            }
            .padding(16)
        }
        .frame(width: 338, height: 354)
    }

    private func largeHeroBar(label: String, value: Double, ratio: CGFloat, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(DesignSystem.Typography.caption).foregroundStyle(inkSub)
                Spacer(minLength: 0)
                Text("¥\(value, format: .number.precision(.fractionLength(0)))")
                    .font(DesignSystem.Typography.caption).foregroundStyle(ink).kerning(-0.2)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(cs == .dark ? DesignSystem.Colors.textOnPrimary.opacity(0.08) : DesignSystem.Colors.bgCard.opacity(0.10))
                    Capsule().fill(color).frame(width: geo.size.width * ratio)
                }
            }
            .frame(height: 4)
        }
    }
}

#Preview("Widget Gallery Home Stubs") {
    ScrollView {
        VStack(spacing: 16) {
            GallerySmallStub(snapshot: .galleryPreview, variant: .reminder)
            GallerySmallStub(snapshot: .galleryPreview, variant: .countdown)
            GallerySmallStub(snapshot: .galleryPreview, variant: .financial)
            GalleryMediumStub(snapshot: .galleryPreview, variant: .reminder)
            GalleryMediumStub(snapshot: .galleryPreview, variant: .event)
            GalleryMediumStub(snapshot: .galleryPreview, variant: .financial)
            GalleryLargeStub(snapshot: .galleryPreview)
        }
        .padding()
    }
}
