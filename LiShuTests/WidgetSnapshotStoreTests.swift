import Foundation
@testable import LiShu
import Testing

// MARK: - WidgetSnapshotStoreTests

struct WidgetSnapshotStoreTests {
    private static let key = "widget.snapshot.v1"

    private func freshDefaults(suite: String = "widget.snapshot.test.\(UUID().uuidString)") -> UserDefaults {
        let d = UserDefaults(suiteName: suite)!
        d.removeObject(forKey: Self.key)
        return d
    }

    private func write(_ snapshot: WidgetSnapshot, to defaults: UserDefaults) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: Self.key)
    }

    private func read(from defaults: UserDefaults) -> WidgetSnapshot {
        guard let data = defaults.data(forKey: Self.key),
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
        else { return .empty }
        return snapshot
    }

    /// 1. Write + read round-trip including pendingReturnCount and eventDateLabel
    @Test func roundTrip() {
        let defaults = freshDefaults()
        let reminder = WidgetReminderItem(
            id: "abc", title: "王五", subtitle: "生日",
            dateLabel: "今天", urgencyDaysFromNow: 0, kind: .birthday,
            deepLinkURL: URL(fileURLWithPath: "/"),
            eventDateLabel: "1月1日"
        )
        let original = WidgetSnapshot(
            generatedAt: Date(timeIntervalSince1970: 1_000_000),
            reminders: [reminder],
            reminderCount: 3,
            yearlyIncome: 1234.5,
            yearlyExpense: 567.8,
            currentYear: 2026,
            nextHostingEvent: nil,
            yearlyRecordCount: 10,
            yearlyContactCount: 5,
            pendingReturnCount: 7
        )
        write(original, to: defaults)
        let restored = read(from: defaults)
        #expect(restored.reminderCount == 3)
        #expect(abs(restored.yearlyIncome - 1234.5) < 0.01)
        #expect(restored.currentYear == 2026)
        #expect(restored.pendingReturnCount == 7)
        #expect(restored.reminders.first?.eventDateLabel == "1月1日")
    }

    /// 2. Missing data → .empty
    @Test func missingDataReturnsEmpty() {
        let defaults = freshDefaults()
        let result = read(from: defaults)
        #expect(result.reminders.isEmpty)
        #expect(result.reminderCount == 0)
    }

    /// 3. Invalid JSON → .empty, no crash
    @Test func invalidJSONReturnsEmpty() {
        let defaults = freshDefaults()
        defaults.set(Data("not-json".utf8), forKey: Self.key)
        let result = read(from: defaults)
        #expect(result.reminders.isEmpty)
    }

    /// 4. Old snapshot JSON (no pendingReturnCount, no eventDateLabel) decodes with defaults
    @Test func backwardCompatibleDecodeWithMissingNewFields() {
        let defaults = freshDefaults()
        let oldJSON = """
        {
          "generatedAt": 1000000,
          "reminders": [],
          "reminderCount": 2,
          "yearlyIncome": 500,
          "yearlyExpense": 100,
          "currentYear": 2025,
          "yearlyRecordCount": 8,
          "yearlyContactCount": 3
        }
        """.data(using: .utf8)!
        defaults.set(oldJSON, forKey: Self.key)
        let result = read(from: defaults)
        #expect(result.reminderCount == 2)
        #expect(result.pendingReturnCount == 0)
    }

    /// 5. refreshed(at:) preserves currentYear so financial stats label matches data
    @Test func refreshedPreservesCurrentYear() {
        let snapshot = WidgetSnapshot(
            generatedAt: Date(timeIntervalSince1970: 1_000_000),
            reminders: [],
            reminderCount: 0,
            yearlyIncome: 9999,
            yearlyExpense: 1111,
            currentYear: 2026,
            nextHostingEvent: nil,
            yearlyRecordCount: 5,
            yearlyContactCount: 2
        )
        // Simulate refreshed one year later (Jan 1 2027 00:00:00 UTC = 1767225600)
        let refreshed = snapshot.refreshed(at: Date(timeIntervalSince1970: 1_767_225_600))
        // currentYear must stay 2026 so the year label matches the 2026 financial figures
        #expect(refreshed.currentYear == 2026)
        #expect(abs(refreshed.yearlyIncome - 9999) < 0.01)
    }

    /// 6. Old snapshot with nextHostingEvent missing addRecordURL decodes with addRecordURL = nil
    @Test func backwardCompatibleDecodeHostingEventWithoutAddRecordURL() {
        let defaults = freshDefaults()
        let oldJSON = """
        {
          "generatedAt": 1000000,
          "reminders": [],
          "reminderCount": 0,
          "yearlyIncome": 0,
          "yearlyExpense": 0,
          "currentYear": 2026,
          "yearlyRecordCount": 0,
          "yearlyContactCount": 0,
          "nextHostingEvent": {
            "name": "我的婚礼",
            "typeName": "婚礼",
            "daysUntil": 7,
            "dateLine": "1月8日",
            "deepLinkURL": "lishu://event?id=10"
          }
        }
        """.data(using: .utf8)!
        defaults.set(oldJSON, forKey: Self.key)
        let result = read(from: defaults)
        #expect(result.nextHostingEvent?.name == "我的婚礼")
        #expect(result.nextHostingEvent?.addRecordURL == nil)
    }
}
