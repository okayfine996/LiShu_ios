import SwiftData
import SwiftUI

enum GRMFocusField {
    case contactSearch
    case amount
    case note
}

struct GiftReceivingModeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel: GiftReceivingModeViewModel
    @FocusState private var focusedField: GRMFocusField?
    @State private var showProSheet = false

    init(eventID: PersistentIdentifier) {
        _viewModel = State(initialValue: GiftReceivingModeViewModel(eventID: eventID))
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                DesignSystem.Colors.bgPage.ignoresSafeArea()

                VStack(spacing: 0) {
                    statsBar
                    Divider()
                        .overlay(DesignSystem.Colors.separator)
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: DesignSystem.Spacing.block) {
                            contactSection
                            amountSection
                            paymentMethodSection
                            noteSection
                            submitButton
                            recentSection
                            Spacer(minLength: DesignSystem.Spacing.scrollBottom)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.pageHorizontal)
                        .padding(.top, DesignSystem.Spacing.block)
                    }
                }

                toastOverlay
            }
            .navigationTitle(String(localized: "giftReceiving.nav.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "common.cancel"), action: dismiss.callAsFunction)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
            .background(DesignSystem.Colors.bgPage)
        }
        .onAppear { viewModel.load(context: modelContext) }
        .onChange(of: viewModel.requestFocusField) { _, field in
            focusedField = field
        }
        .sheet(isPresented: $showProSheet) {
            NavigationStack {
                ProMembershipView()
            }
            .environment(SubscriptionManager.shared)
        }
        .alert(String(localized: "common.error"), isPresented: Binding(
            get: { viewModel.submitError != nil },
            set: { if !$0 { viewModel.submitError = nil } }
        )) {
            Button(String(localized: "common.ok")) { viewModel.submitError = nil }
        } message: {
            if let error = viewModel.submitError {
                Text(error)
            }
        }
    }

    // MARK: - Stats Bar

    private var statsBar: some View {
        HStack {
            if viewModel.totalReceivedCount == 0 {
                Text(String(localized: "giftReceiving.header.noRecords"))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            } else {
                Text(
                    String(
                        format: String(localized: "giftReceiving.header.stats"),
                        viewModel.totalReceivedCount,
                        viewModel.totalReceivedAmount
                    )
                )
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
            Spacer()
        }
        .padding(.horizontal, DesignSystem.Spacing.pageHorizontal)
        .padding(.vertical, DesignSystem.Spacing.inlineTight)
        .background(DesignSystem.Colors.bgCard)
    }

    // MARK: - Contact Section

    private var contactSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.stackTight) {
            Text(String(localized: "giftReceiving.form.contactSection"))
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
                .tracking(1)
                .textCase(.uppercase)
                .padding(.horizontal, DesignSystem.Spacing.stackTight)

            // 搜索输入框
            HStack(spacing: DesignSystem.Spacing.inlineTight) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                    .font(DesignSystem.Typography.caption)
                TextField(
                    String(localized: "giftReceiving.form.contactSearch"),
                    text: $viewModel.contactSearchText
                )
                .focused($focusedField, equals: .contactSearch)
                .onChange(of: viewModel.contactSearchText) { _, text in
                    viewModel.updateContactSearch(text: text)
                }
                .submitLabel(.next)
                .onSubmit {
                    if let first = viewModel.searchResults.first {
                        viewModel.selectContact(first)
                    } else if viewModel.canQuickAddContact {
                        viewModel.quickAddContact(name: viewModel.contactSearchText, context: modelContext)
                    }
                }

                if !viewModel.contactSearchText.isEmpty {
                    Button {
                        viewModel.contactSearchText = ""
                        viewModel.updateContactSearch(text: "")
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                            .font(DesignSystem.Typography.caption)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.block)
            .padding(.vertical, DesignSystem.Spacing.block)
            .background(DesignSystem.Colors.bgInput)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.input)
                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
            )

            // 内联搜索结果列表
            if viewModel.isSearchDropdownVisible {
                contactResultsList
            }
        }
    }

    private var contactResultsList: some View {
        VStack(spacing: 0) {
            if !viewModel.searchResults.isEmpty {
                ForEach(Array(viewModel.searchResults.prefix(5).enumerated()), id: \.element.persistentModelID) { index, contact in
                    Button {
                        viewModel.selectContact(contact)
                    } label: {
                        HStack(spacing: DesignSystem.Spacing.inlineTight) {
                            AvatarView(imageData: contact.avatar, name: contact.name, size: 32)
                                .clipShape(Circle())
                            VStack(alignment: .leading, spacing: 2) {
                                Text(contact.name)
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                                if !contact.relation.isEmpty {
                                    Text(contact.relation)
                                        .font(DesignSystem.Typography.small)
                                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal, DesignSystem.Spacing.block)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if index < min(viewModel.searchResults.count, 5) - 1 {
                        Divider()
                            .overlay(DesignSystem.Colors.separator.opacity(0.5))
                            .padding(.leading, DesignSystem.Spacing.block + 32 + DesignSystem.Spacing.inlineTight)
                    }
                }
            }

            if viewModel.canQuickAddContact {
                if !viewModel.searchResults.isEmpty {
                    Divider()
                        .overlay(DesignSystem.Colors.separator.opacity(0.5))
                }
                Button {
                    viewModel.quickAddContact(name: viewModel.contactSearchText, context: modelContext)
                } label: {
                    HStack(spacing: DesignSystem.Spacing.inlineTight) {
                        Image(systemName: "person.badge.plus")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.primary)
                            .frame(width: 32)
                        Text(
                            String(
                                format: String(localized: "giftReceiving.form.quickAdd"),
                                viewModel.contactSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
                            )
                        )
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.primary)
                        Spacer()
                    }
                    .padding(.horizontal, DesignSystem.Spacing.block)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.input)
                .stroke(DesignSystem.Colors.border.opacity(0.5), lineWidth: 1)
        )
    }

    // MARK: - Amount Section

    private var amountSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.stackTight) {
            Text(String(localized: "record.add.amount")
                .localizedUppercase)
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
                .tracking(1)
                .padding(.horizontal, DesignSystem.Spacing.stackTight)

            HStack(spacing: DesignSystem.Spacing.inlineTight) {
                Text("¥")
                    .font(DesignSystem.Typography.title3)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                TextField("0", text: $viewModel.monetaryAmount)
                    .focused($focusedField, equals: .amount)
                    .keyboardType(.decimalPad)
                    .font(DesignSystem.Typography.title3)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
            }
            .padding(.horizontal, DesignSystem.Spacing.block)
            .padding(.vertical, DesignSystem.Spacing.block)
            .background(DesignSystem.Colors.bgInput)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.input)
                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
            )
        }
    }

    // MARK: - Payment Method Section

    private var paymentMethodSection: some View {
        PaymentMethodSelector(selectedMethod: $viewModel.monetaryPaymentMethod)
    }

    // MARK: - Note Section

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.stackTight) {
            if viewModel.isNoteExpanded {
                TextField(
                    String(localized: "giftReceiving.form.notePlaceholder"),
                    text: $viewModel.note
                )
                .focused($focusedField, equals: .note)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .padding(.horizontal, DesignSystem.Spacing.block)
                .padding(.vertical, DesignSystem.Spacing.block)
                .background(DesignSystem.Colors.bgInput)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.input)
                        .stroke(DesignSystem.Colors.border, lineWidth: 1)
                )
            } else {
                Button {
                    viewModel.isNoteExpanded = true
                    focusedField = .note
                } label: {
                    Label(
                        String(localized: "giftReceiving.form.addNote"),
                        systemImage: "plus.circle"
                    )
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Submit Button

    private var submitButton: some View {
        Button(String(localized: "giftReceiving.submit.button")) {
            submitRecord()
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(!viewModel.isValid)
        .opacity(viewModel.isValid ? 1.0 : DesignSystem.Effects.disabledOpacity)
        .padding(.top, DesignSystem.Spacing.stackTight)
    }

    // MARK: - Recent Section

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.block) {
            Text(String(localized: "giftReceiving.form.recentTitle"))
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
                .tracking(1)
                .textCase(.uppercase)
                .padding(.horizontal, DesignSystem.Spacing.stackTight)
                .padding(.top, DesignSystem.Spacing.block)

            if viewModel.totalReceivedCount == 0 {
                Text(String(localized: "giftReceiving.form.recentEmpty"))
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, DesignSystem.Spacing.block)
            } else {
                VStack(spacing: DesignSystem.Spacing.stackTight) {
                    ForEach(viewModel.recentRecords) { record in
                        GRMRecentEntryRow(record: record) {
                            viewModel.deleteRecord(record, context: modelContext)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Toast

    private var toastOverlay: some View {
        VStack {
            if let message = viewModel.successToastMessage {
                Text(message)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, DesignSystem.Spacing.cardPadding)
                    .padding(.vertical, DesignSystem.Spacing.inlineTight + 2)
                    .background(DesignSystem.Colors.textPrimary.opacity(0.88))
                    .clipShape(Capsule())
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, DesignSystem.Spacing.cardPadding)
            }
            Spacer()
        }
        .animation(.spring(duration: 0.3), value: viewModel.successToastMessage)
        .allowsHitTesting(false)
    }

    // MARK: - Actions

    private func submitRecord() {
        if !SubscriptionManager.shared.canAddRecord(context: modelContext) {
            showProSheet = true
            return
        }
        viewModel.submit(context: modelContext)
    }
}

// MARK: - Recent Entry Row

private struct GRMRecentEntryRow: View {
    let record: Record
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(imageData: record.contact?.avatar, name: record.contact?.name)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(record.contact?.name ?? "—")
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Text(record.date.formatted(date: .omitted, time: .shortened))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }

            Spacer()

            Text("+ ¥\(record.resolvedDisplayAmount, specifier: "%.0f")")
                .font(DesignSystem.Typography.body)
                .fontWeight(.semibold)
                .foregroundStyle(DesignSystem.Colors.income)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label(String(localized: "common.delete"), systemImage: "trash")
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: Contact.self, Event.self, Record.self, configurations: .init(isStoredInMemoryOnly: true))
    let event = Event(name: "预览婚礼", type: .wedding, hostMode: .host, date: .now)
    container.mainContext.insert(event)
    let c1 = Contact(name: "张三")
    let c2 = Contact(name: "李四")
    container.mainContext.insert(c1)
    container.mainContext.insert(c2)
    try! container.mainContext.save()
    return GiftReceivingModeView(eventID: event.persistentModelID)
        .modelContainer(container)
}
