import SwiftUI

// MARK: - Deep Link URL helpers

extension URL {
    static let liShuHome: URL = {
        var c = URLComponents(); c.scheme = "lishu"; c.host = "home"
        return c.url ?? URL(fileURLWithPath: "/")
    }()

    static let liShuAddRecord: URL = {
        var c = URLComponents(); c.scheme = "lishu"; c.host = "add-record"
        return c.url ?? URL(fileURLWithPath: "/")
    }()
}

// MARK: - Palette

enum WidgetPalette {
    static let accent = Color(red: 0.718, green: 0.431, blue: 0.353) // #B76E5A
    static let accentDark = Color(red: 0.624, green: 0.353, blue: 0.278) // #9F5A47
    static let gold = Color(red: 0.773, green: 0.627, blue: 0.396) // #C5A065
    static let sage = Color(red: 0.478, green: 0.620, blue: 0.541) // #7A9E8A
    static let parchment = Color(red: 0.961, green: 0.937, blue: 0.902) // #F5EFE6
    static let ink = Color(red: 0.173, green: 0.173, blue: 0.173) // #2C2C2C
    static let inkSecondary = Color(red: 0.478, green: 0.455, blue: 0.431) // #7A746E
    static let inkTertiary = Color(red: 0.671, green: 0.647, blue: 0.624) // #ABA59F
}

func kindColor(_ kind: ReminderKind) -> Color {
    switch kind {
    case .event: WidgetPalette.accent
    case .birthday: WidgetPalette.gold
    case .pendingReturn: WidgetPalette.sage
    }
}

func kindName(_ kind: ReminderKind) -> String {
    switch kind {
    case .event: String(localized: "widget.kind.event")
    case .birthday: String(localized: "widget.reminder.birthday")
    case .pendingReturn: String(localized: "widget.kind.pendingReturn")
    }
}

func chineseYear(_ gregorianYear: Int) -> String {
    let stems = ["甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸"]
    let branches = ["子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥"]
    return "\(stems[(gregorianYear - 4) % 10])\(branches[(gregorianYear - 4) % 12])年"
}

// MARK: - Background

struct WidgetBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if colorScheme == .dark {
            LinearGradient(
                colors: [
                    Color(red: 0.110, green: 0.106, blue: 0.098),
                    Color(red: 0.055, green: 0.047, blue: 0.039),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            LinearGradient(
                colors: [
                    Color(red: 0.984, green: 0.965, blue: 0.933),
                    Color(red: 0.945, green: 0.898, blue: 0.831),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - Shared Sub-components

struct LiShuMark: View {
    var size: CGFloat = 14

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [WidgetPalette.accent, WidgetPalette.accentDark],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Text("礼")
                .font(.system(size: size * 0.62, weight: .heavy))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
    }
}

struct WidgetHeader: View {
    let count: Int
    var compact: Bool = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 6) {
            LiShuMark(size: compact ? 14 : 16)
            Text(String(localized: "widget.displayName"))
                .font(.system(size: compact ? 11 : 12, weight: .bold))
                .foregroundStyle(
                    colorScheme == .dark
                        ? WidgetPalette.parchment.opacity(0.92)
                        : WidgetPalette.ink
                )
            Spacer(minLength: 0)
            if count > 0 {
                Text(String(format: String(localized: "widget.reminderCount"), count))
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(
                        Capsule().fill(
                            colorScheme == .dark
                                ? WidgetPalette.accent.opacity(0.28)
                                : WidgetPalette.accent.opacity(0.14)
                        )
                    )
                    .foregroundStyle(
                        colorScheme == .dark
                            ? Color(red: 0.910, green: 0.710, blue: 0.635)
                            : WidgetPalette.accent
                    )
            }
        }
    }
}

struct WidgetReminderRow: View {
    let item: WidgetReminderItem
    var compact: Bool = false
    @Environment(\.colorScheme) private var colorScheme

    private var dot: Color {
        kindColor(item.kind)
    }

    var body: some View {
        HStack(spacing: compact ? 6 : 8) {
            Circle()
                .fill(dot)
                .frame(width: 6, height: 6)
            VStack(alignment: .leading, spacing: 1) {
                Text(item.title)
                    .font(.system(size: compact ? 11 : 12, weight: .semibold))
                    .foregroundStyle(
                        colorScheme == .dark ? WidgetPalette.parchment : WidgetPalette.ink
                    )
                    .lineLimit(1)
                if !compact {
                    Text(item.subtitle)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(
                            colorScheme == .dark
                                ? WidgetPalette.parchment.opacity(0.55)
                                : WidgetPalette.inkSecondary
                        )
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
            Text(item.dateLabel)
                .font(.system(size: compact ? 10 : 10.5, weight: .bold))
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(Capsule().fill(
                    colorScheme == .dark ? dot.opacity(0.30) : dot.opacity(0.18)
                ))
                .foregroundStyle(dot)
                .fixedSize()
        }
    }
}

struct WidgetEmptyState: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack {
            Spacer()
            Label(String(localized: "widget.noReminders"), systemImage: "calendar.badge.checkmark")
                .font(.caption)
                .foregroundStyle(
                    colorScheme == .dark ? WidgetPalette.parchment.opacity(0.5) : WidgetPalette.inkSecondary
                )
            Spacer()
        }
    }
}

#Preview("Widget Support") {
    VStack(alignment: .leading, spacing: 16) {
        WidgetHeader(count: 3)
        WidgetReminderRow(item: WidgetReminderItem(
            id: "support-preview",
            title: "王芳",
            subtitle: String(localized: "widget.reminder.birthday"),
            dateLabel: String(localized: "widget.reminder.tomorrow"),
            urgencyDaysFromNow: 1,
            kind: .birthday,
            deepLinkURL: .liShuHome,
            eventDateLabel: "5月16日"
        ))
        WidgetEmptyState()
    }
    .padding(16)
    .background(WidgetBackground())
}
