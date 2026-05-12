import Foundation
@testable import LiShu
import SwiftData
import Testing

@MainActor
struct StatisticsViewModelTests {
    @Test("load empty database hasData=false, totals=0")
    func loadEmptyDatabase() throws {
        let db = try TestDB()
        let vm = StatisticsViewModel()
        loadStatistics(vm, context: db.context)

        #expect(vm.hasData == false)
        #expect(vm.totalIncome == 0)
        #expect(vm.totalExpense == 0)
        #expect(vm.netValue == 0)
    }

    @Test("load with records computes totalIncome/totalExpense/netValue")
    func loadWithData() throws {
        let db = try TestDB()
        let cal = Calendar.current
        let currentYear = cal.component(.year, from: Date())
        var comps = DateComponents()
        comps.year = currentYear
        comps.month = 6
        comps.day = 15
        let recordDate = try #require(cal.date(from: comps))

        let c = SampleData.contact(name: "张三")
        let e = SampleData.event()
        db.context.insert(c)
        db.context.insert(e)
        let rGiven = SampleData.record(contact: c, event: e, amount: 1000, direction: .given, returnedAmount: 0, date: recordDate)
        let rReceived = SampleData.record(contact: c, event: e, amount: 500, direction: .received, returnedAmount: 0, date: recordDate)
        db.context.insert(rGiven)
        db.context.insert(rReceived)
        try db.context.save()

        let vm = StatisticsViewModel()
        loadStatistics(vm, context: db.context)

        #expect(vm.totalIncome == 500)
        #expect(vm.totalExpense == 1000)
        #expect(vm.netValue == -500)
    }

    @Test("monthlyData has correct values for month 3 and 6")
    func testMonthlyData() throws {
        let db = try TestDB()
        let cal = Calendar.current
        let currentYear = cal.component(.year, from: Date())
        var comps = DateComponents()
        comps.year = currentYear
        comps.month = 3
        comps.day = 10
        let marDate = try #require(cal.date(from: comps))
        comps.month = 6
        comps.day = 20
        let junDate = try #require(cal.date(from: comps))

        let c = SampleData.contact(name: "张三")
        let e = SampleData.event()
        db.context.insert(c)
        db.context.insert(e)
        let rMarGiven = SampleData.record(contact: c, event: e, amount: 300, direction: .given, returnedAmount: 0, date: marDate)
        let rMarReceived = SampleData.record(contact: c, event: e, amount: 100, direction: .received, returnedAmount: 0, date: marDate)
        let rJunGiven = SampleData.record(contact: c, event: e, amount: 500, direction: .given, returnedAmount: 0, date: junDate)
        db.context.insert(rMarGiven)
        db.context.insert(rMarReceived)
        db.context.insert(rJunGiven)
        try db.context.save()

        let vm = StatisticsViewModel()
        loadStatistics(vm, context: db.context)

        #expect(vm.monthlyData.count == 12)
        let march = vm.monthlyData[2]
        #expect(march.month == 3)
        #expect(march.income == 100)
        #expect(march.expense == 300)
        let june = vm.monthlyData[5]
        #expect(june.month == 6)
        #expect(june.income == 0)
        #expect(june.expense == 500)
    }

    @Test("eventTypeDistribution has correct percentages")
    func testEventTypeDistribution() throws {
        let db = try TestDB()
        let cal = Calendar.current
        let currentYear = cal.component(.year, from: Date())
        var comps = DateComponents()
        comps.year = currentYear
        comps.month = 6
        comps.day = 15
        let recordDate = try #require(cal.date(from: comps))

        let c = SampleData.contact(name: "张三")
        let e1 = SampleData.event(type: .wedding)
        let e2 = SampleData.event(type: .birthday)
        db.context.insert(c)
        db.context.insert(e1)
        db.context.insert(e2)
        let r1 = SampleData.record(contact: c, event: e1, amount: 600, direction: .given, returnedAmount: 0, date: recordDate)
        let r2 = SampleData.record(contact: c, event: e2, amount: 400, direction: .given, returnedAmount: 0, date: recordDate)
        let dailyRecord = SampleData.record(contact: c, event: nil, amount: 1000, direction: .given, returnedAmount: 0, date: recordDate)
        db.context.insert(r1)
        db.context.insert(r2)
        db.context.insert(dailyRecord)
        try db.context.save()

        let vm = StatisticsViewModel()
        loadStatistics(vm, context: db.context)

        let dist = vm.eventTypeDistribution
        #expect(dist.count == 2)
        let wedding = dist.first { $0.type == .wedding }
        let birthday = dist.first { $0.type == .birthday }
        #expect(wedding != nil)
        #expect(birthday != nil)
        #expect(wedding?.amount == 600)
        #expect(wedding?.percentage == 0.6)
        #expect(birthday?.amount == 400)
        #expect(birthday?.percentage == 0.4)
    }

