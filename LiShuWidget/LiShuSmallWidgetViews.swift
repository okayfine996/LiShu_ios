import SwiftUI
import WidgetKit

// MARK: - Small Widget

struct LiShuSmallWidgetView: View {
    let snapshot: WidgetSnapshot
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Link(destination: snapshot.reminders.first?.deepLinkURL ?? .liShuHome) {
            VStack(alignment: .leading, spacing: 0) {
                WidgetHeader(count: snapshot.reminderCount, compact: true)
                Spacer(minLength: 0)
                if let first = snapshot.reminders.first {
                    let dot = kindColor(first.kind)
                    Text("\(String(localized: "widget.small.nextItem")) · \(kindName(first.kind))")
                        .font(.system(size: 9, weight: .bold))
                        .kerning(0.8)
                        .foregroundStyle(dot)
                        .textCase(.uppercase)
                        .lineLimit(1)
                        .padding(.bottom, 4)
                    // Title
                    Text(first.title)
                        .font(.system(size: 17, weight: .heavy))
                        .foregroundStyle(
                            colorScheme == .dark ? WidgetPalette.parchment : WidgetPalette.ink
                        )
                        .lineLimit(2)
                    // Date + subtitle line
                    if let eventDate = first.eventDateLabel {
                        Text("\(eventDate) · \(first.subtitle)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(
                                colorScheme == .dark
                                    ? WidgetPalette.parchment.opacity(0.55)
                                    : WidgetPalette.inkSecondary
                            )
                            .lineLimit(1)
                            .padding(.top, 2)
                    }
                    // Badge row
                    HStack(spacing: 6) {
                        Text(first.dateLabel)
                            .font(.system(size: 11, weight: .heavy))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule().fill(
                                    LinearGradient(
                                        colors: [dot, dot.opacity(0.85)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            )
                            .foregroundStyle(.white)
                        if snapshot.reminderCount > 1 {
                            Text(String(format: String(localized: "widget.more.items"), snapshot.reminderCount - 1))
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(
                                    colorScheme == .dark
                                        ? WidgetPalette.parchment.opacity(0.55)
                                        : WidgetPalette.inkSecondary
                                )
                        }
                    }
                    .padding(.top, 10)
                } else {
                    WidgetEmptyState()
                }
            }
            .padding(14)
        }
    }
}

// MARK: - Small Countdown Widget

struct LiShuSmallCountdownWidgetView: View {
    let snapshot: WidgetSnapshot
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if let event = snapshot.nextHostingEvent {
            Link(destination: event.deepLinkURL) {
                countdownContent(event: event)
            }
        } else {
            emptyContent
        }
    }

    private func countdownContent(event: WidgetHostingEventItem) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            WidgetHeader(count: 0, compact: true)
            Spacer(minLength: 0)
            // "主办中 · 婚礼" label
            Text(String(format: String(localized: "widget.hosting.status"), event.typeName))
                .font(.system(size: 9, weight: .bold))
                .kerning(0.8)
                .foregroundStyle(WidgetPalette.gold)
                .textCase(.uppercase)
                .lineLimit(1)
                .padding(.bottom, 4)
            // Event name
            Text(event.name)
                .font(.system(size: 16, weight: .heavy))
                .foregroundStyle(
                    colorScheme == .dark ? WidgetPalette.parchment : WidgetPalette.ink
                )
                .lineLimit(1)
            // D-7 large countdown
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("D–")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(colorScheme == .dark ? WidgetPalette.parchment : WidgetPalette.ink)
                    .padding(.bottom, 2)
                Text("\(event.daysUntil)")
                    .font(.system(size: 42, weight: .heavy))
                    .foregroundStyle(colorScheme == .dark ? WidgetPalette.parchment : WidgetPalette.ink)
                    .kerning(-2.5)
                    .lineLimit(1)
            }
            .padding(.top, 4)
            // Date line
            Text(event.dateLine)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(
                    colorScheme == .dark
                        ? WidgetPalette.parchment.opacity(0.6)
                        : WidgetPalette.inkSecondary
                )
                .lineLimit(1)
        }
        .padding(14)
    }

    private var emptyContent: some View {
        Link(destination: .liShuHome) {
            VStack(alignment: .leading, spacing: 0) {
                WidgetHeader(count: 0, compact: true)
                Spacer(minLength: 0)
                WidgetEmptyState()
            }
            .padding(14)
        }
    }
}

