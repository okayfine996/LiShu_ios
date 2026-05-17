import XCTest

final class PulseDiagnosticsUITests: BaseUITestCase {
    override var defaultLaunchArguments: [String] {
        [PulseLaunchArguments.skipOnboarding]
    }

    @MainActor
    func testHiddenDiagnosticsEntryOpensConsole() {
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

        for _ in 0..<7 {
            versionLabel.tap()
        }

        let consoleTitle = app.staticTexts["开发控制台"]
        XCTAssertTrue(consoleTitle.waitForExistence(timeout: 3), "Hidden diagnostics entry should open the console directly")
    }
}

private enum PulseLaunchArguments {
    static let skipOnboarding = "--skip-onboarding"
}