    @Test("topContacts has 5, allRankedContacts has 5")
    func testTopContacts() throws {
        let db = try TestDB()
        let cal = Calendar.current
        let currentYear = cal.component(.year, from: Date())
        var comps = DateComponents()
        comps.year = currentYear
        comps.month = 6
        comps.day = 15
        let recordDate = try #require(cal.date(from: comps))

        let c1 = SampleData.contact(name: "张三")
        let c2 = SampleData.contact(name: "李四")
        let c3 = SampleData.contact(name: "王五")
        let c4 = SampleData.contact(name: "赵六")
        let c5 = SampleData.contact(name: "孙七")
        let e = SampleData.event()
        for c in [c1, c2, c3, c4, c5] {
            db.context.insert(c)
        }
        db.context.insert(e)
        for c in [c1, c2, c3, c4, c5] {
            let r = SampleData.record(contact: c, event: e, amount: 100, direction: .given, returnedAmount: 0, date: recordDate)
            db.context.insert(r)
        }
        try db.context.save()

        let vm = StatisticsViewModel()
        loadStatistics(vm, context: db.context)

        #expect(vm.topContacts.count == 5)
        #expect(vm.allRankedContacts.count == 5)
    }

    @Test("selectYear updates data for chosen year")
    func testSelectYear() throws {
        let db = try TestDB()
        let cal = Calendar.current
        var comps2025 = DateComponents()
        comps2025.year = 2025
        comps2025.month = 6
        comps2025.day = 15
        let date2025 = try #require(cal.date(from: comps2025))
        var comps2026 = DateComponents()
        comps2026.year = 2026
        comps2026.month = 6
        comps2026.day = 15
        let date2026 = try #require(cal.date(from: comps2026))

        let c = SampleData.contact(name: "张三")
        let e = SampleData.event()
        db.context.insert(c)
        db.context.insert(e)
        let r2025 = SampleData.record(contact: c, event: e, amount: 1000, direction: .given, returnedAmount: 0, date: date2025)
        let r2026 = SampleData.record(contact: c, event: e, amount: 2000, direction: .given, returnedAmount: 0, date: date2026)
        db.context.insert(r2025)
        db.context.insert(r2026)
        try db.context.save()

        let vm = StatisticsViewModel()
        loadStatistics(vm, context: db.context)
        let initialYear = vm.selectedYear

        vm.selectYear(2025, context: db.context)
        waitForStatisticsLoad(vm)
        #expect(vm.selectedYear == 2025)
        #expect(vm.totalExpense == 1000)

        vm.selectYear(2026, context: db.context)
        waitForStatisticsLoad(vm)
        #expect(vm.selectedYear == 2026)
        #expect(vm.totalExpense == 2000)
    }

    @Test("formatAmount: 5000 -> 5000, 15000 -> 1.5W")
    func testFormatAmount() {
        let vm = StatisticsViewModel()
        #expect(vm.formatAmount(5000) == "5000")
        #expect(vm.formatAmount(15000) == "1.5W")
    }

    @Test("formatNetValue: 1000 -> +¥1,000, -500 -> correct negative format")
    func testFormatNetValue() {
        let vm = StatisticsViewModel()
        let positive = vm.formatNetValue(1000)
        #expect(positive.contains("+"))
        #expect(positive.contains("¥"))
        #expect(positive.contains("1,000") || positive.contains("1000"))

        let negative = vm.formatNetValue(-500)
        #expect(negative.contains("¥"))
        #expect(negative.contains("500"))
    }

    @Test("contactsSortedByIncome returns correct order")
    func testContactsSortedByIncome() throws {
        let db = try TestDB()
        let cal = Calendar.current
        let currentYear = cal.component(.year, from: Date())
        var comps = DateComponents()
        comps.year = currentYear
        comps.month = 6
        comps.day = 15
        let recordDate = try #require(cal.date(from: comps))

        let c1 = SampleData.contact(name: "低")
        let c2 = SampleData.contact(name: "高")
        let c3 = SampleData.contact(name: "中")
        let e = SampleData.event()
        for c in [c1, c2, c3] {
            db.context.insert(c)
        }
        db.context.insert(e)
        let r1 = SampleData.record(contact: c1, event: e, amount: 100, direction: .received, returnedAmount: 0, date: recordDate)
        let r2 = SampleData.record(contact: c2, event: e, amount: 500, direction: .received, returnedAmount: 0, date: recordDate)
        let r3 = SampleData.record(contact: c3, event: e, amount: 300, direction: .received, returnedAmount: 0, date: recordDate)
        db.context.insert(r1)
        db.context.insert(r2)
        db.context.insert(r3)
        try db.context.save()

        let vm = StatisticsViewModel()
        loadStatistics(vm, context: db.context)
        let sorted = vm.contactsSortedByIncome()
        #expect(sorted.count == 3)
        #expect(sorted[0].contact.name == "高")
        #expect(sorted[1].contact.name == "中")
        #expect(sorted[2].contact.name == "低")
    }

