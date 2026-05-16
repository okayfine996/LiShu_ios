import SwiftUI
import WidgetKit

// MARK: - Large Widget

struct LiShuLargeWidgetView: View {
    let snapshot: WidgetSnapshot

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
            WidgetDivider(topPadding: 10)

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
                    WidgetNetAmountDisplay(amount: snapshot.netAmount, amountFontSize: 30, kerning: -1.2)
                }
                Spacer(minLength: 0)
            }
            if snapshot.financialTotal > 0 {
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 10
                ) {
                    WidgetFinancialBar(label: String(localized: "widget.income"), value: snapshot.yearlyIncome, ratio: snapshot.incomeRatio, color: WidgetPalette.gold, fullAmount: true)
                    WidgetFinancialBar(label: String(localized: "widget.expense"), value: snapshot.yearlyExpense, ratio: snapshot.expenseRatio, color: WidgetPalette.accent, fullAmount: true)
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

}

#Preview("Large") {
    LiShuLargeWidgetView(snapshot: .preview)
        .containerBackground(for: .widget) { WidgetBackground() }
        .frame(width: 364, height: 382)
}
