import Foundation

// MARK: - Output Types

/// 建议依据卡片
///
/// Engine 每次计算后产出若干张卡片，按固定顺序排列：
/// 1. 历史往来（必有，根据净余正负选 `historicalPositive` 或 `historicalNonPositive`；无记录时为 `noHistory`）
/// 2. 通胀调整（可选，仅当净余 > 0 且距最近收礼超过 1 年）
/// 3. 活动对等性（可选，仅当净余 > 0 且本次活动等级与历史加权均值不同）
/// 4. 关系权重（必有，始终是最后一张）
///
/// `params` 携带结构化参数，由 View 层结合本地化格式串渲染为最终文案。
struct SmartReturnGiftReasoningCard: Identifiable {
    let id = UUID()

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
        /// - received: 对方历史累计随礼总额
        /// - given: 我方历史累计随礼总额
        /// - net: 净余（received − given）
        case historicalPositive(received: Double, given: Double, net: Double)

        /// - received: 对方历史累计随礼总额
        /// - given: 我方历史累计随礼总额
        /// - eventTypeName: 本次活动类型显示名，用于说明按哪种类型取最低基准
        /// - baseline: 最终使用的基准金额（等于该活动类型最低基准）
        case historicalNonPositive(received: Double, given: Double, eventTypeName: String, baseline: Double)

        /// - eventTypeName: 本次活动类型显示名
        /// - baseline: 最终使用的基准金额（等于该活动类型最低基准）
        case noHistory(eventTypeName: String, baseline: Double)

        /// - inflationFactor: 原始通胀系数（1.05 / 1.10 / 1.15 / 1.20），View 负责映射为年限文案
        /// - pct: 通胀百分比整数，如 10 表示上调 10%
        /// - cpiBaseline: 仅含通胀调整的阶段性基准（不含对等系数），用于展示推导链
        case cpi(inflationFactor: Double, pct: Int, cpiBaseline: Double)

        /// - currentTier: 本次活动等级（1/2/3），View 负责映射为等级名称
        /// - refTier: 历史加权平均活动等级（已取整），View 负责映射为等级名称
        /// - pct: 调整百分比整数（上调或下调），如 10 表示 ±10%
        /// - baseline: 含通胀与对等性双重调整后的最终基准金额
        /// - isUpgrade: true = 本次规格高于历史均值（上调），false = 低于（下调）
        case eventSymmetry(currentTier: Int, refTier: Int, pct: Int, baseline: Double, isUpgrade: Bool)

        /// - conservative: 保守档金额（baseline × 0.7，向下取整 50）
        /// - generous: 慷慨档金额（baseline × 1.25，向下取整 50）
        /// - circle: 联系人亲密圈层整数（1=家人 2=亲属 3=社交 4=其他），View 负责映射为名称
        case relationship(conservative: Double, generous: Double, circle: Int)
    }

    let type: CardType
    let params: ReasoningParams
}

// MARK: - Result

/// 智能回礼计算结果
///
/// 由 `SmartReturnGiftEngine.calculate(contact:event:allContactRecords:)` 返回，
/// 包含所有中间量和最终建议金额，供 View 直接展示。
struct SmartReturnGiftResult {
    // ── 输入回传 ──────────────────────────────────────────────────────────
    let contact: Contact
    let event: Event
    /// 该联系人所有历史记录，按时间正序（含双向、含全部类型，用于时间轴展示）
    let historicalRecords: [Record]

    /// ── 中间量（可用于 debug 或扩展展示）────────────────────────────────
    /// 对方累计给我的金额（仅 `.monetary` 方向 `.received` 之和）
    let receivedTotal: Double
    /// 我累计给对方的金额（仅 `.monetary` 方向 `.given` 之和）
    let givenTotal: Double
    /// 净余 = receivedTotal − givenTotal（正值表示对方给得多，是本次回礼的参考基础）
    let netReceivedBalance: Double
    /// 通胀系数，基于最近一笔收礼距今年数（1.0 / 1.05 / 1.10 / 1.15 / 1.20）
    let inflationFactor: Double

    /// ── 最终建议金额（均已向下取整 50，且不低于活动类型最低基准）──────────
    /// 基准金额：净余 > 0 时 = max(⌊netBalance × inflation × symmetry / 50⌋ × 50, floor)
    ///          净余 ≤ 0 时 = 活动类型最低基准
    let baselineAmount: Double
    /// 保守档 = max(⌊baseline × 0.70 / 50⌋ × 50, 50)，保证 < standardAmount（除非 baseline = 50）
    let conservativeAmount: Double
    /// 标准档 = baseline
    let standardAmount: Double
    /// 慷慨档 = ⌈baseline × 1.25 / 50⌉ × 50，向上取整保证 > standardAmount
    let generousAmount: Double

    /// ── 建议依据 ───────────────────────────────────────────────────────────
    /// 建议依据卡片，按展示顺序排列（1~4 张，详见 SmartReturnGiftReasoningCard）
    let reasoningCards: [SmartReturnGiftReasoningCard]
}

