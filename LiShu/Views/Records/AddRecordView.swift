import PhotosUI
import SwiftData
import SwiftUI

struct AddRecordView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = AddRecordViewModel()
    @State private var showProSheet = false
    @State private var showAddEventSheet = false
    @State private var showAddContactSheet = false
    @State private var contactIDsBeforeAddSheet: Set<PersistentIdentifier> = []
    @State private var eventIDsBeforeCreation: Set<PersistentIdentifier> = []
    @State private var selectedPhotoItems: [PhotosPickerItem] = []

    var direction: RecordDirection?
    var contactID: PersistentIdentifier?
    var recordID: PersistentIdentifier?

    init(direction: RecordDirection? = nil, contactID: PersistentIdentifier? = nil, recordID: PersistentIdentifier? = nil) {
        self.direction = direction
        self.contactID = contactID
        self.recordID = recordID
    }

    var body: some View {
        addRecordScrollView
            .background(DesignSystem.Colors.bgPage)
            .navigationTitle(viewModel
                .editingRecord != nil ? String(localized: "record.edit.title") : String(localized: "record.add.navTitle"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { addRecordToolbarContent }
            .onAppear(perform: onAppear)
            .onChange(of: selectedPhotoItems) { _, newItems in
                Task {
                    var loaded: [NewRecordPhotoItem] = []
                    for item in newItems {
                        if let data = try? await item.loadTransferable(type: Data.self), !data.isEmpty {
                            loaded.append(NewRecordPhotoItem(id: UUID(), data: data))
                        }
                    }
                    await MainActor.run {
                        viewModel.newPhotoItems = loaded
                    }
                }
            }
            .sheet(isPresented: $showProSheet) {
                NavigationStack {
                    ProMembershipView()
                        .environment(SubscriptionManager.shared)
                }
            }
            .sheet(isPresented: $showAddEventSheet, onDismiss: refreshEventsAfterCreation) {
                NavigationStack {
                    AddEventView()
                }
            }
            .sheet(isPresented: $showAddContactSheet, onDismiss: refreshContactsAfterAddSheet) {
                NavigationStack {
                    AddContactView()
                }
            }
    }

    private var addRecordScrollView: some View {
        ScrollView(showsIndicators: false) {
            addRecordFormStack
                .padding(.horizontal, 20)
                .padding(.top, DesignSystem.Spacing.block)
                .padding(.bottom, 32)
        }
    }

    private var addRecordFormStack: some View {
        VStack(spacing: DesignSystem.Spacing.section) {
            contactIdentitySection
            recordTypeGrid
            contextSelectionSection
            if viewModel.contextSelection == .event {
                eventSection
            } else {
                dailyTagSection
            }
            interactionFormSection
            relationshipWeightSection
            dateSection
            photosSection
            notesSection
            confirmButton
        }
    }

    @ToolbarContentBuilder
    private var addRecordToolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
            }
            .accessibilityIdentifier("record.add.closeButton")
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button(String(localized: "common.save")) {
                saveRecord()
            }
            .foregroundStyle(viewModel.isValid ? DesignSystem.Colors.primary : DesignSystem.Colors.textTertiary)
            .disabled(!viewModel.isValid)
            .accessibilityIdentifier("record.add.saveButton")
        }
    }

    private func onAppear() {
        viewModel.loadData(context: modelContext)
        if let recordID, let record = modelContext.model(for: recordID) as? Record {
            viewModel.configure(with: record)
        } else {
            viewModel.configure(direction: direction, contactID: contactID, context: modelContext)
        }
    }

    // MARK: - Contact Identity Section

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

            contactAvatarScroll
        }
    }

    private var contactAvatarScroll: some View {
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
                    .foregroundStyle(
                        isSelected
                            ? DesignSystem.Colors.textPrimary
                            : DesignSystem.Colors.textSecondary
                    )
                    .fontWeight(isSelected ? .medium : .regular)
                    .lineLimit(1)
            }
            .frame(minWidth: 72)
            .opacity(viewModel.selectedContact == nil || isSelected ? 1.0 : 0.7)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Record Type Grid

    private var recordTypeGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "record.add.recordType"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .fontWeight(.semibold)

            Text(String(localized: "record.add.recordType.description"))
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                ForEach(RecordType.allCases, id: \.self) { type in
                    recordTypeGridItem(type)
                }
            }
        }
    }

    private func recordTypeGridItem(_ type: RecordType) -> some View {
        let isSelected = viewModel.recordType == type
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.recordType = type
            }
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                        .fill(DesignSystem.Colors.bgSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                                .stroke(
                                    isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.border.opacity(0.3),
                                    lineWidth: isSelected ? 1.5 : 1
                                )
                        )
                        .shadow(color: isSelected ? DesignSystem.Colors.primary.opacity(0.08) : .clear, radius: 4, y: 2)

                    Image(systemName: type.iconName)
                        .font(.system(size: 22))
                        .foregroundStyle(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.textSecondary)
                }
                .frame(height: 48)

                Text(type.displayName)
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(isSelected ? DesignSystem.Colors.textPrimary : DesignSystem.Colors.textSecondary)
                    .fontWeight(isSelected ? .semibold : .medium)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Interaction Form Section

    private var interactionFormSection: some View {
        VStack(spacing: 16) {
            directionToggle
            typeSpecificSection
        }
    }

    private var relationshipWeightSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "record.add.relationshipWeight"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .fontWeight(.semibold)

            Text(String(localized: "record.add.relationshipWeight.description"))
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 12) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(DesignSystem.Colors.bgInput)
                            .frame(height: 8)

                        Capsule()
                            .fill(DesignSystem.Colors.primary.opacity(0.18))
                            .frame(width: relationshipWeightProgressWidth(totalWidth: geometry.size.width), height: 8)

                        HStack(spacing: 0) {
                            ForEach(RelationshipWeight.allCases, id: \.rawValue) { weight in
                                relationshipWeightButton(weight)
                            }
                        }
                    }
                }
                .frame(height: 32)

                HStack(alignment: .top, spacing: 0) {
                    ForEach(RelationshipWeight.allCases, id: \.rawValue) { weight in
                        Text(weight.displayName)
                            .font(DesignSystem.Typography.small)
                            .foregroundStyle(
                                viewModel.relationshipWeight == weight
                                    ? DesignSystem.Colors.textPrimary
                                    : DesignSystem.Colors.textTertiary
                            )
                            .fontWeight(viewModel.relationshipWeight == weight ? .semibold : .medium)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(16)
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                    .stroke(DesignSystem.Colors.border.opacity(0.3), lineWidth: 1)
            )
        }
    }

    private var contextSelectionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "record.add.context"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .fontWeight(.semibold)

            Text(String(localized: "record.add.context.description"))
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 0) {
                contextButton(.event, title: String(localized: "record.add.context.event"))
                contextButton(.daily, title: String(localized: "record.add.context.daily"))
            }
            .padding(4)
            .background(DesignSystem.Colors.bgInput)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
        }
    }

    private var directionToggle: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.block) {
            Text(String(localized: "record.add.directionSection"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .fontWeight(.semibold)

            Text(String(localized: "record.add.directionSection.description"))
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 0) {
                directionButton(.given, title: viewModel.directionTitle(for: .given))
                directionButton(.received, title: viewModel.directionTitle(for: .received))
            }
            .padding(4)
            .background(DesignSystem.Colors.bgInput)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
        }
    }

    private func directionButton(_ dir: RecordDirection, title: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.direction = dir
            }
        } label: {
            Text(title)
                .font(DesignSystem.Typography.caption)
                .fontWeight(.medium)
                .foregroundStyle(
                    viewModel.direction == dir
                        ? DesignSystem.Colors.textPrimary
                        : DesignSystem.Colors.textTertiary
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    viewModel.direction == dir
                        ? DesignSystem.Colors.bgSurface
                        : Color.clear
                )
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.tag))
                .shadow(
                    color: viewModel.direction == dir ? DesignSystem.Colors.primary
                        .opacity(DesignSystem.Effects.selectedShadowOpacity) : .clear,
                    radius: DesignSystem.Effects.selectedShadowRadius,
                    y: DesignSystem.Effects.selectedShadowYOffset
                )
        }
        .buttonStyle(.plain)
    }

    private func relationshipWeightButton(_ weight: RelationshipWeight) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.relationshipWeight = weight
            }
        } label: {
            let isSelected = viewModel.relationshipWeight == weight
            ZStack {
                if isSelected {
                    Circle()
                        .fill(DesignSystem.Colors.bgSurface)
                        .frame(width: 32, height: 32)
                        .shadow(color: DesignSystem.Colors.primary.opacity(0.12), radius: 6, y: 2)
                }

                Circle()
                    .fill(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.bgSurface)
                    .frame(width: isSelected ? 22 : 14, height: isSelected ? 22 : 14)
                    .overlay(
                        Circle()
                            .stroke(
                                isSelected ? DesignSystem.Colors.bgSurface : DesignSystem.Colors.border,
                                lineWidth: isSelected ? 4 : 1
                            )
                    )
            }
            .frame(maxWidth: .infinity)
            .frame(height: 32)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func relationshipWeightProgressWidth(totalWidth: CGFloat) -> CGFloat {
        let steps = max(RelationshipWeight.allCases.count - 1, 1)
        let currentIndex = RelationshipWeight.allCases.firstIndex(of: viewModel.relationshipWeight) ?? 0
        return (totalWidth / CGFloat(steps)) * CGFloat(currentIndex)
    }

    private func contextButton(_ selection: RecordContextSelection, title: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.contextSelection = selection
            }
        } label: {
            Text(title)
                .font(DesignSystem.Typography.caption)
                .fontWeight(.medium)
                .foregroundStyle(
                    viewModel.contextSelection == selection
                        ? DesignSystem.Colors.textPrimary
                        : DesignSystem.Colors.textTertiary
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    viewModel.contextSelection == selection
                        ? DesignSystem.Colors.bgSurface
                        : Color.clear
                )
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.tag))
                .shadow(
                    color: viewModel.contextSelection == selection ? DesignSystem.Colors.primary
                        .opacity(DesignSystem.Effects.selectedShadowOpacity) : .clear,
                    radius: DesignSystem.Effects.selectedShadowRadius,
                    y: DesignSystem.Effects.selectedShadowYOffset
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Type Specific Section

    @ViewBuilder
    private var typeSpecificSection: some View {
        switch viewModel.recordType {
        case .monetary: monetaryFormSection
        case .gift: giftFormSection
        case .favor: favorFormSection
        case .banquet: banquetFormSection
        }
    }

    // MARK: - Monetary Form

    private var monetaryFormSection: some View {
        VStack(spacing: 16) {
            amountInputCard
            paymentMethodSection
        }
    }

    private var amountInputCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text(String(localized: "record.add.amount"))
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .fontWeight(.medium)
                Spacer()
            }
            .padding(.bottom, -4)

            // Amount input row
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("¥")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.primary)

                TextField("0.00", text: $viewModel.monetaryAmount)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .keyboardType(.decimalPad)
                    .accessibilityIdentifier("record.add.amountField")
            }

            // Suggestion hint
            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.system(size: 13))
                    .foregroundStyle(DesignSystem.Colors.primary.opacity(0.6))

                Text(String(localized: "record.add.amountHint"))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DesignSystem.Colors.bgInput)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.tag))
        }
        .padding(20)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                .stroke(DesignSystem.Colors.border.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 4, y: 2)
    }

    private var paymentMethodSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "record.add.paymentMethod"))
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
                .tracking(1)
                .textCase(.uppercase)
                .padding(.horizontal, 4)

            HStack(spacing: 8) {
                ForEach(PaymentMethod.allCases, id: \.self) { method in
                    paymentMethodCapsule(method)
                }
                Spacer()
            }
        }
    }

    private func paymentMethodCapsule(_ method: PaymentMethod) -> some View {
        let isSelected = viewModel.monetaryPaymentMethod == method
        return Button {
            viewModel.monetaryPaymentMethod = method
        } label: {
            Text(paymentMethodName(method))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isSelected ? DesignSystem.Colors.textPrimary : DesignSystem.Colors.textSecondary)
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background(isSelected ? DesignSystem.Colors.primary.opacity(0.08) : DesignSystem.Colors.bgSurface)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(
                            isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.border.opacity(0.5),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Gift Form

    private var giftFormSection: some View {
        VStack(spacing: 16) {
            formField(
                label: String(localized: "record.add.giftName"),
                placeholder: String(localized: "record.add.giftName.placeholder"),
                text: $viewModel.giftName
            )

            optionalAmountField(
                label: String(localized: "record.add.estimatedValue"),
                text: $viewModel.giftEstimatedValue
            )
        }
    }

    // MARK: - Favor Form

    private var favorFormSection: some View {
        largeDescriptionField(
            label: String(localized: "record.type.favor") + String(localized: "record.add.favorDescription.label"),
            placeholder: String(localized: "record.add.favorDescription.favor"),
            text: $viewModel.favorDesc
        )
    }

    // MARK: - Banquet Form

    private var banquetFormSection: some View {
        VStack(spacing: 16) {
            formField(
                label: String(localized: "record.add.banquet.location"),
                placeholder: String(localized: "record.add.banquet.location.placeholder"),
                text: $viewModel.banquetLocation
            )

            largeDescriptionField(
                label: String(localized: "record.add.banquet.attendees"),
                placeholder: String(localized: "record.add.banquet.attendees.placeholder"),
                text: $viewModel.banquetAttendeeList
            )

            largeDescriptionField(
                label: String(localized: "record.add.banquet.extraCostNotes"),
                placeholder: String(localized: "record.add.banquet.extraCostNotes.placeholder"),
                text: $viewModel.banquetExtraCostNotes,
                isOptional: true
            )
        }
    }

    // MARK: - Shared Form Helpers

    private func formField(label: String, placeholder: String, text: Binding<String>, isOptional: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Text(label)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .fontWeight(.semibold)
                if isOptional {
                    Text(String(localized: "record.add.amountOptional"))
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }
            }

            TextField(placeholder, text: text)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .padding(12)
                .background(DesignSystem.Colors.bgSurface)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.input)
                        .stroke(DesignSystem.Colors.border, lineWidth: 1)
                )
        }
    }

    private func largeDescriptionField(label: String, placeholder: String, text: Binding<String>, isOptional: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 4) {
                Text(label)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .fontWeight(.semibold)
                if isOptional {
                    Text(String(localized: "record.add.amountOptional"))
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }
            }

            ZStack(alignment: .topLeading) {
                if text.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(placeholder)
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 8)
                        .allowsHitTesting(false)
                }

                TextEditor(text: text)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .frame(minHeight: 120)
                    .scrollContentBackground(.hidden)
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

    private func optionalAmountField(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Text(label)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .fontWeight(.semibold)
                Text(String(localized: "record.add.amountOptional"))
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }

            HStack(spacing: 8) {
                Text("¥")
                    .font(DesignSystem.Typography.title2)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                TextField("0", text: text)
                    .font(DesignSystem.Typography.title2)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .keyboardType(.decimalPad)
            }
            .frame(minHeight: 36)
            .padding(12)
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.input)
                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
            )
        }
    }

    // MARK: - Event Section

    private var eventSection: some View {
        VStack(spacing: DesignSystem.Spacing.block) {
            if let event = viewModel.selectedEvent {
                selectedEventCard(event)
            }

            eventScrollSelector
        }
    }

    private func selectedEventCard(_ event: Event) -> some View {
        HStack(spacing: 12) {
            HStack(spacing: 12) {
                EventCoverView(
                    coverImage: event.coverImage,
                    eventType: event.type,
                    size: 52,
                    placeholderBackground: DesignSystem.Colors.bgSurface
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.input)
                        .stroke(DesignSystem.Colors.border, lineWidth: 1)
                )

                VStack(alignment: .leading, spacing: 6) {
                    Text(event.name)
                        .font(DesignSystem.Typography.title3)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        Text(event.type.displayName)
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

                        Text(formattedEventDate(event.date))
                            .font(DesignSystem.Typography.small)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                            .lineLimit(1)
                    }

                    Text(String(localized: "record.add.relatedEvent"))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }

                Spacer()
            }
        }
        .padding(14)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                .stroke(DesignSystem.Colors.border, lineWidth: 1)
        )
    }

    private var eventScrollSelector: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.block) {
            HStack {
                Text(String(localized: "record.add.selectEvent"))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                    .tracking(1.5)
                    .textCase(.uppercase)

                Spacer()
            }
            .padding(.horizontal, 4)

            eventCoverScroll

            if viewModel.allEvents.isEmpty {
                Text(String(localized: "record.add.noEvent"))
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                    .padding(.horizontal, 4)
            }
        }
    }

    private var eventCoverScroll: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(viewModel.allEvents) { event in
                    eventCoverItem(event)
                }

                createEventButton
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 4)
        }
    }

    private func eventCoverItem(_ event: Event) -> some View {
        let isSelected = viewModel.selectedEvent?.persistentModelID == event.persistentModelID
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.selectedEvent = event
            }
        } label: {
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: DesignSystem.Radius.input)
                    .fill(isSelected ? DesignSystem.Colors.primary.opacity(DesignSystem.Effects.selectedFillOpacity) : .clear)
                    .frame(width: 60, height: 60)
                    .overlay {
                        EventCoverView(
                            coverImage: event.coverImage,
                            eventType: event.type,
                            size: 56,
                            placeholderBackground: DesignSystem.Colors.bgSurface
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.Radius.input)
                                .stroke(
                                    isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.border.opacity(0.35),
                                    lineWidth: isSelected ? 2 : 1
                                )
                        )
                    }
                    .shadow(
                        color: isSelected ? DesignSystem.Colors.primary.opacity(DesignSystem.Effects.selectedShadowOpacity) : .clear,
                        radius: DesignSystem.Effects.selectedShadowRadius,
                        y: DesignSystem.Effects.selectedShadowYOffset
                    )

                Text(event.name)
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(
                        isSelected
                            ? DesignSystem.Colors.textPrimary
                            : DesignSystem.Colors.textSecondary
                    )
                    .fontWeight(isSelected ? .medium : .regular)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(width: 80)
            .opacity(viewModel.selectedEvent == nil || isSelected ? 1.0 : 0.7)
        }
        .buttonStyle(.plain)
    }

    private var createEventButton: some View {
        Button {
            eventIDsBeforeCreation = Set(viewModel.allEvents.map(\.persistentModelID))
            showAddEventSheet = true
        } label: {
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: DesignSystem.Radius.input)
                    .fill(DesignSystem.Colors.bgSurface)
                    .frame(width: 56, height: 56)
                    .overlay {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(DesignSystem.Colors.primary)
                    }

                Text(String(localized: "record.add.newEvent"))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(width: 80)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Daily Tag Section

    private var dailyTagSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(String(localized: "record.add.dailyTag"))
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .fontWeight(.semibold)

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.isCreatingCustomTag.toggle()
                        if !viewModel.isCreatingCustomTag {
                            viewModel.customTagInput = ""
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: viewModel.isCreatingCustomTag ? "xmark" : "plus")
                            .font(.system(size: 11, weight: .semibold))
                        Text(viewModel
                            .isCreatingCustomTag ? String(localized: "common.cancel") : String(localized: "record.add.dailyTag.custom"))
                            .font(DesignSystem.Typography.small)
                    }
                    .foregroundStyle(DesignSystem.Colors.primary)
                }
            }

            if viewModel.isCreatingCustomTag {
                HStack(spacing: 8) {
                    TextField(String(localized: "record.add.dailyTag.customPlaceholder"), text: $viewModel.customTagInput)
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                        .padding(10)
                        .background(DesignSystem.Colors.bgSurface)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.Radius.input)
                                .stroke(DesignSystem.Colors.border, lineWidth: 1)
                        )

                    Button {
                        viewModel.addCustomTag()
                    } label: {
                        Text(String(localized: "common.confirm"))
                            .font(DesignSystem.Typography.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(DesignSystem.Colors.bgSurface)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                viewModel.customTagInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                    ? DesignSystem.Colors.textTertiary
                                    : DesignSystem.Colors.primary
                            )
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
                    }
                    .disabled(viewModel.customTagInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }

            dailyTagFlowLayout
        }
    }

    private var dailyTagFlowLayout: some View {
        FlowLayout(spacing: 8) {
            ForEach(viewModel.allDailyTags, id: \.self) { tag in
                dailyTagCapsule(tag)
            }
        }
    }

    private func dailyTagCapsule(_ tag: String) -> some View {
        let isSelected = viewModel.selectedDailyTag == tag
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                viewModel.selectedDailyTag = isSelected ? "" : tag
            }
        } label: {
            Text(tag)
                .font(DesignSystem.Typography.caption)
                .fontWeight(.medium)
                .foregroundStyle(isSelected ? DesignSystem.Colors.textPrimary : DesignSystem.Colors.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? DesignSystem.Colors.primary.opacity(0.08) : DesignSystem.Colors.bgSurface)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(
                            isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.border.opacity(0.5),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Date Section

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "record.add.date"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .fontWeight(.semibold)

            HStack {
                DatePicker(
                    "",
                    selection: $viewModel.date,
                    displayedComponents: .date
                )
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

    // MARK: - Photos Section

    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "record.add.photos"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .fontWeight(.semibold)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    existingPhotoThumbnails
                    newPhotoThumbnails
                    addPhotoButton
                }
                .padding(12)
            }
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        }
    }

    @ViewBuilder
    private var existingPhotoThumbnails: some View {
        if let record = viewModel.editingRecord {
            ForEach((record.photos ?? []).sorted(by: { $0.createdAt < $1.createdAt })) { photo in
                photoThumbnail(imageData: photo.imageData)
            }
        }
    }

    private var newPhotoThumbnails: some View {
        ForEach(viewModel.newPhotoItems) { item in
            photoThumbnail(imageData: item.data)
        }
    }

    private func photoThumbnail(imageData: Data) -> some View {
        Group {
            if let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            }
        }
        .frame(width: 80, height: 80)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
    }

    private var addPhotoButton: some View {
        PhotosPicker(
            selection: $selectedPhotoItems,
            maxSelectionCount: 20,
            matching: .images
        ) {
            VStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.system(size: 24))
                Text(String(localized: "record.add.addPhoto"))
                    .font(DesignSystem.Typography.small)
            }
            .foregroundStyle(DesignSystem.Colors.textSecondary)
            .frame(width: 80, height: 80)
            .background(DesignSystem.Colors.bgTag)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "record.add.notes"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .fontWeight(.semibold)

            TextEditor(text: $viewModel.note)
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

    // MARK: - Confirm Button

    private var confirmButton: some View {
        VStack(spacing: 8) {
            Button {
                saveRecord()
            } label: {
                Text(viewModel.confirmButtonTitle)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!viewModel.isValid)
            .opacity(viewModel.isValid ? 1.0 : DesignSystem.Effects.disabledOpacity)
            .padding(.top, 4)

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

    // MARK: - Helpers

    private func refreshEventsAfterCreation() {
        viewModel.loadData(context: modelContext)

        let newEvents = viewModel.allEvents.filter { event in
            !eventIDsBeforeCreation.contains(event.persistentModelID)
        }
        if let newestEvent = newEvents.max(by: { $0.createdAt < $1.createdAt }) {
            viewModel.selectedEvent = newestEvent
        }

        eventIDsBeforeCreation = []
    }

    private func refreshContactsAfterAddSheet() {
        viewModel.loadData(context: modelContext)

        let newContacts = viewModel.allContacts.filter { contact in
            !contactIDsBeforeAddSheet.contains(contact.persistentModelID)
        }
        if let newestContact = newContacts.max(by: { $0.createdAt < $1.createdAt }) {
            viewModel.selectedContact = newestContact
        }

        contactIDsBeforeAddSheet = []
    }

    private func formattedEventDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: date)
    }

    private func saveRecord() {
        if viewModel.editingRecord == nil, !SubscriptionManager.shared.canAddRecord(context: modelContext) {
            showProSheet = true
            return
        }
        if viewModel.save(context: modelContext) {
            dismiss()
        }
    }

    private func paymentMethodName(_ method: PaymentMethod) -> String {
        switch method {
        case .cash: String(localized: "payment.cash")
        case .wechat: String(localized: "payment.wechat")
        case .alipay: String(localized: "payment.alipay")
        }
    }
}

