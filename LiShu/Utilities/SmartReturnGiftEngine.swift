import Foundation

/// 建议依据卡片
struct SmartReturnGiftReasoningCard {
    enum CardType {
        /// 有历史往来记录（净余为正），以净余×通胀×对等系数为基准
        case historicalPositive
        /// 有历史往来记录但净余不足，展示记录情况
        case historicalNonPositive
        /// 无任何历史往来，以活动类型最低基准计算
        case noHistory
        /// 通胀系数调整（仅当 inflationFactor > 1.0 且净余为正时出现）
        case cpi
        /// 活动对等性调整（仅当等级不对等且净余为正时出现）
        case eventSymmetry
        /// 关系权重——始终出现，展示保守～慷慨区间
        case relationship
    }

    /// 结构化参数，由 View 层结合本地化格式串渲染为最终文案
    enum ReasoningParams {
        case historicalPositive(received: Double, given: Double, net: Double)
        case historicalNonPositive(received: Double, given: Double, eventTypeName: String, baseline: Double)
        case noHistory(eventTypeName: String, baseline: Double)
        /// inflationFactor 传原始系数，View 负责映射为年限文案
        case cpi(inflationFactor: Double, pct: Int, baseline: Double)
        /// tier 传整数，View 负责映射为等级名称
        case eventSymmetry(currentTier: Int, refTier: Int, pct: Int, baseline: Double, isUpgrade: Bool)
        /// circle 传整数，View 负责映射为关系圈层名称
        case relationship(conservative: Double, generous: Double, circle: Int)
    }

    let type: CardType
    let params: ReasoningParams
}

/// 智能回礼计算结果
struct SmartReturnGiftResult {
    let contact: Contact
    let event: Event
    /// 该联系人所有历史记录，按时间正序
    let historicalRecords: [Record]
    /// 对方累计给我 − 我累计给对方
    let receivedTotal: Double
    let givenTotal: Double
    let netReceivedBalance: Double
    let inflationFactor: Double
    let baselineAmount: Double
    let conservativeAmount: Double
    let standardAmount: Double
    let generousAmount: Double
    /// 建议依据卡片，按展示顺序排列
    let reasoningCards: [SmartReturnGiftReasoningCard]
}

enum SmartReturnGiftEngine {
    /// 计算智能回礼建议
    static func calculate(
        contact: Contact,
        event: Event,
        allContactRecords: [Record]
    ) -> SmartReturnGiftResult {
        let sorted = allContactRecords.sorted { $0.date < $1.date }

        let receivedRecords = sorted.filter { $0.direction == .received }
        let givenRecords = sorted.filter { $0.direction == .given }

        let receivedTotal = receivedRecords.reduce(0.0) { $0 + $1.resolvedDisplayAmount }
        let givenTotal = givenRecords.reduce(0.0) { $0 + $1.resolvedDisplayAmount }
        let netBalance = receivedTotal - givenTotal

        // 通胀系数
        let mostRecentReceived = receivedRecords.last
        let inflationFactor = inflationMultiplier(since: mostRecentReceived?.date)

        // 活动对等系数（仅在净余为正时有意义）
        let symInfo: SymmetryInfo? = netBalance > 0
            ? symmetryInfo(currentEvent: event, receivedRecords: receivedRecords)
            : nil
        let symmetryFactor = symInfo?.factor ?? 1.0

        // 基准金额 = 净余 × 通胀 × 对等系数（向下取整50）
        let floor = Double(eventTypeFloor(event.type))
        let baseline: Double = if netBalance <= 0 {
            floor
        } else {
            max(roundTo50(netBalance * inflationFactor * symmetryFactor), floor)
        }

        let conservative = max(roundTo50(baseline * 0.7), floor)
        let standard = baseline
        let generous = max(roundTo50(baseline * 1.25), floor)

        let reasoningCards = buildReasoningCards(
            contact: contact,
            event: event,
            receivedTotal: receivedTotal,
            givenTotal: givenTotal,
            netBalance: netBalance,
            inflationFactor: inflationFactor,
            symInfo: symInfo,
            baseline: baseline,
            conservative: conservative,
            generous: generous
        )

        return SmartReturnGiftResult(
            contact: contact,
            event: event,
            historicalRecords: sorted,
            receivedTotal: receivedTotal,
            givenTotal: givenTotal,
            netReceivedBalance: netBalance,
            inflationFactor: inflationFactor,
            baselineAmount: baseline,
            conservativeAmount: conservative,
            standardAmount: standard,
            generousAmount: generous,
            reasoningCards: reasoningCards
        )
    }

    // MARK: - Reasoning Cards

