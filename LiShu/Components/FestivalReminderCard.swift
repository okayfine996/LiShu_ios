import SwiftUI

struct FestivalReminderCard: View {
    let occurrence: TraditionalFestivalOccurrence

    private var countdownText: String {
        if occurrence.daysRemaining == 0 {
            return String(localized: "home.today")
        }
        return String(
            format: String(localized: "home.festival.daysRemaining"),
            occurrence.daysRemaining
        )
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: occurrence.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(occurrence.name)
                        .font(DesignSystem.Typography.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                        .lineLimit(2)

                    Text(formattedDate)
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }

                Spacer(minLength: 8)

                Image(systemName: occurrence.eventType.iconName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.primary)
                    .frame(width: 36, height: 36)
                    .background(DesignSystem.Colors.bgSurface)
                    .clipShape(Circle())
            }

            Text(countdownText)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(DesignSystem.Colors.bgSurface)
                .clipShape(Capsule())
        }
        .frame(width: 164, alignment: .leading)
        .padding(16)
        .background(DesignSystem.Colors.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
    }
}

#Preview {
    FestivalReminderCard(
        occurrence: TraditionalFestivalOccurrence(
            definition: TraditionalFestivalDefinition.builtIn[0],
            name: "中秋节",
            date: Calendar.current.date(byAdding: .day, value: 12, to: .now) ?? .now,
            daysRemaining: 12
        )
    )
    .padding()
    .background(DesignSystem.Colors.bgPage)
}
