import CoreGraphics
import Foundation

enum LedgerCandidateLayoutPattern: String, Codable {
    case inlineNameAmount
    case inlineAmountName
    case alignedColumns
    case stackedPair
    case unknown
}

enum LedgerHeuristicFlag: String, Codable, Hashable {
    case normalizedAmount
    case suspiciousName
    case suspiciousAmount
    case duplicateCandidate
    case filteredNoise
    case mergedAdjacentLines
}

struct LedgerEntryCandidate: Identifiable, Hashable {
    let id: UUID
    var nameText: String
    var amountText: String
    var normalizedAmount: Double?
    var sourceLineIDs: [UUID]
    var layoutPattern: LedgerCandidateLayoutPattern
    var warningFlags: Set<LedgerHeuristicFlag>
    var eventNameHint: String?
    var averageConfidence: Float
    var fullText: String

    init(
        id: UUID = UUID(),
        nameText: String,
        amountText: String,
        normalizedAmount: Double?,
        sourceLineIDs: [UUID],
        layoutPattern: LedgerCandidateLayoutPattern,
        warningFlags: Set<LedgerHeuristicFlag> = [],
        eventNameHint: String? = nil,
        averageConfidence: Float = 0,
        fullText: String
    ) {
        self.id = id
        self.nameText = nameText
        self.amountText = amountText
        self.normalizedAmount = normalizedAmount
        self.sourceLineIDs = sourceLineIDs
        self.layoutPattern = layoutPattern
        self.warningFlags = warningFlags
        self.eventNameHint = eventNameHint
        self.averageConfidence = averageConfidence
        self.fullText = fullText
    }
}

struct LedgerPageContext {
    var titleLines: [String]
    var ignoredLines: [String]
    var eventHint: String?
}

struct LedgerHeuristicProcessResult {
    var candidates: [LedgerEntryCandidate]
    var pageContexts: [Int: LedgerPageContext]
    var filteredNoiseCount: Int
}

final class LedgerHeuristicPipeline {
    static let shared = LedgerHeuristicPipeline()

    private init() {}

    private let nameAmountPattern = #"([\u4e00-\u9fff]{2,6})\s*[¥￥]?\s*([0-9OoIlBSs８０１５，,\.]+)"#
    private let amountNamePattern = #"[¥￥]?\s*([0-9OoIlBSs８０１５，,\.]+)\s+([\u4e00-\u9fff]{2,6})"#
    private let pureNamePattern = #"^[\u4e00-\u9fff]{2,6}$"#
    private let pureAmountPattern = #"^[¥￥]?\s*[0-9OoIlBSs８０１５，,\.]+$"#
    private let phonePattern = #"1[3-9]\d{9}"#
    private let pagePattern = #"^第?\s*\d+\s*页$"#
    private let datePattern = #"\d{4}[年/\-\.]\d{1,2}[月/\-\.]\d{1,2}"#
    private let addressTokens = ["路", "街", "号", "栋", "室", "村", "镇", "区"]
    private let noiseTokens = ["礼单", "礼簿", "来宾", "名单", "合计", "共计", "页码", "本页", "上页结转", "下页结转"]

    func process(lines: [LedgerOCRLine], service: OCRService) -> LedgerHeuristicProcessResult {
        let normalized = normalizeLines(lines)
        let filtered = filterNoiseLines(normalized, service: service)
        let candidates = buildEntryCandidates(filtered.lines, service: service)
        return LedgerHeuristicProcessResult(
            candidates: candidates,
            pageContexts: filtered.pageContexts,
            filteredNoiseCount: filtered.filteredNoiseCount
        )
    }

    func normalizeLines(_ lines: [LedgerOCRLine]) -> [LedgerOCRLine] {
        lines.compactMap { line in
            let trimmed = line.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            let normalizedText = normalizeGeneralText(trimmed)
            guard !normalizedText.isEmpty else { return nil }
            return LedgerOCRLine(
                id: line.id,
                text: normalizedText,
                confidence: line.confidence,
                boundingBox: line.boundingBox,
                pageIndex: line.pageIndex
            )
        }
    }

    func filterNoiseLines(
        _ lines: [LedgerOCRLine],
        service: OCRService
    ) -> (lines: [LedgerOCRLine], pageContexts: [Int: LedgerPageContext], filteredNoiseCount: Int) {
        var filtered: [LedgerOCRLine] = []
        var pageContexts: [Int: LedgerPageContext] = [:]
        var filteredNoiseCount = 0

        for line in lines {
            var context = pageContexts[line.pageIndex, default: LedgerPageContext(titleLines: [], ignoredLines: [], eventHint: nil)]

            if shouldIgnore(line.text) {
                filteredNoiseCount += 1
                context.ignoredLines.append(line.text)
                if likelyTitle(line.text) {
                    context.titleLines.append(line.text)
                    if context.eventHint == nil {
                        let eventName = service.matchEventName(from: line.text)
                        if eventName != String(localized: "event.type.other") {
                            context.eventHint = eventName
                        }
                    }
                }
                pageContexts[line.pageIndex] = context
                continue
            }

            if likelyTitle(line.text) {
                context.titleLines.append(line.text)
                if context.eventHint == nil {
                    let eventName = service.matchEventName(from: line.text)
                    if eventName != String(localized: "event.type.other") {
                        context.eventHint = eventName
                    }
                }
                pageContexts[line.pageIndex] = context
            }

            filtered.append(line)
        }

        return (filtered, pageContexts, filteredNoiseCount)
    }

