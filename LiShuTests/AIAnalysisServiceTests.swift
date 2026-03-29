import Foundation
import Testing
@testable import LiShu

#if canImport(FoundationModels)
import FoundationModels

struct AIAnalysisServiceTests {

    // MARK: - Availability

    @Test func testIsAvailableReturnsWithoutCrash() {
        guard #available(iOS 26.0, *) else { return }
        _ = AIAnalysisService.shared.isAvailable
    }

    // MARK: - splitIntoBatches

    @Test func testSplitIntoBatchesSingleBatch() {
        guard #available(iOS 26.0, *) else { return }
        let service = AIAnalysisService.shared
        let lines: [(text: String, confidence: Float)] = [
            (text: "张三 500", confidence: 0.9),
            (text: "李四 300", confidence: 0.8),
        ]

        let batches = service.splitIntoBatches(lines, maxCharsPerBatch: 1500)
        #expect(batches.count == 1)
        #expect(batches[0].count == 2)
    }

    @Test func testSplitIntoBatchesMultipleBatches() {
        guard #available(iOS 26.0, *) else { return }
        let service = AIAnalysisService.shared
        let lines: [(text: String, confidence: Float)] = [
            (text: String(repeating: "张", count: 800), confidence: 0.9),
            (text: String(repeating: "李", count: 800), confidence: 0.8),
            (text: String(repeating: "王", count: 800), confidence: 0.7),
        ]

        let batches = service.splitIntoBatches(lines, maxCharsPerBatch: 1500)
        #expect(batches.count == 3)
        #expect(batches[0].count == 1)
        #expect(batches[1].count == 1)
        #expect(batches[2].count == 1)
    }

    @Test func testSplitIntoBatchesEmptyInput() {
        guard #available(iOS 26.0, *) else { return }
        let service = AIAnalysisService.shared
        let lines: [(text: String, confidence: Float)] = []
        let batches = service.splitIntoBatches(lines, maxCharsPerBatch: 1500)
        #expect(batches.isEmpty)
    }

    @Test func testSplitIntoBatchesSingleLineLargerThanMax() {
        guard #available(iOS 26.0, *) else { return }
        let service = AIAnalysisService.shared
        let lines: [(text: String, confidence: Float)] = [
            (text: String(repeating: "大", count: 2000), confidence: 0.9),
        ]

        let batches = service.splitIntoBatches(lines, maxCharsPerBatch: 1500)
        #expect(batches.count == 1)
        #expect(batches[0].count == 1)
    }

    @Test func testSplitIntoBatchesExactBoundary() {
        guard #available(iOS 26.0, *) else { return }
        let service = AIAnalysisService.shared
        let lines: [(text: String, confidence: Float)] = [
            (text: String(repeating: "字", count: 750), confidence: 0.9),
            (text: String(repeating: "字", count: 750), confidence: 0.8),
            (text: String(repeating: "字", count: 1), confidence: 0.7),
        ]

        let batches = service.splitIntoBatches(lines, maxCharsPerBatch: 1500)
        #expect(batches.count == 2)
        #expect(batches[0].count == 2)
        #expect(batches[1].count == 1)
    }

    // MARK: - buildPrompt

    @Test func testBuildPromptContainsOCRText() {
        guard #available(iOS 26.0, *) else { return }
        let service = AIAnalysisService.shared
        let lines: [(text: String, confidence: Float)] = [
            (text: "张三 500", confidence: 0.9),
            (text: "李四 300", confidence: 0.8),
        ]

        let prompt = service.buildPrompt(from: lines)
        #expect(prompt.contains("张三 500"))
        #expect(prompt.contains("李四 300"))
        #expect(prompt.contains("eventType"))
        #expect(prompt.contains("eventName"))
    }

    @Test func testBuildPromptContainsAllEventTypes() {
        guard #available(iOS 26.0, *) else { return }
        let service = AIAnalysisService.shared
        let lines: [(text: String, confidence: Float)] = [
            (text: "测试", confidence: 0.9),
        ]

        let prompt = service.buildPrompt(from: lines)
        let expectedTypes = ["wedding", "engagement", "funeral", "birth", "birthday",
                             "longevity", "festival", "property", "education",
                             "business", "promotion", "visit", "other"]
        for eventType in expectedTypes {
            #expect(prompt.contains(eventType))
        }
    }

