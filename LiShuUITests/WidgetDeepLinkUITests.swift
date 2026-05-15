import XCTest

final class WidgetDeepLinkUITests: BaseUITestCase {
    // MARK: - Helpers

    override var defaultLaunchArguments: [String] {
        ["--uitesting"]
    }

    private func launchWithURL(_ urlString: String) {
        app.launchArguments = defaultLaunchArguments + ["--open-url=\(urlString)"]
        app.launch()
        sleep(2) // splash
    }

    // MARK: - Tests

    /// lishu://home → home tab is visible after deep link resolves
    @MainActor
    func testHomeDeepLink() {
        launchWithURL("lishu://home")
        sleep(3) // allow task sleep (2.5s) + navigation

        let homeTab = app.otherElements["tab.home"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 5), "Home tab content should be visible after lishu://home deep link")
    }

    /// lishu://add-record → record add sheet appears
    @MainActor
    func testAddRecordDeepLink() {
        launchWithURL("lishu://add-record")
        sleep(3)

        // Check that the add-record sheet or its key field is presented
        let amountField = app.textFields["record.add.amountField"]
        let sheetExists = amountField.waitForExistence(timeout: 5)
        if !sheetExists {
            // Fallback: check that the sheet-like UI appeared via any record add button
            let saveButton = app.buttons["record.add.saveButton"]
            XCTAssertTrue(saveButton.waitForExistence(timeout: 3), "Add record sheet should appear after lishu://add-record deep link")
        } else {
            XCTAssertTrue(sheetExists, "Amount field should exist in add record sheet")
        }
    }

    /// lishu://unknown → app does not crash, home tab remains selected
    @MainActor
    func testUnknownDeepLinkDoesNotCrash() {
        launchWithURL("lishu://unknown")
        sleep(3)

        // App should still be running and home tab accessible
        let homeTabButton = app.tabBars.buttons[TabLabels.home]
        XCTAssertTrue(homeTabButton.waitForExistence(timeout: 5), "App should remain running and show tab bar after unknown deep link")
        XCTAssertTrue(app.state == .runningForeground, "App should still be running in foreground")
    }
}
