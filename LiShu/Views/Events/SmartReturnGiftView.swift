import SwiftData
import SwiftUI

struct SmartReturnGiftView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let eventID: PersistentIdentifier
    let contactID: PersistentIdentifier
    let initialPaymentMethod: PaymentMethod
    let onSelectSuggestedAmount: (@MainActor (Double, PaymentMethod) -> Void)?

    @State private var result: SmartReturnGiftResult?
    @State private var selectedTier: GiftTier = .standard
    @State private var selectedPaymentMethod: PaymentMethod = .cash
    @State private var amountText: String = ""
    @State private var isShowingErrorAlert = false
    @State private var errorMessage: String?

    enum GiftTier {
        case conservative, standard, generous
    }

    init(
        eventID: PersistentIdentifier,
        contactID: PersistentIdentifier,
        initialPaymentMethod: PaymentMethod = .cash,
        onSelectSuggestedAmount: (@MainActor (Double, PaymentMethod) -> Void)? = nil
    ) {
        self.eventID = eventID
        self.contactID = contactID
        self.initialPaymentMethod = initialPaymentMethod
        self.onSelectSuggestedAmount = onSelectSuggestedAmount
        _selectedPaymentMethod = State(initialValue: initialPaymentMethod)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                if let result {
                    contactHeaderCard(result)
                    if !result.historicalRecords.isEmpty {
                        timelineSection(result)
                    }
                    reasoningSection(result)
                    tierSelector(result)
                    confirmSection(result)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                }
                Spacer(minLength: 40)
            }
            .padding(.horizontal, DesignSystem.Spacing.pageHorizontal)
            .padding(.top, DesignSystem.Spacing.block)
        }
        .background(DesignSystem.Colors.bgPage)
        .navigationTitle(String(localized: "event.smartGift.sheet.title"))
        .navigationBarTitleDisplayMode(.inline)
        .sheetCancelButton(action: dismiss.callAsFunction)
        .onAppear(perform: loadResult)
        .alert(String(localized: "common.error"), isPresented: $isShowingErrorAlert) {
            Button(String(localized: "common.ok"), role: .cancel) {}
        } message: {
            if let errorMessage { Text(errorMessage) }
        }
    }

    // MARK: - Contact Header

    private func contactHeaderCard(_ result: SmartReturnGiftResult) -> some View {
        HStack(spacing: 12) {
            AvatarView(
                imageData: result.contact.avatar,
                name: result.contact.name,
                size: 48
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(result.contact.name)
                    .font(DesignSystem.Typography.title3)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                HStack(spacing: 4) {
                    if !result.contact.relation.isEmpty {
                        Text(result.contact.relation)
                            .font(DesignSystem.Typography.small)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                        Image(systemName: "circle.fill")
                            .font(.system(size: 3))
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                    }
                    Text(result.event.name)
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    if let days = daysUntil(result.event.date), days >= 0 {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 3))
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                        Text(countdownText(days: days))
                            .font(DesignSystem.Typography.small)
                            .foregroundStyle(DesignSystem.Colors.primary)
                    }
                }
            }
            Spacer()
        }
        .padding(DesignSystem.Spacing.pageHorizontal)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
    }

    // MARK: - Section Header

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(DesignSystem.Typography.caption)
            .fontWeight(.semibold)
            .foregroundStyle(DesignSystem.Colors.textSecondary)
    }

    // MARK: - Timeline

    private func timelineSection(_ result: SmartReturnGiftResult) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.inlineTight) {
            sectionHeader(String(localized: "event.smartGift.timeline.title"))

            VStack(alignment: .leading, spacing: 0) {
                let all = result.historicalRecords
                let displayed = Array(all.suffix(5))
                let hiddenCount = all.count - displayed.count

                if hiddenCount > 0 {
                    Text(String(format: String(localized: "event.smartGift.timeline.more"), hiddenCount))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                        .padding(.bottom, DesignSystem.Spacing.inlineTight)
                }

                ForEach(Array(displayed.enumerated()), id: \.offset) { index, record in
                    timelineRow(record: record, isLast: index == displayed.count - 1)
                }

                Divider()
                    .foregroundStyle(DesignSystem.Colors.separator)
                    .padding(.top, DesignSystem.Spacing.stackTight)

                balanceSummaryRow(result)
            }
            .padding(DesignSystem.Spacing.pageHorizontal)
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        }
    }

    private func timelineRow(record: Record, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.contentRowSpacing) {
            // Dot + connector line
            VStack(spacing: 0) {
                Circle()
                    .fill(DesignSystem.Colors.accentGold)
                    .frame(width: DesignSystem.Layout.timelineDotSize, height: DesignSystem.Layout.timelineDotSize)
                    .padding(.top, DesignSystem.Spacing.stackTight)

                if !isLast {
                    Rectangle()
                        .fill(DesignSystem.Colors.separator)
                        .frame(width: DesignSystem.Layout.timelineConnectorWidth)
                        .frame(minHeight: DesignSystem.Layout.timelineConnectorMinHeight)
                }
            }
            .frame(width: DesignSystem.Layout.timelineDotSize)

            // Date + name + amount pill
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.dense) {
                Text(shortDate(record.date))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)

                Text(record.contextDisplayName)
                    .font(DesignSystem.Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                // Amount pill
                let prefix = record.direction == .received
                    ? String(localized: "event.smartGift.timeline.received")
                    : String(localized: "event.smartGift.timeline.given")
                Text("\(prefix) \(formatAmount(record.resolvedDisplayAmount))")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .padding(.horizontal, DesignSystem.Spacing.badgePaddingH)
                    .padding(.vertical, DesignSystem.Spacing.dense)
                    .background(DesignSystem.Colors.bgInput)
                    .clipShape(Capsule())
            }
            .padding(.bottom, isLast ? DesignSystem.Spacing.stackTight : DesignSystem.Spacing.pageHorizontal)

            Spacer()
        }
    }

    private func balanceSummaryRow(_ result: SmartReturnGiftResult) -> some View {
        VStack(alignment: .trailing, spacing: DesignSystem.Spacing.dense) {
            // Summary line: "TA 累计送你 ¥X | 你累计送TA ¥Y"
            HStack(spacing: 0) {
                Spacer()
                Text(String(format: String(localized: "event.smartGift.timeline.balance"),
                            formatNumber(result.receivedTotal),
                            formatNumber(result.givenTotal)))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.trailing)
            }

            // Outstanding balance
            if result.netReceivedBalance > 0 {
                Text(String(localized: "event.smartGift.timeline.outstanding"))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                Text(formatAmount(result.netReceivedBalance))
                    .font(DesignSystem.Typography.title1)
                    .foregroundStyle(DesignSystem.Colors.primary)
            }
        }
        .padding(.top, DesignSystem.Spacing.blockTight)
    }

    // MARK: - Reasoning

    private func reasoningSection(_ result: SmartReturnGiftResult) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.inlineTight) {
            sectionHeader(String(localized: "event.smartGift.reasoning.title"))

            ForEach(result.reasoningCards) { card in
                reasoningCard(
                    iconName: iconName(for: card.type),
                    title: title(for: card.type),
                    body: bodyText(for: card),
                    badge: badgeText(for: card)
                )
            }
        }
    }

    private func iconName(for type: SmartReturnGiftReasoningCard.CardType) -> String {
        switch type {
        case .historicalPositive: "clock.arrow.circlepath"
        case .historicalNonPositive: "clock.arrow.circlepath"
        case .noHistory: "tray"
        case .cpi: "chart.line.uptrend.xyaxis"
        case .eventSymmetry: "arrow.up.arrow.down.circle"
        case .relationship: "person.2.fill"
        }
    }

    private func title(for type: SmartReturnGiftReasoningCard.CardType) -> String {
        switch type {
        case .historicalPositive: String(localized: "event.smartGift.reason.historical.title")
        case .historicalNonPositive: String(localized: "event.smartGift.reason.historical.title")
        case .noHistory: String(localized: "event.smartGift.reason.noHistory.title")
        case .cpi: String(localized: "event.smartGift.reason.cpi.title")
        case .eventSymmetry: String(localized: "event.smartGift.reason.eventSymmetry.title")
        case .relationship: String(localized: "event.smartGift.reason.relationship.title")
        }
    }

    // MARK: - Reasoning Rendering Helpers

    private func bodyText(for card: SmartReturnGiftReasoningCard) -> String {
        switch card.params {
        case let .historicalPositive(received, given, net):
            return String(
                format: String(localized: "event.smartGift.reason.historical.body"),
                formatNumber(received), formatNumber(given), formatNumber(net)
            )
        case let .historicalNonPositive(received, given, eventTypeName, baseline):
            return String(
                format: String(localized: "event.smartGift.reason.historical.nonPositive"),
                formatNumber(received), formatNumber(given), eventTypeName, formatNumber(baseline)
            )
        case let .noHistory(eventTypeName, baseline):
            return String(
                format: String(localized: "event.smartGift.reason.noHistory.body"),
                eventTypeName, formatNumber(baseline)
            )
        case let .cpi(inflationFactor, pct, cpiBaseline):
            return String(
                format: String(localized: "event.smartGift.reason.cpi.body"),
                inflationYearsLabel(inflationFactor), pct, formatNumber(cpiBaseline)
            )
        case let .eventSymmetry(currentTier, refTier, pct, baseline, isUpgrade):
            let key = isUpgrade
                ? "event.smartGift.reason.eventSymmetry.upgrade"
                : "event.smartGift.reason.eventSymmetry.downgrade"
            return String(
                format: String(localized: String.LocalizationValue(key)),
                tierName(currentTier), tierName(refTier), pct, formatNumber(baseline)
            )
        case let .relationship(conservative, generous, _):
            return String(
                format: String(localized: "event.smartGift.reason.relationship.body"),
                formatNumber(conservative), formatNumber(generous)
            )
        }
    }

    private func badgeText(for card: SmartReturnGiftReasoningCard) -> String? {
        switch card.params {
        case let .eventSymmetry(_, _, _, _, isUpgrade):
            isUpgrade
                ? String(localized: "event.smartGift.reason.eventSymmetry.badge.upgrade")
                : String(localized: "event.smartGift.reason.eventSymmetry.badge.downgrade")
        case let .relationship(_, _, circle):
            circleBadge(circle)
        default:
            nil
        }
    }

    private func circleBadge(_ circle: Int) -> String {
        switch circle {
        case 1: String(localized: "event.smartGift.circle.family")
        case 2: String(localized: "event.smartGift.circle.relative")
        case 3: String(localized: "event.smartGift.circle.social")
        default: String(localized: "event.smartGift.circle.other")
        }
    }

    private func inflationYearsLabel(_ factor: Double) -> String {
        switch Int(round(factor * 100)) {
        case 105: String(localized: "event.smartGift.reason.cpi.years.1to2")
        case 110: String(localized: "event.smartGift.reason.cpi.years.3to4")
        case 115: String(localized: "event.smartGift.reason.cpi.years.5to7")
        default: String(localized: "event.smartGift.reason.cpi.years.8plus")
        }
    }

    private func tierName(_ tier: Int) -> String {
        switch tier {
        case 3: String(localized: "event.smartGift.tier.level.major")
        case 2: String(localized: "event.smartGift.tier.level.significant")
        default: String(localized: "event.smartGift.tier.level.casual")
        }
    }

    private func reasoningCard(iconName: String, title: String, body: String, badge: String?) -> some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.contentRowSpacing) {
            Image(systemName: iconName)
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.primary)
                .frame(width: DesignSystem.Layout.reasoningIconSize, height: DesignSystem.Layout.reasoningIconSize)
                .background(DesignSystem.Colors.bgIconSubtle)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.dense) {
                HStack(alignment: .center) {
                    Text(title)
                        .font(DesignSystem.Typography.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    Spacer()
                    if let badge {
                        Text(badge)
                            .font(DesignSystem.Typography.small)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                            .padding(.horizontal, DesignSystem.Spacing.badgePaddingH)
                            .padding(.vertical, DesignSystem.Spacing.insetTight)
                            .background(DesignSystem.Colors.bgCard)
                            .clipShape(Capsule())
                    }
                }

                Text(body)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(DesignSystem.Spacing.pageHorizontal)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
    }

    // MARK: - Tier Selector

    private func tierSelector(_ result: SmartReturnGiftResult) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.inlineTight) {
            HStack {
                sectionHeader(String(localized: "event.smartGift.tier.title"))
                Spacer()
                Text(tierName(selectedTier))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.primary)
                    .padding(.horizontal, DesignSystem.Spacing.block)
                    .padding(.vertical, DesignSystem.Spacing.insetSmall)
                    .background(DesignSystem.Colors.primary.opacity(0.1))
                    .clipShape(Capsule())
            }

            VStack(spacing: DesignSystem.Spacing.contentRowSpacing) {
                // Track + nodes
                ZStack {
                    Capsule()
                        .fill(DesignSystem.Colors.separator)
                        .frame(height: DesignSystem.Layout.tierTrackHeight)

                    HStack {
                        tierNode(.conservative, amount: result.conservativeAmount)
                        Spacer()
                        tierNode(.standard, amount: result.standardAmount)
                        Spacer()
                        tierNode(.generous, amount: result.generousAmount)
                    }
                }

                // Labels
                HStack(alignment: .top, spacing: 0) {
                    tierLabel(.conservative, amount: result.conservativeAmount, alignment: .leading)
                    tierLabel(.standard, amount: result.standardAmount, alignment: .center)
                    tierLabel(.generous, amount: result.generousAmount, alignment: .trailing, plusSuffix: true)
                }
            }
            .padding(DesignSystem.Spacing.pageHorizontal)
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        }
    }

    private func tierNode(_ tier: GiftTier, amount: Double) -> some View {
        let isSelected = selectedTier == tier
        return Button {
            selectedTier = tier
            amountText = formatRawAmount(amount)
        } label: {
            Circle()
                .fill(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.bgCard)
                .frame(
                    width: isSelected ? DesignSystem.Layout.tierNodeSizeSelected : DesignSystem.Layout.tierNodeSizeDefault,
                    height: isSelected ? DesignSystem.Layout.tierNodeSizeSelected : DesignSystem.Layout.tierNodeSizeDefault
                )
                .overlay(
                    Circle()
                        .stroke(isSelected ? .clear : DesignSystem.Colors.separator, lineWidth: DesignSystem.Layout.timelineConnectorWidth)
                )
                .shadow(
                    color: isSelected ? DesignSystem.Colors.primary.opacity(0.30) : .clear,
                    radius: 6, y: 2
                )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTier)
    }

    private func tierLabel(_ tier: GiftTier, amount: Double, alignment: HorizontalAlignment, plusSuffix: Bool = false) -> some View {
        let isSelected = selectedTier == tier
        let amountStr = plusSuffix ? "\(formatAmount(amount))+" : formatAmount(amount)
        let name = tierName(tier)

        return Button {
            selectedTier = tier
            amountText = formatRawAmount(amount)
        } label: {
            VStack(alignment: alignment, spacing: DesignSystem.Spacing.insetXS) {
                Text(isSelected ? "\(name) (\(amountStr))" : name)
                    .font(DesignSystem.Typography.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.textSecondary)

                if !isSelected {
                    Text("(\(amountStr))")
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: Alignment(horizontal: alignment, vertical: .top))
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTier)
    }

    private func tierName(_ tier: GiftTier) -> String {
        switch tier {
        case .conservative: String(localized: "event.smartGift.tier.conservative")
        case .standard: String(localized: "event.smartGift.tier.standard")
        case .generous: String(localized: "event.smartGift.tier.generous")
        }
    }

    // MARK: - Confirm Section

    private func confirmSection(_ result: SmartReturnGiftResult) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Text("¥")
                    .font(DesignSystem.Typography.title2)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                TextField(String(localized: "0"), text: $amountText)
                    .font(DesignSystem.Typography.title2)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .keyboardType(.decimalPad)
            }
            .padding(12)
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.input)
                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
            )

            PaymentMethodSelector(selectedMethod: $selectedPaymentMethod)

            Button {
                confirmGift(result)
            } label: {
                Text(confirmButtonTitle)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!isConfirmEnabled)
            .opacity(isConfirmEnabled ? 1.0 : 0.6)

            Text(String(localized: "event.smartGift.disclaimer"))
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
    }

    // MARK: - Logic

    private var isConfirmEnabled: Bool {
        guard let value = UserEnteredDecimal.parse(amountText) else { return false }
        return value > 0
    }

    private var confirmButtonTitle: String {
        if onSelectSuggestedAmount != nil {
            return String(localized: "event.smartGift.confirm.useAmount")
        }
        return String(localized: "event.smartGift.confirm")
    }

    private func loadResult() {
        guard
            let event = modelContext.model(for: eventID) as? Event,
            let contact = modelContext.model(for: contactID) as? Contact
        else { return }

        let allRecords = contact.records ?? []
        result = SmartReturnGiftEngine.calculate(
            contact: contact,
            event: event,
            allContactRecords: allRecords
        )

        if let r = result {
            amountText = formatRawAmount(r.standardAmount)
        }
    }

    @MainActor
    private func confirmGift(_ result: SmartReturnGiftResult) {
        guard let amount = UserEnteredDecimal.parse(amountText), amount > 0 else {
            errorMessage = String(localized: "record.returnGift.amountRequired")
            isShowingErrorAlert = true
            return
        }

        if let onSelectSuggestedAmount {
            onSelectSuggestedAmount(amount, selectedPaymentMethod)
            dismiss()
            return
        }

        let record = Record.makeMonetaryRecord(
            contact: result.contact,
            event: result.event,
            amount: amount,
            direction: .given,
            paymentMethod: selectedPaymentMethod,
            date: .now
        )
        modelContext.insert(record)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            isShowingErrorAlert = true
        }
    }

    // MARK: - Formatting Helpers

    private static let decimalFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f
    }()

    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_Hans")
        f.dateFormat = "yyyy年M月"
        return f
    }()

    /// 带 ¥ 前缀，用于直接展示（时间轴、余额行、档位标签等）
    private func formatAmount(_ value: Double) -> String {
        "¥\(formatNumber(value))"
    }

    /// 不含 ¥ 前缀，用于传入已含 ¥ 的本地化格式串（避免 ¥¥ 重复）
    private func formatNumber(_ value: Double) -> String {
        Self.decimalFormatter.string(from: NSNumber(value: value)) ?? String(format: "%.0f", value)
    }

    private func formatRawAmount(_ value: Double) -> String {
        String(format: "%.0f", value)
    }

    private func shortDate(_ date: Date) -> String {
        Self.monthFormatter.string(from: date)
    }

    private func daysUntil(_ date: Date) -> Int? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let eventDay = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: today, to: eventDay).day
    }

    private func countdownText(days: Int) -> String {
        if days == 0 { return String(localized: "home.today") }
        return String(format: String(localized: "event.detail.countdown"), days)
    }
}