    func buildEntryCandidates(_ lines: [LedgerOCRLine], service: OCRService) -> [LedgerEntryCandidate] {
        let rows = buildRows(from: lines)
        var candidates: [LedgerEntryCandidate] = []
        var usedLineIDs = Set<UUID>()

        for row in rows {
            let availableSegments = row.filter { !usedLineIDs.contains($0.id) }
            guard !availableSegments.isEmpty else { continue }

            if let candidate = candidateFromRow(availableSegments, service: service) {
                candidates.append(candidate)
                usedLineIDs.formUnion(candidate.sourceLineIDs)
                continue
            }
        }

        for index in rows.indices {
            let current = rows[index]
            guard current.allSatisfy({ !usedLineIDs.contains($0.id) }) else { continue }
            let currentName = extractPureName(from: joinedText(for: current))
            let currentAmount = normalizeAmountValue(from: joinedText(for: current))

            if currentName != nil, currentAmount == nil, index + 1 < rows.count {
                let next = rows[index + 1]
                guard samePage(current, next),
                      next.allSatisfy({ !usedLineIDs.contains($0.id) }),
                      rowGap(current, next) <= 0.04
                else { continue }

                let nextAmountText = extractAmountText(from: joinedText(for: next))
                if let name = currentName,
                   !nextAmountText.isEmpty,
                   let amount = normalizeAmountValue(from: nextAmountText)
                {
                    let merged = current + next
                    let averageConfidence = merged.map(\.confidence).reduce(0, +) / Float(merged.count)
                    candidates.append(
                        LedgerEntryCandidate(
                            nameText: name,
                            amountText: nextAmountText,
                            normalizedAmount: amount,
                            sourceLineIDs: merged.map(\.id),
                            layoutPattern: .stackedPair,
                            warningFlags: [.mergedAdjacentLines],
                            eventNameHint: service.matchEventName(from: joinedText(for: merged)),
                            averageConfidence: averageConfidence,
                            fullText: joinedText(for: merged)
                        )
                    )
                    usedLineIDs.formUnion(merged.map(\.id))
                }
            }
        }

        return deduplicateCandidates(candidates)
    }

    func extractHeuristicItems(_ candidates: [LedgerEntryCandidate], service: OCRService) -> [OCRRecordItem] {
        candidates.compactMap { candidate in
            guard let amount = candidate.normalizedAmount else { return nil }
            let eventType = service.matchEventType(from: candidate.fullText)
            let eventName = candidate.eventNameHint ?? service.matchEventName(from: candidate.fullText)
            let confidence: OCRConfidence
            var warningType: WarningType?

            if candidate.averageConfidence >= 0.78, service.isReasonableAmount(amount), candidate.warningFlags.isEmpty {
                confidence = .high
            } else if candidate.averageConfidence >= 0.5 {
                confidence = .medium
                warningType = candidate.warningFlags.contains(.suspiciousAmount) ? .suspiciousAmount : .needsVerification
            } else {
                confidence = .low
                warningType = .needsVerification
            }

            return OCRRecordItem(
                name: candidate.nameText,
                amount: amount,
                amountText: candidate.amountText,
                confidence: confidence,
                warningType: warningType,
                eventType: eventType,
                eventName: eventName,
                sourceMode: .ledgerHeuristicFallback,
                sourceLineIDs: candidate.sourceLineIDs
            )
        }
    }

    func auditItems(_ items: [OCRRecordItem], service: OCRService) -> [OCRRecordItem] {
        var seen = Set<String>()
        return items.map { original in
            var item = original
            let trimmedName = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
            let key = "\(trimmedName)_\(Int(item.amount.rounded()))"
            let hasBlacklistedToken = noiseTokens.contains { trimmedName.contains($0) }
            let nameLooksValid = isLikelyChineseName(trimmedName)
            let amountValid = service.isReasonableAmount(item.amount)
            let duplicate = seen.contains(key)

            if !duplicate {
                seen.insert(key)
            }

            if duplicate || hasBlacklistedToken || !nameLooksValid {
                item.confidence = .low
                item.warningType = .needsVerification
            } else if !amountValid {
                item.confidence = item.confidence == .high ? .medium : .low
                item.warningType = .suspiciousAmount
            } else if item.confidence != .high {
                item.warningType = item.warningType ?? .needsVerification
            }

            return item
        }
    }