    @Test func testBuildPromptContainsPerRecordEventInstruction() {
        guard #available(iOS 26.0, *) else { return }
        let service = AIAnalysisService.shared
        let lines: [(text: String, confidence: Float)] = [
            (text: "张三 500", confidence: 0.9),
        ]

        let prompt = service.buildPrompt(from: lines)
        #expect(prompt.contains("每条记录根据其文字内容或上下文独立判断事件类型和名称"))
    }

    // MARK: - convertToOCRRecordItems

    @Test func testConvertBasicRecords() {
        guard #available(iOS 26.0, *) else { return }
        let service = AIAnalysisService.shared
        let result = AIExtractionResult(records: [
            AIExtractedRecord(name: "张三", amount: 500, eventType: "wedding", eventName: "婚礼"),
            AIExtractedRecord(name: "李四", amount: 300, eventType: "birthday", eventName: "生日"),
        ])
        let sourceLines: [(text: String, confidence: Float)] = [
            (text: "张三 500", confidence: 0.9),
            (text: "李四 300", confidence: 0.85),
        ]

        let items = service.convertToOCRRecordItems(result, sourceLines: sourceLines)
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

    @Test func testConvertHighConfidence() {
        guard #available(iOS 26.0, *) else { return }
        let service = AIAnalysisService.shared
        let result = AIExtractionResult(records: [
            AIExtractedRecord(name: "张三", amount: 500, eventType: "wedding", eventName: "婚礼"),
        ])
        let sourceLines: [(text: String, confidence: Float)] = [
            (text: "张三 500", confidence: 0.9),
        ]

        let items = service.convertToOCRRecordItems(result, sourceLines: sourceLines)
        #expect(items.count == 1)
        #expect(items[0].confidence == .high)
        #expect(items[0].warningType == nil)
    }

    @Test func testConvertMediumConfidence() {
        guard #available(iOS 26.0, *) else { return }
        let service = AIAnalysisService.shared
        let result = AIExtractionResult(records: [
            AIExtractedRecord(name: "张三", amount: 500, eventType: "wedding", eventName: "婚礼"),
        ])
        let sourceLines: [(text: String, confidence: Float)] = [
            (text: "张三 500", confidence: 0.5),
        ]

        let items = service.convertToOCRRecordItems(result, sourceLines: sourceLines)
        #expect(items.count == 1)
        #expect(items[0].confidence == .medium)
        #expect(items[0].warningType == .needsVerification)
    }

    @Test func testConvertLowConfidence() {
        guard #available(iOS 26.0, *) else { return }
        let service = AIAnalysisService.shared
        let result = AIExtractionResult(records: [
            AIExtractedRecord(name: "张三", amount: 500, eventType: "wedding", eventName: "婚礼"),
        ])
        let sourceLines: [(text: String, confidence: Float)] = [
            (text: "张三 500", confidence: 0.2),
        ]

        let items = service.convertToOCRRecordItems(result, sourceLines: sourceLines)
        #expect(items.count == 1)
        #expect(items[0].confidence == .low)
        #expect(items[0].warningType == .needsVerification)
    }

    @Test func testConvertSuspiciousAmount() {
        guard #available(iOS 26.0, *) else { return }
        let service = AIAnalysisService.shared
        let result = AIExtractionResult(records: [
            AIExtractedRecord(name: "张三", amount: 5_000_000, eventType: "wedding", eventName: "婚礼"),
        ])
        let sourceLines: [(text: String, confidence: Float)] = [
            (text: "张三 5000000", confidence: 0.5),
        ]

        let items = service.convertToOCRRecordItems(result, sourceLines: sourceLines)
        #expect(items.count == 1)
        #expect(items[0].confidence == .medium)
        #expect(items[0].warningType == .suspiciousAmount)
    }

    @Test func testConvertFiltersInvalidRecords() {
        guard #available(iOS 26.0, *) else { return }
        let service = AIAnalysisService.shared
        let result = AIExtractionResult(records: [
            AIExtractedRecord(name: "", amount: 500, eventType: "other", eventName: "其他"),
            AIExtractedRecord(name: "张三", amount: 0, eventType: "other", eventName: "其他"),
            AIExtractedRecord(name: "张三", amount: -100, eventType: "other", eventName: "其他"),
            AIExtractedRecord(name: "  ", amount: 500, eventType: "other", eventName: "其他"),
            AIExtractedRecord(name: "李四", amount: 300, eventType: "birthday", eventName: "生日"),
        ])
        let sourceLines: [(text: String, confidence: Float)] = [
            (text: "测试", confidence: 0.9),
        ]

        let items = service.convertToOCRRecordItems(result, sourceLines: sourceLines)
        #expect(items.count == 1)
        #expect(items[0].name == "李四")
    }

    @Test func testConvertInvalidEventTypeFallbackToOther() {
        guard #available(iOS 26.0, *) else { return }
        let service = AIAnalysisService.shared
        let result = AIExtractionResult(records: [
            AIExtractedRecord(name: "张三", amount: 500, eventType: "invalid_type", eventName: "聚会"),
        ])
        let sourceLines: [(text: String, confidence: Float)] = [
            (text: "张三 500", confidence: 0.9),
        ]

        let items = service.convertToOCRRecordItems(result, sourceLines: sourceLines)
        #expect(items.count == 1)
        #expect(items[0].eventType == .other)
        #expect(items[0].eventName == "聚会")
    }

    @Test func testConvertEmptyEventNameUsesDisplayName() {
        guard #available(iOS 26.0, *) else { return }
        let service = AIAnalysisService.shared
        let result = AIExtractionResult(records: [
            AIExtractedRecord(name: "张三", amount: 500, eventType: "wedding", eventName: ""),
        ])
        let sourceLines: [(text: String, confidence: Float)] = [
            (text: "张三 500", confidence: 0.9),
        ]

        let items = service.convertToOCRRecordItems(result, sourceLines: sourceLines)
        #expect(items.count == 1)
        #expect(items[0].eventType == .wedding)
        #expect(items[0].eventName == EventType.wedding.displayName)
    }

    @Test func testConvertAllValidEventTypes() {
        guard #available(iOS 26.0, *) else { return }
        let service = AIAnalysisService.shared
        let types = ["wedding", "engagement", "funeral", "birth", "birthday",
                     "longevity", "festival", "property", "education",
                     "business", "promotion", "visit", "other"]
        let sourceLines: [(text: String, confidence: Float)] = [
            (text: "测试", confidence: 0.9),
        ]

        for (index, type) in types.enumerated() {
            let result = AIExtractionResult(records: [
                AIExtractedRecord(name: "测试\(index)", amount: Double((index + 1) * 100), eventType: type, eventName: "事件\(index)")
            ])
            let items = service.convertToOCRRecordItems(result, sourceLines: sourceLines)
            #expect(items.count == 1)
        }
    }

    @Test func testConvertEmptySourceLinesUsesDefaultConfidence() {
        guard #available(iOS 26.0, *) else { return }
        let service = AIAnalysisService.shared
        let result = AIExtractionResult(records: [
            AIExtractedRecord(name: "张三", amount: 500, eventType: "wedding", eventName: "婚礼"),
        ])
        let sourceLines: [(text: String, confidence: Float)] = []

        let items = service.convertToOCRRecordItems(result, sourceLines: sourceLines)
        #expect(items.count == 1)
        #expect(items[0].confidence == .high)
    }

    // MARK: - formatAmount

    @Test func testFormatAmountInteger() {
        guard #available(iOS 26.0, *) else { return }
        let service = AIAnalysisService.shared
        #expect(service.formatAmount(500) == "500")
        #expect(service.formatAmount(1200) == "1200")
        #expect(service.formatAmount(0) == "0")
    }

    @Test func testFormatAmountDecimal() {
        guard #available(iOS 26.0, *) else { return }
        let service = AIAnalysisService.shared
        #expect(service.formatAmount(500.50) == "500.50")
        #expect(service.formatAmount(100.01) == "100.01")
    }
}
#endif

// MARK: - Fallback path tests (all platforms)

struct AIAnalysisServiceFallbackTests {

    @Test func testRecognizeRecordsEnhancedFallbackProducesSameAsRegex() {
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

    @Test func testDeduplicationWorksInEnhancedPath() {
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
