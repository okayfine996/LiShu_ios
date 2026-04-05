import SwiftUI
import SwiftData

struct ContactExchangeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ContactExchangeViewModel()

    let contactID: PersistentIdentifier

    var body: some View {
        Group {
            if let contact = viewModel.contact {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        profileSection(contact)
                        summaryCards
                        netValueBar
                        timelineSection
                    }
                    .padding(.bottom, 32)
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(DesignSystem.Colors.bgPage)
        .navigationTitle(
            viewModel.contact.map {
                String(format: String(localized: "exchange.title"), $0.name)
            } ?? ""
        )
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.load(contactID: contactID, context: modelContext)
        }
    }

    // MARK: - Profile

    private func profileSection(_ contact: Contact) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                AvatarView(imageData: contact.avatar, name: contact.name, size: 96)

                Text(contact.name)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                if !contact.relation.isEmpty {
                    HStack(spacing: 8) {
                        Text(contact.relation)
                            .font(DesignSystem.Typography.small)
                            .fontWeight(.semibold)
                            .foregroundStyle(DesignSystem.Colors.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(DesignSystem.Colors.primary.opacity(0.1))
                            .clipShape(Capsule())

                        if !contact.category.isEmpty && contact.category != contact.relation {
                            Text(contact.category)
                                .font(DesignSystem.Typography.small)
                                .fontWeight(.semibold)
                                .foregroundStyle(DesignSystem.Colors.primary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(DesignSystem.Colors.primary.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }

                if let lastText = viewModel.lastContactText {
                    Text(String(localized: "exchange.lastContact") + lastText)
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                        .padding(.top, 4)
                }
            }
            .padding(.vertical, 24)
        }
    }

    // MARK: - Summary Cards

    private var summaryCards: some View {
        HStack(spacing: 12) {
            exchangeCard(
                icon: "arrow.up.right",
                label: String(localized: "exchange.given"),
                amount: viewModel.formatAmount(viewModel.totalGiven),
                amountColor: DesignSystem.Colors.textPrimary
            )
            exchangeCard(
                icon: "arrow.down.left",
                label: String(localized: "exchange.received"),
                amount: viewModel.formatAmount(viewModel.totalReceived),
                amountColor: DesignSystem.Colors.textPrimary
            )
        }
        .padding(.horizontal, 16)
    }

    private func exchangeCard(icon: String, label: String, amount: String, amountColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            .foregroundStyle(DesignSystem.Colors.textSecondary)

            Text(amount)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(amountColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
    }

    // MARK: - Net Value Bar

    private var netValueBar: some View {
        VStack(spacing: 8) {
            HStack(alignment: .bottom) {
                Text(String(localized: "exchange.netValue") + " (" + viewModel.netLabel + ")")
                    .font(DesignSystem.Typography.small)
                    .fontWeight(.bold)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Spacer()

                Text(viewModel.formatAmount(abs(viewModel.netValue)))
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.bold)
                    .foregroundStyle(DesignSystem.Colors.primary)
            }

            GeometryReader { geo in
                HStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(DesignSystem.Colors.primary)
                        .frame(width: geo.size.width * viewModel.givenRatio)

                    Rectangle()
                        .fill(DesignSystem.Colors.primary.opacity(0.3))
                }
                .frame(height: 10)
                .clipShape(Capsule())
            }
            .frame(height: 10)

            HStack {
                Text(String(format: String(localized: "exchange.ratio.given"), Int(viewModel.givenRatio * 100)))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                Spacer()
                Text(String(format: String(localized: "exchange.ratio.received"), Int((1 - viewModel.givenRatio) * 100)))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
    }

    // MARK: - Timeline

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(String(localized: "exchange.timeline"))
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.bold)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)

            if viewModel.records.isEmpty {
                EmptyStateView(
                    icon: "clock",
                    message: String(localized: "exchange.timeline.empty")
                )
                .frame(height: 200)
                .padding(.horizontal, 16)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.records.enumerated()), id: \.element.persistentModelID) { index, record in
                        timelineItem(record: record, isLast: index == viewModel.records.count - 1)
                    }
                }
                .padding(.leading, 16)
            }
        }
    }

    private func timelineItem(record: Record, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(spacing: 0) {
                Circle()
                    .fill(isLast ? DesignSystem.Colors.textTertiary : DesignSystem.Colors.primary)
                    .frame(width: 10, height: 10)
                    .padding(.top, 6)

                if !isLast {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    DesignSystem.Colors.primary.opacity(0.4),
                                    DesignSystem.Colors.primary.opacity(0.1)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 2)
                }
            }
            .frame(width: 10)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(viewModel.formatDate(record.date))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                    Spacer()
                    Text(amountText(record))
                        .font(DesignSystem.Typography.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            record.direction == .received
                                ? DesignSystem.Colors.accentGold
                                : DesignSystem.Colors.primary
                        )
                }

                NavigationLink(value: AppRoute.recordDetail(record.persistentModelID)) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(record.contextDisplayName)
                            .font(DesignSystem.Typography.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)

                        if !record.note.isEmpty {
                            Text(String(localized: "exchange.timeline.note") + record.note)
                                .font(DesignSystem.Typography.small)
                                .foregroundStyle(DesignSystem.Colors.textTertiary)
                                .lineLimit(2)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .contentShape(Rectangle())
                    .background(DesignSystem.Colors.bgSurface)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
                }
                .buttonStyle(.plain)
            }
            .padding(.leading, 20)
            .padding(.trailing, 16)
            .padding(.bottom, isLast ? 0 : 24)
        }
    }

    // MARK: - Helpers

    private func amountText(_ record: Record) -> String {
        let prefix = record.direction == .received ? "+ " : "- "
        return prefix + viewModel.formatAmount(record.resolvedDisplayAmount)
    }
}

