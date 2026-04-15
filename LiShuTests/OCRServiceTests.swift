import Foundation
@testable import LiShu
import Testing

struct OCRServiceTests {
    private var service: OCRService {
        OCRService.shared
    }

    // MARK: - Parse Record Items

    @Test func parseRecordItemsNameAmount() {
        let lines: [(text: String, confidence: Float)] = [
            (text: "张三 500", confidence: 0.9),
            (text: "李四 ¥1,200", confidence: 0.85),
            (text: "王五 300.00", confidence: 0.7),
        ]

        let items = service.parseRecordItems(from: lines)
        #expect(items.count == 3)
        #expect(items[0].name == "张三")
        #expect(items[0].amount == 500)
        #expect(items[1].name == "李四")
        #expect(items[1].amount == 1200)
        #expect(items[2].name == "王五")
        #expect(items[2].amount == 300)
    }

    @Test func parseRecordItemsAmountName() {
        let lines: [(text: String, confidence: Float)] = [
            (text: "￥800 赵六", confidence: 0.9),
            (text: "200 孙七", confidence: 0.8),
        ]

        let items = service.parseRecordItems(from: lines)
        #expect(items.count == 2)
        #expect(items[0].name == "赵六")
        #expect(items[0].amount == 800)
    }

    // MARK: - Build Item

    @Test func buildItemConfidenceLevels() {
        let highItem = service.buildItem(name: "张三", rawAmount: "500", visionConfidence: 0.9)
        #expect(highItem != nil)
        #expect(highItem?.confidence == .high)
        #expect(highItem?.warningType == nil)

        let mediumItem = service.buildItem(name: "李四", rawAmount: "300", visionConfidence: 0.6)
        #expect(mediumItem != nil)
        #expect(mediumItem?.confidence == .medium)

        let lowItem = service.buildItem(name: "王五", rawAmount: "200", visionConfidence: 0.3)
        #expect(lowItem != nil)
        #expect(lowItem?.confidence == .low)
        #expect(lowItem?.warningType == .needsVerification)

        let invalidItem = service.buildItem(name: "赵六", rawAmount: "abc", visionConfidence: 0.9)
        #expect(invalidItem == nil)

        let zeroItem = service.buildItem(name: "孙七", rawAmount: "0", visionConfidence: 0.9)
        #expect(zeroItem == nil)
    }

    @Test func buildItemCleansChinaComma() {
        let item = service.buildItem(name: "张三", rawAmount: "1，200", visionConfidence: 0.9)
        #expect(item != nil)
        #expect(item?.amount == 1200)
    }

    // MARK: - Reasonable Amount

    @Test func testIsReasonableAmount() {
        #expect(service.isReasonableAmount(100) == true)
        #expect(service.isReasonableAmount(500) == true)
        #expect(service.isReasonableAmount(10000) == true)
        #expect(service.isReasonableAmount(5) == false)
        #expect(service.isReasonableAmount(2_000_000) == false)
    }

    // MARK: - Deduplication

    @Test func testDeduplicateItems() {
        let items = [
            OCRRecordItem(name: "张三", amount: 500, amountText: "500", confidence: .high),
            OCRRecordItem(name: "张三", amount: 500, amountText: "500", confidence: .medium),
            OCRRecordItem(name: "李四", amount: 500, amountText: "500", confidence: .high),
            OCRRecordItem(name: "张三", amount: 300, amountText: "300", confidence: .high),
        ]

        let result = service.deduplicateItems(items)
        #expect(result.count == 3)
    }
}
