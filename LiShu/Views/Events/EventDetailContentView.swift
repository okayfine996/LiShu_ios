import SwiftUI

struct EventDetailContentView: View {
    let event: Event
    let viewModel: EventDetailViewModel
    @Binding var pendingDeleteRecord: Record?
    let onAddRecord: () -> Void
    let onAddLedgerReceipt: () -> Void
    let onShowLegacyAnomalies: () -> Void

    var body: some View {
        Group {
            if event.hostMode == .host {
                EventDetailLedgerView(
                    event: event,
                    viewModel: viewModel,
                    pendingDeleteRecord: $pendingDeleteRecord,
                    onAddLedgerReceipt: onAddLedgerReceipt,
                    onShowLegacyAnomalies: onShowLegacyAnomalies
                )
            } else {
                EventDetailStandardView(
                    event: event,
                    records: viewModel.allRecords,
                    formattedDate: viewModel.formattedDate,
                    isUpcoming: viewModel.isUpcoming,
                    daysUntilEvent: viewModel.daysUntilEvent,
                    pendingDeleteRecord: $pendingDeleteRecord,
                    onAddRecord: onAddRecord
                )
            }
        }
    }
}

struct EventDetailHeroCard: View {
    let event: Event
    let formattedDate: String
    let isUpcoming: Bool
    let daysUntilEvent: Int?

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: event.type.iconName)
                .font(DesignSystem.Typography.title1)
                .foregroundStyle(DesignSystem.Colors.primary)
                .frame(width: 72, height: 72)
                .background(DesignSystem.Colors.bgIconSubtle)
                .clipShape(Circle())

            Text(event.name)
                .font(DesignSystem.Typography.title2)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            HStack(spacing: 8) {
                Text(event.type.displayName)
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(DesignSystem.Colors.primary.opacity(0.12))
                    .clipShape(Capsule())

                Text("·")
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)

                Text(formattedDate)
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }

            if event.hostMode == .host {
                Text(String(localized: "event.ledger.hostBadge"))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(DesignSystem.Colors.primary.opacity(0.12))
                    .clipShape(Capsule())
            }

            if !event.location.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(DesignSystem.Typography.small)
                    Text(event.location)
                        .font(DesignSystem.Typography.small)
                }
                .foregroundStyle(DesignSystem.Colors.textSecondary)
            }

            if isUpcoming, let daysUntilEvent {
                Text(countdownText(days: daysUntilEvent))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(DesignSystem.Colors.primary.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
    }

    private func countdownText(days: Int) -> String {
        if days == 0 {
            return String(localized: "home.today")
        }
        return String(format: String(localized: "event.detail.countdown"), days)
    }
}

struct EventDetailCoverImageView: View {
    let data: Data

    var body: some View {
        Group {
            if !data.isEmpty {
                DecodedImageView(data: data, maxPixelSize: ImagePipeline.Preset.detailHeroMaxPixelSize)
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
            }
        }
    }
}

struct EventDetailNotesSection: View {
    let note: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "event.detail.notes"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .fontWeight(.semibold)

            Text(note)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
    }
}

struct EventDetailLoadingOverlay: View {
    var body: some View {
        ZStack {
            DesignSystem.Colors.bgPage.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: DesignSystem.Spacing.block) {
                ProgressView()
                    .tint(DesignSystem.Colors.primary)

                Text(String(localized: "csv.ledger.loading"))
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
            }
            .padding(DesignSystem.Spacing.cardPadding)
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        }
    }
}
