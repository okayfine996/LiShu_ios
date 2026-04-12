import PhotosUI
import SwiftData
import SwiftUI

struct AddLedgerReceiptView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel: AddLedgerReceiptViewModel
    @State private var showAddContactSheet = false
    @State private var showProSheet = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var contactIDsBeforeAddSheet: Set<PersistentIdentifier> = []
    @State private var continuousSaveMessage: String?

    init(eventID: PersistentIdentifier) {
        _viewModel = State(initialValue: AddLedgerReceiptViewModel(eventID: eventID))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: DesignSystem.Spacing.section) {
                if let message = continuousSaveMessage {
                    inlineSuccessBanner(message)
                }
                if let event = viewModel.selectedEvent {
                    RecordEventSummaryCard(
                        title: String(localized: "record.add.currentLedger"),
                        event: event
                    )
                }
                contactIdentitySection
                MonetaryAmountInputCard(
                    amount: monetaryAmountBinding,
                    fieldAccessibilityIdentifier: "record.add.amountField"
                )
                PaymentMethodSelector(selectedMethod: paymentMethodBinding)
                RelationshipWeightSelector(selectedWeight: relationshipWeightBinding)
                dateSection
                photosSection
                notesSection
                continueButton
            }
            .padding(.horizontal, 20)
            .padding(.top, DesignSystem.Spacing.block)
            .padding(.bottom, 32)
        }
        .background(DesignSystem.Colors.bgPage)
        .navigationTitle(String(localized: "event.ledger.primaryAction"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .onAppear {
            viewModel.load(context: modelContext)
        }
        .onChange(of: selectedPhotoItems) { _, newItems in
            Task {
                var loaded: [NewRecordPhotoItem] = []
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self), !data.isEmpty,
                       let optimized = ImagePipeline.optimizedJPEGData(
                           from: data,
                           maxPixelSize: ImagePipeline.Preset.recordPhotoMaxPixelSize,
                           compressionQuality: 0.84
                       )
                    {
                        loaded.append(NewRecordPhotoItem(id: UUID(), data: optimized))
                    }
                }
                await MainActor.run {
                    viewModel.newPhotoItems = loaded
                }
            }
        }
        .sheet(isPresented: $showAddContactSheet, onDismiss: refreshContactsAfterAddSheet) {
            NavigationStack {
                AddContactView()
            }
        }
        .sheet(isPresented: $showProSheet) {
            NavigationStack {
                ProMembershipView()
                    .environment(SubscriptionManager.shared)
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button(String(localized: "common.save")) {
                saveRecord(andContinue: false)
            }
            .foregroundStyle(viewModel.isValid ? DesignSystem.Colors.primary : DesignSystem.Colors.textTertiary)
            .disabled(!viewModel.isValid)
        }
    }

    private var contactIdentitySection: some View {
        VStack(spacing: DesignSystem.Spacing.block) {
            if let contact = viewModel.selectedContact {
                selectedContactCard(contact)
            }

            contactScrollSelector
        }
    }

    private func selectedContactCard(_ contact: Contact) -> some View {
        HStack(spacing: 12) {
            AvatarView(imageData: contact.avatar, name: contact.name, size: 52)
                .overlay(
                    Circle()
                        .stroke(DesignSystem.Colors.border, lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(contact.name)
                        .font(DesignSystem.Typography.title3)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    if !contact.relation.isEmpty {
                        Text(contact.relation)
                            .font(DesignSystem.Typography.small)
                            .foregroundStyle(DesignSystem.Colors.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(DesignSystem.Colors.primary.opacity(0.1))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(DesignSystem.Colors.primary.opacity(0.2), lineWidth: 1)
                            )
                    }
                }

                Text(String(localized: "record.add.contactLabel"))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }

            Spacer()
        }
        .padding(14)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                .stroke(DesignSystem.Colors.border, lineWidth: 1)
        )
    }

    private var contactScrollSelector: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.block) {
            Text(String(localized: "record.add.selectContact"))
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
                .tracking(1.5)
                .textCase(.uppercase)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.allContacts) { contact in
                        contactAvatarItem(contact)
                    }

                    newContactTriggerItem
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 4)
            }
        }
    }

    private func contactAvatarItem(_ contact: Contact) -> some View {
        let isSelected = viewModel.selectedContact?.persistentModelID == contact.persistentModelID
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.selectedContact = contact
            }
        } label: {
            VStack(spacing: 6) {
                Circle()
                    .fill(isSelected ? DesignSystem.Colors.primary.opacity(DesignSystem.Effects.selectedFillOpacity) : .clear)
                    .frame(width: 60, height: 60)
                    .overlay {
                        AvatarView(
                            imageData: contact.avatar,
                            name: contact.name,
                            size: 56,
                            placeholderBackground: DesignSystem.Colors.bgSurface
                        )
                        .overlay(
                            Circle()
                                .stroke(
                                    isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.border,
                                    lineWidth: isSelected ? 2 : 1
                                )
                        )
                        .frame(width: 60, height: 60)
                    }
                    .shadow(
                        color: isSelected ? DesignSystem.Colors.primary.opacity(DesignSystem.Effects.selectedShadowOpacity) : .clear,
                        radius: DesignSystem.Effects.selectedShadowRadius,
                        y: DesignSystem.Effects.selectedShadowYOffset
                    )

                Text(contact.name)
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(isSelected ? DesignSystem.Colors.textPrimary : DesignSystem.Colors.textSecondary)
                    .fontWeight(isSelected ? .medium : .regular)
                    .lineLimit(1)
            }
            .frame(minWidth: 72)
            .opacity(viewModel.selectedContact == nil || isSelected ? 1.0 : 0.7)
        }
        .buttonStyle(.plain)
    }

    private var newContactTriggerItem: some View {
        Button {
            contactIDsBeforeAddSheet = Set(viewModel.allContacts.map(\.persistentModelID))
            showAddContactSheet = true
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.bgSurface)
                        .frame(width: 56, height: 56)
                    Circle()
                        .stroke(DesignSystem.Colors.border, lineWidth: 1)
                        .frame(width: 56, height: 56)
                    Image(systemName: "person.badge.plus")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.primary)
                }
                .frame(width: 60, height: 60)

                Text(String(localized: "record.add.newContact"))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .lineLimit(1)
            }
            .frame(minWidth: 72)
        }
        .buttonStyle(.plain)
    }

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "record.add.date"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .fontWeight(.semibold)

            HStack {
                DatePicker("", selection: dateBinding, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .tint(DesignSystem.Colors.primary)

                Spacer()
            }
            .padding(12)
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.input)
                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
            )
        }
    }

    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "record.add.photos"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .fontWeight(.semibold)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.newPhotoItems) { item in
                        photoThumbnail(imageData: item.data)
                    }
                    addPhotoButton
                }
                .padding(12)
            }
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        }
    }

    private func photoThumbnail(imageData: Data) -> some View {
        Group {
            if !imageData.isEmpty {
                DecodedImageView(data: imageData, maxPixelSize: ImagePipeline.Preset.thumbnailMaxPixelSize)
                    .scaledToFill()
            }
        }
        .frame(width: 80, height: 80)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
    }

    private var addPhotoButton: some View {
        PhotosPicker(selection: $selectedPhotoItems, maxSelectionCount: 20, matching: .images) {
            VStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(DesignSystem.Typography.title3)
                Text(String(localized: "record.add.addPhoto"))
                    .font(DesignSystem.Typography.small)
            }
            .foregroundStyle(DesignSystem.Colors.textSecondary)
            .frame(width: 80, height: 80)
            .background(DesignSystem.Colors.bgTag)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "record.add.notes"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .fontWeight(.semibold)

            TextEditor(text: noteBinding)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .frame(minHeight: 80)
                .padding(8)
                .scrollContentBackground(.hidden)
                .background(DesignSystem.Colors.bgSurface)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.input)
                        .stroke(DesignSystem.Colors.border, lineWidth: 1)
                )
        }
    }

    private var continueButton: some View {
        VStack(spacing: 8) {
            Button {
                saveRecord(andContinue: true)
            } label: {
                Text(String(localized: "record.add.saveAndContinue"))
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(!viewModel.isValid)
            .opacity(viewModel.isValid ? 1.0 : DesignSystem.Effects.disabledOpacity)

            if !viewModel.isValid {
                Text(String(localized: "record.add.saveDisabledHint"))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(DesignSystem.Colors.bgInput)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.tag))
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func inlineSuccessBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(DesignSystem.Colors.primary)
            Text(message)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
            Spacer()
        }
        .padding(12)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.input)
                .stroke(DesignSystem.Colors.border, lineWidth: 1)
        )
    }

    private var monetaryAmountBinding: Binding<String> {
        Binding(
            get: { viewModel.monetaryAmount },
            set: { viewModel.monetaryAmount = $0 }
        )
    }

    private var paymentMethodBinding: Binding<PaymentMethod> {
        Binding(
            get: { viewModel.monetaryPaymentMethod },
            set: { viewModel.monetaryPaymentMethod = $0 }
        )
    }

    private var dateBinding: Binding<Date> {
        Binding(
            get: { viewModel.date },
            set: { viewModel.date = $0 }
        )
    }

    private var noteBinding: Binding<String> {
        Binding(
            get: { viewModel.note },
            set: { viewModel.note = $0 }
        )
    }

    private var relationshipWeightBinding: Binding<RelationshipWeight> {
        Binding(
            get: { viewModel.relationshipWeight },
            set: { viewModel.relationshipWeight = $0 }
        )
    }

    private func refreshContactsAfterAddSheet() {
        viewModel.reloadContacts(context: modelContext)

        let newContacts = viewModel.allContacts.filter { contact in
            !contactIDsBeforeAddSheet.contains(contact.persistentModelID)
        }
        if let newestContact = newContacts.max(by: { $0.createdAt < $1.createdAt }) {
            viewModel.selectedContact = newestContact
        }
        contactIDsBeforeAddSheet = []
    }

    private func saveRecord(andContinue: Bool) {
        if !SubscriptionManager.shared.canAddRecord(context: modelContext) {
            showProSheet = true
            return
        }

        if viewModel.save(context: modelContext) {
            guard andContinue else {
                dismiss()
                return
            }

            let contactName = viewModel.selectedContact?.name ?? ""
            let amount = viewModel.monetaryAmount
            if !contactName.isEmpty {
                continuousSaveMessage = String(
                    format: String(localized: "record.add.continueSuccess"),
                    contactName,
                    amount.isEmpty ? "0" : amount
                )
            }
            viewModel.resetForContinuousEntry()
            selectedPhotoItems = []
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(2))
                continuousSaveMessage = nil
            }
        }
    }
}

@MainActor
private func makeAddLedgerReceiptPreviewContainer() -> (ModelContainer, PersistentIdentifier)? {
    guard let container = try? ModelContainer(
        for: Contact.self, Record.self, Event.self, RecordPhoto.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    ) else {
        return nil
    }

    let context = container.mainContext
    let event = Event(name: "我的婚礼", type: .wedding, hostMode: .host, date: .now, location: "锦绣悦府")
    let contacts = [
        Contact(name: "陈明", relation: "同事"),
        Contact(name: "邓伟", relation: "朋友"),
        Contact(name: "何洁", relation: "亲戚"),
    ]

    context.insert(event)
    contacts.forEach { context.insert($0) }
    try? context.save()

    return (container, event.persistentModelID)
}

#Preview {
    if let (container, eventID) = makeAddLedgerReceiptPreviewContainer() {
        NavigationStack {
            AddLedgerReceiptView(eventID: eventID)
        }
        .modelContainer(container)
        .environment(SubscriptionManager.shared)
    } else {
        Text(String(localized: "common.preview.unavailable"))
    }
}
