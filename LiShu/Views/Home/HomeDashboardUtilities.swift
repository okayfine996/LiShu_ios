import SwiftUI

enum HomeDashboardFormatters {
    private static let eventDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans")
        formatter.dateFormat = "M月dd日"
        return formatter
    }()

    private static let lunarYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .chinese)
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.dateFormat = "U年"
        return formatter
    }()

    private static let decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    private static let weekDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans")
        formatter.dateFormat = "EEE"
        return formatter
    }()

    private static let monthDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans")
        formatter.dateFormat = "M月d日"
        return formatter
    }()

    static var lunarYearLabel: String {
        lunarYearFormatter.string(from: Date())
    }

    static func income(_ snapshot: HomeDashboardSnapshot) -> String {
        "¥" + compactNumber(snapshot.yearlyIncome)
    }

    static func expense(_ snapshot: HomeDashboardSnapshot) -> String {
        "¥" + compactNumber(snapshot.yearlyExpense)
    }

    static func monetaryNet(_ snapshot: HomeDashboardSnapshot) -> String {
        netValue(snapshot.yearlyIncome - snapshot.yearlyExpense)
    }

    static func yearOverYearChange(_ snapshot: HomeDashboardSnapshot) -> String? {
        guard let rate = snapshot.yearOverYearChangeRate else { return nil }
        let sign = rate >= 0 ? "+" : "-"
        return String(
            format: String(localized: "statistics.hero.yoy"),
            sign,
            abs(rate) * 100
        )
    }

    static func eventDate(_ date: Date) -> String {
        eventDateFormatter.string(from: date)
    }

    static func upcomingEventSupportingText(_ event: Event) -> String? {
        let trimmedLocation = event.location.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedLocation.isEmpty else {
            return nil
        }
        return trimmedLocation
    }

    static func recordAmount(_ record: Record) -> String {
        "¥" + String(format: "%.0f", record.monetaryAmount)
    }

    static func relativeDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let recordDay = calendar.startOfDay(for: date)
        let days = calendar.dateComponents([.day], from: recordDay, to: today).day ?? 0

        if days == 0 {
            return String(localized: "home.today")
        }
        if days == 1 {
            return String(localized: "home.yesterday")
        }
        if days < 7 {
            return weekDayFormatter.string(from: date)
        }
        return monthDayFormatter.string(from: date)
    }

    private static func compactNumber(_ value: Double) -> String {
        if value >= 10000 {
            return String(format: String(localized: "number.tenThousandsFormat"), value / 10000)
        }
        return String(format: "%.0f", value)
    }

    private static func commaSeparated(_ amount: Double) -> String {
        decimalFormatter.string(from: NSNumber(value: amount)) ?? String(format: "%.0f", amount)
    }

    private static func netValue(_ value: Double) -> String {
        let prefix = value >= 0 ? "+" : ""
        return prefix + "¥" + commaSeparated(value)
    }
}

enum HomeDashboardGradients {
    static func colors(for type: EventType) -> [Color] {
        switch type {
        case .wedding, .engagement:
            [DesignSystem.Colors.primary.opacity(0.3), DesignSystem.Colors.primary.opacity(0.1)]
        case .birthday, .longevity:
            [DesignSystem.Colors.accentGold.opacity(0.3), DesignSystem.Colors.accentGold.opacity(0.1)]
        case .education, .promotion:
            [DesignSystem.Colors.primary.opacity(0.2), DesignSystem.Colors.accentGold.opacity(0.15)]
        case .funeral, .visit:
            [DesignSystem.Colors.textSecondary.opacity(0.2), DesignSystem.Colors.textSecondary.opacity(0.1)]
        case .festival:
            [DesignSystem.Colors.primary.opacity(0.25), DesignSystem.Colors.accentGold.opacity(0.2)]
        case .property, .business:
            [DesignSystem.Colors.accentGold.opacity(0.25), DesignSystem.Colors.primary.opacity(0.15)]
        case .birth:
            [DesignSystem.Colors.primary.opacity(0.2), DesignSystem.Colors.primary.opacity(0.08)]
        case .other:
            [DesignSystem.Colors.textSecondary.opacity(0.15), DesignSystem.Colors.bgCard]
        }
    }
}

extension Array {
    func element(at index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}

extension View {
    func homeSummaryCardChrome() -> some View {
        padding(.horizontal, DesignSystem.Spacing.cardPadding)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                    .stroke(DesignSystem.Colors.primary.opacity(0.08), lineWidth: 1)
            )
    }
}