// MARK: - Small Financial Widget

struct LiShuSmallFinancialWidgetView: View {
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
                WidgetHeader(count: 0, compact: true)
                Spacer(minLength: 0)
                // "礼金净额 · {干支年}" label
                Text("\(String(localized: "widget.netAmount")) · \(chineseYear(snapshot.currentYear))")
                    .font(.system(size: 9, weight: .bold))
                    .kerning(0.8)
                    .foregroundStyle(colorScheme == .dark ? WidgetPalette.parchment.opacity(0.55) : WidgetPalette.inkSecondary)
                    .textCase(.uppercase)
                    .padding(.bottom, 2)
                // Net amount
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(netAmount >= 0 ? "+¥" : "-¥")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(colorScheme == .dark ? WidgetPalette.parchment : WidgetPalette.ink)
                    Text(
                        abs(netAmount),
                        format: .number.precision(.fractionLength(0))
                    )
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundStyle(colorScheme == .dark ? WidgetPalette.parchment : WidgetPalette.ink)
                    .kerning(-1.2)
                }
                // Income / expense bars
                if total > 0 {
                    VStack(alignment: .leading, spacing: 6) {
                        incomeExpenseBar(
                            label: String(localized: "widget.income"),
                            value: snapshot.yearlyIncome,
                            ratio: incomeRatio,
                            color: WidgetPalette.gold
                        )
                        incomeExpenseBar(
                            label: String(localized: "widget.expense"),
                            value: snapshot.yearlyExpense,
                            ratio: expenseRatio,
                            color: WidgetPalette.accent
                        )
                    }
                    .padding(.top, 12)
                }
                // Footer stats
                Text(String(format: String(localized: "widget.stats.footer"), snapshot.yearlyRecordCount, snapshot.yearlyContactCount))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(
                        colorScheme == .dark ? WidgetPalette.parchment.opacity(0.55) : WidgetPalette.inkSecondary
                    )
                    .padding(.top, 8)
            }
            .padding(14)
        }
    }

    private func incomeExpenseBar(label: String, value: Double, ratio: CGFloat, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(label)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(
                        colorScheme == .dark ? WidgetPalette.parchment.opacity(0.6) : WidgetPalette.inkSecondary
                    )
                Spacer(minLength: 0)
                Text("¥\(value, format: .number.notation(.compactName).precision(.significantDigits(2)))")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(
                        colorScheme == .dark ? WidgetPalette.parchment.opacity(0.6) : WidgetPalette.inkSecondary
                    )
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(
                            colorScheme == .dark
                                ? Color.white.opacity(0.08)
                                : Color(red: 0.47, green: 0.35, blue: 0.24).opacity(0.10)
                        )
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * ratio)
                }
            }
            .frame(height: 4)
        }
    }
}

#Preview("Small – Reminders") {
    LiShuSmallWidgetView(snapshot: .preview)
        .containerBackground(for: .widget) { WidgetBackground() }
        .frame(width: 170, height: 170)
}

#Preview("Small – Countdown") {
    LiShuSmallCountdownWidgetView(snapshot: .preview)
        .containerBackground(for: .widget) { WidgetBackground() }
        .frame(width: 170, height: 170)
}

#Preview("Small – Financial") {
    LiShuSmallFinancialWidgetView(snapshot: .preview)
        .containerBackground(for: .widget) { WidgetBackground() }
        .frame(width: 170, height: 170)
}
