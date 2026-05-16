import SwiftUI
import WidgetKit

// MARK: - Entry View

struct LiShuWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: LiShuWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            LiShuSmallWidgetView(snapshot: entry.snapshot)
        case .systemMedium:
            LiShuMediumWidgetView(snapshot: entry.snapshot)
        case .systemLarge:
            LiShuLargeWidgetView(snapshot: entry.snapshot)
        case .accessoryCircular:
            LiShuCircularWidgetView(snapshot: entry.snapshot)
        case .accessoryRectangular:
            LiShuRectangularWidgetView(snapshot: entry.snapshot)
        case .accessoryInline:
            LiShuInlineWidgetView(snapshot: entry.snapshot)
        default:
            LiShuSmallWidgetView(snapshot: entry.snapshot)
        }
    }
}

// MARK: - Widget Definition

struct LiShuHomeWidget: Widget {
    let kind = "LiShuHomeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LiShuWidgetProvider()) { entry in
            LiShuWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) { WidgetBackground() }
        }
        .configurationDisplayName(String(localized: "widget.displayName"))
        .description(String(localized: "widget.description"))
        .supportedFamilies([
            .systemSmall, .systemMedium, .systemLarge,
            .accessoryCircular, .accessoryRectangular, .accessoryInline,
        ])
    }
}

// MARK: - Countdown Widget

struct LiShuCountdownWidget: Widget {
    let kind = "LiShuCountdownWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LiShuWidgetProvider()) { entry in
            LiShuSmallCountdownWidgetView(snapshot: entry.snapshot)
                .containerBackground(for: .widget) { WidgetBackground() }
        }
        .configurationDisplayName(String(localized: "widget.countdown.displayName"))
        .description(String(localized: "widget.countdown.description"))
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Financial Widget

struct LiShuFinancialWidget: Widget {
    let kind = "LiShuFinancialWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LiShuWidgetProvider()) { entry in
            LiShuSmallFinancialWidgetView(snapshot: entry.snapshot)
                .containerBackground(for: .widget) { WidgetBackground() }
        }
        .configurationDisplayName(String(localized: "widget.financial.displayName"))
        .description(String(localized: "widget.financial.description"))
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Medium Event Widget

struct LiShuMediumEventWidget: Widget {
    let kind = "LiShuMediumEventWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LiShuWidgetProvider()) { entry in
            LiShuMediumEventWidgetView(snapshot: entry.snapshot)
                .containerBackground(for: .widget) { WidgetBackground() }
        }
        .configurationDisplayName(String(localized: "widget.mediumEvent.displayName"))
        .description(String(localized: "widget.mediumEvent.description"))
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Medium Financial Widget

struct LiShuMediumFinancialWidget: Widget {
    let kind = "LiShuMediumFinancialWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LiShuWidgetProvider()) { entry in
            LiShuMediumFinancialWidgetView(snapshot: entry.snapshot)
                .containerBackground(for: .widget) { WidgetBackground() }
        }
        .configurationDisplayName(String(localized: "widget.mediumFinancial.displayName"))
        .description(String(localized: "widget.mediumFinancial.description"))
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Circular Countdown Widget

struct LiShuCircularCountdownWidget: Widget {
    let kind = "LiShuCircularCountdownWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LiShuWidgetProvider()) { entry in
            LiShuCircularCountdownWidgetView(snapshot: entry.snapshot)
                .containerBackground(for: .widget) { WidgetBackground() }
        }
        .configurationDisplayName(String(localized: "widget.countdownRing.displayName"))
        .description(String(localized: "widget.countdownRing.description"))
        .supportedFamilies([.accessoryCircular])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    LiShuHomeWidget()
} timeline: {
    LiShuWidgetEntry(date: .now, snapshot: .empty)
}
