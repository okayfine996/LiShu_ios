import SwiftUI
import WidgetKit

// MARK: - Circular Lock Screen Widget

struct LiShuCircularWidgetView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        ZStack {
            if snapshot.reminderCount > 0 {
                Image(systemName: "bell.fill")
                    .widgetAccentable()
                    .font(.title2)
                Text("\(snapshot.reminderCount)")
                    .font(.system(size: 9, weight: .bold))
                    .offset(x: 9, y: -9)
            } else {
                Image(systemName: "bell")
                    .widgetAccentable()
                    .font(.title2)
            }
        }
        .widgetURL(snapshot.reminders.first?.deepLinkURL ?? .liShuHome)
        .widgetLabel {
            Text(snapshot.reminders.first?.title ?? String(localized: "widget.noReminders"))
                .widgetAccentable()
        }
    }
}

// MARK: - Rectangular Lock Screen Widget

struct LiShuRectangularWidgetView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        if let first = snapshot.reminders.first {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 5) {
                    LiShuMark(size: 14)
                    Text(String(localized: "widget.displayName"))
                        .font(.system(size: 11, weight: .bold))
                        .widgetAccentable()
                    Spacer(minLength: 0)
                    Text(first.dateLabel)
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(Color.white.opacity(0.20))
                        )
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(first.title)
                        .font(.system(size: 15, weight: .heavy))
                        .widgetAccentable()
                        .lineLimit(1)
                    Text(first.eventDateLabel.map { "\($0) · \(first.subtitle)" } ?? first.subtitle)
                        .font(.system(size: 10.5, weight: .semibold))
                        .opacity(0.78)
                        .lineLimit(1)
                }
            }
            .widgetURL(first.deepLinkURL)
        } else {
            Label(String(localized: "widget.noReminders"), systemImage: "checkmark.circle")
                .widgetAccentable()
                .widgetURL(.liShuHome)
        }
    }
}

// MARK: - Inline Lock Screen Widget

struct LiShuInlineWidgetView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        if let first = snapshot.reminders.first {
            Label(
                "\(String(localized: "widget.displayName")) · \(first.title) · \(first.dateLabel)",
                systemImage: "bell.fill"
            )
            .widgetAccentable()
            .widgetURL(first.deepLinkURL)
        } else {
            Label(String(localized: "widget.noReminders"), systemImage: "bell")
                .widgetURL(.liShuHome)
        }
    }
}

// MARK: - Circular Countdown Lock Screen Widget

struct LiShuCircularCountdownWidgetView: View {
    let snapshot: WidgetSnapshot

    private var progress: Double {
        guard let event = snapshot.nextHostingEvent, event.daysUntil >= 0 else { return 0 }
        return max(0, min(1, 1.0 - Double(event.daysUntil) / 30.0))
    }

    var body: some View {
        if let event = snapshot.nextHostingEvent {
            Gauge(value: progress, in: 0 ... 1) {
                EmptyView()
            } currentValueLabel: {
                VStack(spacing: 0) {
                    Text("D–")
                        .font(.system(size: 10, weight: .bold))
                        .widgetAccentable()
                    Text("\(event.daysUntil)")
                        .font(.system(size: 24, weight: .heavy))
                        .widgetAccentable()
                }
            }
            .gaugeStyle(.accessoryCircular)
            .widgetAccentable()
            .widgetURL(event.deepLinkURL)
        } else {
            Image(systemName: "calendar.badge.clock")
                .widgetAccentable()
                .font(.title2)
                .widgetURL(.liShuHome)
        }
    }
}

#Preview("Lock – Circular") {
    LiShuCircularWidgetView(snapshot: .preview)
}

#Preview("Lock – Circular Countdown") {
    LiShuCircularCountdownWidgetView(snapshot: .preview)
}

#Preview("Lock – Rectangular") {
    LiShuRectangularWidgetView(snapshot: .preview)
        .frame(width: 338, height: 58)
}

#Preview("Lock – Inline") {
    LiShuInlineWidgetView(snapshot: .preview)
}