    @Test("hasData: no data false, with data true")
    func testHasData() throws {
        let db = try TestDB()

        let vm = StatisticsViewModel()
        loadStatistics(vm, context: db.context)
        #expect(vm.hasData == false)

        let c = SampleData.contact(name: "张三")
        let e = SampleData.event()
        let r = SampleData.record(contact: c, event: e)
        db.context.insert(c)
        db.context.insert(e)
        db.context.insert(r)
        try db.context.save()

        loadStatistics(vm, context: db.context)
        #expect(vm.hasData == true)
    }

    @Test("hasData: only non-financial records in year counts as has data")
    func hasDataNonFinancialOnly() throws {
        let db = try TestDB()
        let c = SampleData.contact(name: "仅礼品")
        let e = SampleData.event()
        let gift = SampleData.recordGift(contact: c, event: e, giftName: "礼盒")
        db.context.insert(c)
        db.context.insert(e)
        db.context.insert(gift)
        try db.context.save()

        let vm = StatisticsViewModel()
        loadStatistics(vm, context: db.context)
        #expect(vm.hasData == true)
        #expect(vm.nonFinancialInteractionCount == 1)
        #expect(vm.totalIncome == 0)
        #expect(vm.totalExpense == 0)
    }

    @Test("demo sample data exposes all record types in recordTypeDistribution")
    func demoSampleDataCoversRecordTypeDistribution() throws {
        let db = try TestDB()
        DebugDataGenerator.generateSampleData(context: db.context)

        let vm = StatisticsViewModel()
        loadStatistics(vm, context: db.context)

        let distributionTypes = Set(vm.recordTypeDistribution.map(\.type))
        #expect(distributionTypes.contains(.monetary))
        #expect(distributionTypes.contains(.gift))
        #expect(distributionTypes.contains(.favor))
        #expect(distributionTypes.contains(.banquet))
    }

    @Test("relationship health summary reuses shared calculator results")
    func relationshipHealthSummaryUsesSharedCalculator() throws {
        let db = try TestDB()
        let closeContact = SampleData.contact(name: "常联系")
        let overdueContact = SampleData.contact(name: "久未联系")
        let event = SampleData.event()
        db.context.insert(closeContact)
        db.context.insert(overdueContact)
        db.context.insert(event)

        let calendar = Calendar.current
        let recentOffsets = [-10, -20, -35, -50]
        for (index, offset) in recentOffsets.enumerated() {
            db.context.insert(
                SampleData.record(
                    contact: closeContact,
                    event: event,
                    amount: 300,
                    direction: index.isMultiple(of: 2) ? .given : .received,
                    date: calendar.date(byAdding: .day, value: offset, to: .now) ?? .now
                )
            )
        }
        db.context.insert(
            SampleData.recordGift(
                contact: closeContact,
                event: event,
                direction: .given,
                date: calendar.date(byAdding: .day, value: -15, to: .now) ?? .now
            )
        )
        db.context.insert(
            SampleData.record(
                contact: overdueContact,
                event: event,
                amount: 1200,
                direction: .received,
                date: calendar.date(byAdding: .day, value: -420, to: .now) ?? .now
            )
        )
        try db.context.save()

        let vm = StatisticsViewModel()
        loadStatistics(vm, context: db.context)

        #expect(vm.relationshipHealthSummary.close == 1)
        #expect(vm.relationshipHealthSummary.needsAttention == 1)
        #expect(vm.relationshipHealthSummary.stable == 0)
        #expect(vm.relationshipHealthSummary.distant == 0)
        #expect(vm.relationshipHealthResults[closeContact.persistentModelID]?.level == .close)
        #expect(vm.relationshipHealthResults[overdueContact.persistentModelID]?.level == .needsAttention)
    }

    private func loadStatistics(_ viewModel: StatisticsViewModel, context: ModelContext) {
        viewModel.loadData(context: context)
        waitForStatisticsLoad(viewModel)
    }

    private func waitForStatisticsLoad(_ viewModel: StatisticsViewModel) {
        let timeout = Date().addingTimeInterval(2)
        while Date() < timeout {
            if case .loaded = viewModel.state {
                return
            }
            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.01))
        }
        Issue.record("StatisticsViewModel 在 2 秒内未进入 .loaded 状态")
    }
}
