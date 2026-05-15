import SwiftUI
import WidgetKit

// MARK: - Medium Widget

struct LiShuMediumWidgetView: View {
    let snapshot: WidgetSnapshot
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            WidgetHeader(count: snapshot.reminderCount)
            if snapshot.reminders.isEmpty {
                Spacer(minLength: 0)
                WidgetEmptyState()
                Spacer(minLength: 0)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(snapshot.reminders.prefix(3)) { item in
                        Link(destination: item.deepLinkURL) {
                            WidgetReminderRow(item: item)
                        }
                    }
                }
                .padding(.top, 8)
                Spacer(minLength: 0)
            }
            // Divider
            Rectangle()
                .fill(
                    colorScheme == .dark
                        ? Color.white.opacity(0.08)
                        : Color(red: 0.47, green: 0.35, blue: 0.24).opacity(0.12)
                )
                .frame(height: 0.5)
                .padding(.top, 8)
            // Quick-add bar
            Link(destination: .liShuAddRecord) {
                HStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [WidgetPalette.accent, WidgetPalette.accentDark],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 22, height: 22)
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    Text(String(localized: "widget.quickAdd"))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(
                            colorScheme == .dark ? WidgetPalette.parchment : WidgetPalette.ink
                        )
                    Text(String(localized: "widget.quickAdd.subtitle"))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(
                            colorScheme == .dark
                                ? WidgetPalette.parchment.opacity(0.50)
                                : WidgetPalette.inkSecondary
                        )
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(
                            colorScheme == .dark
                                ? WidgetPalette.parchment.opacity(0.45)
                                : WidgetPalette.inkTertiary
                        )
                }
                .padding(.top, 6)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .widgetURL(.liShuHome)
    }
}

// MARK: - Medium Hosting Event Widget

