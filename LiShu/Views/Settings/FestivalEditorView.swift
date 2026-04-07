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
                            dateBadge(
                                title: String(localized: "festival.editor.monthBadge"),
                                value: formattedMonthValue,
                                selectionView: AnyView(monthMenu)
                            )
                            dateBadge(
                                title: String(localized: "festival.editor.dayBadge"),
                                value: formattedDayValue,
                                selectionView: AnyView(dayMenu)
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

    private var monthMenu: some View {
        Picker("", selection: monthBinding) {
            ForEach(1 ... 12, id: \.self) { value in
                Text(monthLabel(for: value))
                    .tag(value)
            }
        }
        .pickerStyle(.menu)
    }

    private var dayMenu: some View {
        Picker("", selection: dayBinding) {
            ForEach(1 ... dayRangeUpperBound, id: \.self) { value in
                Text(dayLabel(for: value))
                    .tag(value)
            }
        }
        .pickerStyle(.menu)
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
            "\(monthLabel(for: viewModel.lunarMonth))\(dayLabel(for: viewModel.lunarDay))"
        case .oneTime:
            oneTimeDateFormatter.string(from: viewModel.oneTimeDate)
        }
    }

    private var formattedMonthValue: String {
        switch viewModel.recurrence {
        case .annualGregorian:
            String(format: String(localized: "festival.editor.monthValue"), viewModel.gregorianMonth)
        case .annualLunar:
            String(format: String(localized: "festival.editor.monthValue"), viewModel.lunarMonth)
        case .oneTime:
            String(format: String(localized: "festival.editor.monthValue"), Calendar.current.component(.month, from: viewModel.oneTimeDate))
        }
    }

    private var formattedDayValue: String {
        switch viewModel.recurrence {
        case .annualGregorian:
            String(format: String(localized: "festival.editor.dayValue"), viewModel.gregorianDay)
        case .annualLunar:
            String(format: String(localized: "festival.editor.dayValue"), viewModel.lunarDay)
        case .oneTime:
            String(format: String(localized: "festival.editor.dayValue"), Calendar.current.component(.day, from: viewModel.oneTimeDate))
        }
    }

    private var dayRangeUpperBound: Int {
        switch viewModel.recurrence {
        case .annualGregorian:
            31
        case .annualLunar:
            30
        case .oneTime:
            31
        }
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

    private func dateBadge(title: String, value: String, selectionView: AnyView) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard)
                .fill(DesignSystem.Colors.bgInput)

            VStack(spacing: DesignSystem.Spacing.stackTight) {
                Text(title)
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)

                Text(value.replacingOccurrences(of: "农历 ", with: ""))
                    .font(DesignSystem.Typography.title3)
                    .foregroundStyle(DesignSystem.Colors.primary)
            }
            .padding(.vertical, DesignSystem.Spacing.block)
        }
        .frame(
            width: DesignSystem.Layout.festivalEditorDateBadgeWidth,
            height: DesignSystem.Layout.festivalEditorDateBadgeHeight
        )
        .overlay {
            selectionView
                .labelsHidden()
                .opacity(0.015)
        }
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
            String(format: String(localized: "festival.editor.lunarMonthValue"), value)
        }
    }

    private func dayLabel(for value: Int) -> String {
        switch viewModel.recurrence {
        case .annualGregorian, .oneTime:
            String(format: String(localized: "festival.editor.dayValue"), value)
        case .annualLunar:
            String(format: String(localized: "festival.editor.lunarDayValue"), value)
        }
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
