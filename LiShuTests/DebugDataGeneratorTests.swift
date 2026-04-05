//
//  DebugDataGeneratorTests.swift
//  LiShuTests
//

#if DEBUG
import Foundation
import Testing
import SwiftData
@testable import LiShu

@MainActor
struct DebugDataGeneratorTests {

    @Test func testGenerateSampleDataInsertsContacts() throws {
        let db = try TestDB()
        DebugDataGenerator.generateSampleData(context: db.context)

        let contacts = try db.context.fetch(FetchDescriptor<Contact>())
        #expect(contacts.count >= 10)
        #expect(contacts.contains { $0.name == "张伟" })
        #expect(contacts.contains { $0.name == "李娜" })
    }

    @Test func testGenerateSampleDataInsertsEvents() throws {
        let db = try TestDB()
        DebugDataGenerator.generateSampleData(context: db.context)

        let events = try db.context.fetch(FetchDescriptor<Event>())
        #expect(events.count >= 5)
        #expect(events.contains { $0.name.contains("婚礼") || $0.name.contains("生日") })
    }

    @Test func testGenerateSampleDataInsertsRecords() throws {
        let db = try TestDB()
        DebugDataGenerator.generateSampleData(context: db.context)

        let records = try db.context.fetch(FetchDescriptor<Record>())
        #expect(records.count >= 5)

        let recordTypes = Set(records.map(\.recordType))
        #expect(recordTypes.contains(.monetary))
        #expect(recordTypes.contains(.gift))
        #expect(recordTypes.contains(.favor))
        #expect(recordTypes.contains(.banquet))

        let banquetRecord = records.first { $0.recordType == .banquet }
        #expect(banquetRecord?.banquetData != nil)
        #expect(banquetRecord?.banquetData?.location.isEmpty == false)
        #expect(banquetRecord?.returnGiftBadge == .received)
    }

    @Test func testClearAllDataRemovesAll() throws {
        let db = try TestDB()
        DebugDataGenerator.generateSampleData(context: db.context)

        #expect(try db.context.fetchCount(FetchDescriptor<Contact>()) > 0)
        #expect(try db.context.fetchCount(FetchDescriptor<Event>()) > 0)
        #expect(try db.context.fetchCount(FetchDescriptor<Record>()) > 0)

        DebugDataGenerator.clearAllData(context: db.context)

        #expect(try db.context.fetchCount(FetchDescriptor<Contact>()) == 0)
        #expect(try db.context.fetchCount(FetchDescriptor<Event>()) == 0)
        #expect(try db.context.fetchCount(FetchDescriptor<Record>()) == 0)
    }
}
#endif
