import SwiftData
import SwiftUI
import UIKit

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = HomeViewModel()
    @State private var sheetRoute: SheetRoute?
    private let loadsOnAppear: Bool

    init(viewModel: HomeViewModel = HomeViewModel(), loadsOnAppear: Bool = true) {
        _viewModel = State(initialValue: viewModel)
        self.loadsOnAppear = loadsOnAppear
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                summarySection
                festivalSection
                upcomingSection
                recentRecordsSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 100)
        }
        .background(DesignSystem.Colors.bgPage)
        .navigationTitle(String(localized: "home.title"))
        .navigationBarTitleDisplayMode(.automatic)
        .onAppear {
            guard loadsOnAppear else { return }
            viewModel.load(context: modelContext)
        }
        .sheet(item: $sheetRoute) { route in
            sheetContent(for: route)
        }
        .onChange(of: sheetRoute) { _, newValue in
            if loadsOnAppear, newValue == nil {
                viewModel.load(context: modelContext)
            }
        }
    }

    // MARK: - Summary Section

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header: title + add record button
            Text(String(localized: "home.yearSummaryTitle"))
                .font(DesignSystem.Typography.title2)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            // Inner card: total interactions + type breakdown + monetary net
            summaryCardContent
        }
    }

    private var summaryCardContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Total interactions + chart button
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(String(localized: "home.totalInteractions"))
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(viewModel.recordCount)")
                            .font(DesignSystem.Typography.display)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)

                        Text(String(localized: "home.interactionUnit"))
                            .font(DesignSystem.Typography.title3)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                }

                Spacer()

                NavigationLink(value: AppRoute.statistics) {
                    Image(systemName: "chart.bar.fill")
                        .font(DesignSystem.Typography.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(DesignSystem.Colors.primary)
                        .frame(width: 40, height: 40)
                        .background(DesignSystem.Colors.bgIconSubtle)
                        .clipShape(Circle())
                }
                .accessibilityIdentifier("home.openStatistics")
            }

            // Type breakdown capsules
            if !viewModel.typeBreakdown.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(viewModel.typeBreakdown, id: \.type) { item in
                        typeCountCapsule(type: item.type, count: item.count)
                    }
                }
            }

            // Monetary net summary
            if viewModel.monetaryCount > 0 {
                Divider()
                    .foregroundStyle(DesignSystem.Colors.separator)

                Text(viewModel.monetaryNetSummary)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.cardPadding)
        .padding(.vertical, DesignSystem.Spacing.heroCardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                .stroke(DesignSystem.Colors.primary.opacity(0.05), lineWidth: 1)
        )
    }

    private func typeCountCapsule(type: RecordType, count: Int) -> some View {
        HStack(spacing: 5) {
            Image(systemName: type.iconName)
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.primary)
            Text(String(format: String(localized: "home.typeCountFormat"), count))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(DesignSystem.Colors.bgTag)
        .clipShape(Capsule())
    }

    // MARK: - Upcoming Events Section

    private var festivalSection: some View {
        VStack(spacing: 12) {
            sectionHeader(
                title: String(localized: "home.festival.sectionTitle"),
                route: .festivalManagement
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.block) {
                    ForEach(viewModel.upcomingFestivals) { festival in
                        NavigationLink(value: AppRoute.festivalDetail(festival.route)) {
                            festivalCard(festival)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.pageHorizontal)
            }
            .padding(.horizontal, -DesignSystem.Spacing.pageHorizontal)
        }
    }

    private func festivalCard(_ festival: FestivalOccurrence) -> some View {
        VStack(spacing: 0) {
            festivalArtwork(for: festival)
                .frame(height: DesignSystem.Layout.avatarM * 2 + DesignSystem.Spacing.cardPaddingSmall)

            festivalCardInfo(festival)
        }
        .frame(width: DesignSystem.Layout.avatarM * 3 + DesignSystem.Spacing.cardPadding)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        .contentShape(Rectangle())
    }

    private func festivalCardInfo(_ festival: FestivalOccurrence) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.stackTight) {
            Text(festival.name)
                .font(DesignSystem.Typography.body)
                .fontWeight(.semibold)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .lineLimit(1)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.inlineTight) {
                Text(festival.secondaryText)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(String(format: String(localized: "festival.detail.countdown"), festival.countdownDays))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.primary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.cardPaddingSmall)
        .padding(.vertical, DesignSystem.Spacing.cardPaddingSmall)
        .frame(minHeight: DesignSystem.Layout.avatarM + DesignSystem.Spacing.block)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Colors.bgSurface)
    }

    private func festivalArtwork(for festival: FestivalOccurrence) -> some View {
        ZStack(alignment: .topTrailing) {
            festivalArtworkBackground(for: festival)

            Color.black.opacity(0.05)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                .stroke(DesignSystem.Colors.bgSurface.opacity(0.5), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
    }

    @ViewBuilder
    private func festivalArtworkBackground(for festival: FestivalOccurrence) -> some View {
        if let imageData = customFestivalImageData(for: festival),
           ImagePipeline.image(from: imageData, maxPixelSize: ImagePipeline.Preset.homeHeroMaxPixelSize) != nil
        {
            DecodedImageView(data: imageData, maxPixelSize: ImagePipeline.Preset.homeHeroMaxPixelSize)
                .scaledToFill()
        } else if let assetName = builtinFestivalAssetName(for: festival), UIImage(named: assetName) != nil {
            Image(assetName)
                .resizable()
                .scaledToFill()
        } else {
            fallbackFestivalArtwork(for: festival)
        }
    }

    private func customFestivalImageData(for festival: FestivalOccurrence) -> Data? {
        guard case let .userFestival(id) = festival.route,
              let model = modelContext.model(for: id) as? UserFestival
        else {
            return nil
        }

        return model.coverImage
    }

    private func builtinFestivalAssetName(for festival: FestivalOccurrence) -> String? {
        guard case let .builtin(id) = festival.route else { return nil }
        return id.imageAssetName
    }

    private func fallbackFestivalArtwork(for festival: FestivalOccurrence) -> some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height

            ZStack(alignment: .topTrailing) {
                LinearGradient(
                    colors: [
                        DesignSystem.Colors.bgInput,
                        DesignSystem.Colors.bgIconSubtle,
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Circle()
                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
                    .frame(width: width * 0.54, height: width * 0.54)
                    .offset(x: -width * 0.08, y: -width * 0.04)

                Image(systemName: festivalAccentSymbol(for: festival))
                    .font(DesignSystem.Typography.title2)
                    .foregroundStyle(DesignSystem.Colors.primary)
                    .offset(x: -width * 0.12, y: height * 0.05)

                Image(systemName: festivalOverlaySymbol(for: festival))
                    .font(DesignSystem.Typography.title3)
                    .foregroundStyle(DesignSystem.Colors.primary)
                    .padding(DesignSystem.Spacing.block)
            }
        }
    }

    private func festivalAccentSymbol(for festival: FestivalOccurrence) -> String {
        switch festival.route {
        case let .builtin(id):
            switch id {
            case .springFestival:
                "sparkler"
            case .lanternFestival:
                "lantern.fill"
            case .dragonBoatFestival:
                "leaf.fill"
            case .qixiFestival:
                "heart.fill"
            case .midAutumnFestival:
                "moonphase.waning.crescent"
            case .doubleNinthFestival:
                "mountain.2.fill"
            case .chineseNewYearsEve:
                "moon.stars.fill"
            }
        case .userFestival:
            "seal.fill"
        }
    }

    private func festivalOverlaySymbol(for festival: FestivalOccurrence) -> String {
        switch festival.route {
        case let .builtin(id):
            switch id {
            case .midAutumnFestival:
                return "moon.stars"
            case .doubleNinthFestival:
                return "rosette"
            case .dragonBoatFestival:
                return "drop"
            case .qixiFestival:
                return "sparkles"
            case .springFestival, .lanternFestival, .chineseNewYearsEve:
                return "seal"
            }
        case .userFestival:
            break
        }

        return "seal"
    }

    private var upcomingSection: some View {
        VStack(spacing: 12) {
            sectionHeader(
                title: String(localized: "home.upcoming"),
                route: .eventList
            )

            if viewModel.upcomingEvents.isEmpty {
                emptyUpcomingCard
            } else {
                CarouselView(
                    pageCount: viewModel.upcomingEvents.count,
                    autoScrollInterval: 3
                ) { index in
                    let event = viewModel.upcomingEvents[index]

                    VStack {
                        NavigationLink(value: AppRoute.eventDetail(event.persistentModelID)) {
                            upcomingEventCard(event)
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
                .frame(height: 196)
            }
        }
    }

    private var emptyUpcomingCard: some View {
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

    private func upcomingEventCard(_ event: Event) -> some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if let data = event.coverImage {
                    DecodedImageView(data: data, maxPixelSize: ImagePipeline.Preset.homeHeroMaxPixelSize)
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                } else {
                    LinearGradient(
                        colors: eventGradientColors(event.type),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay {
                        Image(systemName: event.type.iconName)
                            .font(.system(size: 40))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
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

                    Text(formatEventDate(event.date))
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

    // MARK: - Recent Records Section

    private var recentRecordsSection: some View {
        VStack(spacing: 12) {
            sectionHeader(
                title: String(localized: "home.recentRecords")
            )

            if viewModel.recentRecords.isEmpty {
                EmptyStateView(
                    icon: "doc.text",
                    message: String(localized: "record.list.empty"),
                    actionTitle: String(localized: "home.addRecord"),
                    action: {
                        sheetRoute = .addRecord(direction: nil, contactID: nil, dailyTag: nil)
                    }
                )
                .accessibilityIdentifier("home.addRecordButton")
                .frame(height: 200)
            } else {
                VStack(spacing: 10) {
                    ForEach(viewModel.recentRecords) { record in
                        NavigationLink(value: AppRoute.recordDetail(record.persistentModelID)) {
                            recentRecordCard(record)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func recentRecordCard(_ record: Record) -> some View {
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
                    Text("¥" + String(format: "%.0f", record.monetaryAmount))
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
                Text(relativeDateText(record.date))
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

    // MARK: - Helpers

    private func sectionHeader(title: String, route: AppRoute? = nil) -> some View {
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

    private func formatEventDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans")
        formatter.dateFormat = "M月dd日"
        return formatter.string(from: date)
    }

    private func relativeDateText(_ date: Date) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let recordDay = calendar.startOfDay(for: date)
        let days = calendar.dateComponents([.day], from: recordDay, to: today).day ?? 0

        if days == 0 {
            return String(localized: "home.today")
        } else if days == 1 {
            return String(localized: "home.yesterday")
        } else if days < 7 {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "zh_Hans")
            formatter.dateFormat = "EEE"
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "zh_Hans")
            formatter.dateFormat = "M月d日"
            return formatter.string(from: date)
        }
    }

    private func eventGradientColors(_ type: EventType) -> [Color] {
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

    private func eventTypeIcon(_ type: EventType) -> (name: String, color: Color) {
        (type.iconName, DesignSystem.Colors.primary)
    }

    @ViewBuilder
    private func sheetContent(for route: SheetRoute) -> some View {
        switch route {
        case let .addRecord(direction, contactID, dailyTag):
            NavigationStack {
                AddRecordView(direction: direction, contactID: contactID, initialDailyTag: dailyTag)
            }
        case .addContact:
            NavigationStack {
                AddContactView()
            }
        case .addEvent:
            NavigationStack {
                AddEventView()
            }
        case let .editContact(contactID):
            NavigationStack {
                AddContactView(contactID: contactID)
            }
        case let .editEvent(eventID):
            NavigationStack {
                AddEventView(eventID: eventID)
            }
        case let .editRecord(recordID):
            NavigationStack {
                AddRecordView(recordID: recordID)
            }
        case let .returnGift(recordID):
            NavigationStack {
                ReturnGiftSheet(recordID: recordID)
            }
        case .ocrImport:
            OCRImportView()
        case .proMembership:
            NavigationStack {
                ProMembershipView()
            }
        }
    }
}

@MainActor
private func makeHomePreviewViewModel() -> HomeViewModel {
    let viewModel = HomeViewModel()
    let calendar = Calendar.current

    let contact1 = Contact(name: "张三", relation: "大学同学", circle: 2)
    let contact2 = Contact(name: "李四", relation: "远房亲戚", circle: 1)
    let contact3 = Contact(name: "王五", relation: "同事", circle: 2)

    let event1 = Event(name: "王志强的婚礼", type: .wedding, date: calendar.liShuDateByAddingDays(9), location: "上海市")
    let event2 = Event(name: "林悦儿满月酒", type: .birth, date: calendar.liShuDateByAddingDays(15), location: "杭州市")

    let record1 = Record.makeMonetaryRecord(
        contact: contact1,
        event: event1,
        amount: 800,
        direction: .given,
        paymentMethod: .wechat,
        date: calendar.liShuDateByAddingDays(-365)
    )
    let record2 = Record.makeMonetaryRecord(
        contact: contact2,
        event: event2,
        amount: 600,
        direction: .received,
        paymentMethod: .cash,
        date: calendar.liShuDateByAddingDays(-120)
    )
    let record3 = Record.makeMonetaryRecord(
        contact: contact3,
        event: event1,
        amount: 300,
        direction: .given,
        paymentMethod: .alipay,
        date: calendar.liShuDateByAddingDays(-20)
    )

    viewModel.recordCount = 42
    viewModel.contactCount = 18
    viewModel.monetaryCount = 18
    viewModel.giftCount = 3
    viewModel.favorCount = 2
    viewModel.banquetCount = 1
    viewModel.yearlyIncome = 28400
    viewModel.yearlyExpense = 15600
    viewModel.upcomingEvents = [event1, event2]
    viewModel.recentRecords = [record1, record2, record3]
    viewModel.upcomingFestivals = [
        FestivalOccurrence(
            route: .builtin(.midAutumnFestival),
            name: BuiltinFestivalID.midAutumnFestival.localizedTitle,
            date: calendar.liShuDateByAddingDays(12),
            countdownDays: 12,
            recurrence: .annualLunar,
            reminderEnabled: true,
            contactSelectionMode: .recommendedOnly,
            secondaryText: "八月十五 · 团圆",
            isExpired: false,
            sortOrder: 0
        ),
        FestivalOccurrence(
            route: .builtin(.doubleNinthFestival),
            name: BuiltinFestivalID.doubleNinthFestival.localizedTitle,
            date: calendar.liShuDateByAddingDays(26),
            countdownDays: 26,
            recurrence: .annualLunar,
            reminderEnabled: true,
            contactSelectionMode: .recommendedOnly,
            secondaryText: "九月初九 · 敬老",
            isExpired: false,
            sortOrder: 1
        ),
    ]

    return viewModel
}

#Preview {
    NavigationStack {
        HomeView(viewModel: makeHomePreviewViewModel(), loadsOnAppear: false)
    }
}
