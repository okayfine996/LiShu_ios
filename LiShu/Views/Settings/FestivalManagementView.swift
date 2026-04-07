import SwiftData
import SwiftUI

struct FestivalManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = FestivalManagementViewModel()
    private let loadsOnAppear: Bool

    init(viewModel: FestivalManagementViewModel = FestivalManagementViewModel(), loadsOnAppear: Bool = true) {
        _viewModel = State(initialValue: viewModel)
        self.loadsOnAppear = loadsOnAppear
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.section) {
                infoCard
                builtinSection
                userSection
            }
            .padding(.horizontal, DesignSystem.Spacing.pageHorizontal)
            .padding(.top, DesignSystem.Spacing.block)
            .padding(.bottom, DesignSystem.Spacing.scrollBottom)
        }
        .background(DesignSystem.Colors.bgPage)
        .navigationTitle(String(localized: "festival.management.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    NavigationLink(value: AppRoute.addUserFestival) {
                        Label(String(localized: "festival.editor.addAction"), systemImage: "plus")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(DesignSystem.Typography.title3)
                        .foregroundStyle(DesignSystem.Colors.primary)
                }
            }
        }
        .onAppear {
            guard loadsOnAppear else { return }
            viewModel.load(context: modelContext)
        }
    }

    private var infoCard: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.inlineTight) {
            Image(systemName: "info.circle.fill")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.primary)

            Text(String(localized: "festival.management.info"))
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSystem.Spacing.cardPaddingSmall)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
    }

    private var builtinSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.block) {
            sectionHeader(
                title: String(localized: "festival.management.section.builtin"),
                subtitle: String(localized: "festival.management.section.builtin.subtitle")
            )

            VStack(spacing: DesignSystem.Spacing.block) {
                ForEach(viewModel.builtinFestivals) { festival in
                    festivalRow(festival, canEdit: false)
                }
            }
        }
    }

    private var userSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.block) {
            sectionHeader(
                title: String(localized: "festival.management.section.user"),
                subtitle: String(localized: "festival.management.section.user.subtitle")
            )

            VStack(spacing: DesignSystem.Spacing.block) {
                ForEach(viewModel.userFestivals) { festival in
                    festivalRow(festival, canEdit: true)
                }

                NavigationLink(value: AppRoute.addUserFestival) {
                    VStack(spacing: DesignSystem.Spacing.block) {
                        Image(systemName: "plus")
                            .font(DesignSystem.Typography.title2)
                            .foregroundStyle(DesignSystem.Colors.primary)
                            .frame(width: DesignSystem.Layout.avatarM, height: DesignSystem.Layout.avatarM)
                            .background(DesignSystem.Colors.bgTag)
                            .clipShape(Circle())

                        Text(String(localized: "festival.editor.addAction"))
                            .font(DesignSystem.Typography.body)
                            .foregroundStyle(DesignSystem.Colors.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Spacing.heroCardPadding)
                    .background(DesignSystem.Colors.bgSurface)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func festivalRow(_ festival: FestivalOccurrence, canEdit: Bool) -> some View {
        NavigationLink(value: AppRoute.festivalDetail(festival.route)) {
            HStack(spacing: DesignSystem.Spacing.block) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.block) {
                    HStack(spacing: DesignSystem.Spacing.dense) {
                        Text(festival.name)
                            .font(DesignSystem.Typography.body)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                            .lineLimit(1)

                        if let badge = festivalBadge(for: festival, canEdit: canEdit) {
                            badge
                        }
                    }

                    HStack(spacing: DesignSystem.Spacing.inlineTight) {
                        Text(FestivalService.formatFullGregorianDate(festival.date))
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)

                        if festival.isExpired || !festival.reminderEnabled {
                            Text(String(localized: "festival.management.closed"))
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.textTertiary)
                        } else {
                            Text(String(format: String(localized: "festival.management.daysRemaining"), festival.countdownDays))
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.primary)
                        }
                    }
                }

                Spacer()

                Toggle(
                    "",
                    isOn: Binding(
                        get: { festival.reminderEnabled },
                        set: { newValue in
                            FestivalService.setReminderEnabled(newValue, for: festival.route, context: modelContext)
                            viewModel.load(context: modelContext)
                            NotificationManager.shared.rescheduleAll(context: modelContext)
                        }
                    )
                )
                .labelsHidden()
                .tint(DesignSystem.Colors.primary)
            }
            .padding(DesignSystem.Spacing.cardPaddingSmall)
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        }
        .buttonStyle(.plain)
        .contextMenu {
            NavigationLink(value: AppRoute.festivalContactEditor(festival.route)) {
                Label(String(localized: "festival.detail.editContacts"), systemImage: "person.2")
            }
            if canEdit, case let .userFestival(id) = festival.route {
                NavigationLink(value: AppRoute.editUserFestival(id)) {
                    Label(String(localized: "common.edit"), systemImage: "pencil")
                }
            }
        }
    }

    private func sectionHeader(title: String, subtitle: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Spacer()

            Text(subtitle)
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
        }
    }

    private func festivalBadge(for festival: FestivalOccurrence, canEdit: Bool) -> AnyView? {
        if !canEdit, festival.recurrence == .annualLunar {
            return AnyView(
                Text(String(localized: "festival.management.smartBadge"))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.primary)
                    .padding(.horizontal, DesignSystem.Spacing.inlineTight)
                    .padding(.vertical, DesignSystem.Spacing.dense / 2)
                    .background(DesignSystem.Colors.primary.opacity(0.1))
                    .clipShape(Capsule())
            )
        } else if canEdit, festival.contactSelectionMode != .recommendedOnly {
            return AnyView(
                Image(systemName: "pin.fill")
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.primary)
            )
        }

        return nil
    }
}

