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
