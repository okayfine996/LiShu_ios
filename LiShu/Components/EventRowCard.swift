import SwiftUI

struct EventRowCard: View {
    let name: String
    let coverImage: Data?
    let eventType: EventType
    let date: Date
    let location: String
    let recordCount: Int
    var badge: String?

    var body: some View {
        HStack(spacing: 12) {
            EventCoverView(coverImage: coverImage, eventType: eventType)

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(eventType.displayName)
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    Text("\u{00B7}")
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)

                    Text(formattedDate)
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }

                HStack(spacing: 6) {
                    if !location.isEmpty {
                        HStack(spacing: 2) {
                            Image(systemName: "mappin")
                                .font(.system(size: 10))
                            Text(location)
                                .font(DesignSystem.Typography.small)
                        }
                        .foregroundStyle(DesignSystem.Colors.textTertiary)

                        Text("\u{00B7}")
                            .font(DesignSystem.Typography.small)
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                    }

                    Text(String(format: String(localized: "event.list.recordCount"), recordCount))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }
            }

            Spacer()

            if let badge {
                Text(badge)
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(DesignSystem.Colors.primary.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: date)
    }
}

#Preview {
    VStack(spacing: 12) {
        EventRowCard(
            name: "张三的婚礼",
            coverImage: nil,
            eventType: .wedding,
            date: .now.addingTimeInterval(86400 * 3),
            location: "北京国贸大酒店",
            recordCount: 0,
            badge: "3天后"
        )

        EventRowCard(
            name: "春节聚会",
            coverImage: nil,
            eventType: .festival,
            date: .now.addingTimeInterval(-86400 * 60),
            location: "老家",
            recordCount: 5
        )
    }
    .padding()
    .background(DesignSystem.Colors.bgPage)
}
