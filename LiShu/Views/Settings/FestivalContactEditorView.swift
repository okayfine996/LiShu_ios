import SwiftData
import SwiftUI

struct FestivalContactEditorView: View {
    private enum Source {
        case persisted(FestivalRoutePayload)
        case draft(onSave: (FestivalContactSelectionMode, Set<PersistentIdentifier>) -> Void)
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: FestivalContactEditorViewModel

    private let source: Source
    private let loadsOnAppear: Bool

    init(route: FestivalRoutePayload) {
        source = .persisted(route)
        loadsOnAppear = true
        _viewModel = State(initialValue: FestivalContactEditorViewModel())
    }

    init(
        mode: FestivalContactSelectionMode,
        contacts: [Contact],
        selectedContactIDs: Set<PersistentIdentifier>,
        onSave: @escaping (FestivalContactSelectionMode, Set<PersistentIdentifier>) -> Void
    ) {
        let viewModel = FestivalContactEditorViewModel()
        viewModel.configureDraft(mode: mode, contacts: contacts, selectedContactIDs: selectedContactIDs)
        source = .draft(onSave: onSave)
        loadsOnAppear = false
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            DesignSystem.Colors.bgPage
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.section) {
                    selectionStyleSection
                    summarySection
                    contentSection
                }
                .padding(.horizontal, DesignSystem.Spacing.pageHorizontal)
                .padding(.top, DesignSystem.Spacing.block)
                .padding(.bottom, DesignSystem.Spacing.scrollBottom + 80)
            }

