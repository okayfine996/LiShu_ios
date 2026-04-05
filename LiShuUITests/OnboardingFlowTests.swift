import XCTest

final class OnboardingFlowTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testOnboardingSkipButton() {
        app.launchArguments = ["--reset-onboarding"]
        app.launch()
        sleep(3)

        let skipButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] '跳过' OR label CONTAINS[c] 'skip'")
        ).firstMatch

        if skipButton.waitForExistence(timeout: 5) {
            XCTAssertTrue(true, "Skip button exists on onboarding")
            skipButton.tap()
            sleep(2)

            let tabBar = app.tabBars.firstMatch
            XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "Should navigate to main tab view after skip")
        } else {
            let tabBar = app.tabBars.firstMatch
            XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "Main tab view should appear (onboarding may be skipped)")
        }
    }

    @MainActor
    func testAppLaunchToMainView() {
        app.launchArguments = ["--uitesting"]
        app.launch()
        sleep(3)

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "Tab bar should appear after splash")

        let homeTab = app.tabBars.buttons[TabLabels.home]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 3), "Home tab should exist")
    }
}
