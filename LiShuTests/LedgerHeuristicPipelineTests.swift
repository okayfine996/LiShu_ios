import CoreGraphics
import Foundation
@testable import LiShu
import Testing

@Suite(.serialized)
struct LedgerHeuristicPipelineTests {
    private let pipeline = LedgerHeuristicPipeline.shared
    private let service = OCRService.shared

    private func makeLine(
        _ text: String,
        confidence: Float = 0.9,
        x: CGFloat = 0.1,
        y: CGFloat,
        width: CGFloat = 0.3,
        height: CGFloat = 0.04,
        pageIndex: Int = 0
    ) -> LedgerOCRLine {
        LedgerOCRLine(
            text: text,
            confidence: confidence,
            boundingBox: CGRect(x: x, y: y, width: width, height: height),
            pageIndex: pageIndex
        )
    }

    @Test func normalizeLinesTrimsWhitespaceAndNormalizesCurrency() {
        let lines = [
            makeLine("  张三 ￥５００  ", y: 0.9),
            makeLine(" ", y: 0.84),
        ]

        let normalized = pipeline.normalizeLines(lines)

        #expect(normalized.count == 1)
        #expect(normalized[0].text == "张三 ¥500")
    }

    @Test func filterNoiseLinesDropsLedgerNoiseWithoutDroppingRecords() {
        let lines = [
            makeLine("礼单", y: 0.95),
            makeLine("第2页", y: 0.9),
            makeLine("13800138000", y: 0.85),
            makeLine("张三 500", y: 0.8),
        ]

        let filtered = pipeline.filterNoiseLines(lines, service: service)

        #expect(filtered.lines.count == 1)
        #expect(filtered.lines[0].text == "张三 500")
        #expect(filtered.filteredNoiseCount == 3)
    }

    @Test func buildEntryCandidatesSupportsInlineAndReversedPatterns() {
        let lines = [
            makeLine("张三 500", y: 0.9),
            makeLine("800 李四", y: 0.82),
        ]

        let candidates = pipeline.buildEntryCandidates(lines, service: service)

        #expect(candidates.count == 2)
        #expect(candidates[0].nameText == "张三")
        #expect(candidates[0].normalizedAmount == 500)
        #expect(candidates[1].nameText == "李四")
        #expect(candidates[1].normalizedAmount == 800)
    }

    @Test func buildEntryCandidatesSupportsColumnAndStackedPatterns() {
        let lines = [
            makeLine("王五", y: 0.9, width: 0.15),
            makeLine("1200", x: 0.62, y: 0.9, width: 0.12),
            makeLine("赵六", y: 0.8),
            makeLine("500", y: 0.77),
        ]

        let candidates = pipeline.buildEntryCandidates(lines, service: service)
        let hasColumnCandidate = candidates.contains { candidate in
            candidate.nameText == "王五"
                && candidate.normalizedAmount == 1200
        }
        let hasStackedCandidate = candidates.contains { candidate in
            candidate.nameText == "赵六"
                && candidate.layoutPattern == .stackedPair
                && candidate.normalizedAmount == 500
        }

        #expect(candidates.count >= 2)
        #expect(hasColumnCandidate)
        #expect(hasStackedCandidate)
    }

    @Test func extractHeuristicItemsCarriesEventHints() {
        let candidates = [
            LedgerEntryCandidate(
                nameText: "张三",
                amountText: "500",
                normalizedAmount: 500,
                sourceLineIDs: [],
                layoutPattern: .inlineNameAmount,
                eventNameHint: EventType.wedding.displayName,
                averageConfidence: 0.92,
                fullText: "张三婚礼 500"
            ),
        ]

        let items = pipeline.extractHeuristicItems(candidates, service: service)

        #expect(items.count == 1)
        #expect(items[0].eventName == EventType.wedding.displayName)
        #expect(items[0].eventType == .wedding)
        #expect(items[0].sourceMode == .ledgerHeuristicFallback)
    }

    @Test func auditItemsFlagsSuspiciousAmountsAndNames() {
        let items = [
            OCRRecordItem(name: "张三", amount: 5_000_000, amountText: "5000000", confidence: .high),
            OCRRecordItem(name: "合计", amount: 500, amountText: "500", confidence: .high),
            OCRRecordItem(name: "李四", amount: 600, amountText: "600", confidence: .high),
            OCRRecordItem(name: "李四", amount: 600, amountText: "600", confidence: .high),
        ]

        let audited = pipeline.auditItems(items, service: service)

        #expect(audited[0].warningType == .suspiciousAmount)
        #expect(audited[1].warningType == .needsVerification)
        #expect(audited[3].warningType == .needsVerification)
    }