struct LiShuMediumEventWidgetView: View {
    let snapshot: WidgetSnapshot
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if let event = snapshot.nextHostingEvent {
            eventContent(event: event)
                .widgetURL(event.deepLinkURL)
        } else {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(WidgetPalette.accent.opacity(0.15))
                    .frame(width: 100)
                VStack(alignment: .leading, spacing: 0) {
                    WidgetHeader(count: 0, compact: true)
                    Spacer(minLength: 0)
                    WidgetEmptyState()
                    Spacer(minLength: 0)
                }
            }
            .padding(14)
            .widgetURL(.liShuHome)
        }
    }

    private func eventContent(event: WidgetHostingEventItem) -> some View {
        HStack(alignment: .top, spacing: 14) {
            sceneSwatch(event: event)
                .frame(width: 100)
            VStack(alignment: .leading, spacing: 0) {
                WidgetHeader(count: 0, compact: true)
                Text(String(format: String(localized: "widget.hosting.status"), event.typeName))
                    .font(.system(size: 9.5, weight: .bold))
                    .kerning(0.8)
                    .foregroundStyle(WidgetPalette.gold)
                    .textCase(.uppercase)
                    .padding(.top, 6)
                Text(event.name)
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(colorScheme == .dark ? WidgetPalette.parchment : WidgetPalette.ink)
                    .lineLimit(1)
                    .padding(.top, 1)
                Text(event.dateLine)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(colorScheme == .dark ? WidgetPalette.parchment.opacity(0.55) : WidgetPalette.inkSecondary)
                    .lineLimit(1)
                    .padding(.top, 2)
                Spacer(minLength: 0)
                statsRow(event: event)
            }
        }
        .padding(14)
    }

    private func sceneSwatch(event: WidgetHostingEventItem) -> some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [
                    Color(red: 0.961, green: 0.773, blue: 0.690),
                    Color(red: 0.910, green: 0.604, blue: 0.522),
                    WidgetPalette.accent,
                ],
                startPoint: .top, endPoint: .bottom
            )
            Circle()
                .fill(Color(red: 1.0, green: 0.953, blue: 0.843))
                .frame(width: 22, height: 22)
                .shadow(color: Color(red: 1.0, green: 0.953, blue: 0.843).opacity(0.7), radius: 9)
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
                .fill(Color(red: 0.545, green: 0.290, blue: 0.247).opacity(0.55))
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
                .fill(Color(red: 0.361, green: 0.180, blue: 0.157).opacity(0.65))
            }
            Text("D–\(event.daysUntil)")
                .font(.system(size: 10, weight: .heavy))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule().fill(Color.black.opacity(0.30))
                        .overlay(Capsule().strokeBorder(Color.white.opacity(0.35), lineWidth: 0.5))
                )
                .padding(8)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func statsRow(event: WidgetHostingEventItem) -> some View {
        HStack(spacing: 0) {
            if let total = event.giftReceivedTotal {
                VStack(alignment: .leading, spacing: 1) {
                    Text(String(localized: "widget.event.giftReceived"))
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(colorScheme == .dark ? WidgetPalette.parchment.opacity(0.55) : WidgetPalette.inkSecondary)
                    Text("¥\(total, format: .number.precision(.fractionLength(0)))")
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundStyle(WidgetPalette.accent)
                        .kerning(-0.6)
                }
            }
            if let guests = event.guestCount, event.giftReceivedTotal != nil {
                Rectangle()
                    .fill(colorScheme == .dark ? Color.white.opacity(0.10) : Color(red: 0.47, green: 0.35, blue: 0.24).opacity(0.15))
                    .frame(width: 0.5, height: 28)
                    .padding(.horizontal, 10)
                VStack(alignment: .leading, spacing: 1) {
                    Text(String(localized: "widget.event.guestCount"))
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(colorScheme == .dark ? WidgetPalette.parchment.opacity(0.55) : WidgetPalette.inkSecondary)
                    Text("\(guests)")
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundStyle(colorScheme == .dark ? WidgetPalette.parchment : WidgetPalette.ink)
                        .kerning(-0.6)
                }
            } else if event.giftReceivedTotal == nil {
                Text(event.dateLine)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(colorScheme == .dark ? WidgetPalette.parchment.opacity(0.55) : WidgetPalette.inkSecondary)
            }
            Spacer(minLength: 0)
            Link(destination: event.addRecordURL ?? event.deepLinkURL) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(WidgetPalette.accent)
                    Text(String(localized: "widget.event.register"))
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(WidgetPalette.accent)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(colorScheme == .dark ? WidgetPalette.accent.opacity(0.15) : WidgetPalette.accent.opacity(0.10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(WidgetPalette.accent.opacity(0.30), lineWidth: 0.5)
                        )
                )
            }
        }
    }
}

// MARK: - Medium Financial Widget (Annual Overview)

struct LiShuMediumFinancialWidgetView: View {
    let snapshot: WidgetSnapshot
    @Environment(\.colorScheme) private var colorScheme

    private var netAmount: Double {
        snapshot.yearlyIncome - snapshot.yearlyExpense
    }

    private var total: Double {
        snapshot.yearlyIncome + snapshot.yearlyExpense
    }

    private var incomeRatio: CGFloat {
        total > 0 ? CGFloat(snapshot.yearlyIncome / total) : 0
    }

    private var expenseRatio: CGFloat {
        total > 0 ? CGFloat(snapshot.yearlyExpense / total) : 0
    }

    var body: some View {
        Link(destination: .liShuHome) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    LiShuMark(size: 14)
                    Text(String(localized: "widget.medium.financial.header"))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(colorScheme == .dark ? WidgetPalette.parchment.opacity(0.92) : WidgetPalette.ink)
                    Spacer(minLength: 0)
                }