    func summarizeCandidate(_ candidate: LedgerEntryCandidate, index: Int) -> String {
        let amount = candidate.amountText.isEmpty ? "未识别" : candidate.amountText
        let hint = candidate.eventNameHint ?? String(localized: "event.type.other")
        return """
        [\(index)] 原文: \(candidate.fullText)
        [\(index)] 姓名候选: \(candidate.nameText.isEmpty ? "未识别" : candidate.nameText)
        [\(index)] 金额候选: \(amount)
        [\(index)] 事件提示: \(hint)
        """
    }

    private func normalizeGeneralText(_ text: String) -> String {
        let fullWidthDigits = ["０": "0", "１": "1", "２": "2", "３": "3", "４": "4", "５": "5", "６": "6", "７": "7", "８": "8", "９": "9"]
        var normalized = text
        fullWidthDigits.forEach { normalized = normalized.replacingOccurrences(of: $0.key, with: $0.value) }
        normalized = normalized.replacingOccurrences(of: "，", with: ",")
        normalized = normalized.replacingOccurrences(of: "：", with: ":")
        normalized = normalized.replacingOccurrences(of: "￥", with: "¥")
        return normalized
    }

    private func shouldIgnore(_ text: String) -> Bool {
        if noiseTokens.contains(where: { text.contains($0) }) { return true }
        if text.range(of: pagePattern, options: .regularExpression) != nil { return true }
        if text.range(of: phonePattern, options: .regularExpression) != nil { return true }
        if text.range(of: datePattern, options: .regularExpression) != nil, text.count <= 16 { return true }
        if addressTokens.contains(where: { text.contains($0) }), text.count >= 8 { return true }
        if text.allSatisfy({ $0.isNumber || $0 == " " || $0 == "-" }), text.count >= 8 { return true }
        return false
    }

    private func likelyTitle(_ text: String) -> Bool {
        text.count <= 12 && !extractAmountText(from: text).isEmpty
            ? false
            : noiseTokens.contains(where: { text.contains($0) })
            || text.contains("宴")
            || text.contains("婚")
            || text.contains("寿")
            || text.contains("丧")
    }

    private func buildRows(from lines: [LedgerOCRLine]) -> [[LedgerOCRLine]] {
        let sorted = lines.sorted {
            if $0.pageIndex != $1.pageIndex { return $0.pageIndex < $1.pageIndex }
            let lhsY = $0.boundingBox.midY
            let rhsY = $1.boundingBox.midY
            if abs(lhsY - rhsY) > 0.015 { return lhsY > rhsY }
            return $0.boundingBox.minX < $1.boundingBox.minX
        }

        var rows: [[LedgerOCRLine]] = []
        for line in sorted {
            if var last = rows.last, sameRow(last, line) {
                last.append(line)
                last.sort { $0.boundingBox.minX < $1.boundingBox.minX }
                rows[rows.count - 1] = last
            } else {
                rows.append([line])
            }
        }
        return rows
    }

    private func sameRow(_ row: [LedgerOCRLine], _ line: LedgerOCRLine) -> Bool {
        guard let reference = row.first else { return false }
        guard reference.pageIndex == line.pageIndex else { return false }
        return abs(reference.boundingBox.midY - line.boundingBox.midY) <= 0.018
    }

    private func candidateFromRow(_ row: [LedgerOCRLine], service: OCRService) -> LedgerEntryCandidate? {
        let combinedText = joinedText(for: row)
        let averageConfidence = row.map(\.confidence).reduce(0, +) / Float(row.count)
        let sourceIDs = row.map(\.id)

        if let inline = parseInlineRecord(
            from: combinedText,
            sourceLineIDs: sourceIDs,
            averageConfidence: averageConfidence,
            service: service
        ) {
            return inline
        }

        if row.count >= 2 {
            let leftText = row.first?.text ?? ""
            let rightText = row.last?.text ?? ""
            let amountText = extractAmountText(from: rightText.isEmpty ? combinedText : rightText)
            if let name = extractPureName(from: leftText) ?? extractPureName(from: combinedText),
               !amountText.isEmpty,
               let amount = normalizeAmountValue(from: amountText)
            {
                return LedgerEntryCandidate(
                    nameText: name,
                    amountText: amountText,
                    normalizedAmount: amount,
                    sourceLineIDs: sourceIDs,
                    layoutPattern: .alignedColumns,
                    eventNameHint: service.matchEventName(from: combinedText),
                    averageConfidence: averageConfidence,
                    fullText: combinedText
                )
            }
        }

        return nil
    }

