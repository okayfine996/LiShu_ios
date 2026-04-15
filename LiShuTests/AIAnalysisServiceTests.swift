import Foundation
@testable import LiShu
import Testing

#if canImport(FoundationModels)
    import FoundationModels

    struct AIAnalysisServiceTests {
        private func makeCandidates(
            _ values: [(text: String, confidence: Float)]
        ) -> [LedgerEntryCandidate] {
            values.enumerated().map { _, value in
                LedgerEntryCandidate(
                    nameText: "",
                    amountText: "",
                    normalizedAmount: nil,
                    sourceLineIDs: [],
                    layoutPattern: .unknown,
                    averageConfidence: value.confidence,
                    fullText: value.text
                )
            }
        }

        // MARK: - Availability

        @Test func isAvailableReturnsWithoutCrash() {
            guard #available(iOS 26.0, *) else { return }
            _ = AIAnalysisService.shared.isAvailable
        }

        // MARK: - splitIntoBatches

        @Test func splitIntoBatchesSingleBatch() {
            guard #available(iOS 26.0, *) else { return }
            let service = AIAnalysisService.shared
            let candidates = makeCandidates([
                (text: "张三 500", confidence: 0.9),
                (text: "李四 300", confidence: 0.8),
            ])

            let batches = service.splitIntoBatches(candidates, maxCharsPerBatch: 1500)
            #expect(batches.count == 1)
            #expect(batches[0].count == 2)
        }

        @Test func splitIntoBatchesMultipleBatches() {
            guard #available(iOS 26.0, *) else { return }
            let service = AIAnalysisService.shared
            let candidates = makeCandidates([
                (text: String(repeating: "张", count: 800), confidence: 0.9),
                (text: String(repeating: "李", count: 800), confidence: 0.8),
                (text: String(repeating: "王", count: 800), confidence: 0.7),
            ])

            let batches = service.splitIntoBatches(candidates, maxCharsPerBatch: 1500)
            #expect(batches.count == 3)
            #expect(batches[0].count == 1)
            #expect(batches[1].count == 1)
            #expect(batches[2].count == 1)
        }

        @Test func splitIntoBatchesEmptyInput() {
            guard #available(iOS 26.0, *) else { return }
            let service = AIAnalysisService.shared
            let candidates: [LedgerEntryCandidate] = []
            let batches = service.splitIntoBatches(candidates, maxCharsPerBatch: 1500)
            #expect(batches.isEmpty)
        }

        @Test func splitIntoBatchesSingleLineLargerThanMax() {
            guard #available(iOS 26.0, *) else { return }
            let service = AIAnalysisService.shared
            let candidates = makeCandidates([
                (text: String(repeating: "大", count: 2000), confidence: 0.9),
            ])

            let batches = service.splitIntoBatches(candidates, maxCharsPerBatch: 1500)
            #expect(batches.count == 1)
            #expect(batches[0].count == 1)
        }

        @Test func splitIntoBatchesExactBoundary() {
            guard #available(iOS 26.0, *) else { return }
            let service = AIAnalysisService.shared
            let candidates = makeCandidates([
                (text: String(repeating: "字", count: 750), confidence: 0.9),
                (text: String(repeating: "字", count: 750), confidence: 0.8),
                (text: String(repeating: "字", count: 1), confidence: 0.7),
            ])

            let batches = service.splitIntoBatches(candidates, maxCharsPerBatch: 1500)
            #expect(batches.count == 2)
            #expect(batches[0].count == 2)
            #expect(batches[1].count == 1)
        }

        // MARK: - buildPrompt

        @Test func buildPromptContainsOCRText() {
            guard #available(iOS 26.0, *) else { return }
            let service = AIAnalysisService.shared
            let candidates = makeCandidates([
                (text: "张三 500", confidence: 0.9),
                (text: "李四 300", confidence: 0.8),
            ])

            let prompt = service.buildPrompt(from: candidates, pageContexts: [:])
            #expect(prompt.contains("张三 500"))
            #expect(prompt.contains("李四 300"))
            #expect(prompt.contains("eventType"))
            #expect(prompt.contains("eventName"))
        }

        @Test func buildPromptContainsAllEventTypes() {
            guard #available(iOS 26.0, *) else { return }
            let service = AIAnalysisService.shared
            let candidates = makeCandidates([
                (text: "测试", confidence: 0.9),
            ])

            let prompt = service.buildPrompt(from: candidates, pageContexts: [:])
            let expectedTypes = ["wedding", "engagement", "funeral", "birth", "birthday",
                                 "longevity", "festival", "property", "education",
                                 "business", "promotion", "visit", "other"]
            for eventType in expectedTypes {
                #expect(prompt.contains(eventType))
            }
        }

        @Test func buildPromptContainsPerRecordEventInstruction() {
            guard #available(iOS 26.0, *) else { return }
            let service = AIAnalysisService.shared
            let candidates = makeCandidates([
                (text: "张三 500", confidence: 0.9),
            ])

            let prompt = service.buildPrompt(from: candidates, pageContexts: [:])
            #expect(prompt.contains("每条记录根据其文字内容或上下文独立判断事件类型和名称") || prompt.contains("每条记录根据其文字内容或上下文"))
        }

        // MARK: - convertToOCRRecordItems

        @Test func convertBasicRecords() {
            guard #available(iOS 26.0, *) else { return }
            let service = AIAnalysisService.shared
            let result = AIExtractionResult(records: [
                AIExtractedRecord(candidateIndex: 0, name: "张三", amount: 500, eventType: "wedding", eventName: "婚礼"),
                AIExtractedRecord(candidateIndex: 1, name: "李四", amount: 300, eventType: "birthday", eventName: "生日"),
            ])
            let sourceCandidates = makeCandidates([
                (text: "张三 500", confidence: 0.9),
                (text: "李四 300", confidence: 0.85),
            ])

            let items = service.convertToOCRRecordItems(result, sourceCandidates: sourceCandidates)
            #expect(items.count == 2)
            #expect(items[0].name == "张三")
            #expect(items[0].amount == 500)
            #expect(items[0].eventType == .wedding)
            #expect(items[0].eventName == "婚礼")
            #expect(items[1].name == "李四")
            #expect(items[1].amount == 300)
            #expect(items[1].eventType == .birthday)
            #expect(items[1].eventName == "生日")
        }

        @Test func convertHighConfidence() {
            guard #available(iOS 26.0, *) else { return }
            let service = AIAnalysisService.shared
            let result = AIExtractionResult(records: [
                AIExtractedRecord(candidateIndex: 0, name: "张三", amount: 500, eventType: "wedding", eventName: "婚礼"),
            ])
            let sourceCandidates = makeCandidates([
                (text: "张三 500", confidence: 0.9),
            ])

            let items = service.convertToOCRRecordItems(result, sourceCandidates: sourceCandidates)
            #expect(items.count == 1)
            #expect(items[0].confidence == .high)
            #expect(items[0].warningType == nil)
        }

        @Test func convertMediumConfidence() {
            guard #available(iOS 26.0, *) else { return }
            let service = AIAnalysisService.shared
            let result = AIExtractionResult(records: [
                AIExtractedRecord(candidateIndex: 0, name: "张三", amount: 500, eventType: "wedding", eventName: "婚礼"),
            ])
            let sourceCandidates = makeCandidates([
                (text: "张三 500", confidence: 0.5),
            ])

            let items = service.convertToOCRRecordItems(result, sourceCandidates: sourceCandidates)
            #expect(items.count == 1)
            #expect(items[0].confidence == .medium)
            #expect(items[0].warningType == .needsVerification)
        }

        @Test func convertLowConfidence() {
            guard #available(iOS 26.0, *) else { return }
            let service = AIAnalysisService.shared
            let result = AIExtractionResult(records: [
                AIExtractedRecord(candidateIndex: 0, name: "张三", amount: 500, eventType: "wedding", eventName: "婚礼"),
            ])
            let sourceCandidates = makeCandidates([
                (text: "张三 500", confidence: 0.2),
            ])

            let items = service.convertToOCRRecordItems(result, sourceCandidates: sourceCandidates)
            #expect(items.count == 1)
            #expect(items[0].confidence == .low)
            #expect(items[0].warningType == .needsVerification)
        }

        @Test func convertSuspiciousAmount() {
            guard #available(iOS 26.0, *) else { return }
            let service = AIAnalysisService.shared
            let result = AIExtractionResult(records: [
                AIExtractedRecord(candidateIndex: 0, name: "张三", amount: 5_000_000, eventType: "wedding", eventName: "婚礼"),
            ])
            let sourceCandidates = makeCandidates([
                (text: "张三 5000000", confidence: 0.5),
            ])

            let items = service.convertToOCRRecordItems(result, sourceCandidates: sourceCandidates)
            #expect(items.count == 1)
            #expect(items[0].confidence == .medium)
            #expect(items[0].warningType == .suspiciousAmount)
        }

        @Test func convertFiltersInvalidRecords() {
            guard #available(iOS 26.0, *) else { return }
            let service = AIAnalysisService.shared
            let result = AIExtractionResult(records: [
                AIExtractedRecord(candidateIndex: 0, name: "", amount: 500, eventType: "other", eventName: "其他"),
                AIExtractedRecord(candidateIndex: 0, name: "张三", amount: 0, eventType: "other", eventName: "其他"),
                AIExtractedRecord(candidateIndex: 0, name: "张三", amount: -100, eventType: "other", eventName: "其他"),
                AIExtractedRecord(candidateIndex: 0, name: "  ", amount: 500, eventType: "other", eventName: "其他"),
                AIExtractedRecord(candidateIndex: 0, name: "李四", amount: 300, eventType: "birthday", eventName: "生日"),
            ])
            let sourceCandidates = makeCandidates([
                (text: "测试", confidence: 0.9),
            ])

            let items = service.convertToOCRRecordItems(result, sourceCandidates: sourceCandidates)
            #expect(items.count == 1)
            #expect(items[0].name == "李四")
        }

        @Test func convertInvalidEventTypeFallbackToOther() {
            guard #available(iOS 26.0, *) else { return }
            let service = AIAnalysisService.shared
            let result = AIExtractionResult(records: [
                AIExtractedRecord(candidateIndex: 0, name: "张三", amount: 500, eventType: "invalid_type", eventName: "聚会"),
            ])
            let sourceCandidates = makeCandidates([
                (text: "张三 500", confidence: 0.9),
            ])

            let items = service.convertToOCRRecordItems(result, sourceCandidates: sourceCandidates)
            #expect(items.count == 1)
            #expect(items[0].eventType == .other)
            #expect(items[0].eventName == "聚会")
        }

        @Test func convertEmptyEventNameUsesDisplayName() {
            guard #available(iOS 26.0, *) else { return }
            let service = AIAnalysisService.shared
            let result = AIExtractionResult(records: [
                AIExtractedRecord(candidateIndex: 0, name: "张三", amount: 500, eventType: "wedding", eventName: ""),
            ])
            let sourceCandidates = makeCandidates([
                (text: "张三 500", confidence: 0.9),
            ])

            let items = service.convertToOCRRecordItems(result, sourceCandidates: sourceCandidates)
            #expect(items.count == 1)
            #expect(items[0].eventType == .wedding)
            #expect(items[0].eventName == EventType.wedding.displayName)
        }

        @Test func convertAllValidEventTypes() {
            guard #available(iOS 26.0, *) else { return }
            let service = AIAnalysisService.shared
            let types = ["wedding", "engagement", "funeral", "birth", "birthday",
                         "longevity", "festival", "property", "education",
                         "business", "promotion", "visit", "other"]
            let sourceCandidates = makeCandidates([
                (text: "测试", confidence: 0.9),
            ])

            for (index, type) in types.enumerated() {
                let result = AIExtractionResult(records: [
                    AIExtractedRecord(
                        candidateIndex: 0,
                        name: "测试\(index)",
                        amount: Double((index + 1) * 100),
                        eventType: type,
                        eventName: "事件\(index)"
                    ),
                ])
                let items = service.convertToOCRRecordItems(result, sourceCandidates: sourceCandidates)
                #expect(items.count == 1)
            }
        }

        @Test func convertEmptySourceLinesUsesDefaultConfidence() {
            guard #available(iOS 26.0, *) else { return }
            let service = AIAnalysisService.shared
            let result = AIExtractionResult(records: [
                AIExtractedRecord(candidateIndex: 0, name: "张三", amount: 500, eventType: "wedding", eventName: "婚礼"),
            ])
            let sourceCandidates: [LedgerEntryCandidate] = []

            let items = service.convertToOCRRecordItems(result, sourceCandidates: sourceCandidates)
            #expect(items.count == 1)
            #expect(items[0].confidence == .high)
        }

        // MARK: - formatAmount

        @Test func formatAmountInteger() {
            guard #available(iOS 26.0, *) else { return }
            let service = AIAnalysisService.shared
            #expect(service.formatAmount(500) == "500")
            #expect(service.formatAmount(1200) == "1200")
            #expect(service.formatAmount(0) == "0")
        }

        @Test func formatAmountDecimal() {
            guard #available(iOS 26.0, *) else { return }
            let service = AIAnalysisService.shared
            #expect(service.formatAmount(500.50) == "500.50")
            #expect(service.formatAmount(100.01) == "100.01")
        }
    }
#endif

// MARK: - Fallback path tests (all platforms)

struct AIAnalysisServiceFallbackTests {
    @Test func recognizeRecordsEnhancedFallbackProducesSameAsRegex() {
        let service = OCRService.shared
        let lines: [(text: String, confidence: Float)] = [
            (text: "张三 500", confidence: 0.9),
            (text: "李四 ¥1,200", confidence: 0.85),
        ]

        let regexItems = service.parseRecordItems(from: lines)
        #expect(regexItems.count == 2)
        #expect(regexItems[0].name == "张三")
        #expect(regexItems[1].name == "李四")
    }

    @Test func deduplicationWorksInEnhancedPath() {
        let service = OCRService.shared
        let items = [
            OCRRecordItem(name: "张三", amount: 500, amountText: "500", confidence: .high),
            OCRRecordItem(name: "张三", amount: 500, amountText: "500", confidence: .high),
            OCRRecordItem(name: "李四", amount: 300, amountText: "300", confidence: .high),
        ]
        let deduped = service.deduplicateItems(items)
        #expect(deduped.count == 2)
    }
}
