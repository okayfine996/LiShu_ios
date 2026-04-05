import XCTest

final class PulseDiagnosticsUITests: BaseUITestCase {
    override var defaultLaunchArguments: [String] {
        [PulseLaunchArguments.skipOnboarding]
    }

    @MainActor
    func testHiddenDiagnosticsEntryOpensGuide() {
        let settingsTab = app.tabBars.buttons[TabLabels.settings]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5))
        settingsTab.tap()
        sleep(1)

        let aboutRow = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] '关于'")
        ).firstMatch
        XCTAssertTrue(aboutRow.waitForExistence(timeout: 3))
        aboutRow.tap()
        sleep(1)

        let versionLabel = app.staticTexts["about.versionLabel"]
        XCTAssertTrue(versionLabel.waitForExistence(timeout: 3))

        for _ in 0 ..< 7 {
            versionLabel.tap()
        }

        let diagnosticsButton = app.buttons["about.openDiagnosticsConsole"]
        XCTAssertTrue(diagnosticsButton.waitForExistence(timeout: 3), "Hidden diagnostics guide should appear outside UI testing mode")
    }
}

private enum PulseLaunchArguments {
    static let skipOnboarding = "--skip-onboarding"
}
