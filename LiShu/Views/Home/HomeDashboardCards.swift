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
                    HStack(spacing: DesignSystem.Spacing.dense) {
                        Text(String(localized: "common.viewAll"))
                            .font(DesignSystem.Typography.caption)

                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(DesignSystem.Colors.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(DesignSystem.Colors.bgSurface.opacity(0.7))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
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
                            Color.black.opacity(0.02),
                            Color.black.opacity(0.12),
                            Color.black.opacity(0.38),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(.white.opacity(0.16))
                        .frame(width: 110, height: 110)
                        .blur(radius: 14)
                        .offset(x: 20, y: -12)
                        .accessibilityHidden(true)
                }

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.inlineTight) {
                HStack(alignment: .top) {
                    Text(event.type.displayName)
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textOnPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.18))
                        .clipShape(Capsule())

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 10, weight: .semibold))

                        Text(HomeDashboardFormatters.eventDate(event.date))
                            .font(DesignSystem.Typography.small)
                    }
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.black.opacity(0.16))
                    .clipShape(Capsule())
                }

                VStack(alignment: .leading, spacing: DesignSystem.Spacing.stackTight) {
                    Text(event.name)
                        .font(DesignSystem.Typography.title2)
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.9)

                    if let supportingText = HomeDashboardFormatters.upcomingEventSupportingText(event) {
                        Text(supportingText)
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(.white.opacity(0.84))
                            .lineLimit(1)
                    }
                }
            }
            .padding(DesignSystem.Spacing.cardPaddingSmall)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 196)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(
            color: DesignSystem.Colors.primary.opacity(0.10),
            radius: 12,
            x: 0,
            y: 8
        )
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
        HStack(spacing: DesignSystem.Spacing.block) {
            AvatarView(imageData: record.contact?.avatar, name: record.contact?.name ?? "")

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.stackTight) {
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

            VStack(alignment: .trailing, spacing: DesignSystem.Spacing.stackTight) {
                if record.isMonetary {
                    Text(HomeDashboardFormatters.recordAmount(record))
                        .font(DesignSystem.Typography.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(DesignSystem.Colors.primary)
                } else {
                    HStack(spacing: DesignSystem.Spacing.dense) {
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
        .padding(.vertical, 14)
        .padding(.horizontal, DesignSystem.Spacing.cardPaddingSmall)
        .contentShape(Rectangle())
        .background(DesignSystem.Colors.bgSurface.opacity(0.94))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard)
                .stroke(DesignSystem.Colors.primary.opacity(0.05), lineWidth: 1)
        )
    }
}