    private func parseInlineRecord(
        from text: String,
        sourceLineIDs: [UUID],
        averageConfidence: Float,
        service: OCRService
    ) -> LedgerEntryCandidate? {
        let nsText = text as NSString
        let fullRange = NSRange(location: 0, length: nsText.length)
        let nameAmountRegex = try? NSRegularExpression(pattern: nameAmountPattern)
        let amountNameRegex = try? NSRegularExpression(pattern: amountNamePattern)

        if let match = nameAmountRegex?.firstMatch(in: text, range: fullRange), match.numberOfRanges >= 3 {
            let name = nsText.substring(with: match.range(at: 1))
            let amountText = nsText.substring(with: match.range(at: 2))
            guard let amount = normalizeAmountValue(from: amountText) else { return nil }
            return LedgerEntryCandidate(
                nameText: name,
                amountText: amountText,
                normalizedAmount: amount,
                sourceLineIDs: sourceLineIDs,
                layoutPattern: .inlineNameAmount,
                warningFlags: flagsForAmount(amountText, amount),
                eventNameHint: service.matchEventName(from: text),
                averageConfidence: averageConfidence,
                fullText: text
            )
        }

        if let match = amountNameRegex?.firstMatch(in: text, range: fullRange), match.numberOfRanges >= 3 {
            let amountText = nsText.substring(with: match.range(at: 1))
            let name = nsText.substring(with: match.range(at: 2))
            guard let amount = normalizeAmountValue(from: amountText) else { return nil }
            return LedgerEntryCandidate(
                nameText: name,
                amountText: amountText,
                normalizedAmount: amount,
                sourceLineIDs: sourceLineIDs,
                layoutPattern: .inlineAmountName,
                warningFlags: flagsForAmount(amountText, amount),
                eventNameHint: service.matchEventName(from: text),
                averageConfidence: averageConfidence,
                fullText: text
            )
        }

        return nil
    }

    private func flagsForAmount(_ amountText: String, _ amount: Double) -> Set<LedgerHeuristicFlag> {
        var flags: Set<LedgerHeuristicFlag> = []
        let normalized = normalizeAmountText(amountText)
        if normalized != amountText { flags.insert(.normalizedAmount) }
        if amount <= 0 || amount > 1_000_000 { flags.insert(.suspiciousAmount) }
        return flags
    }

    private func extractPureName(from text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.range(of: pureNamePattern, options: .regularExpression) != nil else { return nil }
        return trimmed
    }

    private func extractAmountText(from text: String) -> String {
        let components = text.split(separator: " ").map(String.init)
        if let candidate = components.last(where: { $0.range(of: pureAmountPattern, options: .regularExpression) != nil }) {
            return candidate
        }
        if text.range(of: pureAmountPattern, options: .regularExpression) != nil {
            return text
        }
        return ""
    }

    private func normalizeAmountText(_ raw: String) -> String {
        raw
            .replacingOccurrences(of: "O", with: "0")
            .replacingOccurrences(of: "o", with: "0")
            .replacingOccurrences(of: "I", with: "1")
            .replacingOccurrences(of: "l", with: "1")
            .replacingOccurrences(of: "B", with: "8")
            .replacingOccurrences(of: "S", with: "5")
            .replacingOccurrences(of: "s", with: "5")
            .replacingOccurrences(of: "¥", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func normalizeAmountValue(from raw: String) -> Double? {
        let cleaned = normalizeAmountText(raw)
        guard !cleaned.isEmpty else { return nil }
        return Double(cleaned)
    }

    private func joinedText(for row: [LedgerOCRLine]) -> String {
        row.sorted { $0.boundingBox.minX < $1.boundingBox.minX }
            .map(\.text)
            .joined(separator: " ")
    }

    private func samePage(_ lhs: [LedgerOCRLine], _ rhs: [LedgerOCRLine]) -> Bool {
        lhs.first?.pageIndex == rhs.first?.pageIndex
    }

    private func rowGap(_ lhs: [LedgerOCRLine], _ rhs: [LedgerOCRLine]) -> CGFloat {
        guard let lhsReference = lhs.first, let rhsReference = rhs.first else { return .greatestFiniteMagnitude }
        return abs(lhsReference.boundingBox.midY - rhsReference.boundingBox.midY)
    }

    private func deduplicateCandidates(_ candidates: [LedgerEntryCandidate]) -> [LedgerEntryCandidate] {
        var seen = Set<String>()
        return candidates.filter { candidate in
            let amountKey = candidate.normalizedAmount.map { String(Int($0.rounded())) } ?? candidate.amountText
            let key = "\(candidate.nameText)_\(amountKey)"
            if seen.contains(key) { return false }
            seen.insert(key)
            return true
        }
    }

    private func isLikelyChineseName(_ text: String) -> Bool {
        text.range(of: pureNamePattern, options: .regularExpression) != nil
    }
}
