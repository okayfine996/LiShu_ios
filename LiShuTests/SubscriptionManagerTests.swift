import Foundation
@testable import LiShu
import SwiftData
import Testing

@MainActor
struct SubscriptionManagerTests {
    @Test("UsageLimits constants are correct")
    func usageLimitsConstants() {
        #expect(UsageLimits.freeOCRPerMonth == 3)
        #expect(UsageLimits.freeRecordTotal == 20)
        #expect(UsageLimits.freeContactTotal == 20)
    }

    @Test("canAddRecord returns true when record count < limit")
    func canAddRecordUnderLimit() throws {
        let db = try TestDB()
        let manager = SubscriptionManager.shared

        let result = manager.canAddRecord(context: db.context)
        #expect(result == true)
    }

    @Test("canAddRecord returns false when record count >= limit")
    func canAddRecordAtLimit() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)

        for _ in 0 ..< UsageLimits.freeRecordTotal {
            let r = SampleData.record(contact: contact, event: event, amount: 100)
            db.context.insert(r)
        }
        try db.context.save()

        let manager = SubscriptionManager.shared
        let result = manager.canAddRecord(context: db.context)
        #expect(result == false)
    }

    @Test("canAddContact returns true when contact count < limit")
    func canAddContactUnderLimit() throws {
        let db = try TestDB()
        let manager = SubscriptionManager.shared

        let result = manager.canAddContact(context: db.context)
        #expect(result == true)
    }

    @Test("canAddContact returns false when contact count >= limit")
    func canAddContactAtLimit() throws {
        let db = try TestDB()
        for i in 0 ..< UsageLimits.freeContactTotal {
            let c = SampleData.contact(name: "联系人\(i)")
            db.context.insert(c)
        }
        try db.context.save()

        let manager = SubscriptionManager.shared
        let result = manager.canAddContact(context: db.context)
        #expect(result == false)
    }

    @Test("currentSubscriptionName is nil when not purchased")
    func currentSubscriptionNameNil() {
        let manager = SubscriptionManager.shared
        #expect(manager.isPro == false)
        #expect(manager.currentSubscriptionName == nil)
    }

    @Test("product ID constants are correct")
    func productIDs() {
        #expect(SubscriptionManager.monthlyID == "com.finefine.LiShu.pro.monthly.v2")
        #expect(SubscriptionManager.yearlyID == "com.finefine.LiShu.pro.yearly.v2")
        #expect(SubscriptionManager.lifetimeID == "com.finefine.LiShu.pro.lifetime.v2")
    }
}
