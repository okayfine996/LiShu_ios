import SwiftData
import SwiftUI
import UIKit

struct FestivalDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @State private var viewModel = FestivalDetailViewModel()
    @State private var isGreetedExpanded = true

    let route: FestivalRoutePayload

    var body: some View {
        ZStack(alignment: .bottom) {
            DesignSystem.Colors.bgPage
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.section) {
                    heroSection
                    pendingSection
                    greetedSection
                    footerSection
                }
                .padding(.horizontal, DesignSystem.Spacing.pageHorizontal)
                .padding(.top, DesignSystem.Spacing.block)
                .padding(.bottom, DesignSystem.Spacing.scrollBottom + DesignSystem.Layout.avatarM)
            }

            bottomAction
        }
        .navigationTitle(String(localized: "festival.detail.title"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.load(route: route, context: modelContext)
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.cardPaddingSmall) {
            if let occurrence = viewModel.occurrence {
                heroArtwork(for: occurrence)

                VStack(alignment: .leading, spacing: DesignSystem.Spacing.block) {
                    Text(heroTitle(for: occurrence))
                        .font(DesignSystem.Typography.title1)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    HStack(spacing: DesignSystem.Spacing.inlineTight) {
                        Image(systemName: "clock.fill")
                            .font(DesignSystem.Typography.caption)

                        Text(String(format: String(localized: "festival.detail.countdown"), occurrence.countdownDays))
                            .font(DesignSystem.Typography.title3)
                    }
                    .foregroundStyle(DesignSystem.Colors.primary)
                }
            }
        }
    }

    private var pendingSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.block) {
            sectionTitle(
                title: String(localized: "festival.detail.pending"),
                count: viewModel.pendingContacts.count,
                showsChevron: false
            )

            if viewModel.pendingContacts.isEmpty {
                EmptyStateView(icon: "person.2", message: String(localized: "festival.detail.empty"))
                    .frame(height: DesignSystem.Layout.heroDecorationDiameter)
            } else {
                VStack(spacing: DesignSystem.Spacing.block) {
                    ForEach(viewModel.pendingContacts) { contact in
                        pendingContactCard(contact)
                    }
                }
            }
        }
    }

    private var greetedSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.block) {
            Divider()
                .foregroundStyle(DesignSystem.Colors.separator)

            Button {
                isGreetedExpanded.toggle()
            } label: {
                sectionTitle(
                    title: String(localized: "festival.detail.greeted"),
                    count: viewModel.greetedContacts.count,
                    showsChevron: true
                )
            }
            .buttonStyle(.plain)

            if isGreetedExpanded {
                if viewModel.greetedContacts.isEmpty {
                    EmptyStateView(icon: "checkmark.circle", message: String(localized: "festival.detail.empty"))
                        .frame(height: DesignSystem.Layout.heroDecorationDiameter)
                } else {
                    VStack(spacing: DesignSystem.Spacing.block) {
                        ForEach(viewModel.greetedContacts) { contact in
                            greetedContactCard(contact)
                        }
                    }
                }
            }
        }
    }

    private var footerSection: some View {
        Text(String(localized: "festival.detail.footer"))
            .font(DesignSystem.Typography.caption)
            .foregroundStyle(DesignSystem.Colors.textTertiary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, DesignSystem.Spacing.block)
    }

    private var bottomAction: some View {
        NavigationLink(
            value: AppRoute.addRecord(
                direction: nil,
                contactID: viewModel.selectedContactID,
                dailyTag: String(localized: "record.dailyTag.holiday")
            )
        ) {
            Label(String(localized: "festival.detail.addRecord"), systemImage: "square.and.pencil")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textOnPrimary)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(PrimaryButtonStyle())
        .padding(.horizontal, DesignSystem.Spacing.pageHorizontal)
        .padding(.bottom, DesignSystem.Spacing.scrollBottom)
        .disabled(viewModel.selectedContactID == nil)
    }

    private func pendingContactCard(_ contact: Contact) -> some View {
        HStack(spacing: DesignSystem.Spacing.inlineTight) {
            AvatarView(imageData: contact.avatar, name: contact.name, size: DesignSystem.Layout.avatarM)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.stackTight) {
                Text(contact.name)
                    .font(DesignSystem.Typography.title3)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Text(contactMeta(contact))
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            if let phoneURL = phoneURL(for: contact.phone) {
                Button {
                    openURL(phoneURL)
                } label: {
                    Image(systemName: "phone.fill")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.primary)
                        .frame(width: DesignSystem.Layout.avatarM, height: DesignSystem.Layout.avatarM)
                        .background(DesignSystem.Colors.bgIconSubtle)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(DesignSystem.Spacing.cardPaddingSmall)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.selectedContactID = contact.persistentModelID
        }
        .contextMenu {
            Button(String(localized: "festival.detail.markGreeted")) {
                viewModel.selectedContactID = contact.persistentModelID
                viewModel.markGreeted(contact: contact, context: modelContext)
            }
        }
    }

    private func greetedContactCard(_ contact: Contact) -> some View {
        HStack(spacing: DesignSystem.Spacing.inlineTight) {
            AvatarView(imageData: contact.avatar, name: contact.name, size: DesignSystem.Layout.avatarM)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.stackTight) {
                Text(contact.name)
                    .font(DesignSystem.Typography.title3)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Text(greetedContactMeta(contact))
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(String(localized: "festival.detail.greetedTag"))
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .padding(.horizontal, DesignSystem.Spacing.inlineTight)
                .padding(.vertical, DesignSystem.Spacing.dense)
                .background(DesignSystem.Colors.bgTag)
                .clipShape(Capsule())
        }
        .padding(DesignSystem.Spacing.cardPaddingSmall)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        .contextMenu {
            Button(String(localized: "festival.detail.undoGreeted")) {
                viewModel.unmarkGreeted(contact: contact, context: modelContext)
            }
        }
    }

    private func sectionTitle(title: String, count: Int, showsChevron: Bool) -> some View {
        HStack(spacing: DesignSystem.Spacing.inlineTight) {
            Text(title)
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Text("\(count)")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.primary)
                .padding(.horizontal, DesignSystem.Spacing.inlineTight)
                .padding(.vertical, DesignSystem.Spacing.dense / 2)
                .background(DesignSystem.Colors.bgTag)
                .clipShape(Capsule())

            Spacer()

            if showsChevron {
                Image(systemName: isGreetedExpanded ? "chevron.up" : "chevron.down")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
        }
    }

    private func heroTitle(for occurrence: FestivalOccurrence) -> String {
        occurrence.name + " · " + FestivalService.formatGregorianDate(occurrence.date)
    }

    private func heroArtwork(for occurrence: FestivalOccurrence) -> some View {
        ZStack(alignment: .bottomLeading) {
            artworkBackground(for: occurrence)

            LinearGradient(
                colors: [
                    .clear,
                    DesignSystem.Colors.bgPage.opacity(0.18),
                    DesignSystem.Colors.bgPage.opacity(0.82),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .frame(height: DesignSystem.Layout.avatarM * 3 + DesignSystem.Spacing.cardPadding)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                .stroke(DesignSystem.Colors.primary.opacity(0.05), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func artworkBackground(for occurrence: FestivalOccurrence) -> some View {
        if let imageData = customFestivalImageData(for: occurrence),
           ImagePipeline.image(from: imageData, maxPixelSize: ImagePipeline.Preset.homeHeroMaxPixelSize) != nil
        {
            DecodedImageView(data: imageData, maxPixelSize: ImagePipeline.Preset.homeHeroMaxPixelSize)
                .scaledToFill()
        } else if let assetName = builtinFestivalAssetName(for: occurrence), UIImage(named: assetName) != nil {
            Image(assetName)
                .resizable()
                .scaledToFill()
        } else {
            fallbackArtwork(for: occurrence)
        }
    }

    private func fallbackArtwork(for occurrence: FestivalOccurrence) -> some View {
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
                    .frame(width: width * 0.48, height: width * 0.48)
                    .offset(x: -width * 0.08, y: -width * 0.04)

                Image(systemName: festivalAccentSymbol(for: occurrence.route))
                    .font(DesignSystem.Typography.title1)
                    .foregroundStyle(DesignSystem.Colors.primary)
                    .offset(x: -width * 0.1, y: height * 0.08)

                Image(systemName: festivalOverlaySymbol(for: occurrence.route))
                    .font(DesignSystem.Typography.title2)
                    .foregroundStyle(DesignSystem.Colors.primary)
                    .padding(DesignSystem.Spacing.cardPaddingSmall)
            }
        }
    }

    private func customFestivalImageData(for occurrence: FestivalOccurrence) -> Data? {
        guard case let .userFestival(id) = occurrence.route,
              let festival = modelContext.model(for: id) as? UserFestival
        else {
            return nil
        }

        return festival.coverImage
    }

    private func builtinFestivalAssetName(for occurrence: FestivalOccurrence) -> String? {
        guard case let .builtin(id) = occurrence.route else { return nil }
        return id.imageAssetName
    }

    private func festivalAccentSymbol(for route: FestivalRoutePayload) -> String {
        switch route {
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

    private func festivalOverlaySymbol(for route: FestivalRoutePayload) -> String {
        switch route {
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

    private func contactMeta(_ contact: Contact) -> String {
        let relation = contact.relation.isEmpty ? contact.category : contact.relation
        let lastDate = (contact.records ?? []).map(\.date).max()
        if let lastDate {
            return String(
                format: String(localized: "festival.detail.contactMeta"),
                relation,
                relativeDateText(lastDate)
            )
        }
        return relation
    }

    private func greetedContactMeta(_ contact: Contact) -> String {
        let relation = contact.relation.isEmpty ? contact.category : contact.relation
        return relation + " · " + String(localized: "festival.detail.greetedSummary")
    }

    private func relativeDateText(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "zh-Hans")
        return formatter.localizedString(for: date, relativeTo: .now)
    }

    private func phoneURL(for phone: String) -> URL? {
        let digits = phone.filter(\.isNumber)
        guard !digits.isEmpty else { return nil }
        return URL(string: "tel://\(digits)")
    }
}

@MainActor
private func makeFestivalDetailPreviewContainer() -> ModelContainer? {
    guard let container = try? ModelContainer(
        for: Contact.self,
        Record.self,
        Event.self,
        RecordPhoto.self,
        UserFestival.self,
        FestivalGreeting.self,
        FestivalContactPreference.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    ) else { return nil }

    let context = container.mainContext
    let calendar = Calendar.current
    let event = Event(name: "中秋聚会", type: .festival, date: calendar.liShuDateByAddingDays(12))

    let pending1 = Contact(name: "张敬业", phone: "13800138000", relation: "恩师", circle: 1)
    let pending2 = Contact(name: "王秀珍", phone: "13900139000", relation: "长辈", circle: 1)
    let greeted1 = Contact(name: "王小明", relation: "平辈", circle: 2)
    let greeted2 = Contact(name: "赵阿姨", relation: "长辈", circle: 1)

    context.insert(event)
    [pending1, pending2, greeted1, greeted2].forEach { context.insert($0) }

    let recent1 = Record.makeMonetaryRecord(
        contact: pending1,
        event: event,
        amount: 300,
        direction: .given,
        paymentMethod: .wechat,
        date: calendar.liShuDateByAddingDays(-90)
    )
    let recent2 = Record.makeMonetaryRecord(
        contact: pending2,
        event: event,
        amount: 500,
        direction: .given,
        paymentMethod: .cash,
        date: calendar.liShuDateByAddingDays(-180)
    )
    context.insert(recent1)
    context.insert(recent2)

    let occurrence = FestivalService.occurrence(for: .builtin(.midAutumnFestival), context: context)
    if let occurrence {
        FestivalService.markGreeted(contact: greeted1, occurrence: occurrence, context: context)
        FestivalService.markGreeted(contact: greeted2, occurrence: occurrence, context: context)
    }

    return container
}

#Preview {
    if let container = makeFestivalDetailPreviewContainer() {
        NavigationStack {
            FestivalDetailView(route: .builtin(.midAutumnFestival))
                .modelContainer(container)
        }
    } else {
        Text(String(localized: "common.preview.unavailable"))
    }
}
