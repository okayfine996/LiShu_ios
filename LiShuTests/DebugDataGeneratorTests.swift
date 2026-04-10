//
//  DebugDataGeneratorTests.swift
//  LiShuTests
//

#if DEBUG
    import Foundation
    @testable import LiShu
    import SwiftData
    import Testing

    @MainActor
    struct DebugDataGeneratorTests {
        @Test func generateSampleDataInsertsContacts() throws {
            let db = try TestDB()
            DebugDataGenerator.generateSampleData(context: db.context)

            let contacts = try db.context.fetch(FetchDescriptor<Contact>())
            #expect(contacts.count >= 10)
            #expect(contacts.contains { $0.name == "张伟" })
            #expect(contacts.contains { $0.name == "李娜" })
        }

        @Test func generateSampleDataInsertsEvents() throws {
            let db = try TestDB()
            DebugDataGenerator.generateSampleData(context: db.context)

            let events = try db.context.fetch(FetchDescriptor<Event>())
            #expect(events.count >= 5)
            #expect(events.contains { $0.name.contains("婚礼") || $0.name.contains("生日") })
        }

        @Test func generateSampleDataInsertsRecords() throws {
            let db = try TestDB()
            DebugDataGenerator.generateSampleData(context: db.context)

            let records = try db.context.fetch(FetchDescriptor<Record>())
            #expect(records.count >= 12)

            let recordsByType = Dictionary(grouping: records, by: \.recordType)
            #expect(recordsByType[.monetary]?.count ?? 0 > 1)
            #expect(recordsByType[.gift]?.count ?? 0 > 1)
            #expect(recordsByType[.favor]?.count ?? 0 > 1)
            #expect(recordsByType[.banquet]?.count ?? 0 > 1)

            let dailyTypes = Set(records.filter(\.isDailyInteraction).map(\.recordType))
            #expect(dailyTypes.count >= 2)
            #expect(dailyTypes.contains(.monetary))
            #expect(dailyTypes.contains(.gift))

            let monetaryRecords = recordsByType[.monetary] ?? []
            #expect(monetaryRecords.contains { $0.resolvedReturnedAmount == 0 })
            #expect(monetaryRecords.contains { $0.resolvedReturnedAmount > 0 && $0.resolvedReturnedAmount < $0.monetaryAmount })
            #expect(monetaryRecords.contains { $0.monetaryAmount > 0 && $0.resolvedReturnedAmount == $0.monetaryAmount })

            let giftRecords = recordsByType[.gift] ?? []
            #expect(giftRecords.contains { $0.direction == .given })
            #expect(giftRecords.contains { $0.direction == .received })
            #expect(giftRecords.contains { $0.giftData?.estimatedValue != nil })
            #expect(giftRecords.contains { $0.giftData?.estimatedValue == nil })

            let favorRecords = recordsByType[.favor] ?? []
            #expect(favorRecords.contains { $0.direction == .given })
            #expect(favorRecords.contains { $0.direction == .received })
            #expect(favorRecords.contains { ($0.favorData?.description.isEmpty == false) && $0.event == nil })

            let banquetRecords = recordsByType[.banquet] ?? []
            #expect(banquetRecords.contains { $0.direction == .given })
            #expect(banquetRecords.contains { $0.direction == .received })
            #expect(banquetRecords.contains { $0.banquetData?.location.isEmpty == false && $0.event == nil })
            #expect(banquetRecords.contains {
                ($0.banquetData?.attendeeList.isEmpty ?? true) &&
                    ($0.banquetData?.extraCostNotes.isEmpty ?? true)
            })
        }

        @Test func clearAllDataRemovesAll() throws {
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
