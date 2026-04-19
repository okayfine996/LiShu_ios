import Foundation
@testable import LiShu
import SwiftData
import Testing

// MARK: - SmartReturnGiftEngineTests

//
// 覆盖范围：
//   1. adjustCircle — 职场关系降圈层
//   2. eventTypeFloor — 二维基准表
//   3. conservative < standard（各 floor 边界均不相等）
//   4. generous > standard（向上取整保证）
//   5. 通胀系数映射
//   6. 非金额记录排除
//   7. noHistory / historicalPositive 路径

@MainActor
struct SmartReturnGiftEngineTests {
    // MARK: - Helpers

    /// 无历史记录时 baseline 等于 floor，方便验证二维基准表
    private func baseline(circle: Int, relation: String, eventType: EventType) throws -> Double {
        let db = try TestDB()
        let contact = Contact(name: "测试", relation: relation, category: "", circle: circle)
        let event = Event(name: "测试活动", type: eventType, hostMode: .guest, date: .now, location: "")
        db.context.insert(contact)
        db.context.insert(event)
        return SmartReturnGiftEngine.calculate(contact: contact, event: event, allContactRecords: []).baselineAmount
    }

    // MARK: - Floor Table

    @Test("婚礼 × 家人(1) → 2000")
    func floorWeddingCircle1() throws {
        #expect(try baseline(circle: 1, relation: "母亲", eventType: .wedding) == 2000)
    }

    @Test("婚礼 × 亲属(2) → 1000")
    func floorWeddingCircle2() throws {
        #expect(try baseline(circle: 2, relation: "表弟", eventType: .wedding) == 1000)
    }

    @Test("婚礼 × 朋友/同学(3) → 600")
    func floorWeddingCircle3Friend() throws {
        #expect(try baseline(circle: 3, relation: "好友", eventType: .wedding) == 600)
    }

    @Test("婚礼 × 同事(圈层3职场) → 300（adjustCircle 降为4）")
    func floorWeddingCircle3Colleague() throws {
        #expect(try baseline(circle: 3, relation: "同事", eventType: .wedding) == 300)
    }

    @Test("婚礼 × 领导(圈层3职场) → 300")
    func floorWeddingCircle3Boss() throws {
        #expect(try baseline(circle: 3, relation: "领导", eventType: .wedding) == 300)
    }

    @Test("婚礼 × 客户(圈层3职场) → 300")
    func floorWeddingCircle3Client() throws {
        #expect(try baseline(circle: 3, relation: "客户", eventType: .wedding) == 300)
    }

    @Test("出生 × 家人(1) → 1000")
    func floorBirthCircle1() throws {
        #expect(try baseline(circle: 1, relation: "父亲", eventType: .birth) == 1000)
    }

    @Test("生日 × 亲属(2) → 300")
    func floorBirthdayCircle2() throws {
        #expect(try baseline(circle: 2, relation: "姑姑", eventType: .birthday) == 300)
    }

    @Test("生日 × 同事(圈层3职场) → 100")
    func floorBirthdayCircle3Colleague() throws {
        #expect(try baseline(circle: 3, relation: "同事", eventType: .birthday) == 100)
    }

    @Test("节日 × 家人(1) → 200")
    func floorFestivalCircle1() throws {
        #expect(try baseline(circle: 1, relation: "母亲", eventType: .festival) == 200)
    }

    @Test("节日 × 其他(4) → 50（最低基准）")
    func floorFestivalCircle4() throws {
        #expect(try baseline(circle: 4, relation: "邻居", eventType: .festival) == 50)
    }

    // MARK: - Conservative < Standard

