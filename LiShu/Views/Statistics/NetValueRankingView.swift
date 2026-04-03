import SwiftUI
import SwiftData

struct NetValueRankingView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = StatisticsViewModel()

    let year: Int

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loaded where viewModel.allRankedContacts.isEmpty:
                EmptyStateView(
                    icon: "person.2.fill",
                    message: String(localized: "statistics.ranking.empty")
                )
            case .loaded:
                rankingContent
            case .error(let message):
                ErrorStateView(message: message) {
                    viewModel.selectYear(year, context: modelContext)
                }
            }
        }
        .background(DesignSystem.Colors.bgPage)
        .navigationTitle(String(localized: "statistics.ranking.netValue.title"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.selectYear(year, context: modelContext)
        }
    }

    // MARK: - Content

    private var rankingContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                summaryCard
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)

                rankingList
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)

                if !rankedContacts.isEmpty {
                    Text(String(localized: "statistics.ranking.noMore"))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                        .padding(.bottom, 20)
                }
            }
        }
    }

    private var rankedContacts: [ContactRankingItem] {
        viewModel.allRankedContacts.sorted { $0.netValue > $1.netValue }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.4))
                    .frame(width: 48, height: 48)
                Image(systemName: "wallet.bifold")
                    .font(.system(size: 22))
                    .foregroundStyle(DesignSystem.Colors.primary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(String(format: String(localized: "ranking.summary.count"), rankedContacts.count))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Text(String(localized: "ranking.summary.subtitle"))
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }

            Spacer()
        }
        .padding(20)
        .background(DesignSystem.Colors.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
    }

    // MARK: - Ranking List

    private var rankingList: some View {
        VStack(spacing: 10) {
            ForEach(Array(rankedContacts.enumerated()), id: \.element.id) { index, item in
                rankingCard(rank: index + 1, item: item)
            }
        }
    }

    private func rankingCard(rank: Int, item: ContactRankingItem) -> some View {
        NavigationLink(value: AppRoute.contactExchange(item.contact.persistentModelID)) {
            HStack(spacing: 12) {
                rankBadge(rank)

                AvatarView(imageData: item.contact.avatar, name: item.contact.name, size: 48)

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.contact.name)
                        .font(DesignSystem.Typography.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                        .lineLimit(1)

                    Text(String(format: String(localized: "statistics.ranking.count"), item.recordCount))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }

                Spacer()

                Text(viewModel.formatNetValue(item.netValue))
                    .font(DesignSystem.Typography.small)
                    .fontWeight(.medium)
                    .foregroundStyle(DesignSystem.Colors.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(DesignSystem.Colors.primary.opacity(0.1))
                    .clipShape(Capsule())
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
            .shadow(color: DesignSystem.Colors.separator.opacity(0.2), radius: 2, y: 1)
        }
        .buttonStyle(.plain)
    }

    private func rankBadge(_ rank: Int) -> some View {
        Text("\(rank)")
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(rank <= 3 ? .white : DesignSystem.Colors.textTertiary)
            .frame(width: 24, height: 24)
            .background(rank <= 3 ? DesignSystem.Colors.primary : DesignSystem.Colors.bgInput)
            .clipShape(Circle())
    }
}

// MARK: - Preview

private func makeNetValueRankingPreviewContainer() -> ModelContainer? {
    guard let container = try? ModelContainer(
        for: Contact.self, Record.self, Event.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    ) else { return nil }
    let ctx = container.mainContext
    let cal = Calendar.current
    let thisYear = cal.component(.year, from: .now)

    let contacts = [
        Contact(name: "张伟峰", relation: "同事", circle: 3),
        Contact(name: "李晓敏", relation: "朋友", circle: 2),
        Contact(name: "陈思诚", relation: "表哥", circle: 1),
        Contact(name: "王志平", relation: "同学", circle: 3),
        Contact(name: "周洁如", relation: "邻居", circle: 3),
        Contact(name: "赵云开", relation: "舅舅", circle: 1),
        Contact(name: "孙俪", relation: "同事", circle: 2),
    ]
    contacts.forEach { ctx.insert($0) }

    let event = Event(name: "春节", type: .festival, date: cal.date(from: DateComponents(year: thisYear, month: 1, day: 28))!)
    ctx.insert(event)

    let amounts: [(Double, Double)] = [
        (18000, 5200), (12000, 3500), (8000, 2800),
        (5000, 2000), (3500, 1400), (4000, 2200), (2000, 800),
    ]
    for (i, contact) in contacts.enumerated() {
        let (income, expense) = amounts[i]
        ctx.insert(Record(contact: contact, event: event, amount: income, direction: .received, date: cal.date(from: DateComponents(year: thisYear, month: 1, day: 28))!))
        ctx.insert(Record(contact: contact, event: event, amount: expense, direction: .given, date: cal.date(from: DateComponents(year: thisYear, month: 2, day: 10))!))
    }

    return container
}

#Preview {
    Group {
        if let container = makeNetValueRankingPreviewContainer() {
            let thisYear = Calendar.current.component(.year, from: .now)
            NavigationStack {
                NetValueRankingView(year: thisYear)
            }
            .modelContainer(container)
        } else {
            Text(String(localized: "common.preview.unavailable"))
        }
    }
}
