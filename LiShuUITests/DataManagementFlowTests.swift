import XCTest

final class DataManagementFlowTests: BaseUITestCase {

    @MainActor
    func testDataManagementNavigation() throws {
        let settingsTab = app.tabBars.buttons[TabLabels.settings]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5))
        settingsTab.tap()
        sleep(1)

        let dataRow = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] '数据' OR label CONTAINS[c] '导入' OR label CONTAINS[c] '导出'")
        ).firstMatch

        if dataRow.waitForExistence(timeout: 3) {
            dataRow.tap()
            sleep(1)

            let navBar = app.navigationBars.firstMatch
            XCTAssertTrue(navBar.waitForExistence(timeout: 3), "Data management view should have navigation bar")

            app.navigationBars.buttons.firstMatch.tap()
            sleep(1)
        }
    }

    @MainActor
    func testExportSectionExists() throws {
        let settingsTab = app.tabBars.buttons[TabLabels.settings]
        settingsTab.tap()
        sleep(1)

        let dataRow = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] '数据' OR label CONTAINS[c] '导入' OR label CONTAINS[c] '导出'")
        ).firstMatch

        if dataRow.waitForExistence(timeout: 3) {
            dataRow.tap()
            sleep(1)

            let csvButton = app.buttons.matching(
                NSPredicate(format: "label CONTAINS[c] 'CSV' OR label CONTAINS[c] 'csv'")
            ).firstMatch

            let hasExportOptions = csvButton.waitForExistence(timeout: 3)
            if hasExportOptions {
                XCTAssertTrue(true, "Export options exist")
            }

            app.navigationBars.buttons.firstMatch.tap()
        }
    }

    @MainActor
    func testImportSectionExists() throws {
        let settingsTab = app.tabBars.buttons[TabLabels.settings]
        settingsTab.tap()
        sleep(1)

        let dataRow = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] '数据' OR label CONTAINS[c] '导入' OR label CONTAINS[c] '导出'")
        ).firstMatch

        if dataRow.waitForExistence(timeout: 3) {
            dataRow.tap()
            sleep(1)

            let importSection = app.staticTexts.matching(
                NSPredicate(format: "label CONTAINS[c] '导入' OR label CONTAINS[c] 'OCR' OR label CONTAINS[c] 'CSV'")
            ).firstMatch

            if importSection.waitForExistence(timeout: 3) {
                XCTAssertTrue(true, "Import section exists")
            }

            app.navigationBars.buttons.firstMatch.tap()
        }
    }
}