// MARK: - Preview

private struct SmartReturnGiftPreviewWrapper: View {
    private let container: ModelContainer?
    private let eventID: PersistentIdentifier?
    private let contactID: PersistentIdentifier?

    init() {
        guard let c = try? ModelContainer(
            for: Contact.self, Event.self, Record.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        ) else {
            container = nil; eventID = nil; contactID = nil; return
        }

        let ctx = c.mainContext
        let cal = Calendar.current

        let contact = Contact(name: "张三", relation: "朋友", circle: 2)
        ctx.insert(contact)

        let wedding = Event(name: "我的婚礼", type: .wedding,
                            date: cal.liShuDateByAddingDays(-1200))
        ctx.insert(wedding)
        ctx.insert(Record.makeMonetaryRecord(
            contact: contact, event: wedding, amount: 1000, direction: .received,
            date: cal.liShuDateByAddingDays(-1200)
        ))

        let festivalEvent = Event(name: "春节", type: .festival,
                                  date: cal.liShuDateByAddingDays(-400))
        ctx.insert(festivalEvent)
        ctx.insert(Record.makeMonetaryRecord(
            contact: contact, event: festivalEvent, amount: 200, direction: .given,
            date: cal.liShuDateByAddingDays(-400)
        ))

        let property = Event(name: "你的乔迁", type: .property,
                             date: cal.liShuDateByAddingDays(-180))
        ctx.insert(property)
        ctx.insert(Record.makeMonetaryRecord(
            contact: contact, event: property, amount: 600, direction: .received,
            date: cal.liShuDateByAddingDays(-180)
        ))

        let upcoming = Event(
            name: "张三婚礼", type: .wedding,
            date: cal.liShuDateByAddingDays(15),
            primaryContact: contact
        )
        ctx.insert(upcoming)
        try? ctx.save()

        container = c
        eventID = upcoming.persistentModelID
        contactID = contact.persistentModelID
    }

    var body: some View {
        if let container, let eventID, let contactID {
            NavigationStack {
                SmartReturnGiftView(eventID: eventID, contactID: contactID)
            }
            .modelContainer(container)
        } else {
            Text(String(localized: "common.preview.unavailable"))
        }
    }
}

#Preview {
    SmartReturnGiftPreviewWrapper()
}