// MARK: - Preview

private func makeExchangePreviewContainer() -> ModelContainer? {
    guard let container = try? ModelContainer(
        for: Contact.self, Record.self, Event.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    ) else { return nil }
    let ctx = container.mainContext

    let contact = Contact(name: "李小明", relation: "大学同学", category: "朋友", circle: 3)
    ctx.insert(contact)

    let e1 = Event(name: "张三婚礼", type: .wedding, date: .previewDate(2025, 10, 24))
    let e2 = Event(name: "春节聚会", type: .festival, date: .previewDate(2025, 10, 15))
    let e3 = Event(name: "生日礼物", type: .birthday, date: .previewDate(2025, 9, 28))
    let e4 = Event(name: "乔迁之喜", type: .property, date: .previewDate(2025, 8, 10))
    [e1, e2, e3, e4].forEach { ctx.insert($0) }

    let records: [Record] = [
        Record.makeMonetaryRecord(contact: contact, event: e1, amount: 1200, direction: .given, note: "用于UI设计外包首笔款项", date: .previewDate(2025, 10, 24)),
        Record.makeMonetaryRecord(contact: contact, event: e2, amount: 2500, direction: .received, note: "已通过微信转账确认收妥", date: .previewDate(2025, 10, 15)),
        Record.makeMonetaryRecord(contact: contact, event: e3, amount: 500, direction: .given, note: "送出的书籍与咖啡卡", date: .previewDate(2025, 9, 28)),
        Record.makeMonetaryRecord(contact: contact, event: e4, amount: 800, direction: .given, date: .previewDate(2025, 8, 10)),
        Record.makeMonetaryRecord(contact: contact, event: e2, amount: 1000, direction: .received, date: .previewDate(2025, 7, 1)),
    ]
    records.forEach { ctx.insert($0) }

    return container
}

private extension Date {
    static func previewDate(_ y: Int, _ m: Int, _ d: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: y, month: m, day: d)) ?? .now
    }
}

#Preview {
    Group {
        if let container = makeExchangePreviewContainer(),
           let contacts = try? container.mainContext.fetch(FetchDescriptor<Contact>()),
           let first = contacts.first {
            NavigationStack {
                ContactExchangeView(contactID: first.persistentModelID)
            }
            .modelContainer(container)
        } else {
            Text(String(localized: "common.preview.unavailable"))
        }
    }
}
