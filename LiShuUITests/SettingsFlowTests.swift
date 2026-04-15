import XCTest

final class SettingsFlowTests: BaseUITestCase {
    private let deleteAllRequiredText = "删除"

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
    func testDeleteAllDataSecondConfirmCanCancel() {
        createContact(name: "待清空联系人-取消")
        createEvent(name: "待清空事件-取消")
        createMonetaryRecord(contactName: "待清空联系人-取消", eventName: "待清空事件-取消", amount: "88")

        let settingsTab = app.tabBars.buttons[TabLabels.settings]
        settingsTab.tap()
        sleep(1)

        let deleteAllButton = app.buttons["settings.deleteAllButton"]
        XCTAssertTrue(deleteAllButton.waitForExistence(timeout: 5), "Delete all data button should exist")
        deleteAllButton.tap()

        let requiredInput = app.textFields["settings.deleteAllData.confirmTextField"]
        XCTAssertTrue(requiredInput.waitForExistence(timeout: 5), "Delete all confirmation input should appear")
        requiredInput.tap()
        requiredInput.typeText(deleteAllRequiredText)

        let confirmButton = app.buttons["settings.deleteAllData.confirmButton"]
        confirmButton.tap()

        let deleteAllMessage = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS[c] '清理范围'")
        ).firstMatch
        XCTAssertTrue(deleteAllMessage.waitForExistence(timeout: 3), "Second confirmation should describe cascade counts")

        let cancelButton = app.buttons["settings.deleteAllData.secondConfirmCancel"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 3), "Cancel option should be available in confirmation")
        cancelButton.tap()

        sleep(1)
        XCTAssertTrue(
            app.textFields["settings.deleteAllData.confirmTextField"].waitForExistence(timeout: 1),
            "Cancel should remain on delete all screen"
        )
    }

    @MainActor
    func testDeleteAllDataSecondConfirmDeletesAllData() {
        createContact(name: "待清空联系人-确认")
        createEvent(name: "待清空事件-确认")
        createMonetaryRecord(contactName: "待清空联系人-确认", eventName: "待清空事件-确认", amount: "188")

        let settingsTab = app.tabBars.buttons[TabLabels.settings]
        settingsTab.tap()
        sleep(1)

        let deleteAllButton = app.buttons["settings.deleteAllButton"]
        XCTAssertTrue(deleteAllButton.waitForExistence(timeout: 5), "Delete all data button should exist")
        deleteAllButton.tap()

        let requiredInput = app.textFields["settings.deleteAllData.confirmTextField"]
        XCTAssertTrue(requiredInput.waitForExistence(timeout: 5), "Delete all confirmation input should appear")
        requiredInput.tap()
        requiredInput.typeText(deleteAllRequiredText)

        let confirmButton = app.buttons["settings.deleteAllData.confirmButton"]
        confirmButton.tap()

        let confirmAction = app.buttons["settings.deleteAllData.secondConfirmDelete"]
        XCTAssertTrue(confirmAction.waitForExistence(timeout: 3), "Delete confirmation should appear")
        confirmAction.tap()

        sleep(1)

        settingsTab.tap()
        sleep(1)

        let contactsTab = app.tabBars.buttons[TabLabels.contacts]
        contactsTab.tap()
        sleep(1)
        XCTAssertFalse(
            app.staticTexts["待清空联系人-确认"].waitForExistence(timeout: 3),
            "Confirmed delete all should remove contacts"
        )

        let recordsTab = app.tabBars.buttons[TabLabels.records]
        recordsTab.tap()
        sleep(1)
        XCTAssertFalse(
            app.staticTexts["待清空联系人-确认"].waitForExistence(timeout: 3),
            "Confirmed delete all should remove related records"
        )
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

            let consoleTitle = app.staticTexts["开发控制台"]
            XCTAssertFalse(
                consoleTitle.waitForExistence(timeout: 1),
                "UI testing mode should keep the hidden diagnostics console unavailable"
            )

            app.navigationBars.buttons.firstMatch.tap()
        }
    }
}
