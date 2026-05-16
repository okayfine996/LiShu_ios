import SwiftUI
import WidgetKit

// MARK: - Large Widget

struct LiShuLargeWidgetView: View {
    let snapshot: WidgetSnapshot

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
        VStack(alignment: .leading, spacing: 0) {
            WidgetHeader(count: snapshot.reminderCount)

            // Hero strip
            heroStrip
                .padding(.top, 10)

            // Section header
            HStack {
                Text(String(localized: "widget.reminders.sectionTitle"))
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(WidgetPalette.textPrimary)
                Spacer(minLength: 0)
                Text(String(format: String(localized: "widget.reminderCount"), snapshot.reminderCount))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(WidgetPalette.textSecondary)
            }
            .padding(.top, 12)

            VStack(alignment: .leading, spacing: 7) {
                if snapshot.reminders.isEmpty {
                    WidgetEmptyState()
                } else {
                    ForEach(snapshot.reminders.prefix(5)) { item in
                        Link(destination: item.deepLinkURL) {
                            WidgetReminderRow(item: item)
                        }
                    }
                }
            }
            .padding(.top, 6)

            Spacer(minLength: 0)

            // Divider + CTA
            Rectangle()
                .fill(WidgetPalette.divider)
                .frame(height: 0.5)
                .padding(.top, 10)

            Link(destination: .liShuAddRecord) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.85))
                    Text(String(localized: "widget.quickAdd"))
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [WidgetPalette.accent, WidgetPalette.accentDark],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
            }
            .padding(.top, 10)
        }
        .padding(16)
        .widgetURL(.liShuHome)
    }

    private var heroStrip: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(String(localized: "widget.netAmount")) · \(chineseYear(snapshot.currentYear))")
                        .font(.system(size: 9, weight: .bold))
                        .kerning(0.6)
                        .textCase(.uppercase)
                        .foregroundStyle(WidgetPalette.textSecondary)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(netAmount >= 0 ? "+¥" : "-¥")
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundStyle(WidgetPalette.textPrimary)
                        Text(
                            abs(netAmount),
                            format: .number.precision(.fractionLength(0))
                        )
                        .font(.system(size: 30, weight: .heavy))
                        .foregroundStyle(WidgetPalette.textPrimary)
                        .kerning(-1.2)
                    }
                }
                Spacer(minLength: 0)
            }
            if total > 0 {
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 10
                ) {
                    barItem(
                        label: String(localized: "widget.income"),
                        value: snapshot.yearlyIncome,
                        ratio: incomeRatio,
                        color: WidgetPalette.gold
                    )
                    barItem(
                        label: String(localized: "widget.expense"),
                        value: snapshot.yearlyExpense,
                        ratio: expenseRatio,
                        color: WidgetPalette.accent
                    )
                }
                .padding(.top, 8)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [WidgetPalette.heroAccentFill, WidgetPalette.heroGoldFill],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(WidgetPalette.accent.opacity(0.25), lineWidth: 0.5)
                )
        )
    }

    private func barItem(label: String, value: Double, ratio: CGFloat, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 9.5, weight: .semibold))
                    .foregroundStyle(WidgetPalette.textSecondary)
                Spacer(minLength: 0)
                Text("¥\(value, format: .number.precision(.fractionLength(0)))")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(WidgetPalette.textPrimary)
                    .kerning(-0.2)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(WidgetPalette.barTrack)
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * ratio)
                }
            }
            .frame(height: 4)
        }
    }
}

#Preview("Large") {
    LiShuLargeWidgetView(snapshot: .preview)
        .containerBackground(for: .widget) { WidgetBackground() }
        .frame(width: 364, height: 382)
}
