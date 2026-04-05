import SwiftData
import SwiftUI

struct ContactDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let contactID: PersistentIdentifier

    @State private var viewModel = ContactDetailViewModel()
    @State private var presentedSheet: SheetRoute?
    @State private var currentCardPage: Int = 0

    var body: some View {
        ZStack {
            DesignSystem.Colors.bgPage
                .ignoresSafeArea()

            if let contact = viewModel.contact {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        profileSection(contact)
                        summaryCardsSection(contact)
                        personalInfoSection(contact)
                        timelineSection(contact)
                    }
                    .padding(.bottom, 24)
                }
            } else if viewModel.isLoading {
                ProgressView()
            }
        }
        .navigationTitle(String(localized: "contact.detail.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        presentedSheet = .editContact(contactID)
                    } label: {
                        Label(String(localized: "common.edit"), systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        viewModel.isShowingDeleteAlert = true
                    } label: {
                        Label(String(localized: "common.delete"), systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                }
            }
        }
        .sheet(item: $presentedSheet) { route in
            switch route {
            case let .addRecord(direction, contactID):
                NavigationStack {
                    AddRecordView(direction: direction, contactID: contactID)
                }
            case let .editContact(id):
                NavigationStack {
                    AddContactView(contactID: id)
                }
            default:
                EmptyView()
            }
        }
        .onChange(of: presentedSheet) { _, newValue in
            if newValue == nil {
                viewModel.load(id: contactID, context: modelContext)
            }
        }
        .alert(String(localized: "contact.detail.deleteConfirm"), isPresented: $viewModel.isShowingDeleteAlert) {
            Button(String(localized: "common.cancel"), role: .cancel) {}
            Button(String(localized: "common.delete"), role: .destructive) {
                if viewModel.deleteContact(context: modelContext) {
                    dismiss()
                }
            }
        }
        .onAppear {
            viewModel.load(id: contactID, context: modelContext)
        }
    }

    // MARK: - Profile Section

    private func profileSection(_ contact: Contact) -> some View {
        VStack(spacing: 8) {
            AvatarView(imageData: contact.avatar, name: contact.name, size: 80)
                .overlay {
                    Circle()
                        .stroke(DesignSystem.Colors.bgSurface, lineWidth: 1)
                }

            Text(contact.name)
                .font(DesignSystem.Typography.title2)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            if !contact.category.isEmpty || !contact.relation.isEmpty {
                HStack(spacing: 6) {
                    if !contact.relation.isEmpty {
                        Text(contact.relation)
                            .font(DesignSystem.Typography.small)
                            .foregroundStyle(DesignSystem.Colors.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(DesignSystem.Colors.primary.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    if !contact.category.isEmpty {
                        Text(contact.category)
                            .font(DesignSystem.Typography.small)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(DesignSystem.Colors.bgTag)
                            .clipShape(Capsule())
                    }
                }
            }

            if !contact.location.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(DesignSystem.Typography.small)
                    Text(contact.location)
                        .font(DesignSystem.Typography.caption)
                }
                .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
    }

    // MARK: - Summary Cards (Swipeable)

    private func summaryCardsSection(_ contact: Contact) -> some View {
        ZStack(alignment: .topTrailing) {
            TabView(selection: $currentCardPage) {
                assetOverviewCard(contact)
                    .tag(0)
                relationshipInsightCard(contact)
                    .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .aspectRatio(1.5, contentMode: .fit)

            pageIndicator(current: currentCardPage)
                .padding(.top, DesignSystem.Spacing.cardPadding)
                .padding(.trailing, DesignSystem.Spacing.cardPadding)
                .allowsHitTesting(false)
        }
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        .padding(.horizontal, 16)
    }

    private func pageIndicator(current: Int) -> some View {
        HStack(spacing: 6) {
            ForEach(0 ..< 2, id: \.self) { index in
                Circle()
                    .fill(index == current
                        ? DesignSystem.Colors.primary
                        : DesignSystem.Colors.border)
                    .frame(width: 6, height: 6)
            }
        }
    }

    // MARK: Card 1 — 往来资产概览

    private func assetOverviewCard(_ contact: Contact) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(String(localized: "contact.detail.assetOverview"))
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .padding(.trailing, DesignSystem.Spacing.cardPadding + DesignSystem.Spacing.section)
                .padding(.bottom, 20)

            // Middle row: net value + interaction frequency
            HStack(alignment: .top) {
                // Left: 礼金净值
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "contact.detail.netSurplus"))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                    Text(viewModel.formatNetValue(contact.netValue))
                        .font(DesignSystem.Typography.title1)
                        .foregroundStyle(
                            contact.netValue >= 0
                                ? DesignSystem.Colors.accentGold
                                : DesignSystem.Colors.primary
                        )
                }

                Spacer()

                // Right: 互动频次
                VStack(alignment: .trailing, spacing: 4) {
                    Text(String(localized: "contact.detail.frequency"))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(viewModel.pastYearInteractionCount)")
                            .font(DesignSystem.Typography.title1)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                        Text(String(localized: "common.times"))
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                }
            }
            .padding(.bottom, 20)

            // Bottom row: type composition + income/expense
            HStack(alignment: .top) {
                // Left: 互动构成
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "contact.detail.composition"))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                    let typeCounts = viewModel.typeCounts
                    if !typeCounts.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(typeCounts.prefix(3)) { item in
                                HStack(spacing: 3) {
                                    Circle()
                                        .fill(DesignSystem.Colors.textTertiary)
                                        .frame(width: 4, height: 4)
                                    Text("\(item.type.displayName) \(item.count)")
                                        .font(DesignSystem.Typography.small)
                                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                                }
                            }
                        }
                    }
                }

                Spacer()

                // Right: 累计收支
                VStack(alignment: .trailing, spacing: 6) {
                    Text(String(localized: "contact.detail.incomeExpense"))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                    HStack(spacing: 4) {
                        Text(String(localized: "contact.detail.incomeShort"))
                            .font(DesignSystem.Typography.small)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                        Text(viewModel.formatAmount(contact.totalReceived))
                            .font(DesignSystem.Typography.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                    }
                    HStack(spacing: 4) {
                        Text(String(localized: "contact.detail.expenseShort"))
                            .font(DesignSystem.Typography.small)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                        Text(viewModel.formatAmount(contact.totalGiven))
                            .font(DesignSystem.Typography.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Card 2 — 关系亲疏洞察

    private func relationshipInsightCard(_ contact: Contact) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(String(localized: "contact.detail.relationshipInsight"))
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .padding(.trailing, DesignSystem.Spacing.cardPadding + DesignSystem.Spacing.section)
                .padding(.bottom, 20)

            // Middle row: activity rate + balance index
            HStack(alignment: .top) {
                // Left: 年度互动活跃度
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "contact.detail.activityRate"))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                    Text(String(format: "%.1f%%", viewModel.yearlyActivityRate * 100))
                        .font(DesignSystem.Typography.title1)
                        .foregroundStyle(DesignSystem.Colors.primary)
                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(DesignSystem.Colors.bgTag)
                                .frame(height: 6)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(DesignSystem.Colors.primary)
                                .frame(width: geo.size.width * viewModel.yearlyActivityRate, height: 6)
                        }
                    }
                    .frame(height: 6)
                    .frame(maxWidth: 120)
                }

                Spacer()

                // Right: 互惠平衡指数
                VStack(alignment: .trailing, spacing: 4) {
                    Text(String(localized: "contact.detail.balanceIndex"))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                    Text(viewModel.balanceLevelText(viewModel.balanceLevel))
                        .font(DesignSystem.Typography.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    Text(viewModel.balanceDescription(viewModel.balanceLevel))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                        .multilineTextAlignment(.trailing)
                }
            }
            .padding(.bottom, 20)

            // Bottom row: circle level + relation tags
            HStack(alignment: .top) {
                // Left: 核心圈层位置
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "contact.detail.circlePosition"))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                    HStack(spacing: 6) {
                        Image(systemName: "circle.grid.2x2.fill")
                            .font(DesignSystem.Typography.body)
                            .foregroundStyle(DesignSystem.Colors.primary)
                        Text(viewModel.circleLabel(contact.circle))
                            .font(DesignSystem.Typography.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(DesignSystem.Colors.primary)
                    }
                }

                Spacer()

                // Right: 关系标签
                VStack(alignment: .trailing, spacing: 8) {
                    Text(String(localized: "contact.detail.relationTags"))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                    HStack(spacing: 6) {
                        if !contact.relation.isEmpty {
                            Text(contact.relation)
                                .font(DesignSystem.Typography.small)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(DesignSystem.Colors.bgTag)
                                .clipShape(Capsule())
                        }
                        if !contact.category.isEmpty {
                            Text(contact.category)
                                .font(DesignSystem.Typography.small)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(DesignSystem.Colors.bgTag)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Personal Info Section

    private func personalInfoSection(_ contact: Contact) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(String(localized: "contact.detail.personalInfo"))
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

            VStack(spacing: 0) {
                if let birthday = contact.birthday {
                    infoRow(
                        icon: "birthday.cake.fill",
                        label: String(localized: "contact.add.birthday"),
                        value: viewModel.formatDate(birthday)
                    )
                    Divider()
                        .background(DesignSystem.Colors.separator)
                        .padding(.leading, 52)
                }

                infoRow(
                    icon: "circle.grid.2x2.fill",
                    label: String(localized: "contact.detail.circle"),
                    value: viewModel.circleText(contact.circle)
                )

                if !contact.phone.isEmpty {
                    Divider()
                        .background(DesignSystem.Colors.separator)
                        .padding(.leading, 52)

                    infoRow(
                        icon: "phone.fill",
                        label: String(localized: "contact.add.phone"),
                        value: contact.phone
                    )
                }

                if !contact.note.isEmpty {
                    Divider()
                        .background(DesignSystem.Colors.separator)
                        .padding(.leading, 52)

                    infoRow(
                        icon: "note.text",
                        label: String(localized: "contact.add.notes"),
                        value: contact.note
                    )
                }
            }
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
            .padding(.horizontal, 16)
        }
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.primary)
                .frame(width: 24, height: 24)

            Text(label)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Spacer()

            Text(value)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Timeline Section

    private func timelineSection(_ contact: Contact) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text(String(localized: "contact.detail.timeline"))
                    .font(DesignSystem.Typography.title3)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Spacer()

                Button {
                    presentedSheet = .addRecord(
                        direction: nil,
                        contactID: contact.persistentModelID
                    )
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(DesignSystem.Colors.primary)
                        .font(DesignSystem.Typography.title3)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)

            let records = viewModel.sortedRecords

            if records.isEmpty {
                EmptyStateView(
                    icon: "doc.text",
                    message: String(localized: "contact.detail.noRecords")
                )
                .frame(height: 160)
            } else {
                // Timeline
                VStack(spacing: 0) {
                    ForEach(Array(records.enumerated()), id: \.element.persistentModelID) { index, record in
                        timelineEntry(record, isLast: index == records.count - 1)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Timeline Entry

    private func timelineEntry(_ record: Record, isLast: Bool) -> some View {
        NavigationLink(value: AppRoute.recordDetail(record.persistentModelID)) {
            HStack(alignment: .top, spacing: 0) {
                // Timeline indicator
                VStack(spacing: 0) {
                    Circle()
                        .stroke(DesignSystem.Colors.border, lineWidth: 1.5)
                        .frame(width: 10, height: 10)
                        .background(
                            Circle()
                                .fill(DesignSystem.Colors.bgPage)
                        )
                        .padding(.top, 6)

                    if !isLast {
                        Rectangle()
                            .fill(DesignSystem.Colors.separator)
                            .frame(width: 1)
                    }
                }
                .frame(width: 10)

                Spacer().frame(width: 12)

                // Card content
                VStack(alignment: .leading, spacing: 10) {
                    // Date + amount/icon
                    HStack(alignment: .top) {
                        Text(viewModel.timelineDateText(record.date))
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                            .lineLimit(1)

                        Spacer()

                        timelineAmountView(record)
                            .frame(width: DesignSystem.Layout.timelineMetaWidth, alignment: .trailing)
                    }

                    // Type tag + event title
                    HStack(spacing: 8) {
                        Text(record.recordType.displayName)
                            .font(DesignSystem.Typography.small)
                            .foregroundStyle(typeTagColor(record.recordType))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(typeTagColor(record.recordType).opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.tag))

                        Text(record.contextDisplayName)
                            .font(DesignSystem.Typography.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                            .lineLimit(1)
                    }

                    // Note
                    if !record.note.isEmpty {
                        Text(record.note)
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                    }
                }
                .padding(DesignSystem.Spacing.cardPaddingSmall)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DesignSystem.Colors.bgSurface)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
                .padding(.bottom, isLast ? 0 : 16)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func timelineAmountView(_ record: Record) -> some View {
        switch record.recordType {
        case .monetary:
            let prefix = record.direction == .received ? "+" : "-"
            let formatted = viewModel.formatAmount(record.resolvedDisplayAmount)
            Text("\(prefix)\(formatted)")
                .font(DesignSystem.Typography.body)
                .fontWeight(.semibold)
                .foregroundStyle(
                    record.direction == .received
                        ? DesignSystem.Colors.accentGold
                        : DesignSystem.Colors.primary
                )
        case .gift:
            if let estimated = record.resolvedEstimatedValue, estimated > 0 {
                Text(String(localized: "contact.detail.estimated") + " " + viewModel.formatAmount(estimated))
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
            }
        case .favor:
            Image(systemName: "heart.fill")
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.primary)
        case .banquet:
            Image(systemName: "fork.knife")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
    }

    private func typeTagColor(_ type: RecordType) -> Color {
        switch type {
        case .monetary: DesignSystem.Colors.primary
        case .gift: DesignSystem.Colors.accentGold
        case .favor: DesignSystem.Colors.textSecondary
        case .banquet: DesignSystem.Colors.textTertiary
        }
    }
}

// MARK: - Preview

@MainActor
private func makeContactDetailPreviewContainer() -> (container: ModelContainer, contactID: PersistentIdentifier)? {
    guard let container = try? ModelContainer(
        for: Contact.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    ) else { return nil }

    let context = container.mainContext
    let contact = Contact(
        name: "张敬轩",
        phone: "138-8888-6666",
        relation: "大学同学",
        category: "社交",
        circle: 3,
        birthday: Date(timeIntervalSince1970: 643_334_400),
        location: "浙江 · 杭州"
    )
    context.insert(contact)

    let cal = Calendar.current

    // Event: 婚礼
    let weddingEvent = Event(
        name: "参加张三婚礼",
        type: .wedding,
        date: cal.liShuDate(year: 2025, month: 2, day: 15),
        location: "西湖国宾馆"
    )
    context.insert(weddingEvent)

    // Record 1: 礼金 — 参加婚礼
    let r1 = Record(
        contact: contact,
        event: weddingEvent,
        direction: .given,
        date: cal.liShuDate(year: 2025, month: 2, day: 15),
        recordType: .monetary
    )
    r1.applyTypeData(.monetary(MonetaryData(amount: 1000, paymentMethod: "wechat")))
    r1.note = "大学同学聚会，随份子表达祝贺。于西湖国宾馆举行。"
    context.insert(r1)

    // Record 2: 帮忙 — 帮忙挂号
    let r2 = Record(
        contact: contact,
        direction: .received,
        date: cal.liShuDate(year: 2025, month: 1, day: 8),
        recordType: .favor
    )
    r2.applyTypeData(.favor(FavorData(description: "帮忙挂号")))
    r2.note = "协助张敬轩父亲在省人民医院挂专家号，通过老同学关系顺利排上。"
    r2.contextTag = "帮忙挂号"
    context.insert(r2)

    // Record 3: 礼品 — 节日看望
    let r3 = Record(
        contact: contact,
        direction: .given,
        date: cal.liShuDate(year: 2024, month: 12, day: 22),
        recordType: .gift
    )
    r3.applyTypeData(.gift(GiftData(giftName: "手工点心和茶叶", estimatedValue: 300)))
    r3.note = "冬至带了两盒手工点心和茶叶登门拜访，闲聊两个小时。"
    r3.contextTag = "节日看望"
    context.insert(r3)

    // Record 4: 宴请 — 接风洗尘
    let r4 = Record(
        contact: contact,
        direction: .given,
        date: cal.liShuDate(year: 2024, month: 10, day: 5),
        recordType: .banquet
    )
    r4.applyTypeData(.banquet(BanquetData(location: "老杭帮菜馆", attendeeList: "张敬轩、李伟、王芳")))
    r4.note = "国庆期间张敬轩从北京回来，约了几个老同学一起吃饭叙旧。"
    r4.contextTag = "接风洗尘"
    context.insert(r4)

    // Record 5: 礼金 — 收到生日红包
    let birthdayEvent = Event(
        name: "我的生日",
        type: .birthday,
        date: cal.liShuDate(year: 2024, month: 8, day: 18)
    )
    context.insert(birthdayEvent)

    let r5 = Record(
        contact: contact,
        event: birthdayEvent,
        direction: .received,
        date: cal.liShuDate(year: 2024, month: 8, day: 18),
        recordType: .monetary
    )
    r5.applyTypeData(.monetary(MonetaryData(amount: 520, paymentMethod: "wechat")))
    r5.note = "生日当天收到微信红包，附言「生日快乐老同学」。"
    context.insert(r5)

    // Record 6: 帮忙 — 帮忙搬家
    let r6 = Record(
        contact: contact,
        direction: .received,
        date: cal.liShuDate(year: 2024, month: 6, day: 1),
        recordType: .favor
    )
    r6.applyTypeData(.favor(FavorData(description: "帮忙搬家")))
    r6.note = "新房搬家时主动开车来帮忙搬运，忙了一整天。"
    r6.contextTag = "帮忙搬家"
    context.insert(r6)

    // Record 7: 礼品 — 出差带特产
    let r7 = Record(
        contact: contact,
        direction: .received,
        date: cal.liShuDate(year: 2024, month: 4, day: 10),
        recordType: .gift
    )
    r7.applyTypeData(.gift(GiftData(giftName: "北京稻香村糕点", estimatedValue: 150)))
    r7.note = "出差北京回来带的特产，说是特意给我留的。"
    r7.contextTag = "出差带特产"
    context.insert(r7)

    return (container, contact.persistentModelID)
}

#Preview {
    Group {
        if let preview = makeContactDetailPreviewContainer() {
            NavigationStack {
                ContactDetailView(contactID: preview.contactID)
            }
            .modelContainer(preview.container)
        } else {
            Text(String(localized: "common.preview.unavailable"))
        }
    }
}