            saveButton
        }
        .navigationTitle(String(localized: "festival.contactEditor.title"))
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: String(localized: "festival.contactEditor.search")
        )
        .onAppear {
            guard loadsOnAppear else { return }
            if case let .persisted(route) = source {
                viewModel.load(route: route, context: modelContext)
            }
        }
        .animation(.smooth(duration: 0.2), value: viewModel.selectionStyle)
        .animation(.smooth(duration: 0.2), value: viewModel.selectedContactIDs)
    }

    private var selectionStyleSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.block) {
            sectionLabel(String(localized: "festival.contactEditor.method"))

            HStack(spacing: DesignSystem.Spacing.dense) {
                ForEach(FestivalContactEditorViewModel.SelectionStyle.allCases, id: \.rawValue) { style in
                    Button {
                        withAnimation(.smooth(duration: 0.2)) {
                            viewModel.selectionStyle = style
                        }
                    } label: {
                        Text(style.localizedTitle)
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(
                                viewModel.selectionStyle == style
                                    ? DesignSystem.Colors.primary
                                    : DesignSystem.Colors.textSecondary
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DesignSystem.Spacing.block)
                            .background(
                                Capsule()
                                    .fill(
                                        viewModel.selectionStyle == style
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
    }

    private var summarySection: some View {
        cardContainer {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.block) {
                Text(summaryTitle)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                if !viewModel.selectedContacts.isEmpty {
                    HStack(spacing: DesignSystem.Spacing.inlineTight) {
                        ForEach(viewModel.selectedContacts.prefix(3), id: \.persistentModelID) { contact in
                            AvatarView(
                                imageData: contact.avatar,
                                name: contact.name,
                                size: DesignSystem.Layout.festivalEditorSelectedAvatarSize
                            )
                        }

                        Text(
                            String(
                                format: String(localized: "festival.contactEditor.selectedCount"),
                                viewModel.selectedContacts.count
                            )
                        )
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                        Spacer()
                    }
                } else {
                    Text(String(localized: "festival.contactEditor.emptySelection"))
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
        }
    }

    @ViewBuilder
    private var contentSection: some View {
        switch viewModel.selectionStyle {
        case .byCircle:
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.block) {
                sectionLabel(String(localized: "festival.contactEditor.byCircle"))

                if viewModel.circleGroups.isEmpty {
                    emptyCard
                } else {
                    cardContainer {
                        LazyVGrid(
                            columns: [
                                GridItem(
                                    .adaptive(minimum: DesignSystem.Layout.festivalEditorContactChipMinWidth),
                                    spacing: DesignSystem.Spacing.block
                                ),
                            ],
                            alignment: .leading,
                            spacing: DesignSystem.Spacing.block
                        ) {
                            ForEach(viewModel.circleGroups) { group in
                                circleCard(group)
                            }
                        }
                    }
                }
            }
        case .byPerson:
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.block) {
                sectionLabel(String(localized: "festival.contactEditor.byPerson"))

                if viewModel.filteredContacts.isEmpty {
                    emptyCard
                } else {
                    VStack(spacing: DesignSystem.Spacing.block) {
                        ForEach(viewModel.filteredContacts) { contact in
                            contactRow(contact)
                        }
                    }
                }
            }
        }
    }

    private var emptyCard: some View {
        cardContainer {
            Text(String(localized: "festival.contactEditor.empty"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
    }

    private var saveButton: some View {
        Button {
            handleSave()
        } label: {
            Text(String(localized: "common.save"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textOnPrimary)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(PrimaryButtonStyle())
        .padding(.horizontal, DesignSystem.Spacing.pageHorizontal)
        .padding(.bottom, DesignSystem.Spacing.scrollBottom)
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(DesignSystem.Typography.caption)
            .foregroundStyle(DesignSystem.Colors.textSecondary)
    }

    private func cardContainer(@ViewBuilder content: () -> some View) -> some View {
        content()
            .padding(DesignSystem.Spacing.cardPaddingSmall)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
            .shadow(color: DesignSystem.Colors.textPrimary.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    private func circleCard(_ group: FestivalContactEditorViewModel.CircleGroup) -> some View {
        let isSelected = group.contacts.allSatisfy { viewModel.selectedContactIDs.contains($0.persistentModelID) }
        let memberCount = group.contacts.count

        return Button {
            withAnimation(.smooth(duration: 0.18)) {
                viewModel.toggleCircle(group)
            }
        } label: {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.stackTight) {
                HStack(spacing: DesignSystem.Spacing.inlineTight) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(DesignSystem.Typography.caption)
                    Text(group.title)
                        .font(DesignSystem.Typography.caption)
                }
                .foregroundStyle(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.textPrimary)

                Text(
                    String(
                        format: String(localized: "festival.contactEditor.circleCount"),
                        memberCount
                    )
                )
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
            .padding(DesignSystem.Spacing.cardPaddingSmall)
            .frame(maxWidth: .infinity, minHeight: DesignSystem.Layout.avatarM, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard)
                    .fill(isSelected ? DesignSystem.Colors.primary.opacity(0.1) : DesignSystem.Colors.bgInput)
            )
        }
        .buttonStyle(.plain)
    }

    private func contactRow(_ contact: Contact) -> some View {
        let isSelected = viewModel.selectedContactIDs.contains(contact.persistentModelID)

        return Button {
            withAnimation(.smooth(duration: 0.18)) {
                viewModel.toggleSelection(for: contact)
            }
        } label: {
            HStack(spacing: DesignSystem.Spacing.inlineTight) {
                AvatarView(
                    imageData: contact.avatar,
                    name: contact.name,
                    size: DesignSystem.Layout.avatarM
                )

                VStack(alignment: .leading, spacing: DesignSystem.Spacing.stackTight) {
                    Text(contact.name)
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    Text(contactSubtitle(for: contact))
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.textTertiary)
            }
            .padding(DesignSystem.Spacing.cardPaddingSmall)
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
            .shadow(color: DesignSystem.Colors.textPrimary.opacity(0.04), radius: 8, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }

    private var summaryTitle: String {
        switch viewModel.mode {
        case .recommendedOnly:
            String(localized: "festival.editor.recommendedHint")
        case .manualOnly:
            String(
                format: String(localized: "festival.editor.contactsSelectedCount"),
                viewModel.selectedContacts.count
            )
        case .manualPlusRecommended:
            String(
                format: String(localized: "festival.editor.contactsSelectedCount"),
                viewModel.selectedContacts.count
            )
        }
    }

    private func contactSubtitle(for contact: Contact) -> String {
        if !contact.relation.isEmpty {
            return contact.relation
        }
        if !contact.category.isEmpty {
            return contact.category
        }
        switch contact.circle {
        case 1:
            return String(localized: "festival.contactEditor.circle.family")
        case 2:
            return String(localized: "festival.contactEditor.circle.relatives")
        case 3:
            return String(localized: "festival.contactEditor.circle.social")
        default:
            return String(localized: "festival.contactEditor.circle.other")
        }
    }

    private func handleSave() {
        switch source {
        case let .persisted(route):
            viewModel.save(route: route, context: modelContext)
            NotificationManager.shared.rescheduleAll(context: modelContext)
        case let .draft(onSave):
            onSave(viewModel.mode, viewModel.selectedContactIDs)
        }
        dismiss()
    }
}

#Preview {
    let contacts = [
        Contact(name: "妈妈", relation: "家人", category: "家人", circle: 1),
        Contact(name: "赵阿姨", relation: "亲属", category: "亲属", circle: 2),
        Contact(name: "张敬业", relation: "挚友", category: "朋友", circle: 3),
    ]

    return NavigationStack {
        FestivalContactEditorView(
            mode: .manualPlusRecommended,
            contacts: contacts,
            selectedContactIDs: [contacts[0].persistentModelID]
        ) { _, _ in }
    }
}