@MainActor
private func makeFestivalManagementPreviewViewModel() -> FestivalManagementViewModel {
    let viewModel = FestivalManagementViewModel()
    let calendar = Calendar.current

    viewModel.builtinFestivals = [
        FestivalOccurrence(
            route: .builtin(.springFestival),
            name: BuiltinFestivalID.springFestival.localizedTitle,
            date: calendar.liShuDateByAddingDays(28),
            countdownDays: 28,
            recurrence: .annualLunar,
            reminderEnabled: true,
            contactSelectionMode: .recommendedOnly,
            secondaryText: "正月初一 · 团圆",
            isExpired: false,
            sortOrder: 0
        ),
        FestivalOccurrence(
            route: .builtin(.midAutumnFestival),
            name: BuiltinFestivalID.midAutumnFestival.localizedTitle,
            date: calendar.liShuDateByAddingDays(78),
            countdownDays: 78,
            recurrence: .annualLunar,
            reminderEnabled: true,
            contactSelectionMode: .recommendedOnly,
            secondaryText: "八月十五 · 团圆",
            isExpired: false,
            sortOrder: 1
        ),
        FestivalOccurrence(
            route: .builtin(.dragonBoatFestival),
            name: "清明节",
            date: calendar.liShuDateByAddingDays(-3),
            countdownDays: 0,
            recurrence: .annualLunar,
            reminderEnabled: false,
            contactSelectionMode: .recommendedOnly,
            secondaryText: "四月初四 · 清明",
            isExpired: true,
            sortOrder: 2
        ),
    ]

    viewModel.userFestivals = [
        FestivalOccurrence(
            route: .builtin(.doubleNinthFestival),
            name: "师父寿辰",
            date: calendar.liShuDateByAddingDays(71),
            countdownDays: 71,
            recurrence: .annualGregorian,
            reminderEnabled: true,
            contactSelectionMode: .manualOnly,
            secondaryText: "每年公历",
            isExpired: false,
            sortOrder: 1000
        ),
        FestivalOccurrence(
            route: .builtin(.qixiFestival),
            name: "家祭",
            date: calendar.liShuDateByAddingDays(166),
            countdownDays: 166,
            recurrence: .annualGregorian,
            reminderEnabled: true,
            contactSelectionMode: .manualPlusRecommended,
            secondaryText: "每年公历",
            isExpired: false,
            sortOrder: 1001
        ),
    ]

    return viewModel
}

#Preview {
    NavigationStack {
        FestivalManagementView(
            viewModel: makeFestivalManagementPreviewViewModel(),
            loadsOnAppear: false
        )
    }
}
