import Foundation
import Logging

private let aiAnalysisLogger = PulseDiagnostics.makeLogger(label: AppLogLabel.ai)

#if canImport(FoundationModels)
    import FoundationModels

    @available(iOS 26.0, *)
    @Generable
    struct AIExtractedRecord {
        @Guide(description: "候选条目索引")
        var candidateIndex: Int

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
            let candidates = lines.enumerated().map { _, line in
                LedgerEntryCandidate(
                    nameText: "",
                    amountText: "",
                    normalizedAmount: nil,
                    sourceLineIDs: [],
                    layoutPattern: .unknown,
                    averageConfidence: line.confidence,
                    fullText: line.text
                )
            }
            return try await analyzeLedgerCandidates(candidates, pageContexts: [:])
        }

        func analyzeLedgerCandidates(
            _ candidates: [LedgerEntryCandidate],
            pageContexts: [Int: LedgerPageContext]
        ) async throws -> [OCRRecordItem] {
            aiAnalysisLogger.notice("Starting AI OCR analysis", metadata: [
                "step": .string("analyze_ledger_candidates"),
                "count": .stringConvertible(candidates.count),
            ])
            let batches = splitIntoBatches(candidates, maxCharsPerBatch: 1500)
            var allItems: [OCRRecordItem] = []

            for batch in batches {
                let prompt = buildPrompt(from: batch, pageContexts: pageContexts)
                let session = LanguageModelSession()
                let response = try await session.respond(to: prompt, generating: AIExtractionResult.self)
                let items = convertToOCRRecordItems(response.content, sourceCandidates: batch)
                allItems.append(contentsOf: items)
                aiAnalysisLogger.info("Finished AI OCR batch", metadata: [
                    "step": .string("analyze_ledger_candidates"),
                    "count": .stringConvertible(items.count),
                    "prompt_chars": .stringConvertible(prompt.count),
                ])
            }

            aiAnalysisLogger.notice("Finished AI OCR analysis", metadata: [
                "step": .string("analyze_ledger_candidates"),
                "count": .stringConvertible(allItems.count),
                "result": .string("success"),
            ])
            return allItems
        }

        // MARK: - Batching

        func splitIntoBatches(_ candidates: [LedgerEntryCandidate], maxCharsPerBatch: Int) -> [[LedgerEntryCandidate]] {
            var batches: [[LedgerEntryCandidate]] = []
            var currentBatch: [LedgerEntryCandidate] = []
            var currentChars = 0

            for candidate in candidates {
                let lineChars = candidate.fullText.count
                if currentChars + lineChars > maxCharsPerBatch, !currentBatch.isEmpty {
                    batches.append(currentBatch)
                    currentBatch = []
                    currentChars = 0
                }
                currentBatch.append(candidate)
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

        func buildPrompt(from candidates: [LedgerEntryCandidate], pageContexts: [Int: LedgerPageContext]) -> String {
            let textBlock = candidates.enumerated().map { index, candidate in
                LedgerHeuristicPipeline.shared.summarizeCandidate(candidate, index: index)
            }.joined(separator: "\n")
            let contextBlock = pageContexts.keys.sorted().compactMap { pageIndex -> String? in
                guard let context = pageContexts[pageIndex] else { return nil }
                let title = context.titleLines.joined(separator: " / ")
                let ignored = context.ignoredLines.prefix(3).joined(separator: " / ")
                let hint = context.eventHint ?? String(localized: "event.type.other")
                return "页\(pageIndex + 1): 标题=\(title.isEmpty ? "无" : title)；事件提示=\(hint)；已过滤噪声=\(ignored.isEmpty ? "无" : ignored)"
            }.joined(separator: "\n")
            aiAnalysisLogger.debug("Built AI OCR prompt", metadata: [
                "step": .string("build_prompt"),
                "count": .stringConvertible(candidates.count),
            ])
            return """
            你是一个礼簿条目解析助手。以下内容来自礼簿 OCR 和本地规则预处理。

            请仅提取真正的礼簿条目，每条输出包括：
            0. candidateIndex: 对应候选条目索引
            1. name: 人名（2-6个汉字）
            2. amount: 金额（数字，单位元）
            3. eventType: 该条记录对应的事件类型，只能是以下之一：
               wedding, engagement, funeral, birth, birthday, longevity, festival, property, education, business, promotion, visit, other
            4. eventName: 该条记录对应的事件名称（如"婚礼"、"满月酒"、"寿宴"）

            注意：
            - 忽略标题、页码、合计、电话、地址、说明性文本
            - 如果候选内容不像礼簿条目，不要输出
            - 金额必须是正数，输出阿拉伯数字
            - 每条记录根据其文字内容或上下文独立判断事件类型和名称
            - 如果从页标题或上下文能判断整页属于同一事件，则优先使用该事件
            - 如果无法判断事件类型，eventType 使用 other，eventName 使用"其他"
            - candidateIndex 必须引用下方候选索引

            页面上下文：
            \(contextBlock)

            候选条目：
            \(textBlock)
            """
        }

        // MARK: - Conversion

        func convertToOCRRecordItems(
            _ result: AIExtractionResult,
            sourceCandidates: [LedgerEntryCandidate]
        ) -> [OCRRecordItem] {
            let items: [OCRRecordItem] = result.records.compactMap { record -> OCRRecordItem? in
                let name = record.name.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty, record.amount > 0 else { return nil }
                let candidate = sourceCandidates.indices.contains(record.candidateIndex) ? sourceCandidates[record.candidateIndex] : nil
                let avgConfidence = candidate?.averageConfidence ?? Float(0.7)

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
                    eventName: eventName,
                    sourceMode: .appleAIEnhanced,
                    sourceLineIDs: candidate?.sourceLineIDs ?? []
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

        func analyzeLedgerCandidates(_: [LedgerEntryCandidate], pageContexts _: [Int: LedgerPageContext]) async throws -> [OCRRecordItem] {
            []
        }
    }

#endif
