@testable import LiShu
import SnapshotTesting
import SwiftUI
import XCTest

/// Snapshot tests for key UI surfaces.
/// To regenerate reference images:
///   1. Set isRecording = true in setUp()
///   2. Run the tests (they will "fail" but save new images to __Snapshots__/)
///   3. Verify the images look correct, then set isRecording = false
@MainActor
final class UISnapshotTests: XCTestCase {
    override func setUp() {
        super.setUp()
        isRecording = false
    }

    // MARK: - Widget Gallery

    func testWidgetGalleryHomeWidgets_light() {
        assertSnapshot(
            of: WidgetGalleryHomeWidgets(snapshot: .galleryPreview)
                .environment(\.colorScheme, .light),
            as: .image(layout: .fixed(width: 390, height: 1900))
        )
    }

    func testWidgetGalleryLockWidgets_light() {
        assertSnapshot(
            of: WidgetGalleryLockWidgets(snapshot: .galleryPreview)
                .environment(\.colorScheme, .light),
            as: .image(layout: .fixed(width: 390, height: 1400))
        )
    }

    func testWidgetGalleryHomeWidgets_dark() {
        assertSnapshot(
            of: WidgetGalleryHomeWidgets(snapshot: .galleryPreview)
                .environment(\.colorScheme, .dark)
                .background(DesignSystem.Colors.bgPage),
            as: .image(layout: .fixed(width: 390, height: 1900))
        )
    }

    // MARK: - Home Dashboard

    func testHomeDashboardEmpty_light() {
        let snapshot = HomeDashboardSnapshot.build(records: [], events: [], contacts: [])
        assertSnapshot(
            of: HomeDashboardContentView(snapshot: snapshot, sheetRoute: .constant(nil))
                .environment(\.colorScheme, .light),
            as: .image(layout: .fixed(width: 390, height: 800))
        )
    }

    func testHomeDashboardWithData_light() {
        // Fixed date for stable output regardless of when tests run
        let fixedDate = Date(timeIntervalSinceReferenceDate: 800_000_000)
        let contact = SampleData.contact(name: "张三", relation: "好友", category: "社会", circle: 2)
        let event = SampleData.event(
            name: "张三婚礼", type: .wedding, hostMode: .guest,
            date: fixedDate.addingTimeInterval(86400 * 7)
        )
        let record = SampleData.record(
            contact: contact, event: event,
            amount: 1000, direction: .given,
            date: fixedDate.addingTimeInterval(-86400)
        )
        contact.records = [record]
        let dashSnapshot = HomeDashboardSnapshot.build(
            records: [record], events: [event], contacts: [contact],
            now: fixedDate
        )
        assertSnapshot(
            of: HomeDashboardContentView(snapshot: dashSnapshot, sheetRoute: .constant(nil))
                .environment(\.colorScheme, .light),
            as: .image(layout: .fixed(width: 390, height: 900))
        )
    }
}
