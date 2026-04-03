import SwiftUI
import SwiftData

struct CircleDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = CircleDetailViewModel()

    let circle: Int
    let year: Int

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loaded:
                mainContent
            case .error(let message):
                ErrorStateView(message: message) {
                    viewModel.load(circle: circle, year: year, context: modelContext)
                }
            }
        }
        .background(DesignSystem.Colors.bgPage)
        .navigationTitle(viewModel.circleName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.load(circle: circle, year: year, context: modelContext)
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                profileHeader
                summarySection
                averageSection
                memberListSection
            }
            .padding(.bottom, 24)
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.primary.opacity(0.1))
                    .frame(width: 112, height: 112)

                Image(systemName: viewModel.circleIcon)
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(DesignSystem.Colors.primary)
            }
            .overlay(
                Circle()
                    .stroke(DesignSystem.Colors.bgSurface, lineWidth: 4)
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            )

            VStack(spacing: 8) {
                Text(viewModel.circleName)
                    .font(DesignSystem.Typography.title2)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                HStack(spacing: 8) {
                    Text(String(format: String(localized: "circle.detail.memberCount"), viewModel.memberCount))
                        .font(DesignSystem.Typography.small)
                        .fontWeight(.semibold)
                        .foregroundStyle(DesignSystem.Colors.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(DesignSystem.Colors.primary.opacity(0.15))
                        .clipShape(Capsule())

                    Text(viewModel.closenessLevel)
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Summary Data

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(String(localized: "circle.detail.summary"))
                    .font(DesignSystem.Typography.title3)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Spacer()
            }

            VStack(spacing: 12) {
                totalAmountCard

                HStack(spacing: 12) {
                    netValueCard
                    incomeExpenseCard
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var totalAmountCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "circle.detail.totalAmount"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Text(viewModel.formatAmount(viewModel.totalAmount))
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(DesignSystem.Colors.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                .stroke(DesignSystem.Colors.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private var netValueCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "circle.detail.netValue"))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .textCase(.uppercase)

            Text(viewModel.formatAmount(viewModel.netValue))
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(
                    viewModel.netValue >= 0
                        ? DesignSystem.Colors.accentGold
                        : DesignSystem.Colors.primary
                )
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                .stroke(DesignSystem.Colors.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private var incomeExpenseCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "circle.detail.incomeExpense"))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .textCase(.uppercase)

            HStack(spacing: 4) {
                Text(viewModel.formatCompactAmount(viewModel.totalIncome))
                    .foregroundStyle(DesignSystem.Colors.primary)
                Text("/")
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                Text(viewModel.formatCompactAmount(viewModel.totalExpense))
                    .foregroundStyle(DesignSystem.Colors.primary)
            }
            .font(.system(size: 16, weight: .bold))
            .lineLimit(1)
            .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                .stroke(DesignSystem.Colors.primary.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - Average Data

    private var averageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "circle.detail.averageData"))
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    averageCard(
                        label: String(localized: "circle.detail.avgAmount"),
                        value: viewModel.formatAmount(viewModel.averageAmount)
                    )
                    averageCard(
                        label: String(localized: "circle.detail.avgNetValue"),
                        value: viewModel.formatAmount(viewModel.averageNetValue)
                    )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 32)
    }

    private func averageCard(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(DesignSystem.Colors.primary)
                .textCase(.uppercase)

            Text(value)
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(minWidth: 160, alignment: .leading)
        .padding(16)
        .background(DesignSystem.Colors.primary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard)
                .stroke(DesignSystem.Colors.primary.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - Member List

    private var memberListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(String(localized: "circle.detail.memberList"))
                    .font(DesignSystem.Typography.title3)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Spacer()

                HStack(spacing: 2) {
                    Text(String(localized: "circle.detail.sortByNetValue"))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.primary)
                    Image(systemName: "arrow.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.primary)
                }
            }

            if viewModel.members.isEmpty {
                EmptyStateView(
                    icon: "person.3",
                    message: String(localized: "circle.detail.empty")
                )
                .frame(height: 200)
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(viewModel.members.enumerated()), id: \.element.id) { index, member in
                        NavigationLink(value: AppRoute.contactDetail(member.contact.persistentModelID)) {
                            memberRow(member: member, isLast: index == viewModel.members.count - 1)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 32)
    }

    private func memberRow(member: CircleMemberItem, isLast: Bool) -> some View {
        HStack(spacing: 12) {
            AvatarView(imageData: member.contact.avatar, name: member.contact.name, size: 48)

            VStack(alignment: .leading, spacing: 2) {
                Text(member.contact.name)
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                if !member.contact.relation.isEmpty {
                    Text(member.contact.relation)
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(viewModel.formatAmount(abs(member.netValue)))
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(
                        member.netValue >= 0
                            ? DesignSystem.Colors.accentGold
                            : DesignSystem.Colors.primary
                    )

                Text(String(localized: "circle.detail.netValueLabel"))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(DesignSystem.Colors.primary)
                    .textCase(.uppercase)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        .opacity(isLast && viewModel.members.count > 3 ? 0.8 : 1.0)
    }

}

// MARK: - Preview

private func makeCircleDetailPreviewContainer() -> ModelContainer? {
    guard let container = try? ModelContainer(
        for: Contact.self, Record.self, Event.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    ) else { return nil }
    let ctx = container.mainContext

    let c1 = Contact(name: "张伯伯", relation: "父亲的长兄", circle: 2)
    let c2 = Contact(name: "李阿姨", relation: "母亲的表妹", circle: 2)
    let c3 = Contact(name: "王小弟", relation: "堂弟", circle: 2)
    let c4 = Contact(name: "陈奶奶", relation: "外祖母", circle: 2)
    [c1, c2, c3, c4].forEach { ctx.insert($0) }

    let e1 = Event(name: "结婚喜宴", type: .wedding, date: .now)
    let e2 = Event(name: "生日祝寿", type: .birthday, date: .now)
    [e1, e2].forEach { ctx.insert($0) }

    let records: [Record] = [
        Record(contact: c1, event: e1, amount: 20000, direction: .received, paymentMethod: .wechat),
        Record(contact: c1, event: e2, amount: 5000, direction: .given, paymentMethod: .cash),
        Record(contact: c2, event: e1, amount: 10000, direction: .received, paymentMethod: .alipay),
        Record(contact: c2, event: e2, amount: 3000, direction: .given, paymentMethod: .wechat),
        Record(contact: c3, event: e1, amount: 5000, direction: .received, paymentMethod: .cash),
        Record(contact: c3, event: e2, amount: 2000, direction: .given, paymentMethod: .alipay),
        Record(contact: c4, event: e1, amount: 3000, direction: .received, paymentMethod: .cash),
        Record(contact: c4, event: e2, amount: 2000, direction: .given, paymentMethod: .wechat),
    ]
    records.forEach { ctx.insert($0) }

    return container
}

#Preview {
    Group {
        if let container = makeCircleDetailPreviewContainer() {
            NavigationStack {
                CircleDetailView(circle: 2, year: Calendar.current.component(.year, from: .now))
            }
            .modelContainer(container)
        } else {
            Text(String(localized: "common.preview.unavailable"))
        }
    }
}
