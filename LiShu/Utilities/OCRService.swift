import Foundation
import Vision
import UIKit

enum OCRConfidence: String, Codable {
    case high
    case medium
    case low
}

enum WarningType: String, Codable {
    case needsVerification
    case suspiciousAmount
}

struct OCRRecordItem: Identifiable {
    let id: UUID
    var name: String
    var amount: Double
    var amountText: String
    var confidence: OCRConfidence
    var warningType: WarningType?
    var isSelected: Bool
    var date: Date
    var eventType: EventType
    var eventName: String

    init(
        name: String,
        amount: Double,
        amountText: String,
        confidence: OCRConfidence,
        warningType: WarningType? = nil,
        date: Date = .now,
        eventType: EventType = .other,
        eventName: String = String(localized: "event.type.other")
    ) {
        self.id = UUID()
        self.name = name
        self.amount = amount
        self.amountText = amountText
        self.confidence = confidence
        self.warningType = warningType
        self.isSelected = true
        self.date = date
        self.eventType = eventType
        self.eventName = eventName
    }
}

final class OCRService {

    static let shared = OCRService()
    private init() {}

    // MARK: - Public API

    func recognizeRecords(from images: [UIImage]) async throws -> [OCRRecordItem] {
        var allItems: [OCRRecordItem] = []

        for image in images {
            let lines = try await recognizeText(in: image)
            let items = parseRecordItems(from: lines)
            allItems.append(contentsOf: items)
        }

        return deduplicateItems(allItems)
    }

    func recognizeRecordsEnhanced(from images: [UIImage]) async throws -> (items: [OCRRecordItem], isAIEnhanced: Bool) {
        var allItems: [OCRRecordItem] = []
        var aiCount = 0

        for image in images {
            let lines = try await recognizeText(in: image)

            if let aiItems = await tryAIAnalysis(lines), !aiItems.isEmpty {
                allItems.append(contentsOf: aiItems)
                aiCount += 1
            } else {
                let items = parseRecordItems(from: lines)
                allItems.append(contentsOf: items)
            }
        }

        return (items: deduplicateItems(allItems), isAIEnhanced: aiCount == images.count && aiCount > 0)
    }