    @Test func processProducesHeuristicFallbackCandidatesWithoutVision() {
        let lines = [
            makeLine("礼簿", y: 0.96),
            makeLine("张三 5O0", y: 0.88),
            makeLine("李四", y: 0.8),
            makeLine("800", y: 0.77),
        ]

        let result = pipeline.process(lines: lines, service: service)
        let items = pipeline.extractHeuristicItems(result.candidates, service: service)

        #expect(result.filteredNoiseCount >= 1)
        #expect(items.count >= 2)
        #expect(items.contains(where: { $0.name == "张三" && $0.amount == 500 }))
        #expect(items.contains(where: { $0.name == "李四" && $0.amount == 800 }))
    }

    @Test func analyzeLayoutRecognizesVerticalLedger() {
        let lines = [
            makeLine("王", x: 0.1, y: 0.82, width: 0.04, height: 0.08),
            makeLine("昭", x: 0.1, y: 0.72, width: 0.04, height: 0.08),
            makeLine("君", x: 0.1, y: 0.62, width: 0.04, height: 0.08),
            makeLine("礼", x: 0.1, y: 0.48, width: 0.04, height: 0.06),
            makeLine("陆", x: 0.1, y: 0.28, width: 0.04, height: 0.08),
            makeLine("佰", x: 0.1, y: 0.18, width: 0.04, height: 0.08),
            makeLine("600", x: 0.1, y: 0.05, width: 0.08, height: 0.03),
            makeLine("李", x: 0.2, y: 0.82, width: 0.04, height: 0.08),
            makeLine("白", x: 0.2, y: 0.72, width: 0.04, height: 0.08),
            makeLine("礼", x: 0.2, y: 0.48, width: 0.04, height: 0.06),
            makeLine("贰", x: 0.2, y: 0.28, width: 0.04, height: 0.08),
            makeLine("仟", x: 0.2, y: 0.18, width: 0.04, height: 0.08),
            makeLine("2000", x: 0.2, y: 0.05, width: 0.1, height: 0.03),
        ]

        let analysis = pipeline.analyzeLayout(lines: lines)

        #expect(analysis.kind == .verticalLedger)
    }

    @Test func analyzeLayoutRecognizesHorizontalLedger() {
        let lines = [
            makeLine("张三", x: 0.1, y: 0.84, width: 0.12, height: 0.04),
            makeLine("500", x: 0.62, y: 0.84, width: 0.1, height: 0.04),
            makeLine("李四", x: 0.1, y: 0.74, width: 0.12, height: 0.04),
            makeLine("800", x: 0.62, y: 0.74, width: 0.1, height: 0.04),
        ]

        let analysis = pipeline.analyzeLayout(lines: lines)

        #expect(analysis.kind == .horizontalLedger)
    }

    @Test func buildEntryCandidatesParsesVerticalLedgerColumns() {
        let lines = [
            makeLine("王", x: 0.1, y: 0.82, width: 0.04, height: 0.08),
            makeLine("昭", x: 0.1, y: 0.72, width: 0.04, height: 0.08),
            makeLine("君", x: 0.1, y: 0.62, width: 0.04, height: 0.08),
            makeLine("礼", x: 0.1, y: 0.48, width: 0.04, height: 0.06),
            makeLine("陆", x: 0.1, y: 0.28, width: 0.04, height: 0.08),
            makeLine("佰", x: 0.1, y: 0.18, width: 0.04, height: 0.08),
            makeLine("600", x: 0.1, y: 0.05, width: 0.08, height: 0.03),
        ]

        let candidates = pipeline.buildEntryCandidates(lines, layoutKind: .verticalLedger, service: service)

        #expect(candidates.count == 1)
        #expect(candidates[0].nameText == "王昭君")
        #expect(candidates[0].normalizedAmount == 600)
        #expect(candidates[0].layoutKind == .verticalLedger)
    }

    @Test func extractHeuristicItemsDowngradesUnknownLayoutCandidates() {
        let candidates = [
            LedgerEntryCandidate(
                nameText: "张三",
                amountText: "500",
                normalizedAmount: 500,
                sourceLineIDs: [],
                layoutPattern: .inlineNameAmount,
                averageConfidence: 0.95,
                fullText: "张三 500",
                layoutKind: .unknownLedger
            ),
        ]

        let items = pipeline.extractHeuristicItems(candidates, service: service)

        #expect(items.count == 1)
        #expect(items[0].confidence != .high)
        #expect(items[0].warningType == .needsVerification)
    }
}
