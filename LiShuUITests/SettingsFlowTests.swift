import XCTest

final class SettingsFlowTests: BaseUITestCase {
    @MainActor
    func testSettingsNavigation() {
        let settingsTab = app.tabBars.buttons[TabLabels.settings]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5))
        settingsTab.tap()
        sleep(1)

        let navBar = app.navigationBars.firstMatch
        XCTAssertTrue(navBar.waitForExistence(timeout: 3), "Settings navigation bar should exist")

        let appearanceRow = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] '外观' OR label CONTAINS[c] '显示'")
        ).firstMatch
        if appearanceRow.waitForExistence(timeout: 3) {
            appearanceRow.tap()
            sleep(1)
            app.navigationBars.buttons.firstMatch.tap()
            sleep(1)
        }
    }

    @MainActor
    func testAboutPage() {
        let settingsTab = app.tabBars.buttons[TabLabels.settings]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5))
        settingsTab.tap()
        sleep(1)

        let aboutRow = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] '关于'")
        ).firstMatch

        if aboutRow.waitForExistence(timeout: 3) {
            aboutRow.tap()
            sleep(1)

            let versionText = app.staticTexts.matching(
                NSPredicate(format: "label CONTAINS[c] 'v' OR label CONTAINS[c] '版本'")
            ).firstMatch
            XCTAssertTrue(versionText.waitForExistence(timeout: 3), "About page should show version info")

            let versionLabel = app.staticTexts["about.versionLabel"]
            XCTAssertTrue(
                versionLabel.waitForExistence(timeout: 3),
                "Version label should expose an accessibility identifier for diagnostics"
            )
            for _ in 0 ..< 7 {
                versionLabel.tap()
            }

            let diagnosticsButton = app.buttons["about.openDiagnosticsConsole"]
            XCTAssertFalse(
                diagnosticsButton.waitForExistence(timeout: 1),
                "UI testing mode should keep the hidden diagnostics entry unavailable"
            )

            app.navigationBars.buttons.firstMatch.tap()
        }
    }
}