    private func tryAIAnalysis(_ lines: [(text: String, confidence: Float)]) async -> [OCRRecordItem]? {
        if #available(iOS 26.0, *) {
            let service = AIAnalysisService.shared
            guard service.isAvailable else { return nil }
            do {
                return try await service.analyzeOCRText(lines)
            } catch {
                return nil
            }
        }
        return nil
    }

    // MARK: - Vision Text Recognition

    func recognizeText(in image: UIImage) async throws -> [(text: String, confidence: Float)] {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                let lines = observations.compactMap { observation -> (text: String, confidence: Float)? in
                    guard let candidate = observation.topCandidates(1).first else { return nil }
                    return (text: candidate.string, confidence: candidate.confidence)
                }
                continuation.resume(returning: lines)
            }

            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["zh-Hans", "en"]
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    // MARK: - Event Keyword Matching

    private static let eventKeywords: [(keywords: [String], eventType: EventType)] = [
        (["婚礼", "婚宴", "结婚"], .wedding),
        (["订婚"], .engagement),
        (["丧事", "白事", "丧葬", "葬礼"], .funeral),
        (["满月", "百日", "新生"], .birth),
        (["生日", "生辰"], .birthday),
        (["寿宴", "大寿", "寿辰"], .longevity),
        (["节庆", "春节", "中秋", "端午"], .festival),
        (["乔迁", "搬家", "新居"], .property),
        (["升学", "毕业", "金榜"], .education),
        (["开业", "开张"], .business),
        (["升职", "晋升"], .promotion),
        (["探望", "慰问", "看望"], .visit),
    ]

    func matchEventType(from text: String) -> EventType {
        for entry in Self.eventKeywords {
            for keyword in entry.keywords {
                if text.contains(keyword) {
                    return entry.eventType
                }
            }
        }
        return .other
    }

    func matchEventName(from text: String) -> String {
        matchEventType(from: text).displayName
    }

    // MARK: - Text Parsing

    let nameAmountPattern = #"([\u4e00-\u9fff]{2,6})\s*[¥￥]?\s*([\d,，]+(?:\.\d{1,2})?)"#
    let amountNamePattern = #"[¥￥]?\s*([\d,，]+(?:\.\d{1,2})?)\s+([\u4e00-\u9fff]{2,6})"#

    func parseRecordItems(from lines: [(text: String, confidence: Float)]) -> [OCRRecordItem] {
        var items: [OCRRecordItem] = []
        let nameAmountRegex = try? NSRegularExpression(pattern: nameAmountPattern)
        let amountNameRegex = try? NSRegularExpression(pattern: amountNamePattern)

        for line in lines {
            let text = line.text.trimmingCharacters(in: .whitespacesAndNewlines)
            if text.isEmpty { continue }

            let nsText = text as NSString
            let fullRange = NSRange(location: 0, length: nsText.length)
            let eventType = matchEventType(from: text)
            let eventName = eventType.displayName

            if let match = nameAmountRegex?.firstMatch(in: text, range: fullRange),
               match.numberOfRanges >= 3 {
                let name = nsText.substring(with: match.range(at: 1))
                let rawAmount = nsText.substring(with: match.range(at: 2))
                if let item = buildItem(
                    name: name,
                    rawAmount: rawAmount,
                    visionConfidence: line.confidence,
                    eventType: eventType,
                    eventName: eventName
                ) {
                    items.append(item)
                    continue
                }
            }

            if let match = amountNameRegex?.firstMatch(in: text, range: fullRange),
               match.numberOfRanges >= 3 {
                let rawAmount = nsText.substring(with: match.range(at: 1))
                let name = nsText.substring(with: match.range(at: 2))
                if let item = buildItem(
                    name: name,
                    rawAmount: rawAmount,
                    visionConfidence: line.confidence,
                    eventType: eventType,
                    eventName: eventName
                ) {
                    items.append(item)
                }
            }
        }

        return items
    }

    func buildItem(
        name: String,
        rawAmount: String,
        visionConfidence: Float,
        eventType: EventType = .other,
        eventName: String = String(localized: "event.type.other")
    ) -> OCRRecordItem? {
        let cleaned = rawAmount
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "，", with: "")

        guard let amount = Double(cleaned), amount > 0 else { return nil }

        let confidence: OCRConfidence
        var warningType: WarningType?

        if visionConfidence >= 0.8 && isReasonableAmount(amount) {
            confidence = .high
        } else if visionConfidence >= 0.5 {
            confidence = .medium
            if !isReasonableAmount(amount) {
                warningType = .suspiciousAmount
            } else {
                warningType = .needsVerification
            }
        } else {
            confidence = .low
            warningType = .needsVerification
        }

        return OCRRecordItem(
            name: name,
            amount: amount,
            amountText: rawAmount,
            confidence: confidence,
            warningType: warningType,
            eventType: eventType,
            eventName: eventName
        )
    }

    func isReasonableAmount(_ amount: Double) -> Bool {
        amount >= 10
            && amount <= 1_000_000
            && (amount == amount.rounded(.down) || amount.truncatingRemainder(dividingBy: 1) < 0.01)
    }

    // MARK: - Deduplication

    func deduplicateItems(_ items: [OCRRecordItem]) -> [OCRRecordItem] {
        var seen = Set<String>()
        return items.filter { item in
            let key = "\(item.name)_\(Int(item.amount))"
            if seen.contains(key) { return false }
            seen.insert(key)
            return true
        }
    }
}

enum OCRError: LocalizedError {
    case invalidImage
    case recognitionFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return String(localized: "ocr.error.invalidImage")
        case .recognitionFailed(let msg):
            return msg
        }
    }
}
