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

        for _ in 0..<UsageLimits.freeRecordTotal {
            let r = SampleData.record(contact: contact, event: event, amount: 100)
            db.context.insert(r)
        }
        try db.context.save()

        let manager = SubscriptionManager.shared
        let result = manager.canAddRecord(context: db.context)
        #expect(result == false)
    }

    @Test("session override allows adding records beyond limit")
    func sessionOverrideAllowsAddRecordAtLimit() throws {
        let db = try TestDB()
        let contact = SampleData.contact()
        let event = SampleData.event()
        db.context.insert(contact)
        db.context.insert(event)

        for _ in 0..<UsageLimits.freeRecordTotal {
            db.context.insert(SampleData.record(contact: contact, event: event, amount: 100))
        }
        try db.context.save()

        let overrides = DebugOverrideManager()
        overrides.proAccessOverrideEnabled = true

        let manager = SubscriptionManager.shared
        #expect(manager.canAddRecord(context: db.context, overrides: overrides))
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
        for i in 0..<UsageLimits.freeContactTotal {
            let c = SampleData.contact(name: "联系人\(i)")
            db.context.insert(c)
        }
        try db.context.save()

        let manager = SubscriptionManager.shared
        let result = manager.canAddContact(context: db.context)
        #expect(result == false)
    }

    @Test("session override allows adding contacts beyond limit")
    func sessionOverrideAllowsAddContactAtLimit() throws {
        let db = try TestDB()
        for i in 0..<UsageLimits.freeContactTotal {
            db.context.insert(SampleData.contact(name: "联系人\(i)"))
        }
        try db.context.save()

        let overrides = DebugOverrideManager()
        overrides.proAccessOverrideEnabled = true

        let manager = SubscriptionManager.shared
        #expect(manager.canAddContact(context: db.context, overrides: overrides))
    }

    @Test("canAddContacts blocks batch imports that exceed the free limit")
    func canAddContactsRejectsOverflowBatch() throws {
        let db = try TestDB()
        for i in 0..<(UsageLimits.freeContactTotal - 1) {
            db.context.insert(SampleData.contact(name: "联系人\(i)"))
        }
        try db.context.save()

        let manager = SubscriptionManager.shared
        #expect(manager.canAddContacts(1, context: db.context))
        #expect(manager.canAddContacts(2, context: db.context) == false)
    }

    @Test("session override allows batch contact import beyond limit")
    func sessionOverrideAllowsBatchContactImportAtLimit() async throws {
        let db = try TestDB()
        for i in 0..<UsageLimits.freeContactTotal {
            db.context.insert(SampleData.contact(name: "联系人\(i)"))
        }
        try db.context.save()

        let overrides = DebugOverrideManager.shared
        let originalOverrideValue = overrides.proAccessOverrideEnabled
        defer { overrides.proAccessOverrideEnabled = originalOverrideValue }
        overrides.proAccessOverrideEnabled = true

        let viewModel = BatchContactImportViewModel()
        let importItem = PhoneContactItem(
            id: PhoneContactItem.key(name: "新增联系人", phone: "13800138000"),
            displayName: "新增联系人",
            phone: "13800138000",
            isExisting: false
        )
        viewModel.allItems = [importItem]
        viewModel.selectedIDs = [importItem.id]

        let result = await viewModel.performImport(context: db.context)

        #expect(result)
        #expect(viewModel.showProSheet == false)
    }

    @Test("session override allows OCR after usage limit")
    func sessionOverrideAllowsOCRAfterLimit() {
        let settings = AppSettings.shared
        let originalUsageCount = settings.ocrUsageCount
        let originalUsageMonth = settings.ocrUsageMonth
        let originalUsageYear = settings.ocrUsageYear
        defer {
            settings.ocrUsageCount = originalUsageCount
            settings.ocrUsageMonth = originalUsageMonth
            settings.ocrUsageYear = originalUsageYear
        }

        let currentMonth = Calendar.current.component(.month, from: .now)
        let currentYear = Calendar.current.component(.year, from: .now)
        settings.ocrUsageCount = UsageLimits.freeOCRPerMonth
        settings.ocrUsageMonth = currentMonth
        settings.ocrUsageYear = currentYear

        let overrides = DebugOverrideManager()
        overrides.proAccessOverrideEnabled = true

        let manager = SubscriptionManager.shared
        #expect(manager.canUseOCR(overrides: overrides))
        #expect(manager.remainingOCRCount(overrides: overrides) == .max)
    }

    @Test("effective Pro uses session override without active entitlement")
    func effectiveProUsesSessionOverride() {
        let overrides = DebugOverrideManager()
        overrides.proAccessOverrideEnabled = true

        let manager = SubscriptionManager.shared
        #expect(manager.hasActiveEntitlement == false)
        #expect(manager.effectiveIsPro(overrides: overrides))
    }

    @Test("resetSessionOverrides clears temporary Pro override")
    func resetSessionOverridesClearsOverride() {
        let overrides = DebugOverrideManager()
        overrides.proAccessOverrideEnabled = true

        overrides.resetSessionOverrides()

        #expect(!overrides.proAccessOverrideEnabled)
    }

    @Test("reset OCR usage only updates OCR counters")
    func resetOCRUsageOnlyUpdatesOCRCounters() {
        let settings = AppSettings.shared
        let originalSeenOnboarding = settings.hasSeenOnboarding
        let originalUsageCount = settings.ocrUsageCount
        let originalUsageMonth = settings.ocrUsageMonth
        let originalUsageYear = settings.ocrUsageYear
        defer {
            settings.hasSeenOnboarding = originalSeenOnboarding
            settings.ocrUsageCount = originalUsageCount
            settings.ocrUsageMonth = originalUsageMonth
            settings.ocrUsageYear = originalUsageYear
        }

        settings.hasSeenOnboarding = true
        settings.ocrUsageCount = 9
        settings.ocrUsageMonth = 1
        settings.ocrUsageYear = 2001

        DebugConsoleActions.resetOCRUsage()

        #expect(settings.ocrUsageCount == 0)
        #expect(settings.hasSeenOnboarding == true)
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