    @Test("保守 < 标准：朋友婚礼 baseline=floor=600")
    func conservativeLessThanStandardFloor600() throws {
        let db = try TestDB()
        let contact = Contact(name: "好友", relation: "好友", category: "社交", circle: 3)
        let event = Event(name: "婚礼", type: .wedding, hostMode: .guest, date: .now, location: "")
        db.context.insert(contact)
        db.context.insert(event)
        let result = SmartReturnGiftEngine.calculate(contact: contact, event: event, allContactRecords: [])
        #expect(result.conservativeAmount < result.standardAmount,
                "conservative=\(result.conservativeAmount) standard=\(result.standardAmount)")
    }

    @Test("保守 < 标准：家人婚礼 baseline=floor=2000")
    func conservativeLessThanStandardFloor2000() throws {
        let db = try TestDB()
        let contact = Contact(name: "父亲", relation: "父亲", category: "家人", circle: 1)
        let event = Event(name: "婚礼", type: .wedding, hostMode: .guest, date: .now, location: "")
        db.context.insert(contact)
        db.context.insert(event)
        let result = SmartReturnGiftEngine.calculate(contact: contact, event: event, allContactRecords: [])
        #expect(result.conservativeAmount < result.standardAmount,
                "conservative=\(result.conservativeAmount) standard=\(result.standardAmount)")
    }

    @Test("保守 < 标准：同事生日 baseline=floor=100")
    func conservativeLessThanStandardFloor100() throws {
        let db = try TestDB()
        let contact = Contact(name: "同事", relation: "同事", category: "社交", circle: 3)
        let event = Event(name: "生日", type: .birthday, hostMode: .guest, date: .now, location: "")
        db.context.insert(contact)
        db.context.insert(event)
        let result = SmartReturnGiftEngine.calculate(contact: contact, event: event, allContactRecords: [])
        #expect(result.conservativeAmount < result.standardAmount,
                "conservative=\(result.conservativeAmount) standard=\(result.standardAmount)")
    }

    @Test("保守 < 标准：有历史记录 baseline > floor")
    func conservativeLessThanStandardWithHistory() throws {
        let db = try TestDB()
        let contact = Contact(name: "好友", relation: "好友", category: "社交", circle: 3)
        let pastEvent = Event(name: "过去婚礼", type: .wedding, hostMode: .guest, date: .now, location: "")
        db.context.insert(contact)
        db.context.insert(pastEvent)
        let received = SampleData.record(contact: contact, event: pastEvent, amount: 2000, direction: .received)
        db.context.insert(received)
        let newEvent = Event(name: "我的婚礼", type: .wedding, hostMode: .host, date: .now, location: "")
        db.context.insert(newEvent)
        let result = SmartReturnGiftEngine.calculate(contact: contact, event: newEvent, allContactRecords: [received])
        #expect(result.conservativeAmount < result.standardAmount,
                "conservative=\(result.conservativeAmount) standard=\(result.standardAmount)")
    }

    // MARK: - Generous > Standard

    @Test("慷慨 > 标准：baseline=100（原向下取整会导致慷慨=标准）")
    func generousGreaterThanStandardAt100() throws {
        let db = try TestDB()
        let contact = Contact(name: "同事", relation: "同事", category: "社交", circle: 3)
        let event = Event(name: "生日", type: .birthday, hostMode: .guest, date: .now, location: "")
        db.context.insert(contact)
        db.context.insert(event)
        let result = SmartReturnGiftEngine.calculate(contact: contact, event: event, allContactRecords: [])
        // baseline=100, 100×1.25=125 → 向上取整50 = 150（不再等于100）
        #expect(result.generousAmount > result.standardAmount,
                "generous=\(result.generousAmount) standard=\(result.standardAmount)")
    }

    @Test("慷慨 > 标准：baseline=600")
    func generousGreaterThanStandardAt600() throws {
        let db = try TestDB()
        let contact = Contact(name: "好友", relation: "好友", category: "社交", circle: 3)
        let event = Event(name: "婚礼", type: .wedding, hostMode: .guest, date: .now, location: "")
        db.context.insert(contact)
        db.context.insert(event)
        let result = SmartReturnGiftEngine.calculate(contact: contact, event: event, allContactRecords: [])
        #expect(result.generousAmount > result.standardAmount,
                "generous=\(result.generousAmount) standard=\(result.standardAmount)")
    }

    @Test("三档金额严格递增：conservative < standard < generous")
    func threeAmountsStrictlyIncreasing() throws {
        let db = try TestDB()
        // 用几种不同 floor 都验证
        let cases: [(circle: Int, relation: String, type: EventType)] = [
            (1, "父亲", .wedding),
            (2, "表弟", .wedding),
            (3, "好友", .wedding),
            (3, "同事", .wedding),
            (3, "好友", .birthday),
            (3, "同事", .birthday),
            (1, "母亲", .festival),
            (4, "邻居", .festival),
        ]
        for c in cases {
            let contact = Contact(name: "测试", relation: c.relation, category: "", circle: c.circle)
            let event = Event(name: "测试", type: c.type, hostMode: .guest, date: .now, location: "")
            db.context.insert(contact)
            db.context.insert(event)
            let result = SmartReturnGiftEngine.calculate(contact: contact, event: event, allContactRecords: [])
            let std = result.standardAmount
            // baseline=50 是绝对最低，此时 conservative 无法再低，允许相等
            if std > 50 {
                let msg = "circle=\(c.circle) \(c.relation) \(c.type): con=\(result.conservativeAmount) std=\(std)"
                #expect(result.conservativeAmount < std, "\(msg)")
            }
            let msg2 = "circle=\(c.circle) \(c.relation) \(c.type): gen=\(result.generousAmount) std=\(std)"
            #expect(result.generousAmount > std, "\(msg2)")
        }
    }

    // MARK: - Inflation

    @Test("0年内收礼 → inflationFactor = 1.0（无调整）")
    func inflationNone() throws {
        let db = try TestDB()
        let contact = Contact(name: "好友", relation: "好友", category: "社交", circle: 3)
        let pastEvent = Event(name: "过去婚礼", type: .wedding, hostMode: .guest, date: .now, location: "")
        db.context.insert(contact)
        db.context.insert(pastEvent)
        let received = SampleData.record(contact: contact, event: pastEvent, amount: 1000, direction: .received, date: .now)
        db.context.insert(received)
        let newEvent = Event(name: "新活动", type: .wedding, hostMode: .host, date: .now, location: "")
        db.context.insert(newEvent)
        let result = SmartReturnGiftEngine.calculate(contact: contact, event: newEvent, allContactRecords: [received])
        #expect(result.inflationFactor == 1.0)
    }

    @Test("3-4年前收礼 → inflationFactor = 1.10")
    func inflationThreeYears() throws {
        let db = try TestDB()
        let contact = Contact(name: "好友", relation: "好友", category: "社交", circle: 3)
        let pastEvent = Event(name: "过去婚礼", type: .wedding, hostMode: .guest, date: .now, location: "")
        db.context.insert(contact)
        db.context.insert(pastEvent)
        let threeYearsAgo = try #require(Calendar.current.date(byAdding: .year, value: -3, to: .now))
        let received = SampleData.record(contact: contact, event: pastEvent, amount: 1000, direction: .received, date: threeYearsAgo)
        db.context.insert(received)
        let newEvent = Event(name: "新活动", type: .wedding, hostMode: .host, date: .now, location: "")
        db.context.insert(newEvent)
        let result = SmartReturnGiftEngine.calculate(contact: contact, event: newEvent, allContactRecords: [received])
        #expect(result.inflationFactor == 1.10)
    }

    @Test("8年以上 → inflationFactor = 1.20")
    func inflationEightYears() throws {
        let db = try TestDB()
        let contact = Contact(name: "好友", relation: "好友", category: "社交", circle: 3)
        let pastEvent = Event(name: "过去婚礼", type: .wedding, hostMode: .guest, date: .now, location: "")
        db.context.insert(contact)
        db.context.insert(pastEvent)
        let eightYearsAgo = try #require(Calendar.current.date(byAdding: .year, value: -8, to: .now))
        let received = SampleData.record(contact: contact, event: pastEvent, amount: 1000, direction: .received, date: eightYearsAgo)
        db.context.insert(received)
        let newEvent = Event(name: "新活动", type: .wedding, hostMode: .host, date: .now, location: "")
        db.context.insert(newEvent)
        let result = SmartReturnGiftEngine.calculate(contact: contact, event: newEvent, allContactRecords: [received])
        #expect(result.inflationFactor == 1.20)
    }

    // MARK: - Non-monetary exclusion

    @Test("礼品/拜访记录不计入金额，走 noHistory 路径")
    func nonMonetaryRecordsExcluded() throws {
        let db = try TestDB()
        let contact = Contact(name: "好友", relation: "好友", category: "社交", circle: 3)
        let pastEvent = Event(name: "拜访", type: .visit, hostMode: .guest, date: .now, location: "")
        db.context.insert(contact)
        db.context.insert(pastEvent)
        let giftRecord = SampleData.recordGift(contact: contact, event: pastEvent, direction: .received)
        let favorRecord = SampleData.recordFavor(contact: contact, event: pastEvent, direction: .given)
        db.context.insert(giftRecord)
        db.context.insert(favorRecord)
        let newEvent = Event(name: "好友婚礼", type: .wedding, hostMode: .guest, date: .now, location: "")
        db.context.insert(newEvent)
        let result = SmartReturnGiftEngine.calculate(
            contact: contact,
            event: newEvent,
            allContactRecords: [giftRecord, favorRecord]
        )
        #expect(result.receivedTotal == 0)
        #expect(result.givenTotal == 0)
        #expect(result.reasoningCards.first?.type == .noHistory)
    }

    // MARK: - noHistory vs historicalPositive

    @Test("净余为正 → historicalPositive 卡片")
    func historicalPositiveCard() throws {
        let db = try TestDB()
        let contact = Contact(name: "好友", relation: "好友", category: "社交", circle: 3)
        let pastEvent = Event(name: "对方婚礼", type: .wedding, hostMode: .guest, date: .now, location: "")
        db.context.insert(contact)
        db.context.insert(pastEvent)
        let received = SampleData.record(contact: contact, event: pastEvent, amount: 1000, direction: .received)
        db.context.insert(received)
        let newEvent = Event(name: "我的婚礼", type: .wedding, hostMode: .host, date: .now, location: "")
        db.context.insert(newEvent)
        let result = SmartReturnGiftEngine.calculate(contact: contact, event: newEvent, allContactRecords: [received])
        #expect(result.reasoningCards.first?.type == .historicalPositive)
        #expect(result.receivedTotal == 1000)
        #expect(result.netReceivedBalance == 1000)
        // baseline ≥ floor（朋友婚礼 floor=600，净余1000 ≥ 600）
        #expect(result.baselineAmount >= 600)
    }

    @Test("净余 ≤ 0 → historicalNonPositive 卡片，baseline = floor")
    func historicalNonPositiveCard() throws {
        let db = try TestDB()
        let contact = Contact(name: "好友", relation: "好友", category: "社交", circle: 3)
        let pastEvent = Event(name: "我的婚礼", type: .wedding, hostMode: .host, date: .now, location: "")
        db.context.insert(contact)
        db.context.insert(pastEvent)
        // 我给出 1000，对方收到 0 → netBalance = -1000
        let given = SampleData.record(contact: contact, event: pastEvent, amount: 1000, direction: .given)
        db.context.insert(given)
        let newEvent = Event(name: "对方婚礼", type: .wedding, hostMode: .guest, date: .now, location: "")
        db.context.insert(newEvent)
        let result = SmartReturnGiftEngine.calculate(contact: contact, event: newEvent, allContactRecords: [given])
        #expect(result.reasoningCards.first?.type == .historicalNonPositive)
        #expect(result.baselineAmount == 600) // floor for circle3 wedding
    }
}