    private static func buildReasoningCards(
        contact: Contact,
        event: Event,
        receivedTotal: Double,
        givenTotal: Double,
        netBalance: Double,
        inflationFactor: Double,
        symInfo: SymmetryInfo?,
        baseline: Double,
        conservative: Double,
        generous: Double
    ) -> [SmartReturnGiftReasoningCard] {
        var cards: [SmartReturnGiftReasoningCard] = []
        let hasAnyHistory = receivedTotal > 0 || givenTotal > 0

        // ── 历史往来 / 无历史 ──────────────────────────────────────────
        if hasAnyHistory {
            if netBalance > 0 {
                cards.append(.init(
                    type: .historicalPositive,
                    params: .historicalPositive(received: receivedTotal, given: givenTotal, net: netBalance)
                ))
            } else {
                cards.append(.init(
                    type: .historicalNonPositive,
                    params: .historicalNonPositive(
                        received: receivedTotal,
                        given: givenTotal,
                        eventTypeName: event.type.displayName,
                        baseline: baseline
                    )
                ))
            }
        } else {
            cards.append(.init(
                type: .noHistory,
                params: .noHistory(eventTypeName: event.type.displayName, baseline: baseline)
            ))
        }

        // ── 通胀调整（净余为正 + 超过1年）────────────────────────────
        if netBalance > 0, inflationFactor > 1.0 {
            let pct = Int(round((inflationFactor - 1.0) * 100))
            cards.append(.init(
                type: .cpi,
                params: .cpi(inflationFactor: inflationFactor, pct: pct, baseline: baseline)
            ))
        }

        // ── 活动对等性（净余为正 + 等级不对等）──────────────────────
        if let sym = symInfo, sym.factor != 1.0 {
            let isUpgrade = sym.currentTier > sym.refTier
            let pct = Int(round(abs(sym.factor - 1.0) * 100))
            cards.append(.init(
                type: .eventSymmetry,
                params: .eventSymmetry(
                    currentTier: sym.currentTier,
                    refTier: sym.refTier,
                    pct: pct,
                    baseline: baseline,
                    isUpgrade: isUpgrade
                )
            ))
        }

        // ── 关系权重（始终出现）──────────────────────────────────────
        cards.append(.init(
            type: .relationship,
            params: .relationship(conservative: conservative, generous: generous, circle: contact.circle)
        ))

        return cards
    }

    // MARK: - Event Symmetry

    private struct SymmetryInfo {
        let factor: Double
        let currentTier: Int
        let refTier: Int
    }

    /// 计算活动对等系数：当前活动等级 vs 对方随礼时活动等级（金额加权平均）
    private static func symmetryInfo(
        currentEvent: Event,
        receivedRecords: [Record]
    ) -> SymmetryInfo? {
        let withEvents = receivedRecords.compactMap { record -> (tier: Int, amount: Double)? in
            guard let type = record.event?.type else { return nil }
            return (eventTier(type), record.resolvedDisplayAmount)
        }
        guard !withEvents.isEmpty else { return nil }

        let totalAmount = withEvents.reduce(0.0) { $0 + $1.amount }
        guard totalAmount > 0 else { return nil }

        // 金额加权平均活动等级
        let weightedTier = withEvents.reduce(0.0) { sum, item in
            sum + Double(item.tier) * (item.amount / totalAmount)
        }

        let currentTier = eventTier(currentEvent.type)
        let refTier = Int(weightedTier.rounded())
        let tierDiff = currentTier - refTier

        let factor = switch tierDiff {
        case 2...: 1.20 // 本次大幅升格
        case 1: 1.10 // 本次小幅升格
        case 0: 1.00 // 对等，无需调整
        case -1: 0.85 // 本次小幅降格
        default: 0.70 // 本次大幅降格
        }

        return SymmetryInfo(factor: factor, currentTier: currentTier, refTier: refTier)
    }

    /// 活动等级（1=日常场合，2=重要活动，3=大型仪式）
    static func eventTier(_ type: EventType) -> Int {
        switch type {
        case .wedding, .engagement, .longevity, .birth: 3
        case .birthday, .education, .property, .business, .promotion, .funeral: 2
        case .festival, .visit, .other: 1
        }
    }

    // MARK: - Helpers

    private static func inflationMultiplier(since date: Date?) -> Double {
        guard let date else { return 1.0 }
        let years = yearsBetween(date, and: Date())
        switch years {
        case 0: return 1.0
        case 1 ... 2: return 1.05
        case 3 ... 4: return 1.10
        case 5 ... 7: return 1.15
        default: return 1.20
        }
    }

    private static func yearsBetween(_ from: Date, and to: Date) -> Int {
        max(0, Calendar.current.dateComponents([.year], from: from, to: to).year ?? 0)
    }

    private static func roundTo50(_ value: Double) -> Double {
        Double(Int((value / 50).rounded()) * 50)
    }

    private static func eventTypeFloor(_ type: EventType) -> Int {
        switch type {
        case .wedding, .engagement: 600
        case .birth, .longevity: 500
        case .birthday, .education, .funeral: 300
        case .property, .business, .promotion: 400
        case .festival, .visit, .other: 200
        }
    }

    private static func formatAmount(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.0f", value)
    }
}