// MARK: - Engine

/// 智能回礼本地计算引擎
///
/// ## 输入
/// - `contact`: 联系人，提供亲密圈层（`circle`）
/// - `event`: 本次活动，提供活动类型（`type`）用于取最低基准和计算对等系数
/// - `allContactRecords`: 该联系人名下所有历史往来记录（含双向、含所有活动）
///
/// ## 计算流程
/// ```
/// 1. 分拣方向（仅统计 recordType == .monetary）
///    receivedTotal = Σ received 记录的 resolvedDisplayAmount
///    givenTotal    = Σ given    记录的 resolvedDisplayAmount
///    netBalance    = receivedTotal − givenTotal
///
/// 2. 通胀系数（基于最近一笔 received 记录距今年数）
///    0年   → ×1.00
///    1-2年 → ×1.05
///    3-4年 → ×1.10
///    5-7年 → ×1.15
///    8年+  → ×1.20
///
/// 3. 活动对等系数（仅 netBalance > 0 时计算，否则系数为 1.0）
///    对方每笔 received 记录若关联事件，取该事件的活动等级（1/2/3）
///    以金额加权平均得到参考等级 refTier（取整）
///    本次活动等级 currentTier vs refTier：
///    差值 ≥+2 → ×1.20  差值 +1 → ×1.10  差值 0 → ×1.00
///    差值 -1  → ×0.85  差值 ≤-2 → ×0.70
///
/// 4. 基准金额（两步推导，保证推导卡片叙事一致）
///    若 netBalance ≤ 0：
///      cpiBaseline = baseline = 活动类型最低基准
///    否则：
///      cpiBaseline = max(⌊netBalance × inflation / 50⌋ × 50, floor)   ← CPI 卡片展示此值
///      baseline    = max(⌊cpiBaseline × symmetry / 50⌋ × 50, floor)   ← 对等性卡片展示此值
///
/// 5. 三档金额
///    conservative = max(⌊baseline × 0.70 / 50⌋ × 50, 50)  — 绝对最低 50，不受 floor 下限
///    standard     = baseline
///    generous     = ⌈baseline × 1.25 / 50⌉ × 50           — 向上取整，保证 generous > standard
///
/// 6. 活动类型最低基准（eventTypeFloor × adjustCircle，二维表）
///    先用 adjustCircle 修正有效圈层（圈层 3 中职场关系降为 4），再查表
///    活动类型         家人(1)  亲属(2)  朋友/同学(3)  同事/其他(4)
///    婚礼/订婚         2000    1000      600          300
///    出生/寿宴         1000     600      300          200
///    生日/升学/丧礼     500     300      200          100
///    乔迁/开业/晋升     500     300      200          100
///    节日/拜访/其他     200     100      100           50
/// ```
///
/// ## 输出
/// 返回 `SmartReturnGiftResult`，包含所有中间量、三档建议金额和建议依据卡片列表。
enum SmartReturnGiftEngine {
    static func calculate(
        contact: Contact,
        event: Event,
        allContactRecords: [Record]
    ) -> SmartReturnGiftResult {
        let sorted = allContactRecords.sorted { $0.date < $1.date }

        // 仅统计金额类型记录，排除礼品/拜访等非金额往来
        let receivedRecords = sorted.filter { $0.direction == .received && $0.recordType == .monetary }
        let givenRecords = sorted.filter { $0.direction == .given && $0.recordType == .monetary }

        let receivedTotal = receivedRecords.reduce(0.0) { $0 + $1.resolvedDisplayAmount }
        let givenTotal = givenRecords.reduce(0.0) { $0 + $1.resolvedDisplayAmount }
        let netBalance = receivedTotal - givenTotal

        // 通胀系数
        let inflationFactor = inflationMultiplier(since: receivedRecords.last?.date)

        // 活动对等系数（仅在净余为正时有意义）
        let symInfo: SymmetryInfo? = netBalance > 0
            ? symmetryInfo(currentEvent: event, receivedRecords: receivedRecords)
            : nil
        let symmetryFactor = symInfo?.factor ?? 1.0

        let effectiveCircle = adjustCircle(contact.circle, relation: contact.relation)
        let floor = Double(eventTypeFloor(event.type, circle: effectiveCircle))

        // 两步推导，保证 CPI 卡片和对等性卡片各自展示正确的阶段性基准
        let cpiBaseline: Double
        let baseline: Double
        if netBalance <= 0 {
            cpiBaseline = floor
            baseline = floor
        } else {
            cpiBaseline = max(roundTo50(netBalance * inflationFactor), floor)
            baseline = max(roundTo50(cpiBaseline * symmetryFactor), floor)
        }

        let conservative = max(roundTo50(baseline * 0.7), 50)
        let standard = baseline
        let generous = roundTo50Up(baseline * 1.25)

        let reasoningCards = buildReasoningCards(
            contact: contact,
            event: event,
            receivedTotal: receivedTotal,
            givenTotal: givenTotal,
            netBalance: netBalance,
            inflationFactor: inflationFactor,
            symInfo: symInfo,
            cpiBaseline: cpiBaseline,
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
        cpiBaseline: Double,
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

        // ── 通胀调整（净余为正 + 超过1年）──── 展示阶段性 cpiBaseline ──
        if netBalance > 0, inflationFactor > 1.0 {
            let pct = Int(round((inflationFactor - 1.0) * 100))
            cards.append(.init(
                type: .cpi,
                params: .cpi(inflationFactor: inflationFactor, pct: pct, cpiBaseline: cpiBaseline)
            ))
        }

        // ── 活动对等性（净余为正 + 等级不对等）── 展示最终 baseline ───
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

        let weightedTier = withEvents.reduce(0.0) { sum, item in
            sum + Double(item.tier) * (item.amount / totalAmount)
        }

        let currentTier = eventTier(currentEvent.type)
        let refTier = Int(weightedTier.rounded())
        let tierDiff = currentTier - refTier

        let factor = switch tierDiff {
        case 2...: 1.20
        case 1: 1.10
        case 0: 1.00
        case -1: 0.85
        default: 0.70
        }

        return SymmetryInfo(factor: factor, currentTier: currentTier, refTier: refTier)
    }

    /// 活动等级（1=日常场合，2=重要活动，3=大型仪式）
    private static func eventTier(_ type: EventType) -> Int {
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
        case 1...2: return 1.05
        case 3...4: return 1.10
        case 5...7: return 1.15
        default: return 1.20
        }
    }

