import Foundation
@testable import LiShu
import Testing

#if canImport(FoundationModels)
    import FoundationModels

    struct AIAnalysisServiceTests {
        @Test func isAvailableReturnsWithoutCrash() {
            guard #available(iOS 26.0, *) else { return }
            _ = AIAnalysisService.shared.isAvailable
        }

        @Test func splitIntoBatchesSingleBatch() {
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

        @Test func splitIntoBatchesMultipleBatches() {
            guard #available(iOS 26.0, *) else { return }
            let service = AIAnalysisService.shared
            let lines: [(text: String, confidence: Float)] = [
                (text: String(repeating: "张", count: 800), confidence: 0.9),
                (text: String(repeating: "李", count: 800), confidence: 0.8),
                (text: String(repeating: "王", count: 800), confidence: 0.7),
            ]

            let batches = service.splitIntoBatches(lines, maxCharsPerBatch: 1500)
            #expect(batches.count == 3)
        }

        @Test func buildPromptContainsOnlyLedgerExtractionInstructions() {
            guard #available(iOS 26.0, *) else { return }
            let service = AIAnalysisService.shared
            let lines: [(text: String, confidence: Float)] = [
                (text: "张三 500", confidence: 0.9),
                (text: "李四 300", confidence: 0.8),
            ]

            let prompt = service.buildPrompt(from: lines)
            #expect(prompt.contains("张三 500"))
            #expect(prompt.contains("李四 300"))
            #expect(prompt.contains("只返回姓名和金额"))
            #expect(prompt.contains("不要推断事件类型"))
            #expect(prompt.contains("忽略标题、页码、合计、备注、席位号"))
            #expect(!prompt.contains("eventType"))
            #expect(!prompt.contains("eventName"))
        }

        @Test func convertBasicRecords() {
            guard #available(iOS 26.0, *) else { return }
            let service = AIAnalysisService.shared
            let result = AIExtractionResult(records: [
                AIExtractedRecord(name: "张三", amount: 500),
                AIExtractedRecord(name: "李四", amount: 300),
            ])
            let sourceLines: [(text: String, confidence: Float)] = [
                (text: "张三 500", confidence: 0.9),
                (text: "李四 300", confidence: 0.85),
            ]

            let items = service.convertToOCRRecordItems(result, sourceLines: sourceLines)
            #expect(items.count == 2)
            #expect(items[0].name == "张三")
            #expect(items[0].amount == 500)
            #expect(items[1].name == "李四")
            #expect(items[1].amount == 300)
        }

        @Test func convertHighConfidence() {
            guard #available(iOS 26.0, *) else { return }
            let service = AIAnalysisService.shared
            let result = AIExtractionResult(records: [
                AIExtractedRecord(name: "张三", amount: 500),
            ])
            let sourceLines: [(text: String, confidence: Float)] = [
                (text: "张三 500", confidence: 0.9),
            ]

            let items = service.convertToOCRRecordItems(result, sourceLines: sourceLines)
            #expect(items.count == 1)
            #expect(items[0].confidence == .high)
            #expect(items[0].warningType == nil)
        }

        @Test func convertMediumConfidence() {
            guard #available(iOS 26.0, *) else { return }
            let service = AIAnalysisService.shared
            let result = AIExtractionResult(records: [
                AIExtractedRecord(name: "张三", amount: 500),
            ])
            let sourceLines: [(text: String, confidence: Float)] = [
                (text: "张三 500", confidence: 0.5),
            ]

            let items = service.convertToOCRRecordItems(result, sourceLines: sourceLines)
            #expect(items.count == 1)
            #expect(items[0].confidence == .medium)
            #expect(items[0].warningType == .needsVerification)
        }

        @Test func convertLowConfidence() {
            guard #available(iOS 26.0, *) else { return }
            let service = AIAnalysisService.shared
            let result = AIExtractionResult(records: [
                AIExtractedRecord(name: "张三", amount: 500),
            ])
            let sourceLines: [(text: String, confidence: Float)] = [
                (text: "张三 500", confidence: 0.2),
            ]

            let items = service.convertToOCRRecordItems(result, sourceLines: sourceLines)
            #expect(items.count == 1)
            #expect(items[0].confidence == .low)
            #expect(items[0].warningType == .needsVerification)
        }

        @Test func convertSuspiciousAmount() {
            guard #available(iOS 26.0, *) else { return }
            let service = AIAnalysisService.shared
            let result = AIExtractionResult(records: [
                AIExtractedRecord(name: "张三", amount: 5_000_000),
            ])
            let sourceLines: [(text: String, confidence: Float)] = [
                (text: "张三 5000000", confidence: 0.5),
            ]

            let items = service.convertToOCRRecordItems(result, sourceLines: sourceLines)
            #expect(items.count == 1)
            #expect(items[0].confidence == .medium)
            #expect(items[0].warningType == .suspiciousAmount)
        }

        @Test func convertFiltersInvalidRecords() {
            guard #available(iOS 26.0, *) else { return }
            let service = AIAnalysisService.shared
            let result = AIExtractionResult(records: [
                AIExtractedRecord(name: "", amount: 500),
                AIExtractedRecord(name: "张三", amount: 0),
                AIExtractedRecord(name: "张三", amount: -100),
                AIExtractedRecord(name: "  ", amount: 500),
                AIExtractedRecord(name: "李四", amount: 300),
            ])
            let sourceLines: [(text: String, confidence: Float)] = [
                (text: "测试", confidence: 0.9),
            ]

            let items = service.convertToOCRRecordItems(result, sourceLines: sourceLines)
            #expect(items.count == 1)
            #expect(items[0].name == "李四")
        }

        @Test func convertEmptySourceLinesUsesDefaultConfidence() {
            guard #available(iOS 26.0, *) else { return }
            let service = AIAnalysisService.shared
            let result = AIExtractionResult(records: [
                AIExtractedRecord(name: "张三", amount: 500),
            ])

            let items = service.convertToOCRRecordItems(result, sourceLines: [])
            #expect(items.count == 1)
            #expect(items[0].confidence == .high)
        }

        @Test func formatAmountInteger() {
            guard #available(iOS 26.0, *) else { return }
            let service = AIAnalysisService.shared
            #expect(service.formatAmount(500) == "500")
            #expect(service.formatAmount(1200) == "1200")
        }

        @Test func formatAmountDecimal() {
            guard #available(iOS 26.0, *) else { return }
            let service = AIAnalysisService.shared
            #expect(service.formatAmount(500.50) == "500.50")
            #expect(service.formatAmount(100.01) == "100.01")
        }
    }
#endif

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
        #expect(regexItems[1].amount == 1200)
    }
}
