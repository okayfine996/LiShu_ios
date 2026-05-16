import XCTest

/// Widget Gallery E2E flow tests.
///
/// Verifies the in-app Widget Gallery screen (accessible from Settings → Widget 介绍)
/// renders without crash and responds to tab switching.
final class WidgetGalleryUITests: BaseUITestCase {
    // MARK: - Tests

    /// Settings → Widget 介绍 navigation renders the gallery view.
    @MainActor
    func testWidgetGalleryNavigation() {
        navigateToGallery()

        let navBar = app.navigationBars.firstMatch
        XCTAssertTrue(navBar.waitForExistence(timeout: 5), "Gallery navigation bar should appear")

        // Segmented control (桌面 / 锁屏) should be present
        let homeTabButton = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] '桌面'")
        ).firstMatch
        XCTAssertTrue(homeTabButton.waitForExistence(timeout: 5), "桌面 tab should be visible in widget gallery")
    }

    /// Home widgets tab renders systemSmall section header.
    @MainActor
    func testWidgetGalleryHomeWidgets() {
        navigateToGallery()

        // The gallery section title is uppercased, look for SMALL keyword
        let smallSection = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] 'SMALL' OR label CONTAINS[c] 'small'")
        ).firstMatch
        XCTAssertTrue(smallSection.waitForExistence(timeout: 5), "systemSmall section should be visible in home tab")
    }

    /// Tapping lock screen tab loads lock widget content.
    @MainActor
    func testWidgetGalleryLockWidgets() {
        navigateToGallery()

        let lockTab = app.buttons["gallery.tab.lock"]
        guard lockTab.waitForExistence(timeout: 5) else {
            XCTFail("Lock screen tab button should exist in widget gallery")
            return
        }
        lockTab.tap()
        sleep(1)

        let circularSection = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] 'CIRCULAR' OR label CONTAINS[c] 'circular'")
        ).firstMatch
        XCTAssertTrue(circularSection.waitForExistence(timeout: 5), "accessoryCircular section should be visible in lock tab")
    }

    // MARK: - Helpers

    @MainActor
    private func navigateToGallery() {
        let settingsTab = app.tabBars.buttons[TabLabels.settings]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5), "Settings tab should exist")
        settingsTab.tap()
        sleep(1)

        let galleryRow = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] 'Widget'")
        ).firstMatch
        XCTAssertTrue(galleryRow.waitForExistence(timeout: 5), "Widget Gallery row should exist in Settings")
        galleryRow.tap()
        sleep(1)
    }
}