// MARK: - Preview

@MainActor
private func makeAddRecordPreviewContainer() -> ModelContainer? {
    guard let container = try? ModelContainer(
        for: Contact.self, Record.self, Event.self, RecordPhoto.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    ) else { return nil }
    let ctx = container.mainContext
    let cal = Calendar.current
    let now = Date()

    let c1 = Contact(name: "张三", relation: "同事", category: "社交", circle: 3)
    let c2 = Contact(name: "李四", relation: "朋友", category: "社交", circle: 3)
    let c3 = Contact(name: "王五", relation: "舅舅", category: "亲属", circle: 2)
    let c4 = Contact(name: "赵六", relation: "同学", category: "社交", circle: 3)
    let c5 = Contact(name: "钱七", relation: "邻居", category: "其他", circle: 4)
    let c6 = Contact(name: "孙八", relation: "客户", category: "社交", circle: 3)
    [c1, c2, c3, c4, c5, c6].forEach { ctx.insert($0) }

    let e1 = Event(name: "表哥的婚礼", type: .wedding, date: cal.liShuDateByAddingDays(5, to: now), location: "家乡酒店")
    let e2 = Event(name: "小李30岁生日", type: .birthday, date: cal.liShuDateByAddingDays(12, to: now), location: "上海")
    let e3 = Event(name: "硕士毕业典礼", type: .education, date: cal.liShuDateByAddingDays(20, to: now), location: "广州")
    let e4 = Event(name: "春节拜年", type: .festival, date: cal.liShuDateByAddingMonths(-1, to: now), location: "老家")
    let e5 = Event(name: "王总乔迁", type: .property, date: cal.liShuDateByAddingDays(-5, to: now), location: "深圳")
    let e6 = Event(name: "爷爷丧事", type: .funeral, date: cal.liShuDateByAddingMonths(-2, to: now), location: "县城")
    let e7 = Event(name: "新店开业", type: .business, date: cal.liShuDateByAddingDays(30, to: now), location: "杭州")
    [e1, e2, e3, e4, e5, e6, e7].forEach { ctx.insert($0) }

    let r1 = Record.makeMonetaryRecord(contact: c1, event: e1, amount: 800, direction: .given, paymentMethod: .wechat, date: now)
    let r2 = Record.makeMonetaryRecord(
        contact: c2,
        event: e2,
        amount: 600,
        direction: .given,
        paymentMethod: .cash,
        date: cal.liShuDateByAddingDays(-2, to: now)
    )
    let r3 = Record.makeMonetaryRecord(
        contact: c3,
        event: e4,
        amount: 500,
        direction: .received,
        paymentMethod: .alipay,
        date: cal.liShuDateByAddingMonths(-1, to: now)
    )
    let r4 = Record.makeMonetaryRecord(
        contact: c4,
        event: nil,
        amount: 200,
        direction: .given,
        paymentMethod: .wechat,
        date: cal.liShuDateByAddingDays(-3, to: now)
    )
    r4.contextTag = "年会凑份"
    let r5 = Record.makeMonetaryRecord(
        contact: c5,
        event: nil,
        amount: 100,
        direction: .given,
        date: cal.liShuDateByAddingDays(-10, to: now)
    )
    r5.contextTag = "社区互助"
    [r1, r2, r3, r4, r5].forEach { ctx.insert($0) }

    return container
}

#Preview {
    Group {
        if let container = makeAddRecordPreviewContainer() {
            NavigationStack {
                AddRecordView()
            }
            .modelContainer(container)
            .environment(SubscriptionManager.shared)
        } else {
            Text(String(localized: "common.preview.unavailable"))
        }
    }
}
