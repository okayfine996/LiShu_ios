import PhotosUI
import SwiftData
import SwiftUI

struct FestivalEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: FestivalEditorViewModel
    @State private var showDeleteAlert = false
    @State private var selectedCoverItem: PhotosPickerItem?
    @State private var showContactEditor = false

    let festivalID: PersistentIdentifier?
    private let loadsOnAppear: Bool

    init(
        festivalID: PersistentIdentifier? = nil,
        viewModel: FestivalEditorViewModel = FestivalEditorViewModel(),
        loadsOnAppear: Bool = true
    ) {
        self.festivalID = festivalID
        self.loadsOnAppear = loadsOnAppear
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.section) {
                coverImageSection
                nameSection
                recurrenceSection
                reminderSection
                contactSelectionSection

                if festivalID != nil {
                    Button(String(localized: "common.delete"), role: .destructive) {
                        showDeleteAlert = true
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .padding(.top, DesignSystem.Spacing.block)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.pageHorizontal)
            .padding(.top, DesignSystem.Spacing.block)
            .padding(.bottom, DesignSystem.Spacing.scrollBottom)
        }
        .animation(.smooth(duration: 0.24), value: viewModel.recurrence)
        .animation(.smooth(duration: 0.22), value: viewModel.contactSelectionMode)
        .animation(.smooth(duration: 0.2), value: viewModel.selectedContactIDs)
        .animation(.smooth(duration: 0.22), value: viewModel.reminderEnabled)
        .animation(.smooth(duration: 0.25), value: viewModel.coverImage != nil)
        .background(DesignSystem.Colors.bgPage.ignoresSafeArea())
        .navigationTitle(festivalID == nil ? String(localized: "festival.editor.addTitle") : String(localized: "festival.editor.editTitle"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(String(localized: "common.save")) {
                    if viewModel.save(context: modelContext) != nil {
                        NotificationManager.shared.rescheduleAll(context: modelContext)
                        dismiss()
                    }
                }
                .disabled(!viewModel.isValid)
            }
        }
        .alert(String(localized: "festival.editor.deleteConfirm"), isPresented: $showDeleteAlert) {
            Button(String(localized: "common.cancel"), role: .cancel) {}
            Button(String(localized: "common.delete"), role: .destructive) {
                if viewModel.delete(context: modelContext) {
                    NotificationManager.shared.rescheduleAll(context: modelContext)
                    dismiss()
                }
            }
        }
        .onAppear {
            guard loadsOnAppear else { return }
            viewModel.loadContacts(context: modelContext)
            if let festivalID, let festival = modelContext.model(for: festivalID) as? UserFestival {
                viewModel.configure(with: festival, context: modelContext)
            }
        }
        .onChange(of: selectedCoverItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let optimized = ImagePipeline.optimizedJPEGData(
                       from: data,
                       maxPixelSize: ImagePipeline.Preset.homeHeroMaxPixelSize,
                       compressionQuality: 0.84
                   )
                {
                    await MainActor.run {
                        viewModel.coverImage = optimized
                    }
                }
            }
        }
        .sheet(isPresented: $showContactEditor) {
            NavigationStack {
                FestivalContactEditorView(
                    mode: viewModel.contactSelectionMode,
                    contacts: viewModel.contacts,
                    selectedContactIDs: viewModel.selectedContactIDs
                ) { mode, selectedIDs in
                    viewModel.contactSelectionMode = mode
                    viewModel.selectedContactIDs = selectedIDs
                }
            }
        }
    }

    private var coverImageSection: some View {
        PhotosPicker(selection: $selectedCoverItem, matching: .images) {
            ZStack(alignment: .bottomLeading) {
                coverImageBackground

                LinearGradient(
                    colors: [
                        Color.clear,
                        DesignSystem.Colors.textPrimary.opacity(0.15),
                    ],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))

                VStack(alignment: .leading, spacing: DesignSystem.Spacing.stackTight) {
                    Text(String(localized: "festival.editor.coverImageAction"))
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.bgSurface)

                    Text(String(localized: "festival.editor.coverImageHint"))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.bgSurface.opacity(0.82))
                        .multilineTextAlignment(.leading)
                }
                .padding(DesignSystem.Spacing.cardPaddingSmall)
            }
            .frame(maxWidth: .infinity)
            .frame(height: DesignSystem.Layout.festivalEditorCoverHeight)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
            .contentShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        }
        .buttonStyle(.plain)
        .overlay(alignment: .topTrailing) {
            if viewModel.coverImage != nil {
                Button {
                    viewModel.coverImage = nil
                    selectedCoverItem = nil
                } label: {
                    Image(systemName: "xmark")
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                        .frame(
                            width: DesignSystem.Layout.rankBadgeSize,
                            height: DesignSystem.Layout.rankBadgeSize
                        )
                        .background(DesignSystem.Colors.bgSurface.opacity(0.92))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .padding(DesignSystem.Spacing.block)
            }
        }
    }

    private var coverImageBackground: some View {
        Group {
            if let coverImage = viewModel.coverImage {
                DecodedImageView(data: coverImage, maxPixelSize: ImagePipeline.Preset.homeHeroMaxPixelSize)
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else {
                LinearGradient(
                    colors: [
                        DesignSystem.Colors.primary.opacity(0.98),
                        DesignSystem.Colors.primary.opacity(0.72),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay {
                    ZStack {
                        Circle()
                            .stroke(DesignSystem.Colors.bgSurface.opacity(0.35), lineWidth: 2)
                            .padding(DesignSystem.Spacing.block)

                        Circle()
                            .stroke(DesignSystem.Colors.primary.opacity(0.24), lineWidth: 20)
                            .padding(DesignSystem.Spacing.section)

                        Image(systemName: "photo.badge.plus")
                            .font(DesignSystem.Typography.title2)
                            .foregroundStyle(DesignSystem.Colors.bgSurface.opacity(0.75))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
    }

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.block) {
            sectionLabel(
                icon: "pencil.and.list.clipboard",
                title: String(localized: "festival.editor.name")
            )

            cardContainer {
                TextField(String(localized: "festival.editor.namePlaceholder"), text: $viewModel.name)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
            }
        }
    }

    private var recurrenceSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.block) {
            sectionLabel(
                icon: "calendar.badge.clock",
                title: String(localized: "festival.editor.recurrence")
            )

            recurrenceModeStrip

            dateSelectionCard
        }
    }

    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.block) {
            sectionLabel(
                icon: "bell.and.waves.left.and.right",
                title: String(localized: "festival.editor.reminder")
            )

            cardContainer {
                HStack(spacing: DesignSystem.Spacing.block) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.stackTight) {
                        Text(String(localized: "festival.editor.reminderToggle"))
                            .font(DesignSystem.Typography.body)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)

                        Text(String(localized: "festival.editor.reminderDescription"))
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }

                    Spacer(minLength: DesignSystem.Spacing.block)

                    Toggle("", isOn: $viewModel.reminderEnabled)
                        .labelsHidden()
                        .tint(DesignSystem.Colors.primary)
                }
            }
        }
    }

    private var contactSelectionSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.block) {
            sectionLabel(
                icon: "person.2.badge.plus",
                title: String(localized: "festival.editor.contactSelectionStyle")
            )

            capsuleStrip {
                ForEach(FestivalContactSelectionMode.allCases, id: \.rawValue) { mode in
                    modeChip(mode)
                }
            }

            cardContainer {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.cardPaddingSmall) {
                    if viewModel.contactSelectionMode == .recommendedOnly {
                        Text(String(localized: "festival.editor.recommendedHint"))
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.cardPaddingSmall) {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.stackTight) {
                                Text(selectionSummaryTitle)
                                    .font(DesignSystem.Typography.body)
                                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                                Text(selectionSummaryDescription)
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Button(String(localized: "festival.editor.configureContacts")) {
                                showContactEditor = true
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            .frame(maxWidth: .infinity, alignment: .leading)

                            if !selectedContacts.isEmpty {
                                selectedContactsSummary
                                    .padding(.top, DesignSystem.Spacing.dense)
                            }
                        }
                    }
                }
            }

            Text(contactHintText)
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var recurrenceModeStrip: some View {
        HStack(spacing: DesignSystem.Spacing.dense) {
            ForEach(FestivalRecurrence.allCases, id: \.rawValue) { recurrence in
                Button {
                    withAnimation(.smooth(duration: 0.22)) {
                        viewModel.recurrence = recurrence
                    }
                } label: {
                    Text(recurrence.localizedTitle)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(
                            viewModel.recurrence == recurrence
                                ? DesignSystem.Colors.primary
                                : DesignSystem.Colors.textSecondary
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.block)
                        .background(
                            Capsule()
                                .fill(
                                    viewModel.recurrence == recurrence
                                        ? DesignSystem.Colors.bgSurface
                                        : Color.clear
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(DesignSystem.Spacing.dense)
        .background(DesignSystem.Colors.bgInput)
        .clipShape(Capsule())
    }

    private var dateSelectionCard: some View {
        cardContainer {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.block) {
                HStack(alignment: .center, spacing: DesignSystem.Spacing.block) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.stackTight) {
                        Text(String(localized: "festival.editor.selectDate"))
                            .font(DesignSystem.Typography.small)
                            .foregroundStyle(DesignSystem.Colors.textTertiary)

                        Text(primaryDateSummary)
                            .font(DesignSystem.Typography.title3)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                    }

                    Spacer(minLength: DesignSystem.Spacing.block)

                    if viewModel.recurrence == .oneTime {
                        DatePicker(
                            "",
                            selection: $viewModel.oneTimeDate,
                            displayedComponents: .date
                        )
                        .labelsHidden()
                        .tint(DesignSystem.Colors.primary)
                    } else {
                        HStack(spacing: DesignSystem.Spacing.block) {
                            dateBadgeMenu(
                                title: String(localized: "festival.editor.monthBadge"),
                                value: formattedMonthValue,
                                options: Array(1 ... 12),
                                label: { monthLabel(for: $0) },
                                action: { value in
                                    withAnimation(.smooth(duration: 0.18)) {
                                        monthBinding.wrappedValue = value
                                        if viewModel.recurrence == .annualGregorian {
                                            viewModel.gregorianDay = min(viewModel.gregorianDay, gregorianDayUpperBound)
                                        }
                                    }
                                }
                            )
                            dateBadgeMenu(
                                title: String(localized: "festival.editor.dayBadge"),
                                value: formattedDayValue,
                                options: Array(1 ... dayRangeUpperBound),
                                label: { dayLabel(for: $0) },
                                action: { value in
                                    withAnimation(.smooth(duration: 0.18)) {
                                        dayBinding.wrappedValue = value
                                    }
                                }
                            )
                        }
                    }
                }
            }
        }
    }

    private var selectedContactsSummary: some View {
        HStack(spacing: DesignSystem.Spacing.inlineTight) {
            ForEach(selectedContacts.prefix(3), id: \.persistentModelID) { contact in
                selectedContactBadge(contact)
            }

            Text(
                String(
                    format: String(localized: "festival.editor.contactsSelectedCount"),
                    selectedContacts.count
                )
            )
            .font(DesignSystem.Typography.caption)
            .foregroundStyle(DesignSystem.Colors.textSecondary)

            Spacer()
        }
    }

    private func selectedContactBadge(_ contact: Contact) -> some View {
        Group {
            if let avatarData = contact.avatar {
                AvatarView(
                    imageData: avatarData,
                    name: contact.name,
                    size: DesignSystem.Layout.festivalEditorSelectedAvatarSize
                )
            } else {
                Text(String(contact.name.prefix(1)))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.primary)
                    .frame(
                        width: DesignSystem.Layout.festivalEditorSelectedAvatarSize,
                        height: DesignSystem.Layout.festivalEditorSelectedAvatarSize
                    )
                    .background(DesignSystem.Colors.bgInput)
                    .clipShape(Circle())
            }
        }
    }

    private var monthBinding: Binding<Int> {
        Binding(
            get: {
                switch viewModel.recurrence {
                case .annualGregorian:
                    viewModel.gregorianMonth
                case .annualLunar:
                    viewModel.lunarMonth
                case .oneTime:
                    Calendar.current.component(.month, from: viewModel.oneTimeDate)
                }
            },
            set: { newValue in
                switch viewModel.recurrence {
                case .annualGregorian:
                    viewModel.gregorianMonth = newValue
                case .annualLunar:
                    viewModel.lunarMonth = newValue
                case .oneTime:
                    break
                }
            }
        )
    }

    private var dayBinding: Binding<Int> {
        Binding(
            get: {
                switch viewModel.recurrence {
                case .annualGregorian:
                    viewModel.gregorianDay
                case .annualLunar:
                    viewModel.lunarDay
                case .oneTime:
                    Calendar.current.component(.day, from: viewModel.oneTimeDate)
                }
            },
            set: { newValue in
                switch viewModel.recurrence {
                case .annualGregorian:
                    viewModel.gregorianDay = newValue
                case .annualLunar:
                    viewModel.lunarDay = newValue
                case .oneTime:
                    break
                }
            }
        )
    }

    private var primaryDateSummary: String {
        switch viewModel.recurrence {
        case .annualGregorian:
            "\(formattedMonthValue)\(formattedDayValue)"
        case .annualLunar:
            lunarFullDate(month: viewModel.lunarMonth, day: viewModel.lunarDay)
        case .oneTime:
            oneTimeDateFormatter.string(from: viewModel.oneTimeDate)
        }
    }

    private var formattedMonthValue: String {
        switch viewModel.recurrence {
        case .annualGregorian:
            String(format: String(localized: "festival.editor.monthValue"), viewModel.gregorianMonth)
        case .annualLunar:
            lunarMonthText(viewModel.lunarMonth)
        case .oneTime:
            String(format: String(localized: "festival.editor.monthValue"), Calendar.current.component(.month, from: viewModel.oneTimeDate))
        }
    }

    private var formattedDayValue: String {
        switch viewModel.recurrence {
        case .annualGregorian:
            String(format: String(localized: "festival.editor.dayValue"), viewModel.gregorianDay)
        case .annualLunar:
            lunarDayText(viewModel.lunarDay)
        case .oneTime:
            String(format: String(localized: "festival.editor.dayValue"), Calendar.current.component(.day, from: viewModel.oneTimeDate))
        }
    }

    private var dayRangeUpperBound: Int {
        switch viewModel.recurrence {
        case .annualGregorian:
            gregorianDayUpperBound
        case .annualLunar:
            30
        case .oneTime:
            31
        }
    }

    private var gregorianDayUpperBound: Int {
        let calendar = Calendar(identifier: .gregorian)
        let components = DateComponents(year: 2024, month: viewModel.gregorianMonth)
        return calendar.range(of: .day, in: .month, for: calendar.date(from: components) ?? .now)?.count ?? 31
    }

    private var selectedContacts: [Contact] {
        viewModel.contacts.filter { viewModel.selectedContactIDs.contains($0.persistentModelID) }
    }

    private func sectionLabel(icon: String, title: String) -> some View {
        HStack(spacing: DesignSystem.Spacing.inlineTight) {
            Image(systemName: icon)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Text(title)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
    }

    private func cardContainer(
        padding: CGFloat = DesignSystem.Spacing.cardPaddingSmall,
        @ViewBuilder content: () -> some View
    ) -> some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
            .shadow(color: DesignSystem.Colors.textPrimary.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    private func capsuleStrip(@ViewBuilder content: () -> some View) -> some View {
        HStack(spacing: DesignSystem.Spacing.dense) {
            content()
        }
        .padding(DesignSystem.Spacing.dense)
        .frame(maxWidth: .infinity)
        .background(DesignSystem.Colors.bgInput)
        .clipShape(Capsule())
    }

    private func modeChip(_ mode: FestivalContactSelectionMode) -> some View {
        Button {
            withAnimation(.smooth(duration: 0.22)) {
                viewModel.contactSelectionMode = mode
            }
        } label: {
            Text(mode.localizedTitle)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(
                    viewModel.contactSelectionMode == mode
                        ? DesignSystem.Colors.primary
                        : DesignSystem.Colors.textSecondary
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.block)
                .background(
                    Capsule()
                        .fill(
                            viewModel.contactSelectionMode == mode
                                ? DesignSystem.Colors.bgSurface
                                : Color.clear
                        )
                )
        }
        .buttonStyle(.plain)
    }

    private func dateBadgeMenu(
        title: String,
        value: String,
        options: [Int],
        label: @escaping (Int) -> String,
        action: @escaping (Int) -> Void
    ) -> some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(label(option)) {
                    action(option)
                }
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard)
                    .fill(DesignSystem.Colors.bgInput)

                VStack(spacing: DesignSystem.Spacing.stackTight) {
                    Text(title)
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)

                    Text(value)
                        .font(DesignSystem.Typography.title3)
                        .foregroundStyle(DesignSystem.Colors.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .padding(.vertical, DesignSystem.Spacing.block)
            }
            .frame(
                width: DesignSystem.Layout.festivalEditorDateBadgeWidth,
                height: DesignSystem.Layout.festivalEditorDateBadgeHeight
            )
        }
        .buttonStyle(.plain)
    }

    private var selectionSummaryTitle: String {
        String(
            format: String(localized: "festival.editor.contactsSelectedCount"),
            selectedContacts.count
        )
    }

    private var selectionSummaryDescription: String {
        switch viewModel.contactSelectionMode {
        case .manualOnly:
            selectedContacts.isEmpty
                ? String(localized: "festival.editor.manualFallbackHint")
                : String(localized: "festival.editor.manualOnlyHint")
        case .manualPlusRecommended:
            String(localized: "festival.editor.manualPlusHint")
        case .recommendedOnly:
            String(localized: "festival.editor.recommendedHint")
        }
    }

    private var contactHintText: String {
        switch viewModel.contactSelectionMode {
        case .recommendedOnly:
            String(localized: "festival.editor.contactHint")
        case .manualOnly:
            String(localized: "festival.editor.manualFallbackHint")
        case .manualPlusRecommended:
            String(localized: "festival.editor.contactHint")
        }
    }

    private func monthLabel(for value: Int) -> String {
        switch viewModel.recurrence {
        case .annualGregorian, .oneTime:
            String(format: String(localized: "festival.editor.monthValue"), value)
        case .annualLunar:
            lunarMonthText(value)
        }
    }

    private func dayLabel(for value: Int) -> String {
        switch viewModel.recurrence {
        case .annualGregorian, .oneTime:
            String(format: String(localized: "festival.editor.dayValue"), value)
        case .annualLunar:
            lunarDayText(value)
        }
    }

    private func lunarFullDate(month: Int, day: Int) -> String {
        lunarMonthText(month) + lunarDayText(day)
    }

    private func lunarMonthText(_ month: Int) -> String {
        if month == 1 {
            return "正月"
        }
        return chineseNumberText(month) + "月"
    }

    private func lunarDayText(_ day: Int) -> String {
        switch day {
        case 1 ... 10:
            "初" + chineseNumberText(day)
        case 11 ... 19:
            "十" + chineseNumberText(day - 10)
        case 20:
            "二十"
        case 21 ... 29:
            "廿" + chineseNumberText(day - 20)
        case 30:
            "三十"
        default:
            "\(day)"
        }
    }

    private func chineseNumberText(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .spellOut
        formatter.locale = Locale(identifier: "zh_Hans")
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }

    private var oneTimeDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans")
        formatter.dateFormat = "M月d日"
        return formatter
    }
}

#Preview {
    NavigationStack {
        FestivalEditorView(
            viewModel: makeFestivalEditorPreviewViewModel(),
            loadsOnAppear: false
        )
    }
}

private func makeFestivalEditorPreviewViewModel() -> FestivalEditorViewModel {
    let viewModel = FestivalEditorViewModel()
    viewModel.name = "结婚纪念日"
    viewModel.recurrence = .annualGregorian
    viewModel.gregorianMonth = 5
    viewModel.gregorianDay = 20
    viewModel.reminderEnabled = true
    viewModel.contactSelectionMode = .manualPlusRecommended

    let family = Contact(name: "妈妈", relation: "家人", category: "家人", circle: 1)
    let relative = Contact(name: "赵阿姨", relation: "亲戚", category: "亲属", circle: 2)
    let friend = Contact(name: "张敬业", relation: "挚友", category: "朋友", circle: 3)
    let colleague = Contact(name: "林悦儿", relation: "同事", category: "同事", circle: 3)

    viewModel.contacts = [family, relative, friend, colleague]
    viewModel.selectedContactIDs = [family.persistentModelID, friend.persistentModelID]
    return viewModel
}
