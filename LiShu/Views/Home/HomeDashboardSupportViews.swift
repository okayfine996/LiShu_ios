import SwiftUI

struct HomeSectionHeader: View {
    let title: String
    var route: AppRoute?

    var body: some View {
        HStack {
            Text(title)
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Spacer()

            if let route {
                NavigationLink(value: route) {
                    Text(String(localized: "common.viewAll"))
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.primary)
                }
            }
        }
    }
}

struct HomeEmptyUpcomingCard: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar")
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
                .frame(width: 40, height: 40)
                .background(DesignSystem.Colors.bgIconSubtle)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))

            Text(String(localized: "home.noUpcoming"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textTertiary)

            Spacer()
        }
        .padding(14)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard)
                .stroke(DesignSystem.Colors.primary.opacity(0.05), lineWidth: 1)
        )
    }
}

struct HomeUpcomingEventCard: View {
    let event: Event

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            cardBackground
                .overlay {
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0),
                            Color.black.opacity(0.08),
                            Color.black.opacity(0.26),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }

            VStack(alignment: .leading, spacing: 8) {
                Text(event.type.displayName)
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(DesignSystem.Colors.bgSurface.opacity(0.9))
                    .clipShape(Capsule())

                VStack(alignment: .leading, spacing: 2) {
                    Text(event.name)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(.white)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    Text(HomeDashboardFormatters.eventDate(event.date))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(.white.opacity(0.82))
                }
            }
            .padding(12)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 196)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .padding(.horizontal, 2)
    }

    @ViewBuilder
    private var cardBackground: some View {
        if let data = event.coverImage {
            DecodedImageView(data: data, maxPixelSize: ImagePipeline.Preset.homeHeroMaxPixelSize)
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
        } else {
            LinearGradient(
                colors: HomeDashboardGradients.colors(for: event.type),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                Image(systemName: event.type.iconName)
                    .font(DesignSystem.Typography.title1)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }
}

struct HomeRecentRecordCard: View {
    let record: Record

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(imageData: record.contact?.avatar, name: record.contact?.name ?? "")

            VStack(alignment: .leading, spacing: 3) {
                Text(record.contact?.name ?? "")
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Text(record.contextDisplayName)
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if record.isMonetary {
                    Text(HomeDashboardFormatters.recordAmount(record))
                        .font(DesignSystem.Typography.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(DesignSystem.Colors.primary)
                } else {
                    HStack(spacing: 4) {
                        Text(record.recordType.iconEmoji)
                            .font(DesignSystem.Typography.caption)
                        Text(record.resolvedDescription)
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                            .lineLimit(1)
                    }
                }

                Text(HomeDashboardFormatters.relativeDate(record.date))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
    }
}

enum HomeDashboardMetrics {
    static var summaryCardWidth: CGFloat {
        UIScreen.main.bounds.width - (DesignSystem.Spacing.pageHorizontal * 2) - 4
    }
}

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

    static func totalExchangeAmount(_ snapshot: HomeDashboardSnapshot) -> String {
        "¥" + commaSeparated(snapshot.totalExchangeAmount)
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

    static func coreCircleSummary(_ snapshot: HomeDashboardSnapshot) -> String {
        String(format: String(localized: "home.coreCircleShareFormat"), snapshot.coreCircleRatioPercent)
    }

    static func nonFinancialSummary(_ snapshot: HomeDashboardSnapshot) -> String {
        String(
            format: String(localized: "home.nonFinancialSummaryFormat"),
            snapshot.nonFinancialInteractionCount
        )
    }

    static func eventDate(_ date: Date) -> String {
        eventDateFormatter.string(from: date)
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

private enum HomeDashboardGradients {
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
