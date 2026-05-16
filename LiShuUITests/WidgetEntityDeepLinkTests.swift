import XCTest

/// Widget entity deep link E2E tests.
///
/// These tests cover the two deep link patterns generated when a user taps a
/// reminder row in the widget:
///   lishu://event?id={stableID}   → navigates to EventDetailView (events tab selected)
///   lishu://contact?id={stableID} → navigates to ContactDetailView (contacts tab selected)
///
/// stableID is read from MainTabView's debug probe ("debug.event.sid.{id}.{name}"),
/// which uses the same allEvents @Query as handleDeepLink — guaranteeing the IDs match.
///
/// Verification uses app.otherElements["tab.events"] / ["tab.contacts"] —
/// these identifiers are set on the NavigationStack for each tab in MainTabView
/// and are only present in the accessibility tree when that tab is SELECTED
/// (SwiftUI TabView only renders the selected tab's content).
final class WidgetEntityDeepLinkTests: BaseUITestCase {
    // MARK: - Tests

    /// Widget event reminder tap: lishu://event?id={stableID} → events tab selected.
    @MainActor
    func testEventDetailDeepLink() {
        createEvent(name: "Widget事件")

        // Read stableID from MainTabView's debug probe (same source as handleDeepLink).
        guard let stableID = readStableIDFromMainView(
            entityPrefix: "debug.event.sid.",
            name: "Widget事件"
        ) else {
            XCTFail("MainTabView debug probe not found for Widget事件 after event creation")
            return
        }
        XCTAssertFalse(stableID.isEmpty, "stableID should not be empty")

        terminateAndRelaunchWithURL("lishu://event?id=\(stableID)")

        // Read debug probes to include in failure message if needed.
        let dbgTab = readDebugProbe(prefix: "debug.tab.", timeout: 9)
        let dbgDeepLink = readDebugProbe(prefix: "debug.deeplink.", timeout: 1)

        // Verify navigation: "tab.events" is only in the accessibility tree when events tab is selected.
        XCTAssertTrue(
            app.otherElements["tab.events"].waitForExistence(timeout: 5),
            "Events tab should be selected after lishu://event deep link — " +
                "debug.tab=\(dbgTab ?? "nil"), debug.deeplink=\(dbgDeepLink ?? "nil"), stableID=\(stableID)"
        )
    }

    /// Widget contact reminder tap: lishu://contact?id={stableID} → contacts tab selected.
    @MainActor
    func testContactDetailDeepLink() {
        createContact(name: "Widget联系人")

        // Read stableID from MainTabView's debug probe (same source as handleDeepLink).
        guard let stableID = readStableIDFromMainView(
            entityPrefix: "debug.contact.sid.",
            name: "Widget联系人"
        ) else {
            XCTFail("MainTabView debug probe not found for Widget联系人 after contact creation")
            return
        }
        XCTAssertFalse(stableID.isEmpty, "stableID should not be empty")

        terminateAndRelaunchWithURL("lishu://contact?id=\(stableID)")

        // Read debug probes to include in failure message if needed.
        let dbgTab = readDebugProbe(prefix: "debug.tab.", timeout: 9)
        let dbgDeepLink = readDebugProbe(prefix: "debug.deeplink.", timeout: 1)

        // Verify navigation: "tab.contacts" is only in the accessibility tree when contacts tab is selected.
        XCTAssertTrue(
            app.otherElements["tab.contacts"].waitForExistence(timeout: 5),
            "Contacts tab should be selected after lishu://contact deep link — " +
                "debug.tab=\(dbgTab ?? "nil"), debug.deeplink=\(dbgDeepLink ?? "nil"), stableID=\(stableID)"
        )
    }

    /// Widget pendingReturn reminder tap: lishu://add-record?event={stableID}&direction=given
    /// → events tab selected and add-record sheet opened.
    @MainActor
    func testGiveGiftForEventDeepLink() {
        createEvent(name: "礼单测试事件")

        guard let stableID = readStableIDFromMainView(
            entityPrefix: "debug.event.sid.",
            name: "礼单测试事件"
        ) else {
            XCTFail("MainTabView debug probe not found for 礼单测试事件 after event creation")
            return
        }
        XCTAssertFalse(stableID.isEmpty, "stableID should not be empty")

        terminateAndRelaunchWithURL("lishu://add-record?event=\(stableID)&direction=given")

        XCTAssertTrue(
            app.otherElements["tab.events"].waitForExistence(timeout: 5),
            "Events tab should be selected after lishu://add-record?direction=given deep link, stableID=\(stableID)"
        )
        XCTAssertTrue(
            app.buttons["record.add.saveButton"].waitForExistence(timeout: 5),
            "Add-record sheet should be open after giveGiftForEvent deep link, stableID=\(stableID)"
        )
    }

    /// Invalid stableID in event deep link: guard-return in router, app stays running on home tab.
    @MainActor
    func testEventDetailDeepLinkInvalidIDDoesNotCrash() {
        terminateAndRelaunchWithURL("lishu://event?id=invalid00000")

        XCTAssertEqual(app.state, .runningForeground, "App should remain running after unresolvable deep link")
        XCTAssertTrue(
            app.tabBars.buttons[TabLabels.home].waitForExistence(timeout: 5),
            "Tab bar should be visible after unresolvable event deep link"
        )
    }

    // MARK: - Helpers

    /// Reads a debug probe accessibility identifier that starts with `prefix`.
    @MainActor
    private func readDebugProbe(prefix: String, timeout: TimeInterval) -> String? {
        let predicate = NSPredicate(format: "identifier BEGINSWITH %@", prefix)
        let el = app.descendants(matching: .any).matching(predicate).firstMatch
        guard el.waitForExistence(timeout: timeout) else { return nil }
        let id = el.identifier
        return id.hasPrefix(prefix) ? String(id.dropFirst(prefix.count)) : nil
    }
}
