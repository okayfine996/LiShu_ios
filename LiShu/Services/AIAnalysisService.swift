import Foundation
import Logging

private let aiAnalysisLogger = PulseDiagnostics.makeLogger(label: AppLogLabel.ai)

#if canImport(FoundationModels)
    import FoundationModels

    @available(iOS 26.0, *)
    @Generable
    struct AIExtractedRecord {
        @Guide(description: "人名，2-6个汉字")
        var name: String

        @Guide(description: "金额，单位元，正数")
        var amount: Double

        @Guide(description: "事件类型", .anyOf([
            "wedding", "engagement", "funeral", "birth", "birthday",
            "longevity", "festival", "property", "education",
            "business", "promotion", "visit", "other",
        ]))
        var eventType: String

        @Guide(description: "事件名称，如'婚礼'、'满月酒'、'寿宴'，无法判断时使用'其他'")
        var eventName: String
    }

    @available(iOS 26.0, *)
    @Generable
    struct AIExtractionResult {
        @Guide(description: "从文本中提取的礼金记录列表")
        var records: [AIExtractedRecord]
    }

    @available(iOS 26.0, *)
    final class AIAnalysisService {
        static let shared = AIAnalysisService()
        private init() {}

        // MARK: - Availability

        var isAvailable: Bool {
            SystemLanguageModel.default.isAvailable
        }

        // MARK: - Public API

        func analyzeOCRText(_ lines: [(text: String, confidence: Float)]) async throws -> [OCRRecordItem] {
            aiAnalysisLogger.notice("Starting AI OCR analysis", metadata: [
                "step": .string("analyze_ocr_text"),
                "count": .stringConvertible(lines.count),
            ])
            let batches = splitIntoBatches(lines, maxCharsPerBatch: 1500)
            var allItems: [OCRRecordItem] = []

            for batch in batches {
                let prompt = buildPrompt(from: batch)
                let session = LanguageModelSession()
                let response = try await session.respond(to: prompt, generating: AIExtractionResult.self)
                let items = convertToOCRRecordItems(response.content, sourceLines: batch)
                allItems.append(contentsOf: items)
                aiAnalysisLogger.info("Finished AI OCR batch", metadata: [
                    "step": .string("analyze_ocr_text"),
                    "count": .stringConvertible(items.count),
                    "prompt_chars": .stringConvertible(prompt.count),
                ])
            }

            aiAnalysisLogger.notice("Finished AI OCR analysis", metadata: [
                "step": .string("analyze_ocr_text"),
                "count": .stringConvertible(allItems.count),
                "result": .string("success"),
            ])
            return allItems
        }

        // MARK: - Batching

        func splitIntoBatches(_ lines: [(text: String, confidence: Float)], maxCharsPerBatch: Int) -> [[(
            text: String,
            confidence: Float
        )]] {
            var batches: [[(text: String, confidence: Float)]] = []
            var currentBatch: [(text: String, confidence: Float)] = []
            var currentChars = 0

            for line in lines {
                let lineChars = line.text.count
                if currentChars + lineChars > maxCharsPerBatch, !currentBatch.isEmpty {
                    batches.append(currentBatch)
                    currentBatch = []
                    currentChars = 0
                }
                currentBatch.append(line)
                currentChars += lineChars
            }

            if !currentBatch.isEmpty {
                batches.append(currentBatch)
            }

            aiAnalysisLogger.info("Split OCR lines into AI batches", metadata: [
                "step": .string("split_batches"),
                "count": .stringConvertible(batches.count),
            ])
            return batches
        }

        // MARK: - Prompt

        func buildPrompt(from lines: [(text: String, confidence: Float)]) -> String {
            let textBlock = lines.map(\.text).joined(separator: "\n")
            aiAnalysisLogger.debug("Built AI OCR prompt", metadata: [
                "step": .string("build_prompt"),
                "count": .stringConvertible(lines.count),
            ])
            return """
            你是一个礼金簿OCR文字解析助手。以下是从礼金簿图片中OCR识别出的文字行。

            请提取每一条人情往来记录，包括：
            1. name: 人名（2-6个汉字）
            2. amount: 金额（数字，单位元）
            3. eventType: 该条记录对应的事件类型，只能是以下之一：
               wedding, engagement, funeral, birth, birthday, longevity, festival, property, education, business, promotion, visit, other
            4. eventName: 该条记录对应的事件名称（如"婚礼"、"满月酒"、"寿宴"）

            注意：
            - 忽略非记录内容（标题、页码、合计等）
            - 金额可能包含逗号或中文大写数字，请转为阿拉伯数字
            - 每条记录根据其文字内容或上下文独立判断事件类型和名称
            - 如果某条记录本身包含事件关键词（如"张三婚礼 500"），则该条 eventType 为 wedding，eventName 为"婚礼"
            - 如果从标题或上下文能判断整页属于同一事件，则所有记录使用该事件
            - 如果无法判断事件类型，eventType 使用 other，eventName 使用"其他"

            OCR文字：
            \(textBlock)
            """
        }

        // MARK: - Conversion

        func convertToOCRRecordItems(
            _ result: AIExtractionResult,
            sourceLines: [(text: String, confidence: Float)]
        ) -> [OCRRecordItem] {
            let avgConfidence = sourceLines.isEmpty ? Float(0.7) : sourceLines.map(\.confidence).reduce(0, +) / Float(sourceLines.count)

            let items: [OCRRecordItem] = result.records.compactMap { record -> OCRRecordItem? in
                let name = record.name.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty, record.amount > 0 else { return nil }

                let confidence: OCRConfidence
                var warningType: WarningType?

                if avgConfidence >= 0.6 && OCRService.shared.isReasonableAmount(record.amount) {
                    confidence = .high
                } else if avgConfidence >= 0.4 {
                    confidence = .medium
                    if !OCRService.shared.isReasonableAmount(record.amount) {
                        warningType = .suspiciousAmount
                    } else {
                        warningType = .needsVerification
                    }
                } else {
                    confidence = .low
                    warningType = .needsVerification
                }

                let eventType = EventType(rawValue: record.eventType) ?? .other
                let trimmedEventName = record.eventName.trimmingCharacters(in: .whitespacesAndNewlines)
                let eventName = trimmedEventName.isEmpty ? eventType.displayName : trimmedEventName

                return OCRRecordItem(
                    name: name,
                    amount: record.amount,
                    amountText: formatAmount(record.amount),
                    confidence: confidence,
                    warningType: warningType,
                    eventType: eventType,
                    eventName: eventName
                )
            }
            aiAnalysisLogger.info("Converted AI OCR result", metadata: [
                "step": .string("convert_items"),
                "count": .stringConvertible(items.count),
            ])
            return items
        }

        func formatAmount(_ amount: Double) -> String {
            if amount == Double(Int(amount)) {
                return "\(Int(amount))"
            }
            return String(format: "%.2f", amount)
        }
    }

#else

    final class AIAnalysisService {
        static let shared = AIAnalysisService()
        private init() {}

        var isAvailable: Bool {
            false
        }

        func analyzeOCRText(_: [(text: String, confidence: Float)]) async throws -> [OCRRecordItem] {
            []
        }
    }

#endif