    private static func yearsBetween(_ from: Date, and to: Date) -> Int {
        max(0, Calendar.current.dateComponents([.year], from: from, to: to).year ?? 0)
    }

    /// 向下取整到最近的 50
    private static func roundTo50(_ value: Double) -> Double {
        Double(Int((value / 50).rounded(.down)) * 50)
    }

    /// 向上取整到最近的 50（用于慷慨档，保证 ≥ 输入值）
    private static func roundTo50Up(_ value: Double) -> Double {
        Double(Int(ceil(value / 50)) * 50)
    }

    /// 根据具体关系文本修正有效圈层，用于 floor 计算
    /// 圈层 3（社交）中的职场关系降为圈层 4，使用更保守的基准
    private static func adjustCircle(_ circle: Int, relation: String) -> Int {
        guard circle == 3 else { return circle }
        let workKeywords = ["同事", "上级", "下属", "领导", "老板", "客户", "甲方", "生意伙伴", "合作伙伴", "同僚"]
        return workKeywords.contains(where: { relation.contains($0) }) ? 4 : 3
    }

    /// 活动类型最低基准（二维表：活动类型 × 有效圈层）
    ///
    /// | 活动类型         | 家人(1) | 亲属(2) | 朋友/同学(3) | 同事/其他(4) |
    /// |----------------|--------|--------|------------|------------|
    /// | 婚礼/订婚        | 2000   | 1000   | 600        | 300        |
    /// | 出生/寿宴        | 1000   | 600    | 300        | 200        |
    /// | 生日/升学/丧礼   | 500    | 300    | 200        | 100        |
    /// | 乔迁/开业/晋升   | 500    | 300    | 200        | 100        |
    /// | 节日/拜访/其他   | 200    | 100    | 100        | 50         |
    ///
    /// 有效圈层由 `adjustCircle` 修正，圈层 3 中职场关系降为圈层 4。
    private static func eventTypeFloor(_ type: EventType, circle: Int) -> Int {
        switch (type, circle) {
        case (.wedding, 1), (.engagement, 1): 2000
        case (.wedding, 2), (.engagement, 2): 1000
        case (.wedding, 3), (.engagement, 3): 600
        case (.wedding, _), (.engagement, _): 300
        case (.birth, 1), (.longevity, 1): 1000
        case (.birth, 2), (.longevity, 2): 600
        case (.birth, 3), (.longevity, 3): 300
        case (.birth, _), (.longevity, _): 200
        case (.birthday, 1), (.education, 1), (.funeral, 1): 500
        case (.birthday, 2), (.education, 2), (.funeral, 2): 300
        case (.birthday, 3), (.education, 3), (.funeral, 3): 200
        case (.birthday, _), (.education, _), (.funeral, _): 100
        case (.property, 1), (.business, 1), (.promotion, 1): 500
        case (.property, 2), (.business, 2), (.promotion, 2): 300
        case (.property, 3), (.business, 3), (.promotion, 3): 200
        case (.property, _), (.business, _), (.promotion, _): 100
        case (.festival, 1), (.visit, 1), (.other, 1): 200
        case (.festival, 2), (.visit, 2), (.other, 2): 100
        default: 50
        }
    }
}