                HStack(alignment: .bottom, spacing: 14) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(String(localized: "widget.netAmount"))
                            .font(.system(size: 9, weight: .bold))
                            .kerning(0.6)
                            .textCase(.uppercase)
                            .foregroundStyle(colorScheme == .dark ? WidgetPalette.parchment.opacity(0.55) : WidgetPalette.inkSecondary)
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text(netAmount >= 0 ? "+¥" : "-¥")
                                .font(.system(size: 13, weight: .heavy))
                                .foregroundStyle(WidgetPalette.accent)
                            Text(abs(netAmount), format: .number.precision(.fractionLength(0)))
                                .font(.system(size: 34, weight: .heavy))
                                .foregroundStyle(WidgetPalette.accent)
                                .kerning(-1.5)
                        }
                    }
                }
                .padding(.top, 8)

                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 10
                ) {
                    financialBar(
                        label: String(localized: "widget.income"),
                        value: snapshot.yearlyIncome,
                        ratio: incomeRatio,
                        color: WidgetPalette.gold
                    )
                    financialBar(
                        label: String(localized: "widget.expense"),
                        value: snapshot.yearlyExpense,
                        ratio: expenseRatio,
                        color: WidgetPalette.accent
                    )
                }
                .padding(.top, 10)

                Rectangle()
                    .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color(red: 0.47, green: 0.35, blue: 0.24).opacity(0.12))
                    .frame(height: 0.5)
                    .padding(.top, 8)

                HStack(spacing: 10) {
                    statItem(
                        dot: WidgetPalette.accent,
                        label: String(localized: "widget.stat.interactions"),
                        value: "\(snapshot.yearlyRecordCount)",
                        unit: String(localized: "widget.stat.unit.records")
                    )
                    statItem(
                        dot: WidgetPalette.gold,
                        label: String(localized: "widget.stat.contacts"),
                        value: "\(snapshot.yearlyContactCount)",
                        unit: String(localized: "widget.stat.unit.contacts")
                    )
                    if snapshot.pendingReturnCount > 0 {
                        statItem(
                            dot: WidgetPalette.sage,
                            label: String(localized: "widget.stat.pendingReturn"),
                            value: "\(snapshot.pendingReturnCount)",
                            unit: String(localized: "widget.stat.unit.records")
                        )
                    }
                }
                .padding(.top, 8)
            }
            .padding(14)
        }
    }

    private func financialBar(label: String, value: Double, ratio: CGFloat, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 9.5, weight: .semibold))
                    .foregroundStyle(colorScheme == .dark ? WidgetPalette.parchment.opacity(0.6) : WidgetPalette.inkSecondary)
                Spacer(minLength: 0)
                Text("¥\(value, format: .number.notation(.compactName).precision(.significantDigits(2)))")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(color)
                    .kerning(-0.2)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color(red: 0.47, green: 0.35, blue: 0.24).opacity(0.10))
                    Capsule().fill(color).frame(width: geo.size.width * ratio)
                }
            }
            .frame(height: 4)
        }
    }

    private func statItem(dot: Color, label: String, value: String, unit: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(dot).frame(width: 5, height: 5)
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(colorScheme == .dark ? WidgetPalette.parchment.opacity(0.6) : WidgetPalette.inkSecondary)
            Text(value)
                .font(.system(size: 12, weight: .heavy))
                .foregroundStyle(colorScheme == .dark ? WidgetPalette.parchment : WidgetPalette.ink)
                .kerning(-0.2)
                + Text(unit)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(colorScheme == .dark ? WidgetPalette.parchment.opacity(0.55) : WidgetPalette.inkSecondary)
        }
    }
}

#Preview("Medium – Reminders") {
    LiShuMediumWidgetView(snapshot: .preview)
        .containerBackground(for: .widget) { WidgetBackground() }
        .frame(width: 364, height: 170)
}

#Preview("Medium – Event") {
    LiShuMediumEventWidgetView(snapshot: .preview)
        .containerBackground(for: .widget) { WidgetBackground() }
        .frame(width: 364, height: 170)
}

#Preview("Medium – Financial") {
    LiShuMediumFinancialWidgetView(snapshot: .preview)
        .containerBackground(for: .widget) { WidgetBackground() }
        .frame(width: 364, height: 170)
}
